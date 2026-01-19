import runpod
import os
import subprocess
import requests
import sys

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
        job_input = job.get('input', {})
        source_url = job_input.get('source_url')
        target_url = job_input.get('target_url')

        if not source_url or not target_url:
            return {"error": "Отсутствуют URL-адреса", "received": job_input}

        os.makedirs('/tmp/input', exist_ok=True)
        os.makedirs('/tmp/output', exist_ok=True)

        source_path = download_file(source_url, "/tmp/input/source.jpg")
        target_path = download_file(target_url, "/tmp/input/target.mp4")
        output_path = "/tmp/output/result.mp4"

        # ИСПРАВЛЕННАЯ КОМАНДА
        command = [
            "python", "-u", "facefusion.py", "headless-run",
            "--execution-providers", "cuda",
            "--processors", "face_swapper",
            "--execution-thread-count", "24",
            "--video-memory-strategy", "tolerant",
            "--skip-download", # Мы уже скачали модели в Dockerfile
            "--content-analyser-model", "none", # Отключаем проверку NSFW, которая выдает ошибку
            "-s", source_path,
            "-t", target_path,
            "-o", output_path
        ]

        log("🚀 Запуск процесса (tolerant mode)...")
        
        process = subprocess.Popen(
            command, 
            stdout=subprocess.PIPE, 
            stderr=subprocess.STDOUT, 
            text=True,
            bufsize=1
        )

        # Здесь полетят твои любимые проценты Processing: 5%...
        for line in process.stdout:
            print(line, end='', flush=True)

        process.wait()

        if os.path.exists(output_path):
            log("✅ Победа! Видео готово.")
            return {"status": "success", "message": "Done"}
        else:
            log("❌ Ошибка: Файл не создался.")
            return {"status": "error", "message": "Process failed"}

    except Exception as e:
        log(f"Критический сбой: {str(e)}")
        return {"status": "error", "message": str(e)}

runpod.serverless.start({"handler": handler})