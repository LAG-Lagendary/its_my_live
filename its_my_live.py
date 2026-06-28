import urllib.request
import json
import subprocess
import os

# Базовая информация о репозитории
REPO_OWNER = "LAG-Lagendary"
REPO_NAME = "its_my_live"
TOOLBOX_URL = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/contents/cli-toolbox"

def get_available_tools():
    # Запрашиваем список файлов в директории cli-toolbox через API
    with urllib.request.urlopen(TOOLBOX_URL) as response:
        content = json.loads(response.read().decode())

    # Ищем папки, в которых лежит install.sh
    tools = []
    for item in content:
        if item['type'] == 'dir':
            # Проверяем, есть ли там install.sh (можно сделать еще один запрос,
            # или просто ожидать, что он там есть)
            tools.append({
                "name": item['name'],
                "install_url": f"https://raw.githubusercontent.com/{REPO_OWNER}/{REPO_NAME}/main/cli-toolbox/{item['name']}/install.sh"
            })
    return tools

# Запуск в цикле:
# subprocess.run(["bash", "-c", f"curl -s {tool['install_url']} | bash"])