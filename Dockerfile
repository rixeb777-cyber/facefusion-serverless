FROM runpod/base:0.4.0-cuda11.8.0

WORKDIR /app

# 1. Установка системных зависимостей
RUN apt-get update && apt-get install -y ffmpeg libsm6 libxext6 curl unzip && rm -rf /var/lib/apt/lists/*

# 2. Скачивание и ПРАВИЛЬНАЯ распаковка (все файлы из папки архива переносим в /app)
RUN curl -L https://github.com/facefusion/facefusion/archive/refs/heads/master.zip -o master.zip && \
    unzip master.zip && \
    mv facefusion-master/* . && \
    rm -rf facefusion-master master.zip

# 3. Установка зависимостей Python
RUN pip install --upgrade pip
RUN pip install requests runpod onnxruntime-gpu insightface opencv-python numpy tqdm psutil scipy

# 4. Копируем твой обработчик
COPY handler.py /app/handler.py

# 5. Теперь файл точно на месте, даем права
RUN chmod +x /app/run.py

CMD [ "python3", "-u", "handler.py" ]
