import os
import subprocess
import requests
import runpod

def download_file(url, save_path):
    print(f"--- НАЧАЛО ЗАГРУЗКИ ФАЙЛА ---")
    response = requests.get(url, stream=True)
    if response.status_code == 200:
        with open(save_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        print(f"--- ФАЙЛ СОХРАНЕН: {save_path} ---")
    else:
        raise Exception(f"Ошибка загрузки: {response.status_code}")

def handler(job):
    print("--- ⚡️ АГЕНТ ЗАПУЩЕН (v42: Final Path) ---")
    job_input = job['input']
    
    source_path = "/tmp/source.jpg"
    target_path = "/tmp/target.mp4"
    output_path = "/tmp/output.mp4"

    try:
        download_file(job_input.get('source_image_url'), source_path)
        download_file(job_input.get('target_video_url'), target_path)

        print("--- 🚀 ЗАПУСК FACEFUSION ---")
        
        # Используем полный путь к python3 и facefusion.py
        cmd = [
            "/usr/bin/python3", "/app/facefusion.py", "run",
            "--source", source_path,
            "--target", target_path,
            "--output", output_path,
            "--headless"
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            return {"error": f"FaceFusion error: {result.stderr}"}

        return {"status": "success", "message": "Готово!", "output": output_path}

    except Exception as e:
        return {"error": f"Ошибка: {str(e)}"}

runpod.serverless.start({"handler": handler})
