# --- Advanced Stealth Quarantine for Rabbit CLI ---
function quarantine_ru_apps() {
    local ru_apps=$(adb shell pm list packages | grep ru | cut -d ":" -f2)

    echo "--- Инициация stealth-режима для RU-пакетов ---"

    for app in $ru_apps; do
        echo "Маскирую: $app"

        # 1. Принудительная остановка
        adb shell am force-stop $app

        # 2. Блокировка доступа к статусу сети и состоянию VPN
        # Это ключевые команды, чтобы приложение не "видело" тип соединения
        adb shell appops set $app GET_USAGE_STATS deny
        adb shell appops set $app ACCESS_NETWORK_STATE deny
        adb shell appops set $app CHANGE_NETWORK_STATE deny

        # Опционально: запрет на чтение настроек телефона, где может быть инфа о VPN
        adb shell appops set $app READ_PHONE_STATE deny
    done

    echo "Маскировка завершена. Запускайте целевое приложение."
    echo "Если пошли глюки — используйте: unquarantine_ru_apps"
}

# Функция для отката изменений
function unquarantine_ru_apps() {
    local ru_apps=$(adb shell pm list packages | grep ru | cut -d ":" -f2)
    echo "--- Отключение маскировки ---"
    for app in $ru_apps; do
        adb shell appops set $app GET_USAGE_STATS allow
        adb shell appops set $app ACCESS_NETWORK_STATE allow
        adb shell appops set $app CHANGE_NETWORK_STATE allow
        adb shell appops set $app READ_PHONE_STATE allow
    done
    echo "Доступы восстановлены."
}