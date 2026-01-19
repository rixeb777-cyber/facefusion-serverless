import runpod
import subprocess
import os
import sys
import urllib.request
import onnxruntime
import time

# Диагностика при старте
print("=== DIAGNOSTICS ===")
providers = onnxruntime.get_available_providers()
print(f"Available Providers: {providers}")
print(f"CUDA Active: {'CUDAExecutionProvider' in providers}")
print("===================")

def download_file(url, output_path):
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    try:
        print(f"Downloading {url}...")
        urllib.request.urlretrieve(url, output_path)
        return output_path
    except Exception as e:
        print(f"Download Error: {e}")
        raise

def process_facefusion(job):
    try:
        job_input = job["input"]
        source_url = job_input.get("source")
        target_url = job_input.get("target")
        
        # Рабочие пути
        source_path = "/tmp/input/source.jpg"
        target_path = "/tmp/input/target.mp4"
        output_path = "/tmp/output/output.mp4"
        
        # Очистка и создание папок
        os.makedirs("/tmp/input", exist_ok=True)
        os.makedirs("/tmp/output", exist_ok=True)
        if os.path.exists(output_path): os.remove(output_path)
        
        # Загрузка файлов
        download_file(source_url, source_path)
        download_file(target_url, target_path)
        
        # Команда запуска (именно run.py для версии 3.0)
        command = [
            "python", "run.py", "headless-run",
            "-s", source_path,
            "-t", target_path,
            "-o", output_path,
            "--processors", "face_swapper",
            "--execution-providers", "cuda",
            "--skip-download"
        ]
        
        print(f"Starting FaceFusion: {' '.join(command)}")
        
        result = subprocess.run(
            command,
            cwd="/app",
            capture_output=True,
            text=True,
            timeout=600 # Увеличили до 10 минут
        )
        
        print("STDOUT:", result.stdout)
        
        if os.path.exists(output_path):
            size = os.path.getsize(output_path)
            return {
                "success": True,
                "message": f"Generated! Size: {size} bytes",
                "output_path": output_path,
                "diagnostics": providers
            }
        else:
            return {"error": "Output file not found", "stderr": result.stderr}
            
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    runpod.serverless.start({"handler": process_facefusion})