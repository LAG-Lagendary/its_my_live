#!/usr/bin/env bash
# Универсальный скрипт: RabbitMQ + Твой Маскот (Rabbit CLI)
set -euo pipefail

APP_DIR="/opt/its_my_live"
LOG_DIR="/var/log/its_my_live"
CONF_DIR="/etc/its_my_live"
RABBITMQ_USER="live_admin"
RABBITMQ_PASS=$(openssl rand -hex 16)

# Определяем реального пользователя (не root), который запустил скрипт через sudo
REAL_USER=${SUDO_USER:-$USER}
REAL_USER_HOME=$(eval echo "~$REAL_USER")

if [ "$EUID" -ne 0 ]; then
    echo "Ошибка: Скрипт должен быть запущен от имени root (через sudo)." >&2
    exit 1
fi

echo "=== Шаг 1: Установка системных утилит и пакетов для Маскота ==="
apt-get update -y
# Добавляем fastfetch, fortune, lolcat, figlet для интерфейса кролика
apt-get install -y curl gnupg apt-transport-https python3 python3-pip python3-venv openssl lsb-release fortune-mod lolcat fastfetch figlet

DEBIAN_CODENAME=$(lsb_release -cs 2>/dev/null || grep -oP 'VERSION_CODENAME=\K\w+' /etc/os-release)

echo "=== Шаг 2: Настройка репозиториев и установка RabbitMQ ==="
rm -f /usr/share/keyrings/com.rabbitmq.team.gpg
curl -1sLf "https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA" \
    | gpg --dearmor | tee /usr/share/keyrings/com.rabbitmq.team.gpg > /dev/null

tee /etc/apt/sources.list.d/rabbitmq.list <<EOF
deb [arch=amd64 signed-by=/usr/share/keyrings/com.rabbitmq.team.gpg] https://deb2.rabbitmq.com/rabbitmq-erlang/ubuntu noble main
deb [arch=amd64 signed-by=/usr/share/keyrings/com.rabbitmq.team.gpg] https://deb2.rabbitmq.com/rabbitmq-server/debian $DEBIAN_CODENAME main
EOF

apt-get update -y
apt-get install -y erlang-base erlang-crypto erlang-ssl erlang-mnesia rabbitmq-server --fix-missing

systemctl enable rabbitmq-server --now
sleep 3
rabbitmq-plugins enable rabbitmq_management

if rabbitmqctl list_users | grep -q "$RABBITMQ_USER"; then
    rabbitmqctl delete_user "$RABBITMQ_USER"
fi
rabbitmqctl add_user "$RABBITMQ_USER" "$RABBITMQ_PASS"
rabbitmqctl set_user_tags "$RABBITMQ_USER" administrator
rabbitmqctl set_permissions -p / "$RABBITMQ_USER" ".*" ".*" ".*"
rabbitmqctl delete_user guest || true

echo "=== Шаг 3: Развертывание Python-агента ==="
mkdir -p "$APP_DIR" "$LOG_DIR" "$CONF_DIR"
# (Предполагается, что agent.py лежит в той же папке, откуда запущен скрипт)
[ -f agent.py ] && cp agent.py "$APP_DIR/agent.py" || touch "$APP_DIR/agent.py"
chmod +x "$APP_DIR/agent.py"

python3 -m venv "$APP_DIR/venv"
"$APP_DIR/venv/bin/pip" install --upgrade pip
"$APP_DIR/venv/bin/pip" install pika python-dotenv

tee "$CONF_DIR/.env" <<EOF
RABBITMQ_HOST=localhost
RABBITMQ_USER=$RABBITMQ_USER
RABBITMQ_PASS=$RABBITMQ_PASS
QUEUE_NAME=live_tasks
EOF
chmod 600 "$CONF_DIR/.env"
ln -sf "$CONF_DIR/.env" "$APP_DIR/.env"

echo "=== Шаг 4: Развертывание Твоего Маскота (Rabbit CLI) ==="
TARGET_SCRIPT="$REAL_USER_HOME/.welcome_rabbit.sh"

tee "$TARGET_SCRIPT" <<'EOF'
#!/bin/bash

# Массив с разными мордочками (15 вариантов)
faces=(
" (•_•)" " (-_-)" " (0_0)"
" (^_^)" " (>_<)" " (o_o)"
" (u_u)" " (@ @)" " (x_x)"
" (\$ \$)" " (*_*)" " (._.)"
" (' ')" " (O_O)" " (Q_Q)"
)

# Выбираем случайный индекс
random_index=$(( RANDOM % ${#faces[@]} ))
selected_face=${faces[$random_index]}

# Сбор данных
TIME=$(date +"%H:%M:%S")
IP=$(hostname -I | awk '{print $1}')
EXT_IP=$(curl -s --connect-timeout 1 ifconfig.me || echo "Offline")

# Отрисовка кролика Bio-Sync
echo -e "
(\\_/) \e[1;95mBIO-SYNC ACTIVE\e[0m
${selected_face} \e[1;36mUSER:\e[0m $USER
/ >  \e[1;36mLOCAL:\e[0m ${IP%% *}
\e[1;36mEXTERN:\e[0m $EXT_IP
\e[1;36mTIME:\e[0m $TIME
\e[1;95m──────────────────────────────────────────────────\e[0m" | lolcat

# Проверка fastfetch и вывод структуры
if command -v fastfetch > /dev/null; then
    fastfetch --structure Title:Separator:OS:Kernel:Uptime:Packages:Shell:DE:WM:CPU:Memory --logo none | lolcat
    echo -e "\e[1;95m──────────────────────────────────────────────────\e[0m" | lolcat
fi

# Мудрость дня
if command -v fortune > /dev/null; then
    fortune -s | lolcat
fi
EOF

chmod +x "$TARGET_SCRIPT"
chown "$REAL_USER:$REAL_USER" "$TARGET_SCRIPT"

# Интеграция в .bashrc реального пользователя, если её там еще нет
BASHRC="$REAL_USER_HOME/.bashrc"
if ! grep -q "welcome_rabbit.sh" "$BASHRC"; then
    tee -a "$BASHRC" <<EOF

# === STYLE SETTINGS ===
if [ -x ~/.welcome_rabbit.sh ]; then
    ~/.welcome_rabbit.sh
fi

export PS1="\\[\\e[1;95m\\]┌──(\\[\\e[1;36m\\]\\u\\e[1;95m\\]🧬\\[\\e[1;36m\\]\\h\\e[1;95m\\])-[\\[\\e[1;32m\\]\\w\\e[1;95m\\]]\\n\\[\\e[1;95m\\]└─\\[\\e[1;32m\\]❯ \\[\\e[0m\\]"
alias myip='curl ipinfo.io | lolcat'
EOF
fi

echo "=== Все готово! Перезапусти терминал или выполни: source ~/.bashrc ==="