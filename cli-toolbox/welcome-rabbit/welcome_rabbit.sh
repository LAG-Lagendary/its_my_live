#!/bin/bash

# Массив с мордочками кролика (все строго по 5 символов, чтобы не ехала геометрия)
faces=(
"(•_•)" "(-_-)" "(0_0)"
"(^_^)" "(>_<)" "(o_o)"
"(u_u)" "(@_@)" "(x_x)"
"(\$_\$)" "(*_*)" "(._.)"
"( ' ')" "(O_O)" "(Q_Q)"
)

# Выбираем случайную эмоцию
random_index=$(( RANDOM % ${#faces[@]} ))
selected_face=${faces[$random_index]}

# Сбор сетевых данных
TIME=$(date +"%H:%M:%S")
IP=$(ip route get 1.0.0.1 2>/dev/null | awk '{print $7; exit}')
[[ -z "$IP" ]] && IP="Offline"

# Проверка внешнего IP с таймаутом в 1 сек
EXT_IP=$(curl -s --connect-timeout 1 ifconfig.me || echo "Offline")

# Отрисовка неонового кролика с жестко фиксированными отступами
echo -e "
 (\_/)      \e[1;95mBIO-SYNC ACTIVE\e[0m
 ${selected_face}      \e[1;36mUSER:\e[0m   $USER
 / >🌈      \e[1;36mLOCAL:\e[0m  ${IP%% *}
            \e[1;36mEXTERN:\e[0m $EXT_IP
            \e[1;36mTIME:\e[0m   $TIME
" | lolcat

# Разделитель
echo -e "\e[1;95m──────────────────────────────────────────────────\e[0m" | lolcat

# Системная инфа через fastfetch без логотипа
fastfetch --structure Title:Separator:OS:Kernel:Uptime:Packages:Shell:Display:DE:WM:CPU:GPU:Memory --logo none | lolcat

echo -e "\e[1;95m──────────────────────────────────────────────────\e[0m" | lolcat

# Мудрость дня
if command -v fortune > /dev/null; then
    fortune -s | lolcat
fi
