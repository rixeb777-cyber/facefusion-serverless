FROM runpod/base:0.4.0-cuda11.8.0

# 1. Системные зависимости
RUN apt-get update && apt-get install -y \
    python3-pip ffmpeg libsm6 libxext6 curl unzip \
    && rm -rf /var/lib/apt/lists/*

# 2. Обновляем окружение
RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install requests runpod

WORKDIR /app

# 3. Скачиваем FaceFusion
RUN curl -L https://github.com/facefusion/facefusion/archive/refs/heads/master.zip -o master.zip && \
    unzip master.zip && \
    cp -r facefusion-master/* . && \
    rm -rf facefusion-master master.zip

# 4. Установка зависимостей FaceFusion (используем только нужные)
RUN python3 -m pip install --no-cache-dir onnxruntime-gpu numpy opencv-python insightface psutil tqdm scipy

# 5. Копируем обработчик
COPY handler.py /app/handler.py

CMD [ "python3", "-u", "handler.py" ]
