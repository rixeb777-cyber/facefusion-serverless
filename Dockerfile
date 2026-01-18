FROM runpod/base:0.4.0-cuda11.8.0

WORKDIR /app

# 1. Системные зависимости
RUN apt-get update && apt-get install -y \
    ffmpeg libsm6 libxext6 libgl1-mesa-glx git curl libgomp1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Клонируем проект
RUN git clone --depth 1 https://github.com/facefusion/facefusion.git .

# 3. Установка библиотек (Добавляем scipy и другие явно)
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --no-cache-dir runpod requests gdown && \
    # Установка фундаментальных библиотек для ИИ
    python3 -m pip install --no-cache-dir numpy==1.24.3 scipy==1.10.1 opencv-python onnxruntime-gpu==1.15.1 && \
    # Добиваем остальное из требований
    python3 -m pip install --no-cache-dir -r requirements.txt || true

# 4. Рабочие ссылки на модели (v187)
RUN mkdir -p /root/.facefusion/models && \
    curl -L -o /root/.facefusion/models/inswapper_128.onnx https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/inswapper_128_fp16.onnx && \
    curl -L -o /root/.facefusion/models/yoloface_8n.onnx https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/yoloface_8n.onnx

# 5. Скрипт запуска (уже проверен, работает!)
RUN echo "from facefusion import core" > /app/run.py && \
    echo "if __name__ == '__main__':" >> /app/run.py && \
    echo "    core.cli()" >> /app/run.py && \
    chmod +x /app/run.py

COPY handler.py /app/handler.py

ENV PYTHONPATH="/app"
ENV HOME="/root"

CMD [ "python3", "-u", "handler.py" ]
