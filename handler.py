import runpod
import os
import subprocess
import requests
import torch
import numpy
import onnxruntime

def log(message):
    print(f"DEBUG: {message}", flush=True)

def download_file(url, save_path):
    if os.path.exists(save_path): return save_path
    log(f"📥 Скачиваю: {url}")
    response = requests.get(url, stream=True)
    response.raise_for_status()
    with open(save_path, 'wb') as f:
        for chunk in response.iter_content(chunk_size=8192):
            f.write(chunk)
    log(f"✅ Файл сохранен: {save_path}")
    return save_path

def handler(job):
    try:
        # Достаем входные данные
        job_input = job.get('input', {})
        log(f"Входящий JSON: {job_input}") # Это поможет понять, что пришло

        source_url = job_input.get('source_url')
        target_url = job_input.get('target_url')

        if not source_url or not target_url:
            return {
                "error": "Отсутствуют URL-адреса", 
                "received_input": job_input,
                "tip": "Убедитесь, что параметры внутри объекта 'input'"
            }

        # Подготовка папок
        os.makedirs('/tmp/input', exist_ok=True)
        os.makedirs('/tmp/output', exist_ok=True)

        source_path = download_file(source_url, "/tmp/input/source.jpg")
        target_path = download_file(target_url, "/tmp/input/target.mp4")
        output_path = "/tmp/output/result.mp4"

        # Команда для RTX 4090
        command = [
            "python", "facefusion.py", "headless-run",
            "--execution-providers", "cuda",
            "--processors", "face_swapper",
            "--execution-thread-count", "24",
            "--video-memory-strategy", "high",
            "--skip-download",
            "-s", source_path,
            "-t", target_path,
            "-o", output_path
        ]

        log("🚀 Начинаю замену лица...")
        process = subprocess.run(command, capture_output=True, text=True)
        
        # Печатаем логи самого FaceFusion для диагностики
        print(process.stdout)
        print(process.stderr)

        if os.path.exists(output_path):
            return {"status": "success", "message": "Готово!"}
        else:
            return {"status": "error", "message": "Файл не создался", "stderr": process.stderr}

    except Exception as e:
        log(f"Критический сбой: {str(e)}")
        return {"status": "error", "message": str(e)}

runpod.serverless.start({"handler": handler})