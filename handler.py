import runpod
import os
import subprocess
import requests
import torch
import numpy
import sys

# Включаем логирование ошибок в консоль сразу
def log(message):
    print(f"DEBUG: {message}", flush=True)

try:
    import onnxruntime
    log(f"ONNX Runtime загружен. Провайдеры: {onnxruntime.get_available_providers()}")
except Exception as e:
    log(f"ОШИБКА ЗАГРУЗКИ ONNX: {str(e)}")

def download_file(url, save_path):
    if os.path.exists(save_path): return save_path
    log(f"Скачиваю: {url}")
    response = requests.get(url, stream=True)
    with open(save_path, 'wb') as f:
        for chunk in response.iter_content(chunk_size=8192):
            f.write(chunk)
    return save_path

def handler(job):
    try:
        job_input = job['input']
        source_url = job_input.get('source_url')
        target_url = job_input.get('target_url')

        if not source_url or not target_url:
            return {"error": "Отсутствуют URL-адреса"}

        os.makedirs('/tmp/input', exist_ok=True)
        os.makedirs('/tmp/output', exist_ok=True)

        source_path = download_file(source_url, "/tmp/input/source.jpg")
        target_path = download_file(target_url, "/tmp/input/target.mp4")
        output_path = "/tmp/output/result.mp4"

        # Настройки для RTX 4090
        command = [
            "python", "facefusion.py", "headless-run",
            "--execution-providers", "cuda",
            "--processors", "face_swapper",
            "--execution-thread-count", "20",
            "--video-memory-strategy", "high",
            "--skip-download",
            "-s", source_path,
            "-t", target_path,
            "-o", output_path
        ]

        log("Запуск FaceFusion...")
        result = subprocess.run(command, capture_output=True, text=True)
        
        # Выводим логи FaceFusion в консоль RunPod
        print(result.stdout)
        print(result.stderr)

        if os.path.exists(output_path):
            return {"status": "success", "output": "Файл готов"}
        else:
            return {"status": "error", "message": "Файл не создался", "stderr": result.stderr}

    except Exception as e:
        log(f"КРИТИЧЕСКАЯ ОШИБКА: {str(e)}")
        return {"status": "error", "message": str(e)}

runpod.serverless.start({"handler": handler})