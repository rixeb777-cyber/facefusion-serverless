# Используем официальный образ NVIDIA, где CUDA уже настроена идеально
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

WORKDIR /app

# 1. Системные либы + Python
RUN apt-get update && apt-get install -y \
    python3 python3-pip ffmpeg libsm6 libxext6 libgl1-mesa-glx git curl libgomp1 \
    libglib2.0-0 && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Клонируем FaceFusion 3.0.0
RUN git clone --branch 3.0.0 --depth 1 https://github.com/facefusion/facefusion.git .

# 3. Установка библиотек
RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install --no-cache-dir \
    numpy==1.24.3 \
    onnxruntime-gpu==1.17.1 \
    runpod requests gdown

# Ставим зависимости из файла
RUN python3 -m pip install --no-cache-dir -r requirements.txt || echo "Done"

# 4. Модели
RUN mkdir -p /root/.facefusion/models && \
    curl -L -o /root/.facefusion/models/inswapper_128_fp16.onnx https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/inswapper_128_fp16.onnx && \
    curl -L -o /root/.facefusion/models/yoloface_8n.onnx https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/yoloface_8n.onnx

RUN ln -s /root/.facefusion/models/inswapper_128_fp16.onnx /root/.facefusion/models/inswapper_128.onnx || true
RUN ln -s /root/.facefusion/models/yoloface_8n.onnx /root/.facefusion/models/yoloface_8n.onnx || true

# 5. Скрипт запуска
RUN printf "from facefusion import core\nif __name__ == '__main__':\n    core.cli()" > /app/run.py

COPY handler.py /app/handler.py
ENV PYTHONPATH="/app"
ENV HOME="/root"

# Жёсткие пути для NVIDIA
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

CMD [ "python3", "-u", "handler.py" ]