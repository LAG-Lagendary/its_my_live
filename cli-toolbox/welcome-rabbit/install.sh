#!/bin/bash

# Настройка вывода (цвета)
GREEN='\e[1;32m'
PURPLE='\e[1;95m'
NC='\e[0m'

echo -e "${PURPLE}[*] Starting Bio-Sync (Rabbit CLI) Installation...${NC}"

# 1. Обновление баз и установка необходимых ПО для Debian
echo -e "${GREEN}[+] Installing packages (apt)...${NC}"
sudo apt update
sudo apt install -y fortune lolcat figlet curl wget git

# Попытка установить fastfetch (в старых Debian его может не быть в дефолтных репо, проверяем)
if ! apt-cache show fastfetch > /dev/null 2>&1; then
    echo -e "${PURPLE}[*] fastfetch not found in standard repositories, skipping or installing alternative...${NC}"
else
    sudo apt install -y fastfetch
fi

# 2. Скачивание самого скрипта кролика во внутреннюю директорию
TARGET_SCRIPT="$HOME/.welcome_rabbit.sh"
# Ссылка на raw-версию файла в вашем репозитории
RAW_URL="https://raw.githubusercontent.com/ВАШ_НИК/ИМЯ_РЕПО/main/welcome_rabbit.sh"

echo -e "${GREEN}[+] Downloading welcome_rabbit.sh...${NC}"
curl -s -L "$RAW_URL" -o "$TARGET_SCRIPT"

# Делаем скрипт исполняемым
chmod +x "$TARGET_SCRIPT"

# 3. Настройка .bashrc (проверка на дубликаты, чтобы не дописывать при повторном запуске)
BASHRC="$HOME/.bashrc"

if ! grep -q "welcome_rabbit.sh" "$BASHRC"; then
    echo -e "${GREEN}[+] Configuring .bashrc and Bio-Neon Style prompt...${NC}"

    cat << 'EOF' >> "$BASHRC"

# === BIO-SYNC SYSTEM STYLE SETTINGS ===

# Запуск радужного кролика
if [ -x ~/.welcome_rabbit.sh ]; then
    ~/.welcome_rabbit.sh
fi

# Футуристичный двухстрочный промпт (Bio-Neon Style)
export PS1="\[\e[1;95m\]┌──(\[\e[1;36m\]\$USER\e[1;95m\]🧬\[\e[1;36m\]\h\e[1;95m\])-[\[\e[1;32m\]\w\[\e[1;95m\]]\n\[\e[1;95m\]└─\[\e[1;32m\]❯ \[\e[0m\]"

# Алиас для быстрой проверки IP
alias myip='curl ipinfo.io | lolcat'
EOF
else
    echo -e "${PURPLE}[*] .bashrc layout already configured.${NC}"
fi

echo -e "${GREEN}[臨] Installation Complete! Restart your terminal or run: source ~/.bashrc${NC}"