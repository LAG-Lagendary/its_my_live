#!/bin/bash

# Массив с 15 мордочками
faces=(
"(•_•)" "(-_-)" "(0_0)" "(^_^)" "(>_<)"
"(o_o)" "(u_u)" "(@ @)" "(x_x)" "($ $)"
"(*_*)" "(._.)" "(' ')" "(O_O)" "(Q_Q)"
)

# Выбор случайного элемента
selected_face=${faces[$(( RANDOM % ${#faces[@]} ))]}

# Сбор данных с таймаутами
TIME=$(date +"%H:%M:%S")
IP=$(hostname -I | awk '{print $1}')
# Используем короткий таймаут для определения внешнего IP
EXT_IP=$(curl -s --connect-timeout 2 --max-time 3 ifconfig.me || echo "Offline")

# Вывод информации
cat <<EOF | lolcat
(\_/)   BIO-SYNC ACTIVE
$selected_face   USER:   $USER
/ >🧬   LOCAL:  ${IP:-Unavailable}
        EXTERN: $EXT_IP
        TIME:   $TIME
──────────────────────────────────────────────────
EOF

# Дополнительная случайная мудрость
if command -v fortune > /dev/null; then
    fortune -s | lolcat
fi
