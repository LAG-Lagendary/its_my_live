#!/bin/bash

# Настройки
INSTALL_DIR="$HOME/.bash_aliases"
SCRIPT_NAME="bash_aliases.sh"
DEST_PATH="$INSTALL_DIR/$SCRIPT_NAME"
BASHRC="$HOME/.bashrc"
RAW_URL="https://raw.githubusercontent.com/LAG-Lagendary/its_my_live/main/cli-toolbox/bash_aliases/$SCRIPT_NAME"

echo "=== Инициализация установки Rabbit CLI Tools ==="

# 1. Создаем директорию для инструментов
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Создаю директорию $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
fi

# 2. Скачиваем файл скрипта
echo "Загрузка актуального $SCRIPT_NAME..."
if curl -sSf "$RAW_URL" -o "$DEST_PATH"; then
    chmod +x "$DEST_PATH"
    echo "Файл успешно установлен в $DEST_PATH"
else
    echo "Ошибка: не удалось скачать скрипт. Проверьте сеть." >&2
    exit 1
fi

# 3. Интеграция в .bashrc
# Проверяем, есть ли уже строка подключения
HOOK="[ -f $DEST_PATH ] && . $DEST_PATH"

if ! grep -Fq "$HOOK" "$BASHRC"; then
    echo "Добавляю хук в .bashrc..."
    echo "" >> "$BASHRC"
    echo "# Rabbit CLI integration" >> "$BASHRC"
    echo "$HOOK" >> "$BASHRC"
else
    echo "Хук уже присутствует в .bashrc."
fi

echo "=== Установка завершена ==="
echo "Для применения изменений выполните: source ~/.bashrc"