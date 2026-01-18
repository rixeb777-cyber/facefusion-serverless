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
    except Exception as e:
        print(f"ERROR: {str(e)}")

def handler(job):
    job_input = job.get('input', job)
    source_url = job_input.get('source')
    target_url = job_input.get('target')

    source_p, target_p, output_p = "/app/source.jpg", "/app/target.mp4", "/app/output.mp4"
    if os.path.exists(output_p): os.remove(output_p)

    download_file(source_url, source_p)
    download_file(target_url, target_p)

    # Запуск v205
    cmd = [
        "python3", "run.py", "headless-run",
        "-s", source_p,
        "-t", target_p,
        "-o", output_p,
        "--processors", "face_swapper",
        "--execution-providers", "cuda", 
        "--skip-download"
    ]

    print(f"DEBUG: Running: {' '.join(cmd)}")
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    for line in process.stdout:
        print(f"FACEFUSION_LOG: {line.strip()}")
        sys.stdout.flush()
    process.wait()

    if os.path.exists(output_p):
        return {"status": "success", "output": output_p}
    return {"status": "error", "msg": "Look at logs."}

runpod.serverless.start({"handler": handler})