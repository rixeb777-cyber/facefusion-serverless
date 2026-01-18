import runpod
import os
import requests
import subprocess

WORKDIR = "/workspace"
SOURCE_IMG = f"{WORKDIR}/source.jpg"
TARGET_VID = f"{WORKDIR}/target.mp4"
OUTPUT_VID = f"{WORKDIR}/output.mp4"

DEFAULT_PHOTO = "https://raw.githubusercontent.com/rixeb777-cyber/facefusion-serverless/main/photo_2025-12-08_21-44-55.jpg"
DEFAULT_VIDEO = "https://raw.githubusercontent.com/rixeb777-cyber/facefusion-serverless/main/target.mp4"

def download(url, path):
    r = requests.get(url, timeout=120)
    r.raise_for_status()
    with open(path, "wb") as f:
        f.write(r.content)

def handler(job):
    print("🚀 FaceFusion Serverless handler started")

    job_input = job.get("input", {})
    source_url = job_input.get("source_url", DEFAULT_PHOTO)
    target_url = job_input.get("target_url", DEFAULT_VIDEO)

    try:
        os.makedirs(WORKDIR, exist_ok=True)
        os.chdir(WORKDIR)

        print("📥 Downloading files...")
        download(source_url, SOURCE_IMG)
        download(target_url, TARGET_VID)

        cmd = [
            "python3", "run.py",
            "--source", SOURCE_IMG,
            "--target", TARGET_VID,
            "--output", OUTPUT_VID,
            "--execution-providers", "cuda"
        ]

        print("⚙️ Running FaceFusion CLI...")
        proc = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

        print(proc.stdout)

        if proc.returncode != 0:
            print(proc.stderr)
            return {
                "status": "error",
                "error": proc.stderr
            }

        if not os.path.exists(OUTPUT_VID):
            return {
                "status": "error",
                "error": "Output video was not created"
            }

        return {
            "status": "success",
            "message": "Video generated",
            "output_path": OUTPUT_VID
        }

    except Exception as e:
        return {
            "status": "error",
            "exception": str(e)
        }

runpod.serverless.start({"handler": handler})
