FROM runpod/pytorch:2.1.0-py3.10-cuda12.1.1

WORKDIR /workspace

RUN apt update && apt install -y \
    ffmpeg \
    git \
    wget \
    && rm -rf /var/lib/apt/lists/*

# FaceFusion
RUN git clone https://github.com/facefusion/facefusion.git /workspace
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
RUN pip install onnxruntime-gpu insightface runpod requests

COPY handler.py /workspace/handler.py

CMD ["python3", "-u", "handler.py"]
