FROM runpod/base:0.4.0-cuda11.8.0

WORKDIR /app

# 1. Системные либы
RUN apt-get update && apt-get install -y \
    ffmpeg libsm6 libxext6 libgl1-mesa-glx git curl libgomp1 \
    gfortran libopenblas-dev liblapack-dev libglib2.0-0 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Клонируем стабильную версию 3.0.0
RUN git clone --branch 3.0.0 --depth 1 https://github.com/facefusion/facefusion.git .

# 3. Установка Python-пакетов
RUN python3 -m pip install --upgrade pip

# КРУТО: Устанавливаем конкретную версию ONNX, которая дружит с CUDA 11.8
RUN python3 -m pip install --no-cache-dir \
    numpy==1.24.3 \
    scipy==1.10.1 \
    opencv-python-headless==4.10.0.84 \
    onnxruntime-gpu==1.17.1 \
    runpod requests gdown

# Доставляем зависимости
RUN python3 -m pip install --no-cache-dir -r requirements.txt || echo "Done"

# 4. Скачивание моделей
RUN mkdir -p /root/.facefusion/models && \
    curl -L -o /root/.facefusion/models/inswapper_128_fp16.onnx https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/inswapper_128_fp16.onnx && \
    curl -L -o /root/.facefusion/models/yoloface_8n.onnx https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/yoloface_8n.onnx

# Ссылки для совместимости
RUN ln -s /root/.facefusion/models/inswapper_128_fp16.onnx /root/.facefusion/models/inswapper_128.onnx || true
RUN ln -s /root/.facefusion/models/yoloface_8n.onnx /root/.facefusion/models/yoloface_8n.onnx || true

# 5. Скрипт запуска
RUN printf "from facefusion import core\nif __name__ == '__main__':\n    core.cli()" > /app/run.py

COPY handler.py /app/handler.py
ENV PYTHONPATH="/app"
ENV HOME="/root"

# КРУТО: Эти две строки заставят FaceFusion "увидеть" видеокарту
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
ENV CUDA_MODULE_LOADING=LAZY

CMD [ "python3", "-u", "handler.py" ]