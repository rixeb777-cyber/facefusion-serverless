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
        print(f"DEBUG: Downloaded to {save_path}")
    except Exception as e:
        print(f"ERROR: Download failed: {str(e)}")

def handler(job):
    job_input = job.get('input', job)
    source_url = job_input.get('source')
    target_url = job_input.get('target')

    source_p = "/app/source.jpg"
    target_p = "/app/target.mp4"
    output_p = "/app/output.mp4"

    if os.path.exists(output_p):
        os.remove(output_p)

    download_file(source_url, source_p)
    download_file(target_url, target_p)

    # Команда v201
    cmd = [
        "python3", "run.py", "headless-run",
        "-s", source_p,
        "-t", target_p,
        "-o", output_p,
        "--processors", "face_swapper",
        "--execution-providers", "cuda",
        "--skip-download"
    ]

    print(f"DEBUG: Running command: {' '.join(cmd)}")
    
    try:
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in process.stdout:
            print(f"FACEFUSION_LOG: {line.strip()}")
            sys.stdout.flush()
        process.wait()
    except Exception as e:
        print(f"CRASH: {str(e)}")

    if os.path.exists(output_p):
        return {"status": "success", "output": output_p}
    else:
        return {"status": "error", "msg": "Look at logs above."}

runpod.serverless.start({"handler": handler})