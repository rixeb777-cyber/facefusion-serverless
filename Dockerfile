FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04

RUN apt-get update && apt-get install -y \
    python3.11 python3-pip libgl1-mesa-glx libglib2.0-0 libsndfile1 bash ffmpeg curl \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install runpod requests numpy scipy opencv-python onnxruntime-gpu

WORKDIR /app
COPY handler.py /app/handler.py
CMD ["python3", "-u", "/app/handler.py"]
