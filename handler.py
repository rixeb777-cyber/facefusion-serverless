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
        print(f"--- ФАЙЛ СОХРАНЕН: {save_path} ({os.path.getsize(save_path)} байт) ---")
    else:
        raise Exception(f"Ошибка загрузки файлов: {response.status_code}")

def handler(job):
    print("--- ⚡️ АГЕНТ ЗАПУЩЕН (v41: Path Fix) ---")
    job_input = job['input']
    
    source_url = job_input.get('source_image_url')
    target_url = job_input.get('target_video_url')

    if not source_url or not target_url:
        return {"error": "Нужны source_image_url и target_video_url"}

    # Создаем временные пути
    source_path = "/tmp/source.jpg"
    target_path = "/tmp/target.mp4"
    output_path = "/tmp/output.mp4"

    try:
        download_file(source_url, source_path)
        download_file(target_url, target_path)

        print("--- 🚀 ЗАПУСК FACEFUSION ---")
        
        # В новых образах RunPod FaceFusion обычно лежит в /app или прямо в корне
        # Мы используем команду python facefusion.py напрямую
        cmd = [
            "python", "facefusion.py", "run",
            "--source", source_path,
            "--target", target_path,
            "--output", output_path,
            "--headless"
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"Ошибка FF: {result.stderr}")
            return {"error": f"FaceFusion error: {result.stderr}"}

        return {"status": "success", "message": "Готово!", "output_file": output_path}

    except Exception as e:
        return {"error": f"Ошибка выполнения: {str(e)}"}

runpod.serverless.start({"handler": handler})
