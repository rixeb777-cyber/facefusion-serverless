import runpod
import os
import requests
import subprocess

def handler(job):
    # ПЫТАЕМСЯ ДОСТАТЬ ССЫЛКИ ИЗ ЗАПРОСА
    job_input = job.get('input', {})
    
    # ЕСЛИ ССЫЛОК НЕТ (NONE), МЫ ПОДСТАВЛЯЕМ ТВОИ ЛИЧНЫЕ ССЫЛКИ АВТОМАТОМ
    source_url = job_input.get('source_url') or "https://raw.githubusercontent.com/rixeb777-cyber/facefusion-serverless/main/photo_2025-12-08_21-44-55.jpg"
    target_url = job_input.get('target_url') or "https://raw.githubusercontent.com/rixeb777-cyber/facefusion-serverless/main/target.mp4"

    print(f"--- ⚡️ НАЧИНАЮ РАБОТУ ---")
    print(f"Source: {source_url}")
    print(f"Target: {target_url}")

    try:
        # Скачиваем файлы (теперь ошибки 'None' не будет, так как есть запасной вариант)
        print("Загрузка файлов...")
        s_res = requests.get(source_url)
        t_res = requests.get(target_url)
        
        with open("source.jpg", "wb") as f: f.write(s_res.content)
        with open("target.mp4", "wb") as f: f.write(t_res.content)

        # Запуск FaceFusion
        cmd = [
            "python3", "run.py",
            "--headless",
            "--source", "source.jpg",
            "--target", "target.mp4",
            "--output", "output.mp4",
            "--execution-providers", "cuda"
        ]
        
        print("Запускаю рендеринг на GPU...")
        subprocess.run(cmd, check=True)
        
        return {"status": "success", "output": "Видео готово!"}

    except Exception as e:
        print(f"ОШИБКА: {str(e)}")
        return {"status": "error", "message": str(e)}

runpod.serverless.start({"handler": handler})
