#!/bin/bash

# Массив с разными мордочками (15 вариантов)
faces=(
" (•_•)" " (-_-)" " (0_0)"
" (^_^)" " (>_<)" " (o_o)"
" (u_u)" " (@ @)" " (x_x)"
" ($ $)" " (*_*)" " (._.)"
" (' ')" " (O_O)" " (Q_Q)"
)

# Выбираем случайный индекс
random_index=$(( RANDOM % ${#faces[@]} ))
selected_face=${faces[$random_index]}

# Сбор данных
TIME=$(date +"%H:%M:%S")
IP=$(hostname -I | awk '{print $1}')
EXT_IP=$(curl -s --connect-timeout 1 ifconfig.me || echo "Offline")

# Отрисовка
echo -e "
(\\_/) \e[1;95mBIO-SYNC ACTIVE\e[0m
${selected_face} \e[1;36mUSER:\e[0m $USER
/ >  \e[1;36mLOCAL:\e[0m ${IP%% *}
\e[1;36mEXTERN:\e[0m $EXT_IP
\e[1;36mTIME:\e[0m $TIME
\e[1;95m──────────────────────────────────────────────────\e[0m" | lolcat

# Проверка fastfetch
if command -v fastfetch > /dev/null; then
    fastfetch --structure Title:Separator:OS:Kernel:Uptime:Packages:Shell:DE:WM:CPU:Memory --logo none | lolcat
    echo -e "\e[1;95m──────────────────────────────────────────────────\e[0m" | lolcat
fi

# Мудрость дня
if command -v fortune > /dev/null; then
    fortune -s | lolcat
fi