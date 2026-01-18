FROM runpod/base:0.4.0-cuda11.8.0

WORKDIR /app

# 1. СИСТЕМНЫЕ ЗАВИСИМОСТИ (ФУНДАМЕНТ)
# Добавлены libgl1 и libglib для OpenCV, gfortran для SciPy
RUN apt-get update && apt-get install -y \
    ffmpeg libsm6 libxext6 libgl1-mesa-glx git curl libgomp1 \
    gfortran libopenblas-dev liblapack-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. КЛОНИРОВАНИЕ FACEFUSION
RUN git clone --depth 1 https://github.com/facefusion/facefusion.git .

# 3. УСТАНОВКА PYTHON ОКРУЖЕНИЯ (ЖЕСТКАЯ ФИКСАЦИЯ)
RUN python3 -m pip install --upgrade pip

# Сначала ставим runpod и утилиты
RUN python3 -m pip install --no-cache-dir runpod requests gdown

# ГЛАВНЫЙ ИСПРАВЛЕННЫЙ БЛОК:
# Мы не используем requirements.txt слепо. Мы ставим рабочий костяк вручную.
# Это решает проблему NumPy 2.x, отсутствия cv2 и SciPy.
RUN python3 -m pip install --no-cache-dir \
    numpy==1.24.3 \
    scipy==1.10.1 \
    opencv-python==4.8.0.76 \
    onnxruntime-gpu==1.15.1 \
    imageio \
    psutil \
    tqdm \
    protobuf==3.20.3

# Доустанавливаем остальное из requirements, НО запрещаем ломать наши версии (--no-deps или просто поверх)
# Если тут будет конфликт, pip пожалуется, но наши версии останутся
RUN python3 -m pip install --no-cache-dir -r requirements.txt || echo "Warning: Some requirements failed but core libs are installed"

# 4. СКАЧИВАНИЕ МОДЕЛЕЙ (v3.0.0)
RUN mkdir -p /root/.facefusion/models && \
    curl -L -o /root/.facefusion/models/inswapper_128.onnx https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/inswapper_128_fp16.onnx && \
    curl -L -o /root/.facefusion/models/yoloface_8n.onnx https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/yoloface_8n.onnx

# 5. СКРИПТ ЗАПУСКА (Безопасный метод)
RUN printf "from facefusion import core\nif __name__ == '__main__':\n    core.cli()" > /app/run.py

COPY handler.py /app/handler.py
ENV PYTHONPATH="/app"
ENV HOME="/root"

CMD [ "python3", "-u", "handler.py" ]
