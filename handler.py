import runpod
import os
import subprocess
import requests
import uuid

# Жестко задаем рабочую директорию
BASE_DIR = "/app"
os.chdir(BASE_DIR)

def download_file(url, save_path):
    """Скачивает файл по ссылке"""
    response = requests.get(url, stream=True)
    if response.status_code == 200:
        with open(save_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        print(f"✅ Файл скачан: {save_path}")
    else:
        raise Exception(f"❌ Не удалось скачать файл: {url}")

def handler(job):
    job_input = job['input']
    
    # Ссылки из входных данных
    source_url = job_input.get('source_url')
    target_url = job_input.get('target_url')
    
    if not source_url or not target_url:
        return {"error": "Необходимо указать source_url и target_url"}

    # Генерируем уникальные имена для файлов этой задачи
    job_id = str(uuid.uuid4())[:8]
    source_path = os.path.join(BASE_DIR, f"source_{job_id}.jpg")
    target_path = os.path.join(BASE_DIR, f"target_{job_id}.mp4")
    output_path = os.path.join(BASE_DIR, f"output_{job_id}.mp4")

    try:
        # 1. Скачиваем файлы
        print("🚀 Скачивание исходных файлов...")
        download_file(source_url, source_path)
        download_file(target_url, target_path)

        # 2. Формируем команду запуска FaceFusion
        # Мы запускаем наш созданный /app/run.py
        cmd = [
            "python3", "run.py",
            "--source", source_path,
            "--target", target_path,
            "--output", output_path,
            "--headless",
            "--execution-providers", "cuda"
        ]

        print(f"⚙️ Запуск FaceFusion: {' '.join(cmd)}")
        
        # 3. Запускаем процесс
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"❌ Ошибка FaceFusion: {result.stderr}")
            return {"error": "Ошибка при обработке", "details": result.stderr}

        # 4. Проверяем результат (здесь должна быть логика загрузки в облако, например S3)
        # Для теста вернем подтверждение, что файл готов
        if os.path.exists(output_path):
            print(f"✅ Готово! Файл сохранен: {output_path}")
            return {
                "status": "success",
                "message": "Face swap completed",
                "output_file_name": f"output_{job_id}.mp4"
            }
        else:
            return {"error": "Файл результата не найден"}

    except Exception as e:
        return {"error": str(e)}
    
    finally:
        # Очистка временных файлов (опционально)
        # if os.path.exists(source_path): os.remove(source_path)
        pass

# Запуск воркера
runpod.serverless.start({"handler": handler})
