FROM runpod/base:0.4.0-cuda11.8.0

WORKDIR /app

# 1. Системные зависимости для работы с видео и нейронками
RUN apt-get update && apt-get install -y \
    ffmpeg libsm6 libxext6 libgl1-mesa-glx git curl libgomp1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Клонируем официальный репозиторий FaceFusion
RUN git clone --depth 1 https://github.com/facefusion/facefusion.git .

# 3. Установка Python библиотек
# Мы фиксируем numpy и onnxruntime-gpu для стабильности на CUDA 11.8
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --no-cache-dir runpod requests gdown && \
    python3 -m pip install --no-cache-dir onnxruntime-gpu==1.15.1 opencv-python numpy==1.24.3 && \
    python3 -m pip install --no-cache-dir -r requirements.txt || true

# 4. Предварительная загрузка моделей из официального зеркала (v187)
RUN mkdir -p /root/.facefusion/models && \
    curl -L -o /root/.facefusion/models/inswapper_128.onnx https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/inswapper_128_fp16.onnx && \
    curl -L -o /root/.facefusion/models/yoloface_8n.onnx https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/yoloface_8n.onnx

# 5. Исправленное создание run.py (без SyntaxError)
# Записываем строки по одной, чтобы избежать проблем с переносами символов
RUN echo "from facefusion import core" > /app/run.py && \
    echo "if __name__ == '__main__':" >> /app/run.py && \
    echo "    core.cli()" >> /app/run.py && \
    chmod +x /app/run.py

# 6. Копируем твой обработчик
COPY handler.py /app/handler.py

# Переменные окружения
ENV PYTHONPATH="/app"
ENV HOME="/root"

# Запуск воркера
CMD [ "python3", "-u", "handler.py" ]
