FROM runpod/base:0.4.0-cuda11.8.0

WORKDIR /app

# Только необходимые системные зависимости
RUN apt-get update && apt-get install -y ffmpeg libsm6 libxext6 git && rm -rf /var/lib/apt/lists/*

# Клонируем репозиторий вместо тяжелого unzip
RUN git clone --depth 1 https://github.com/facefusion/facefusion.git .

# Установка библиотек без кэша (экономим место)
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir runpod requests

COPY handler.py /app/handler.py
RUN chmod +x /app/run.py

# Указываем, что работать будем из /app
WORKDIR /app
CMD [ "python3", "-u", "handler.py" ]
