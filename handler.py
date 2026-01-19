import runpod
import os
import subprocess
import requests
import torch
import numpy
import onnxruntime

# --- ДИАГНОСТИКА ---
print(f"NumPy версия: {numpy.__version__}")
print(f"ONNX Runtime версия: {onnxruntime.__version__}")
print(f"Доступные провайдеры: {onnxruntime.get_available_providers()}")
print(f"CUDA доступна: {torch.cuda.is_available()}")
print("=" * 60)

def download_file(url, save_path):
    if os.path.exists(save_path):
        return save_path
    print(f"📥 Скачиваю файл: {url}")
    response = requests.get(url, stream=True)
    response.raise_for_status()
    with open(save_path, 'wb') as f:
        for chunk in response.iter_content(chunk_size=8192):
            f.write(chunk)
    print(f"✅ Файл сохранен: {save_path}")
    return save_path

def handler(job):
    job_input = job['input']
    source_url = job_input.get('source_url')
    target_url = job_input.get('target_url')

    if not source_url or not target_url:
        return {"error": "Нужны source_url и target_url"}

    # Создаем папки
    os.makedirs('/tmp/input', exist_ok=True)
    os.makedirs('/tmp/output', exist_ok=True)

    source_path = "/tmp/input/source.jpg"
    target_path = "/tmp/input/target.mp4"
    output_path = "/tmp/output/result.mp4"

    # Скачивание входных данных
    download_file(source_url, source_path)
    download_file(target_url, target_path)

    # --- НАСТРОЙКА КОМАНДЫ ДЛЯ МАКСИМАЛЬНОЙ СКОРОСТИ ---
    # Для RTX 4090 мы можем смело ставить много потоков (execution-thread-count)
    # И использовать стратегию 'high' или 'relaxed' для памяти.
    command = [
        "python", "facefusion.py",
        "headless-run",
        "--execution-providers", "cuda",
        "--processors", "face_swapper",
        "--execution-thread-count", "24",  # Увеличено для 4090
        "--execution-queue-count", "2",    # Очередь кадров
        "--video-memory-strategy", "high", # Позволяем использовать всю VRAM
        "--skip-download",                 # Мы всё скачали в Docker
        "-s", source_path,
        "-t", target_path,
        "-o", output_path
    ]

    print(f"🔧 ЗАПУСК ГЕНЕРАЦИИ (GPU ускорение)...")
    
    try:
        # Запускаем и ловим вывод в реальном времени
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in process.stdout:
            print(line, end='')
        
        process.wait()

        if os.path.exists(output_path):
            print("✅ Готово! Отправляю результат...")
            # Здесь должна быть твоя логика загрузки файла (например, в S3 или Telegram)
            return {"status": "success", "message": "Video processed"}
        else:
            return {"status": "error", "message": "Output file not found"}

    except Exception as e:
        return {"status": "error", "message": str(e)}

runpod.serverless.start({"handler": handler})