import runpod
import subprocess
import requests
import os
import sys

def download_file(url, save_path):
    print(f"DEBUG: Downloading {url}")
    r = requests.get(url, stream=True)
    with open(save_path, 'wb') as f:
        for chunk in r.iter_content(chunk_size=8192): f.write(chunk)

def handler(job):
    job_input = job.get('input', job)
    source_p, target_p, output_p = "/app/source.jpg", "/app/target.mp4", "/app/output.mp4"
    if os.path.exists(output_p): os.remove(output_p)

    download_file(job_input.get('source'), source_p)
    download_file(job_input.get('target'), target_p)

    # v213 ТАКТИКА: Сначала пробуем CUDA, если ругается - пробуем авто-режим
    # Мы убрали принудительный список провайдеров, чтобы дать программе шанс самой найти GPU
    cmd = [
        "python3", "run.py", "headless-run",
        "-s", source_p, "-t", target_p, "-o", output_p,
        "--processors", "face_swapper",
        "--skip-download"
    ]

    print(f"DEBUG: Executing: {' '.join(cmd)}")
    
    # Добавляем переменные окружения прямо в процесс
    my_env = os.environ.copy()
    my_env["ONNXRUNTIME_EXECUTION_PROVIDERS"] = "CUDAExecutionProvider"

    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, env=my_env)
    for line in process.stdout:
        print(f"FACEFUSION_LOG: {line.strip()}")
        sys.stdout.flush()
    process.wait()

    if os.path.exists(output_p):
        return {"status": "success", "output": output_p}
    return {"status": "error", "msg": "Process finished but no file found."}

runpod.serverless.start({"handler": handler})