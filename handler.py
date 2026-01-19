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

    # v214: Теперь запускаем с CUDA на полную мощность!
    cmd = [
        "python3", "run.py", "headless-run",
        "-s", source_p, "-t", target_p, "-o", output_p,
        "--processors", "face_swapper",
        "--execution-providers", "cuda",
        "--skip-download"
    ]

    print(f"DEBUG: Running FaceSwap on GPU...")
    
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    for line in process.stdout:
        # Убираем лишний мусор из логов, оставляем только важное
        if "Processing" in line or "Analyzing" in line:
            print(f"FACEFUSION_LOG: {line.strip()}")
            sys.stdout.flush()
    process.wait()

    if os.path.exists(output_p):
        return {"status": "success", "output": output_p}
    return {"status": "error", "msg": "Processing failed. Check worker logs."}

runpod.serverless.start({"handler": handler})