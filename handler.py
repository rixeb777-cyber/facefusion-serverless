import runpod
import subprocess
import requests
import os

def download_file(url, save_path):
    print(f"Downloading {url} to {save_path}...")
    response = requests.get(url, stream=True)
    if response.status_code == 200:
        with open(save_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        print("Download complete.")
    else:
        print(f"Failed to download. Status code: {response.status_code}")

def handler(job):
    job_input = job['input']
    source_url = job_input.get('source')
    target_url = job_input.get('target')

    source_path = "/app/source.jpg"
    target_path = "/app/target.mp4"
    output_path = "/app/output.mp4"

    if source_url:
        download_file(source_url, source_path)
    if target_url:
        download_file(target_url, target_path)

    # Команда запуска
    command = [
        "python3", "run.py",
        "--processors", "face_swapper",
        "-s", source_path,
        "-t", target_path,
        "-o", output_path,
        "--headless"
    ]

    print(f"Running command: {' '.join(command)}")

    try:
        # Увеличиваем таймаут, так как видео может обрабатываться долго
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        print("STDOUT:", result.stdout)
    except subprocess.CalledProcessError as e:
        print("ERROR:", e.stderr)
        return {"error": e.stderr, "stdout": e.stdout}

    if os.path.exists(output_path):
        return {"status": "success", "message": "Video processed", "output_file": output_path}
    else:
        return {"status": "error", "message": "Output file not found"}

runpod.serverless.start({"handler": handler})
