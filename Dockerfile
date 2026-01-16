# Используем стабильный образ с CUDA
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

# Скачиваем FaceFusion как ZIP-архив (обход ошибки git clone)
WORKDIR /app
RUN wget https://github.com/facefusion/facefusion/archive/refs/heads/master.zip && \
    unzip master.zip && \
    mv facefusion-master/* . && \
    rm master.zip

# Устанавливаем зависимости FaceFusion
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install runpod requests

# Копируем твой обработчик поверх
COPY handler.py /app/handler.py

# Запуск
CMD [ "python3", "-u", "handler.py" ]
