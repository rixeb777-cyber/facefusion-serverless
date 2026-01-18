FROM runpod/base:0.4.0-cuda11.8.0

WORKDIR /app

# 1. Системные либы
RUN apt-get update && apt-get install -y \
    ffmpeg libsm6 libxext6 libgl1-mesa-glx git curl libgomp1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Клонируем проект
RUN git clone --depth 1 https://github.com/facefusion/facefusion.git .

# 3. Установка библиотек по шагам (чтобы не упало)
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --no-cache-dir runpod requests gdown && \
    # Ставим ONNX и основные либы отдельно
    python3 -m pip install --no-cache-dir onnxruntime-gpu==1.15.1 opencv-python numpy==1.24.3 && \
    # Ставим зависимости из файла, но игнорируя конфликты
    python3 -m pip install --no-cache-dir -r requirements.txt || true

# 4. Модели (теперь их две)
RUN mkdir -p /root/.facefusion/models && \
    curl -L -o /root/.facefusion/models/inswapper_128.onnx https://github.com/facefusion/facefusion-assets/releases/download/models/inswapper_128.onnx && \
    curl -L -o /root/.facefusion/models/yoloface_8n.onnx https://github.com/facefusion/facefusion-assets/releases/download/models/yoloface_8n.onnx

# 5. Скрипты
RUN echo "from facefusion import core\nif __name__ == '__main__':\n    core.cli()" > /app/run.py && \
    chmod +x /app/run.py

COPY handler.py /app/handler.py

ENV PYTHONPATH="/app"
ENV HOME="/root"

CMD [ "python3", "-u", "handler.py" ]
