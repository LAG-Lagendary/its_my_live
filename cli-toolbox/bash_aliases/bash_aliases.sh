#===============================================
#BASH ALIASES AND FUNCTIONS CONFIGURATION
#===============================================
#1. НАВИГАЦИЯ И ФАЙЛОВАЯ СИСТЕМА
#Быстрый переход на несколько уровней вверх
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
#Быстрый переход в домашнюю директорию и корень
alias home='cd ~'
alias top='cd /'
#Показать размер текущей директории в удобочитаемом виде
alias duf='du -sh *'
#Показать информацию о дисковом пространстве
alias dfh='df -h'
#Создать директорию и сразу перейти в нее
mkcd1() { mkdir -p "$1" && cd "$1"; }
alias mkcd=mkcd1
# Копирование с прогрессом (использует rsync
cpr() {
  rsync -ah --progress "$1" "$2"
}

#2. ИСТОРИЯ, ФАЙЛОВЫЕ УТИЛИТЫ И АРХИВЫ
#вывести последние 30 команд
alias h='history | tail -30'
#ls aliases
alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alF'
#делаем исполняемым для всех
alias ax="chmod a+x"
#попробовать в начале присоединиться к имеющейся сессии
alias tm='tmux attach || tmux new'
#работа с архивами
alias TAR='tar -zcvf'
alias UNTAR='tar -zxvf'

#3. СИСТЕМНОЕ АДМИНИСТРИРОВАНИЕ И СЕТЬ
#обновить инфу в пакетном менеджере (для Debian/Ubuntu)
alias update="sudo apt update"
alias UU="sudo apt update && sudo apt upgrade -y"
#перечитать конфиг Bash
alias bash-reload='source ~/.bashrc'
#Показать 10 самых ресурсоемких процессов по памяти
alias top10='ps aux --sort=-%mem | head -11'
#Показать текущий публичный IP адрес
alias myip='curl ifconfig.me' # Раскомментируйте для активации
#Простой вывод сетевых прослушивающих портов (аналог netstat)
alias ports='ss -tuln'
#Очистить экран и историю команд в буфере терминала
alias cls='clear && history -c'
#Редактировать основной файл конфига bash
alias ebash='${EDITOR:-nano} ~/.bashrc'
alias rebash='source ~/.bashrc'

#4. РАБОТА С GIT
alias gs='git status'
alias gd='git diff'
alias gitb='git branch -v'
alias gitc='git commit -m'
alias gitcam='git commit -a -m'
alias githist='git log --pretty=format:"%h %ad | %s%d [%an]" --graph --date=short'
alias go='git checkout'
#Дополнительные алиасы git
alias gadd='git add .'
alias gpush='git push'
alias gpull='git pull'
alias gco='git checkout'

#5. СПЕЦИАЛЬНЫЕ СКРИПТЫ И VPN
alias shull="~/ollama_cli.sh"
alias ovpn1='sudo openvpn --config /etc/openvpn/XXX.ovpn'
alias ovpn2='sudo openvpn --config /etc/openvpn/XYZ.ovpn'
alias ovpn3='sudo openvpn --config /etc/openvpn/ZZZ.ovpn'
alias ovpn4='sudo openvpn --config /etc/openvpn/ZXC.ovpn'
alias pt='python3 /home/lag/Documents/python.py'
#Быстрое создание временного пароля/ключа
alias genpass='openssl rand -base64 20'

#===============================================
# --- Определите стили Prompt ---
#===============================================

# 1. Установите переменную для выбора стиля
PROMPT_ALTERNATIVE="twoline"

# 2. Определите переменные для кодов цвета ANSI
# ВАЖНО: \[\033[...m\] используется, чтобы Bash правильно считал ширину Prompt.
PROMPT_COLOR='\[\033[0;36m\]'  # Голубой/Циан (Цвет рамки)
PURPLE_COLOR='\[\033[0;35m\]' # ФИОЛЕТОВЫЙ/ПУРПУРНЫЙ (Цвет user@host)
RESET_COLOR='\[\033[0m\]'     # Сброс цвета
RED_COLOR='\[\033[0;31m\]'    # Красный
BOLD='\[\033[1m\]'           # Жирный
NO_BOLD='\[\033[0m\]'         # Нежирный

# 3. Функция, которая будет устанавливать PS1
configure_bash_prompt() {
    # Здесь используется переменная, которую мы установили выше
    case "$PROMPT_ALTERNATIVE" in
        twoline)
            # Двустрочный Prompt: ┌──(user@host - ФИОЛЕТОВЫЙ)-[/current/dir]\n└─$
            PS1="$PROMPT_COLOR┌──${BOLD}${PURPLE_COLOR}\u@\h${PROMPT_COLOR}${NO_BOLD}-[\w]${RESET_COLOR}\n${PROMPT_COLOR}└─${BOLD}\$ ${RESET_COLOR}"
            ;;
        oneline)
            # Однострочный (классический): user@host - ФИОЛЕТОВЫЙ:dir$
            PS1="${PURPLE_COLOR}\u@\h${RESET_COLOR}:${PROMPT_COLOR}\w${RESET_COLOR}\$ "
            ;;
        backtrack)
            # Однострочный (с альтернативными цветами: КРАСНЫЙ user@host)
            PS1="${RED_COLOR}\u@\h${RESET_COLOR}:${PROMPT_COLOR}\w${RESET_COLOR}\$ "
            ;;
        *)
            # Стиль по умолчанию, если переменная не установлена или неверна
            PS1="\u@\h:\w\$ "
            ;;
    esac
}

# 4. Вызовите функцию, чтобы применить Prompt
configure_bash_prompt








