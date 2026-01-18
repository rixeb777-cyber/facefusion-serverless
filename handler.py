import runpod
import subprocess
import requests
import os
import sys

# Диагностика при старте контейнера
try:
    import torch
    print(f"DIAGNOSTIC: CUDA available in Torch: {torch.cuda.is_available()}")
    import onnxruntime as ort
    print(f"DIAGNOSTIC: ORT Providers: {ort.get_available_providers()}")
except:
    pass

def download_file(url, save_path):
    print(f"DEBUG: Downloading {url}")
    try:
        r = requests.get(url, stream=True)
        with open(save_path, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192): f.write(chunk)
    except Exception as e: print(f"ERROR: {e}")

def handler(job):
    job_input = job.get('input', job)
    source_p, target_p, output_p = "/app/source.jpg", "/app/target.mp4", "/app/output.mp4"
    if os.path.exists(output_p): os.remove(output_p)

    download_file(job_input.get('source'), source_p)
    download_file(job_input.get('target'), target_p)

    cmd = [
        "python3", "run.py", "headless-run",
        "-s", source_p, "-t", target_p, "-o", output_p,
        "--processors", "face_swapper",
        "--execution-providers", "cuda",
        "--skip-download"
    ]

    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    for line in process.stdout:
        print(f"FACEFUSION_LOG: {line.strip()}")
        sys.stdout.flush()
    process.wait()

    if os.path.exists(output_p):
        return {"status": "success", "output": output_p}
    return {"status": "error", "msg": "CUDA check failed again."}

runpod.serverless.start({"handler": handler})