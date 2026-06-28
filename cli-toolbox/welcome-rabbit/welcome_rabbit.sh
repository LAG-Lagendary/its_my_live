#!/bin/bash

# Путь к .bashrc и целевой путь для скрипта
BASHRC="$HOME/.bashrc"
DEST_SCRIPT="$HOME/.welcome_rabbit.sh"
RAW_URL="https://raw.githubusercontent.com/LAG-Lagendary/its_my_live/main/cli-toolbox/welcome-rabbit/welcome_rabbit.sh"

# Блок текста, который мы ищем и хотим добавить
# Используем одинарные кавычки, чтобы сохранить символ ~ в исходном виде
BLOCK_TO_ADD=$(cat << 'EOF'
if [ -x ~/.welcome_rabbit.sh ]; then
    ~/.welcome_rabbit.sh
fi
EOF
)

echo "Проверяем наличие автозапуска в .bashrc..."

# Ищем первую строку блока в .bashrc. Если не нашли — добавляем весь блок.
if ! grep -Fq "if [ -x ~/.welcome_rabbit.sh ]; then" "$BASHRC"; then
    echo "Строки не найдены. Добавляем блок автозапуска в конец $BASHRC..."
    echo "" >> "$BASHRC" # Добавляем пустую строку для аккуратности
    echo "$BLOCK_TO_ADD" >> "$BASHRC"
else
    echo "Автозапуск уже прописан в .bashrc, пропускаем."
fi

echo "Проверяем наличие самого скрипта..."

# Скачиваем скрипт из репозитория, если его ещё нет, или обновляем его
if [ ! -f "$DEST_SCRIPT" ]; then
    echo "Скачиваем welcome_rabbit.sh в домашнюю директорию..."
    if curl -sSf "$RAW_URL" -o "$DEST_SCRIPT"; then
        echo "Файл успешно скачан."
        # Делаем скрипт исполняемым
        chmod +x "$DEST_SCRIPT"
        echo "Скрипту присвоены права на исполнение."
    else
        echo "Ошибка: Не удалось скачать файл. Проверьте подключение к сети или URL." >&2
        exit 1
    fi
else
    echo "Файл $DEST_SCRIPT уже существует."
fi

echo "Готово! Всё настроено."