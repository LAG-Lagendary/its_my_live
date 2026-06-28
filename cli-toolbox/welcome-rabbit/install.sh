#!/usr/bin/env bash

# Включение строгого режима обработки ошибок Bash (выход при любой ошибке, неинициализированной переменной)
set -euo pipefail
IFS=$'\n\t'

# Константы приложения
APP_NAME="its_my_live"
INSTALL_DIR="/opt/${APP_NAME}"
SYSTEMD_FILE="/etc/systemd/system/${APP_NAME}.service"

# Цветовое оформление вывода
GREEN='\e[32m'
RED='\e[31m'
YELLOW='\e[33m'
NC='\e[0m' # No Color

log_status() {
    echo -e "${GREEN}[SYSTEM]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# 1. Проверка прав суперпользователя
if [ "$EUID" -ne 0 ]; then
    log_error "Скрипт установки должен быть запущен с правами суперпользователя root (например, через sudo)."
    exit 1
fi

# 2. Проверка операционной системы (совместимость с Debian/Ubuntu)
if [ ! -f /etc/debian_version ]; then
    log_error "Данный скрипт автоматической установки оптимизирован только под ОС семейства Debian!"
    exit 1
fi

log_status "=========================================="
log_status "   Автоматическая установка ${APP_NAME}"
log_status "=========================================="

# 3. Обновление репозиториев и установка системных утилит
log_status "Шаг 1: Обновление пакетного менеджера и установка системных зависимостей..."
apt-get update -y
apt-get install -y python3 python3-pip python3-venv curl gnupg apt-transport-https lsb-release

# 4. Автоматическая установка RabbitMQ на Debian (Официальный метод через репозитории Cloudsmith)
if ! systemctl is-active --quiet rabbitmq-server; then
    log_status "Шаг 2: Установка брокера сообщений RabbitMQ..."

    # Добавление GPG ключей подписи репозиториев Erlang и RabbitMQ
    mkdir -p /etc/apt/keyrings

    log_status "Импорт доверенных ключей подписи..."
    curl -1sLf "https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687F29837A0F3D4EE055B81136604" | gpg --dearmor --yes -o /etc/apt/keyrings/rabbitmq.Erlang.gpg
    curl -1sLf "https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq.server.ASC" | gpg --dearmor --yes -o /etc/apt/keyrings/rabbitmq.server.gpg

    # Определение кодового имени дистрибутива Debian (например, bookworm, bullseye)
    DEB_CODENAME=$(lsb_release -cs 2>/dev/null || grep -oP '(?<=VERSION_CODENAME=)[a-z]+' /etc/os-release)

    log_status "Подключение официального зеркала APT для Debian (${DEB_CODENAME})..."
    cat <<EOF > /etc/apt/sources.list.d/rabbitmq.list
deb [signed-by=/etc/apt/keyrings/rabbitmq.Erlang.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/debian ${DEB_CODENAME} main
deb-src [signed-by=/etc/apt/keyrings/rabbitmq.Erlang.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/debian ${DEB_CODENAME} main

deb [signed-by=/etc/apt/keyrings/rabbitmq.server.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-server/deb/debian ${DEB_CODENAME} main
deb-src [signed-by=/etc/apt/keyrings/rabbitmq.server.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-server/deb/debian ${DEB_CODENAME} main
EOF

    log_status "Обновление индекса пакетов и установка erlang и rabbitmq-server..."
    apt-get update -y
    apt-get install -y erlang-base rabbitmq-server

    log_status "Активация и запуск службы RabbitMQ..."
    systemctl daemon-reload
    systemctl enable rabbitmq-server
    systemctl start rabbitmq-server
else
    log_status "Шаг 2: Служба RabbitMQ уже установлена и активна в системе. Пропускаем..."
fi

# 5. Развёртывание директории приложения и кода
log_status "Шаг 3: Подготовка рабочей директории приложения в ${INSTALL_DIR}..."
mkdir -p "${INSTALL_DIR}"

if [ -f "${APP_NAME}.py" ]; then
    cp "${APP_NAME}.py" "${INSTALL_DIR}/${APP_NAME}.py"
    chmod +x "${INSTALL_DIR}/${APP_NAME}.py"
else
    log_error "Критическая ошибка: Файл ${APP_NAME}.py не найден в текущей директории!"
    exit 1
fi

if [ -f "requirements.txt" ]; then
    cp "requirements.txt" "${INSTALL_DIR}/requirements.txt"
fi

# 6. Создание изолированного Python Virtual Environment (venv)
log_status "Шаг 4: Развертывание виртуального окружения python-venv..."
python3 -m venv "${INSTALL_DIR}/venv"
"${INSTALL_DIR}/venv/bin/pip" install --upgrade pip

if [ -f "${INSTALL_DIR}/requirements.txt" ]; then
    log_status "Установка зависимостей Python из requirements.txt..."
    "${INSTALL_DIR}/venv/bin/pip" install -r "${INSTALL_DIR}/requirements.txt"
fi

# 7. Генерация и регистрация конфигурационного файла systemd-службы с ограничениями ресурсов
log_status "Шаг 5: Регистрация системного демона systemd с лимитированием cgroups..."

cat <<EOF > "${SYSTEMD_FILE}"
[Unit]
Description=Its My Live Service Daemon (LAG Security Framework)
After=network.target rabbitmq-server.service
Requires=rabbitmq-server.service

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/venv/bin/python3 ${INSTALL_DIR}/${APP_NAME}.py
Restart=always
RestartSec=10

# Ограничения использования ресурсов (Защита стабильности Debian)
CPUAccounting=true
CPUQuota=15%
MemoryAccounting=true
MemoryMax=128M
MemorySwapMax=0
TasksMax=10

# Логирование стандартного вывода в системный журнал journald
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 8. Финальный перезапуск служб и проверка статуса
log_status "Шаг 6: Обновление конфигурации инициализации и запуск службы..."
systemctl daemon-reload
systemctl enable "${APP_NAME}.service"
systemctl restart "${APP_NAME}.service"

log_status "=========================================="
log_status "   УСТАНОВКА УСПЕШНО ЗАВЕРШЕНА!"
log_status "=========================================="
log_status "Проверить статус службы:  systemctl status ${APP_NAME}.service"
log_status "Посмотреть логи демона:   journalctl -u ${APP_NAME}.service -f"
log_status "Контроль RabbitMQ:        rabbitmqctl status"
log_status "=========================================="