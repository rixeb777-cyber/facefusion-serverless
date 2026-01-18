import runpod
import os
import subprocess

def handler(job):
    # Команда 1: Показать текущую папку и все файлы (включая скрытые)
    ls_app = subprocess.check_output("ls -R /app", shell=True).decode()
    
    # Команда 2: Показать, что лежит в папке root (где часто прячутся конфиги)
    try:
        ls_root = subprocess.check_output("ls -R /root/.facefusion", shell=True).decode()
    except:
        ls_root = "Папка /root/.facefusion не найдена"

    # Команда 3: Узнать от какого пользователя работает система
    whoami = subprocess.check_output("whoami", shell=True).decode()

    # Возвращаем результат тебе в консоль RunPod
    return {
        "current_user": whoami,
        "files_in_app": ls_app,
        "files_in_root": ls_root,
        "env_home": os.environ.get('HOME')
    }

runpod.serverless.start({"handler": handler})
