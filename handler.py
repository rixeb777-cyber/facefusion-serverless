import runpod
import subprocess
import requests
import os
import sys

def download_file(url, save_path):
    print(f"DEBUG: Downloading {url}")
    try:
        r = requests.get(url, stream=True, timeout=60)
        r.raise_for_status()
        with open(save_path, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192):
                f.write(chunk)
        print(f"DEBUG: Downloaded to {save_path}")
    except Exception as e:
        print(f"ERROR: Download failed: {str(e)}")

def handler(job):
    job_input = job.get('input', job)
    source_url = job_input.get('source')
    target_url = job_input.get('target')

    source_p = "/app/source.jpg"
    target_p = "/app/target.mp4"
    output_p = "/app/output.mp4"

    # Предварительная очистка, чтобы не получить старый результат
    if os.path.exists(output_p):
        os.remove(output_p)

    download_file(source_url, source_p)
    download_file(target_url, target_p)

    # ОБНОВЛЕННАЯ КОМАНДА ДЛЯ FACEFUSION 3.0.0
    # Мы добавляем 'run' перед всеми параметрами
    cmd = [
        "python3", "run.py", "run", 
        "--processors", "face_swapper",
        "--source", source_p,
        "--target", target_p,
        "--output", output_p,
        "--skip-download" # Чтобы он не пытался качать модели сам (они у нас уже есть)
    ]

    print(f"DEBUG: Running command: {' '.join(cmd)}")
    
    try:
        # Запуск и вывод логов
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        
        for line in process.stdout:
            print(f"FACEFUSION_LOG: {line.strip()}")
            sys.stdout.flush()
        
        process.wait()
        print(f"DEBUG: Process finished with code {process.returncode}")

    except Exception as e:
        print(f"CRASH: {str(e)}")

    if os.path.exists(output_p):
        # Здесь ты потом добавишь загрузку файла в облако, 
        # но для теста — убедимся, что файл просто создался
        return {"status": "success", "message": "Video processed!", "output_file": output_p}
    else:
        return {"status": "error", "msg": "FaceFusion finished but output file was not created. Check logs above."}

runpod.serverless.start({"handler": handler})
