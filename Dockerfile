# Используем образ с поддержкой CUDA
FROM runpod/base:0.4.0-cuda11.8.0

# Устанавливаем системные зависимости
RUN apt-get update && apt-get install -y \
    git \
    python3-pip \
    ffmpeg \
    libsm6 \
    libxext6 \
    && rm -rf /var/lib/apt/lists/*

# Клонируем FaceFusion (используем https без .git для надежности)
RUN git clone https://github.com/facefusion/facefusion-assets /app && \
    cd /app && git clone https://github.com/facefusion/facefusion /app/facefusion_src

WORKDIR /app

# Переносим файлы из скачанной папки в корень /app, если нужно
RUN cp -r /app/facefusion_src/* /app/ && rm -rf /app/facefusion_src

# Устанавливаем зависимости
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install runpod requests

# Копируем твой обработчик
COPY handler.py /app/handler.py

# Запускаем через python3
CMD [ "python3", "-u", "handler.py" ]
