FROM runpod/base:0.4.0-cuda11.8.0

WORKDIR /app

# 1. Системные зависимости
RUN apt-get update && apt-get install -y ffmpeg libsm6 libxext6 git && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Клонируем проект
RUN git clone --depth 1 https://github.com/facefusion/facefusion.git .

# 3. Установка библиотек (используем python3 -m pip для надежности)
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --no-cache-dir -r requirements.txt && \
    python3 -m pip install --no-cache-dir runpod requests

# 4. Создаем run.py
RUN echo 'from facefusion import core\nif __name__ == "__main__":\n    core.cli()' > /app/run.py

# 5. Копируем твой handler.py
COPY handler.py /app/handler.py
RUN chmod +x /app/run.py

# Указываем путь к библиотекам, чтобы Python их точно нашел
ENV PYTHONPATH="/app"

CMD [ "python3", "-u", "handler.py" ]
