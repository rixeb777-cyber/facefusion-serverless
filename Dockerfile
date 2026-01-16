FROM runpod/base:0.4.0-cuda11.8.0

# Устанавливаем системные зависимости
RUN apt-get update && apt-get install -y git python3-pip ffmpeg libsm6 libxext6

# Клонируем сам FaceFusion в папку /app
RUN git clone https://github.com/facefusion/facefusion.py.git /app

WORKDIR /app

# Устанавливаем зависимости FaceFusion
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install runpod requests

# Копируем твой обработчик поверх скачанных файлов
COPY handler.py /app/handler.py

# Запускаем
CMD [ "python3", "-u", "handler.py" ]
