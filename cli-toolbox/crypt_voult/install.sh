#!/bin/bash

# Путь к папке назначения
DEST_DIR="$HOME/Documents/VeraCrypt_Vaults"
mkdir -p "$DEST_DIR"

echo "📥 Скачиваю содержимое репозитория..."

# Используем git archive для скачивания конкретной папки из репозитория
# Нам не нужно клонировать весь проект, только одну папку
curl -L https://github.com/LAG-Lagendary/its_my_live/archive/main.tar.gz | tar -xz -C "$DEST_DIR" --strip-components=2 "its_my_live-main/cli-toolbox/crypt_voult"

# Теперь удаляем скрипт установки из папки назначения, чтобы он там не валялся
if [ -f "$DEST_DIR/install.sh" ]; then
    rm "$DEST_DIR/install.sh"
    echo "🧹 Файл install.sh удален из папки назначения."
fi

echo "✅ Все файлы (кроме install.sh) успешно перемещены в $DEST_DIR"