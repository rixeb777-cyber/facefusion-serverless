FROM runpod/base:0.4.0-cuda11.8.0

WORKDIR /app

# 1. Системные либы (уже проверенные)
RUN apt-get update && apt-get install -y \
    ffmpeg libsm6 libxext6 libgl1-mesa-glx git curl libgomp1 \
    gfortran libopenblas-dev liblapack-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Клонируем проект
RUN git clone --depth 1 https://github.com/facefusion/facefusion.git .

# 3. Установка библиотек (СЕКРЕТНЫЙ ПОРЯДОК)
RUN python3 -m pip install --upgrade pip

# Сначала ставим всё из файла (оно поставит кривой NumPy 2.2.6)
RUN python3 -m pip install --no-cache-dir -r requirements.txt || true

# А ТЕПЕРЬ ПРИНУДИТЕЛЬНО ИСПРАВЛЯЕМ ВЕРСИИ
# Мы удаляем то, что поставил requirements, и ставим то, что РАБОТАЕТ
RUN python3 -m pip uninstall -y numpy
RUN python3 -m pip install --no-cache-dir numpy==1.24.3 scipy==1.10.1 onnxruntime-gpu==1.15.1 runpod requests gdown

# 4. Модели (v3.0.0)
RUN mkdir -p /root/.facefusion/models && \
    curl -L -o /root/.facefusion/models/inswapper_128.onnx https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/inswapper_128_fp16.onnx && \
    curl -L -o /root/.facefusion/models/yoloface_8n.onnx https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/yoloface_8n.onnx

# 5. Скрипт
RUN printf "from facefusion import core\nif __name__ == '__main__':\n    core.cli()" > /app/run.py

COPY handler.py /app/handler.py
ENV PYTHONPATH="/app"
ENV HOME="/root"

CMD [ "python3", "-u", "handler.py" ]
