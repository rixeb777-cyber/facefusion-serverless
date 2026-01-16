# Используем образ с поддержкой CUDA для работы видеокарты
FROM runpod/base:0.4.0-cuda11.8.0

# Устанавливаем необходимые системные утилиты
RUN apt-get update && apt-get install -y \
    git \
    python3-pip \
    ffmpeg \
    libsm6 \
    libxext6 \
    && rm -rf /var/lib/apt/lists/*

# Клонируем официальный репозиторий FaceFusion прямо в образ
RUN git clone https://github.com/facefusion/facefusion.py.git /app

WORKDIR /app

# Устанавливаем все библиотеки для нейросетей (это займет время)
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install runpod requests

# Копируем твой файл-обработчик в папку с программой
COPY handler.py /app/handler.py

# Команда для запуска сервера
CMD [ "python3", "-u", "handler.py" ]
