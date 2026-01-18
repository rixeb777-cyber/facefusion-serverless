import runpod
import os
import requests
import subprocess
import time

# Твои дефолтные ссылки
DEFAULT_PHOTO = "https://raw.githubusercontent.com/rixeb777-cyber/facefusion-serverless/main/photo_2025-12-08_21-44-55.jpg"
DEFAULT_VIDEO = "https://raw.githubusercontent.com/rixeb777-cyber/facefusion-serverless/main/target.mp4"

def handler(job):
    print("--- ⚡️ АГЕНТ ЗАПУЩЕН (v71) ---")
    
    # 1. Чиним входящие данные
    job_input = job.get('input', {})
    source_url = job_input.get('source_url') or DEFAULT_PHOTO
    target_url = job_input.get('target_url') or DEFAULT_VIDEO

    try:
        # 2. Скачиваем файлы в текущую папку (/app)
        print("📥 Скачиваю медиа...")
        s_res = requests.get(source_url, timeout=60)
        t_res = requests.get(target_url, timeout=60)
        
        with open("s.jpg", "wb") as f: f.write(s_res.content)
        with open("t.mp4", "wb") as f: f.write(t_res.content)

        # 3. Запуск FaceFusion (теперь run.py точно в этой же папке!)
        cmd = [
            "python3", "run.py",
            "--headless",
            "--source", "s.jpg",
            "--target", "t.mp4",
            "--output", "out.mp4",
            "--execution-providers", "cuda"
        ]
        
        print("🚀 РАБОТАЮ...")
        # capture_output поможет нам увидеть ошибки в логах RunPod
        result = subprocess.run(cmd, capture_output=True, text=True)
        print(result.stdout)
        
        if result.returncode != 0:
            print(f"❌ Ошибка FaceFusion: {result.stderr}")
            return {"status": "error", "error": result.stderr}

        return {"status": "success", "message": "Видео готово!"}

    except Exception as e:
        return {"status": "error", "message": str(e)}

runpod.serverless.start({"handler": handler})
