import runpod
import os
import requests
import subprocess
import time

# Константы путей
BASE_DIR = "/app"
SOURCE_PATH = os.path.join(BASE_DIR, "source.jpg")
TARGET_PATH = os.path.join(BASE_DIR, "target.mp4")
OUTPUT_PATH = os.path.join(BASE_DIR, "output.mp4")

DEFAULT_PHOTO = "https://raw.githubusercontent.com/rixeb777-cyber/facefusion-serverless/main/photo_2025-12-08_21-44-55.jpg"
DEFAULT_VIDEO = "https://raw.githubusercontent.com/rixeb777-cyber/facefusion-serverless/main/target.mp4"

def handler(job):
    print("🚀 АГЕНТ: Запуск генерации v75...")
    
    # Извлекаем данные
    job_input = job.get('input', {})
    source_url = job_input.get('source_url') or DEFAULT_PHOTO
    target_url = job_input.get('target_url') or DEFAULT_VIDEO

    try:
        # 1. Очистка старых файлов перед запуском
        for f in [SOURCE_PATH, TARGET_PATH, OUTPUT_PATH]:
            if os.path.exists(f): os.remove(f)

        # 2. Скачивание файлов
        print(f"📥 Загрузка медиа...")
        s_res = requests.get(source_url, timeout=60)
        t_res = requests.get(target_url, timeout=60)
        
        with open(SOURCE_PATH, "wb") as f: f.write(s_res.content)
        with open(TARGET_PATH, "wb") as f: f.write(t_res.content)

        # 3. Формируем команду CLI (как советовал GPT, но с нашими путями)
        # В новых версиях facefusion команда запускается через 'run.py'
        cmd = [
            "python3", "run.py",
            "--source", SOURCE_PATH,
            "--target", TARGET_PATH,
            "--output", OUTPUT_PATH,
            "--execution-providers", "cuda",
            "--headless" # Оставляем на случай, если версия его требует
        ]
        
        print(f"⚙️ Выполняю CLI: {' '.join(cmd)}")
        
        # Запуск с контролем вывода
        process = subprocess.run(cmd, cwd=BASE_DIR, capture_output=True, text=True)
        
        if process.returncode != 0:
            print(f"❌ Ошибка CLI: {process.stderr}")
            return {"status": "error", "message": process.stderr}

        if not os.path.exists(OUTPUT_PATH):
            return {"status": "error", "message": "Файл вывода не создан"}

        print("✅ Видео успешно создано!")
        return {
            "status": "success",
            "message": "Круто! Все готово.",
            "output_file": OUTPUT_PATH
        }

    except Exception as e:
        print(f"❌ Критическая ошибка: {str(e)}")
        return {"status": "error", "message": str(e)}

runpod.serverless.start({"handler": handler})
