#!/bin/bash

# Путь к .bashrc, целевое имя файла в home и его raw URL на GitHub
BASHRC="$HOME/.bashrc"
DEST_SCRIPT="$HOME/.bash_aliases.sh"
RAW_URL="https://raw.githubusercontent.com/LAG-Lagendary/its_my_live/main/cli-toolbox/bash_aliases/bash_aliases.sh"

# Блок текста, который мы ищем в .bashrc и добавляем при отсутствии
BLOCK_TO_ADD=$(cat << 'EOF'
if [ -f ~/.bash_aliases.sh ]; then
    . ~/.bash_aliases.sh
fi
EOF
)

echo "Проверяем наличие подключения .bash_aliases.sh в .bashrc..."

# Проверяем по первой строчке условия.
# Используем -F, чтобы символы [ ] не обрабатывались как регулярное выражение.
if ! grep -Fq "if [ -f ~/.bash_aliases.sh ]; then" "$BASHRC"; then
    echo "Строки подключения не найдены. Добавляем блок в конец $BASHRC..."
    echo "" >> "$BASHRC" # Пустая строка для читаемости кода
    echo "$BLOCK_TO_ADD" >> "$BASHRC"
else
    echo "Файл .bash_aliases.sh уже подключается в .bashrc, пропускаем этот шаг."
fi

echo "Проверяем наличие самого файла скрипта..."

# Скачиваем файл из репозитория, если его ещё нет
if [ ! -f "$DEST_SCRIPT" ]; then
    echo "Скачиваем bash_aliases.sh в домашнюю директорию как .bash_aliases.sh..."
    if curl -sSf "$RAW_URL" -o "$DEST_SCRIPT"; then
        echo "Файл успешно скачан."
        # Делаем файл исполняемым (на всякий случай, хотя для source/. это не всегда строго обязательно)
        chmod +x "$DEST_SCRIPT"
        echo "Права на исполнение установлены."
    else
        echo "Ошибка: Не удалось скачать файл. Проверьте сеть или URL." >&2
        exit 1
    fi
else
    echo "Файл $DEST_SCRIPT уже существует в домашней директории."
fi

echo "Готово! Всё настроено."