# Используем образ с CUDA
FROM runpod/base:0.4.0-cuda11.8.0

# Устанавливаем системные зависимости
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    python3-pip \
    ffmpeg \
    libsm6 \
    libxext6 \
    && rm -rf /var/lib/apt/lists/*

# Сначала устанавливаем критически важные библиотеки для RunPod
RUN pip install --no-cache-dir requests runpod

# Скачиваем код FaceFusion как архив (это обходит ошибку Username)
WORKDIR /app
RUN wget https://github.com/facefusion/facefusion/archive/refs/heads/master.zip && \
    unzip master.zip && \
    mv facefusion-master/* . && \
    rm master.zip

# Устанавливаем остальные зависимости программы
RUN pip install --no-cache-dir -r requirements.txt

# Копируем твой обработчик
COPY handler.py /app/handler.py

# Команда запуска
CMD [ "python3", "-u", "handler.py" ]
