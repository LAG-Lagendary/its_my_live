#!/bin/bash

# --- НАСТРОЙКИ ---
# Обычный софт из apt
APT_SOFT=("ufw" "libreoffice" "gimp" "reaper" "anydesk" "kate" "dolphin" "rclone" "feathernotes")

# --- ЛОГИРОВАНИЕ ---
LOG_FILE="install_log.txt"
echo "--- ЛОГ УСТАНОВКИ $(date) ---" > $LOG_FILE

echo "===================================================="
echo "🚑 РЕАНИМАТОР ДЕБИАНА ЗАПУЩЕН!"
echo "===================================================="

# 1. Обновление системы
echo "🔄 Обновляю списки пакетов..."
sudo apt update && sudo apt upgrade -y >> $LOG_FILE 2>&1

SUCCESS=()
FAILED=()

# 2. Установка софта из репозиториев Debian
for app in "${APT_SOFT[@]}"; do
    echo "⚙️ Установка $app..."
    if sudo apt install -y "$app" >> $LOG_FILE 2>&1; then
        SUCCESS+=("$app")
    else
        FAILED+=("$app")
    fi
done

# 3. Специальная установка (GoST, AmnesiaWG, Xray)
echo "🚀 Накатываю спец-инструменты (GoST, AmnesiaWG, Xray)..."

# Установка GoST v3
echo "  - Настройка GoST v3..."
# Здесь логика установки GoST (замени на реальный метод установки)
if (curl -fsSL https://github.com/go-gost/gost/releases/latest/download/gost-linux-amd64.tar.gz | tar -xz -C /usr/local/bin) >> $LOG_FILE 2>&1; then
    SUCCESS+=("gost-v3")
else
    FAILED+=("gost-v3")
fi

# Установка AmnesiaWG
echo "  - Настройка AmnesiaWG..."
if (echo "deb [trusted=yes] https://repo.amnesia.am/debian stable main" | sudo tee /etc/apt/sources.list.d/amnesia.list > /dev/null && sudo apt update && sudo apt install -y amnesia-wg) >> $LOG_FILE 2>&1; then
    SUCCESS+=("amnesia-wg")
else
    FAILED+=("amnesia-wg")
fi

# Установка Xray (VLESS)
echo "  - Настройка Xray (VLESS)..."
if (bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install) >> $LOG_FILE 2>&1; then
    SUCCESS+=("xray-vless")
else
    FAILED+=("xray-vless")
fi

# 4. Итоги
echo -e "\n===================================================="
echo "✅ Успешно установлено:"
for item in "${SUCCESS[@]}"; do echo "  [OK] $item"; done

if [ ${#FAILED[@]} -ne 0 ]; then
    echo -e "\n❌ Ошибки при установке (смотри логи):"
    for item in "${FAILED[@]}"; do echo "  [FAIL] $item"; done
    echo -e "\nПолный лог ошибок: $LOG_FILE"
fi
echo "===================================================="
echo "Всё, что мог — сделал. Работа окончена!"
