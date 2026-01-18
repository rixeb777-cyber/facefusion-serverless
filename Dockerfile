# Используем официальный ML-образ от RunPod, где CUDA всегда работает
FROM runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04

WORKDIR /app

# 1. Системные либы
RUN apt-get update && apt-get install -y \
    ffmpeg libsm6 libxext6 libgl1-mesa-glx git curl libgomp1 \
    libglib2.0-0 && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Клонируем проект
RUN git clone --branch 3.0.0 --depth 1 https://github.com/facefusion/facefusion.git .

# 3. Чистим и ставим заново
RUN python3 -m pip install --upgrade pip
RUN python3 -m pip uninstall -y onnxruntime onnxruntime-gpu

# Ставим зависимости, исключая сломанный onnx
RUN sed -i '/onnxruntime/d' requirements.txt
RUN python3 -m pip install -r requirements.txt
RUN python3 -m pip install numpy==1.26.4 runpod requests gdown

# Ставим правильный GPU пакет
RUN python3 -m pip install onnxruntime-gpu==1.17.1

# 4. Модели
RUN mkdir -p /root/.facefusion/models && \
    curl -L -o /root/.facefusion/models/inswapper_128_fp16.onnx https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/inswapper_128_fp16.onnx && \
    curl -L -o /root/.facefusion/models/yoloface_8n.onnx https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/yoloface_8n.onnx

# 5. Скрипт запуска
COPY handler.py /app/handler.py
RUN printf "from facefusion import core\nif __name__ == '__main__':\n    core.cli()" > /app/run.py

ENV PYTHONPATH="/app"
# Пути к либам в этом образе могут быть другими, пропишем всё
ENV LD_LIBRARY_PATH=/usr/local/lib/python3.10/dist-packages/torch/lib:/usr/local/cuda/lib64:$LD_LIBRARY_PATH

CMD [ "python3", "-u", "handler.py" ]