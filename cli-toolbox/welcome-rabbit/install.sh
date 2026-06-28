echo "=== Шаг 4: Развертывание Твоего Маскота (Rabbit CLI) ==="

# Задаем жесткий путь к хоуму лага, как ты просил
TARGET_HOME="/home/lag"
TARGET_SCRIPT="$TARGET_HOME/.welcome_rabbit.sh"

# Проверяем, есть ли файл локально (если репозиторий уже склонирован)
if [ -f "welcome_rabbit.sh" ]; then
    cp welcome_rabbit.sh "$TARGET_SCRIPT"
else
    # Если ставим «в один клик» из сети — выкачиваем RAW-файл из твоего репозитория
    echo "Скачиваем маскота из репозитория..."
    curl -sLf "https://raw.githubusercontent.com/LAG-Lagendary/its_my_live/main/welcome_rabbit.sh" -o "$TARGET_SCRIPT"
fi

# Выставляем права и владельца (пользователь lag)
chmod +x "$TARGET_SCRIPT"
chown lag:lag "$TARGET_SCRIPT"

# Интеграция стилей и промпта в .bashrc пользователя lag
BASHRC="$TARGET_HOME/.bashrc"

if [ -f "$BASHRC" ]; then
    if ! grep -q "welcome_rabbit.sh" "$BASHRC"; then
        tee -a "$BASHRC" << 'EOF'

# === STYLE SETTINGS ===
if [ -x ~/.welcome_rabbit.sh ]; then
    ~/.welcome_rabbit.sh
fi

# Футуристичный двухстрочный промпт (Bio-Neon Style)
export PS1="\[\e[1;95m\]┌──(\[\e[1;36m\]\u\e[1;95m\]🧬\[\e[1;36m\]\h\[\e[1;95m\])-[\[\e[1;32m\]\w\[\e[1;95m\]]\n\[\e[1;95m\]└─\[\e[1;32m\]❯ \[\e[0m\]"

# Алиас для быстрой проверки IP
alias myip='curl ipinfo.io | lolcat'
EOF
        echo "Настройки Bio-Neon промпта добавлены в $BASHRC"
    else
        echo "Маскот уже был прописан в $BASHRC, пропускаем."
    fi
else
    echo "Предупреждение: Файл $BASHRC не найден!"
fi