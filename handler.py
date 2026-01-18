import runpod
import subprocess
import requests
import os
import sys

def download_file(url, save_path):
    print(f"DEBUG: Starting download from {url} to {save_path}")
    try:
        response = requests.get(url, stream=True, timeout=30)
        if response.status_code == 200:
            with open(save_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
            print(f"DEBUG: Download successful: {save_path}")
        else:
            print(f"ERROR: Download failed. HTTP Status: {response.status_code}")
    except Exception as e:
        print(f"ERROR: Exception during download: {str(e)}")

def handler(job):
    job_input = job['input']
    source_url = job_input.get('source')
    target_url = job_input.get('target')

    source_path = "/app/source.jpg"
    target_path = "/app/target.mp4"
    output_path = "/app/output.mp4"

    # 1. Скачивание
    download_file(source_url, source_path)
    download_file(target_url, target_path)

    # 2. Формируем команду с DEBUG-логированием
    command = [
        "python3", "run.py",
        "--processors", "face_swapper",
        "-s", source_path,
        "-t", target_path,
        "-o", output_path,
        "--headless",
        "--log-level", "debug"  # <--- ВОТ ЭТО ДАСТ НАМ ВСЕ ПОДРОБНОСТИ
    ]

    print(f"DEBUG: Executing command: {' '.join(command)}")

    try:
        # Используем Popen для вывода логов в реальном времени
        process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT, # Склеиваем ошибки и обычный текст
            text=True,
            bufsize=1
        )

        # Печатаем каждую строку, которую выдает нейронка
        for line in process.stdout:
            print(f"FACEFUSION_LOG: {line.strip()}")
            sys.stdout.flush() # Принудительно отправляем в консоль RunPod

        process.wait()
        
        if process.returncode != 0:
            print(f"ERROR: Process exited with code {process.returncode}")

    except Exception as e:
        print(f"ERROR: Subprocess crash: {str(e)}")

    if os.path.exists(output_path):
        return {"status": "success", "output_file": output_path}
    else:
        # Если файла нет, возвращаем статус ошибки для дебага
        return {"status": "failed", "message": "Look at the logs for 'FACEFUSION_LOG' entries"}

runpod.serverless.start({"handler": handler})
