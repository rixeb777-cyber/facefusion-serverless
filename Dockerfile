FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /workspace

# Система
RUN apt update && apt install -y \
    python3 \
    python3-pip \
    git \
    ffmpeg \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/bin/python3 /usr/bin/python

# pip
RUN python -m pip install --upgrade pip

# PyTorch CUDA 11.8 (ОЧЕНЬ ВАЖНО)
RUN pip install torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cu118

# FaceFusion
RUN git clone https://github.com/facefusion/facefusion.git /workspace

# Python зависимости
RUN pip install -r requirements.txt
RUN pip install onnxruntime-gpu insightface runpod requests

# handler
COPY handler.py /workspace/handler.py

CMD ["python", "-u", "handler.py"]
