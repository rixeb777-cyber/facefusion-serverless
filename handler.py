import runpod
import subprocess
import requests
import os
import sys

def download_file(url, save_path):
    print(f"DEBUG: Downloading {url}")
    try:
        response = requests.get(url, stream=True, timeout=60)
        if response.status_code == 200:
            with open(save_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
            print(f"DEBUG: Saved to {save_path}")
        else:
            print(f"ERROR: HTTP {response.status_code}")
    except Exception as e:
        print(f"ERROR: {str(e)}")

def handler(job):
    job_input = job.get('input', job)
    source_url = job_input.get('source')
    target_url = job_input.get('target')

    source_path, target_path, output_path = "/app/source.jpg", "/app/target.mp4", "/app/output.mp4"

    download_file(source_url, source_path)
    download_file(target_url, target_path)

    command = [
        "python3", "run.py", "--processors", "face_swapper",
        "-s", source_path, "-t", target_path, "-o", output_path,
        "--headless", "--log-level", "debug"
    ]

    print(f"DEBUG: Starting FaceFusion...")
    try:
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
        for line in process.stdout:
            print(f"FACEFUSION: {line.strip()}")
            sys.stdout.flush()
        process.wait()
    except Exception as e:
        print(f"CRASH: {str(e)}")

    if os.path.exists(output_path):
        return {"status": "success", "file": output_path}
    return {"status": "failed", "check_logs": "true"}

runpod.serverless.start({"handler": handler})
