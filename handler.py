import os
import subprocess
import requests
import runpod

def download_file(url, save_path):
    response = requests.get(url, stream=True)
    if response.status_code == 200:
        with open(save_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
    else:
        raise Exception(f"Ошибка загрузки: {response.status_code}")

def handler(job):
    print("--- ⚡️ АГЕНТ ЗАПУЩЕН (v43: Auto-Path) ---")
    job_input = job['input']
    
    # Пытаемся найти файл facefusion.py в разных папках
    possible_paths = ["/app/facefusion.py", "/facefusion.py", "./facefusion.py"]
    ff_path = next((p for p in possible_paths if os.path.exists(p)), None)

    if not ff_path:
        return {"error": f"Файл facefusion.py не найден. Текущая папка: {os.getcwd()}, файлы: {os.listdir()}"}

    source_path = "/tmp/source.jpg"
    target_path = "/tmp/target.mp4"
    output_path = "/tmp/output.mp4"

    try:
        download_file(job_input.get('source_image_url'), source_path)
        download_file(job_input.get('target_video_url'), target_path)

        print(f"--- 🚀 ЗАПУСК FACEFUSION ИЗ {ff_path} ---")
        
        cmd = [
            "python3", ff_path, "run",
            "--source", source_path,
            "--target", target_path,
            "--output", output_path,
            "--headless"
        ]

        # Добавляем переменные окружения для GPU
        env = os.environ.copy()
        result = subprocess.run(cmd, capture_output=True, text=True, env=env)
        
        if result.returncode != 0:
            return {"error": f"FF Error: {result.stderr}"}

        return {"status": "success", "output": output_path}

    except Exception as e:
        return {"error": f"Ошибка: {str(e)}"}

runpod.serverless.start({"handler": handler})
