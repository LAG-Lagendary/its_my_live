#!/usr/bin/env python3
import os
import subprocess
import sys

def main():
    # Приветствие в вашем фирменном стиле
    print("====================================================")
    print("Сука, бля! Че хочешь поставить? Готовься, я готов работать!")
    print("====================================================\n")

    # Определяем путь к папке с инструментами относительно корня проекта
    base_dir = os.path.dirname(os.path.abspath(__file__))
    toolbox_path = os.path.join(base_dir, "cli-toolbox")

    # Проверяем, существует ли папка cli-toolbox
    if not os.path.exists(toolbox_path):
        print(f"❌ Ошибка: Папка {toolbox_path} не найдена!")
        sys.exit(1)

    # Сканируем папку и ищем только те подпапки, где есть install.sh
    available_tools = []
    try:
        for entry in os.scandir(toolbox_path):
            if entry.is_dir():
                install_script = os.path.join(entry.path, "install.sh")
                if os.path.exists(install_script):
                    available_tools.append({
                        "name": entry.name,
                        "path": entry.path,
                        "script": install_script
                    })
    except Exception as e:
        print(f"❌ Не удалось прочитать директорию: {e}")
        sys.exit(1)

    # Если инструментов с install.sh не найдено
    if not available_tools:
        print("📭 В папке cli-toolbox не найдено инструментов с файлом install.sh.")
        sys.exit(0)

    # Сортируем для стабильного порядка вывода
    available_tools.sort(key=lambda x: x["name"])

    # Выводим список инструментов пользователю
    print("Доступные инструменты для установки:")
    for index, tool in enumerate(available_tools, start=1):
        print(f"  [{index}] {tool['name']}")
    print("")

    # Запрашиваем ввод у пользователя
    user_input = input("Введи номера через пробел (например, 1 3 4) и жми Enter: ").strip()

    if not user_input:
        print("Ничего не выбрано. Выходим.")
        sys.exit(0)

    # Парсим введенные номера
    selected_indices = []
    for num in user_input.split():
        if num.isdigit():
            idx = int(num) - 1
            if 0 <= idx < len(available_tools):
                selected_indices.append(idx)
            else:
                print(f"⚠️  Номер {num} вне диапазона и будет пропущен.")
        else:
            print(f"⚠️  '{num}' не является числом и будет пропущено.")

    if not selected_indices:
        print("❌ Нет валидных номеров для установки. Работа завершена.")
        sys.exit(1)

    # Удаляем дубликаты, если пользователь случайно ввел один номер дважды
    selected_indices = list(dict.fromkeys(selected_indices))

    print(f"\n Начинаем установку выбранных компонентов ({len(selected_indices)} шт.)...\n")

    # Запуск скриптов установки
    for idx in selected_indices:
        tool = available_tools[idx]
        print(f"⚙️  Установка: {tool['name']}...")

        try:
            # Делаем install.sh исполняемым на всякий случай
            os.chmod(tool["script"], 0o755)

            # Запускаем install.sh.
            # cwd=tool["path"] важно, чтобы скрипт выполнялся внутри своей папки
            result = subprocess.run(
                ["bash", "./install.sh"],
                cwd=tool["path"],
                check=True
            )
            print(f"✅ {tool['name']} успешно установлен!\n")
        except subprocess.CalledProcessError:
            print(f"❌ Ошибка при выполнении install.sh в {tool['name']}. Переходим к следующему.\n")
        except Exception as e:
            print(f"❌ Непредвиденная ошибка при запуске {tool['name']}: {e}\n")

    print(" Всё, что мог — сделал. Работа окончена!")

if __name__ == "__main__":
    main()