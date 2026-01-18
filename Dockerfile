FROM runpod/base:0.4.0-cuda11.8.0

WORKDIR /app

# Установка системных зависимостей
RUN apt-get update && apt-get install -y ffmpeg libsm6 libxext6 curl unzip && rm -rf /var/lib/apt/lists/*

# Клонируем facefusion напрямую в /app
RUN curl -L https://github.com/facefusion/facefusion/archive/refs/heads/master.zip -o master.zip && \
    unzip master.zip && \
    cp -r facefusion-master/* . && \
    rm -rf facefusion-master master.zip

# Установка зависимостей Python
RUN pip install --upgrade pip
RUN pip install requests runpod onnxruntime-gpu insightface opencv-python numpy tqdm psutil scipy

# Копируем handler
COPY handler.py /app/handler.py

# Даем права на выполнение
RUN chmod +x /app/run.py

CMD [ "python3", "-u", "handler.py" ]
