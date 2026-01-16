import runpod
import os
import subprocess
import requests
import time

# --- 🚀 КОНФИГУРАЦИЯ ---
# Мы больше ничего не скачиваем при запуске, всё уже в v40!
FACEFUSION_PATH = "/app/facefusion"

def handler(job):
    job_input = job['input']
    
    # Извлекаем параметры из запроса
    source_url = job_input.get("source_image_url")
    target_url = job_input.get("target_video_url")
    
    if not source_url or not target_url:
        return {"error": "Нужны source_image_url и target_video_url"}

    print(f"--- 📥 НАЧАЛО ЗАГРУЗКИ ФАЙЛОВ ---")
    
    # Качаем файлы во временную папку
    try:
        source_res = requests.get(source_url)
        with open("/tmp/source.jpg", "wb") as f:
            f.write(source_res.content)
            
        target_res = requests.get(target_url)
        with open("/tmp/target.mp4", "wb") as f:
            f.write(target_res.content)
    except Exception as e:
        return {"error": f"Ошибка загрузки файлов: {str(e)}"}

    print(f"--- 🎭 ЗАПУСК FACEFUSION ---")
    
    # Команда запуска (используем GPU через onnxruntime)
    output_path = "/tmp/output.mp4"
    cmd = [
        "python3", "facefusion.py", "run",
        "--source", "/tmp/source.jpg",
        "--target", "/tmp/target.mp4",
        "--output", output_path,
        "--execution-providers", "cuda"
    ]
    
    try:
        # Запускаем процесс и ждем завершения
        result = subprocess.run(cmd, cwd=FACEFUSION_PATH, capture_output=True, text=True)
        print(result.stdout)
        
        if result.returncode != 0:
            return {"error": "FaceFusion завершился с ошибкой", "details": result.stderr}
            
    except Exception as e:
        return {"error": f"Ошибка выполнения: {str(e)}"}

    # Здесь должна быть логика отправки готового файла в S3 или возврата ссылки
    # Пока возвращаем просто статус успеха для теста
    return {
        "status": "success",
        "message": "Видео обработано",
        "output_file_exists": os.path.exists(output_path)
    }

print("--- ⚡ АГЕНТ ЗАПУЩЕН (v40: Cloud Build) ---")
runpod.serverless.start({"handler": handler})
