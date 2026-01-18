# Самый актуальный образ RunPod с CUDA 12.1 (она стабильнее)
FROM runpod/base:0.6.2-cuda12.1.0

WORKDIR /app

# 1. Системные зависимости
RUN apt-get update && apt-get install -y \
    ffmpeg libsm6 libxext6 libgl1-mesa-glx git curl libgomp1 \
    libglib2.0-0 && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Клонируем проект
RUN git clone --branch 3.0.0 --depth 1 https://github.com/facefusion/facefusion.git .

# 3. Python и библиотеки
RUN python3 -m pip install --upgrade pip

# КРУТО: Ставим ONNX и FaceFusion зависимости через их собственный метод
RUN python3 -m pip install onnxruntime-gpu==1.18.0
RUN python3 -m pip install -r requirements.txt
RUN python3 -m pip install runpod requests gdown

# 4. Модели
RUN mkdir -p /root/.facefusion/models && \
    curl -L -o /root/.facefusion/models/inswapper_128_fp16.onnx https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/inswapper_128_fp16.onnx && \
    curl -L -o /root/.facefusion/models/yoloface_8n.onnx https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/yoloface_8n.onnx

# 5. Скрипт запуска
RUN printf "from facefusion import core\nif __name__ == '__main__':\n    core.cli()" > /app/run.py

COPY handler.py /app/handler.py
ENV PYTHONPATH="/app"

# Принудительно заставляем систему искать библиотеки CUDA везде
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH

CMD [ "python3", "-u", "handler.py" ]