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

    # v215: Добавляем --log-level debug для полной картины
    cmd = [
        "python3", "run.py", "headless-run",
        "-s", source_p, 
        "-t", target_p, 
        "-o", output_p,
        "--processors", "face_swapper",
        "--execution-providers", "cuda",
        "--skip-download",
        "--log-level", "debug"
    ]

    print(f"DEBUG: Starting FaceSwap process...")
    
    # Запускаем и читаем всё: и stdout, и stderr
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    
    for line in process.stdout:
        print(f"FF_LOG: {line.strip()}")
        sys.stdout.flush()
    
    process.wait()

    if os.path.exists(output_p):
        print(f"DEBUG: Success! Output created at {output_p}")
        return {"status": "success", "output": output_p}
    else:
        print(f"DEBUG: Failed. No output file found.")
        return {"status": "error", "msg": "Process finished but no output file. Check FF_LOGs."}

runpod.serverless.start({"handler": handler})