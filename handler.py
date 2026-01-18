import runpod
import subprocess
import requests
import os
import sys

def download_file(url, save_path):
    print(f"DEBUG: Downloading {url}")
    try:
        response = requests.get(url, stream=True, timeout=60)
        if response.status_code == 200:
            with open(save_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
            print(f"DEBUG: Download complete: {save_path}")
        else:
            print(f"ERROR: HTTP Status {response.status_code}")
    except Exception as e:
        print(f"ERROR: Download failed: {str(e)}")

def handler(job):
    job_input = job.get('input', job)
    source_url = job_input.get('source')
    target_url = job_input.get('target')

    source_path = "/app/source.jpg"
    target_path = "/app/target.mp4"
    output_path = "/app/output.mp4"

    # Скачиваем файлы
    download_file(source_url, source_path)
    download_file(target_url, target_path)

    # Параметры запуска
    command = [
        "python3", "run.py",
        "--processors", "face_swapper",
        "-s", source_path,
        "-t", target_path,
        "-o", output_path,
        "--headless",
        "--log-level", "debug"
    ]

    print(f"DEBUG: Starting FaceFusion process...")
    
    try:
        process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1
        )

        for line in process.stdout:
            print(f"FACEFUSION: {line.strip()}")
            sys.stdout.flush()

        process.wait()
    except Exception as e:
        print(f"CRASH: {str(e)}")

    if os.path.exists(output_path):
        return {"status": "success", "output": output_path}
    else:
        return {"status": "failed", "msg": "Output file not generated. Check logs."}

runpod.serverless.start({"handler": handler})
