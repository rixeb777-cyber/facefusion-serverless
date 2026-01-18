FROM runpod/base:0.4.0-cuda11.8.0

WORKDIR /app

# 1. Системные зависимости
RUN apt-get update && apt-get install -y ffmpeg libsm6 libxext6 git && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Клонируем проект
RUN git clone --depth 1 https://github.com/facefusion/facefusion.git .

# 3. Установка библиотек
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir runpod requests

# 4. СОЗДАЕМ СВОЙ run.py (Тот самый "run", который ты предложил!)
# Этот файл просто импортирует и запускает FaceFusion
RUN echo 'from facefusion import core\nif __name__ == "__main__":\n    core.cli()' > /app/run.py

# 5. Копируем твой handler.py
COPY handler.py /app/handler.py

# 6. Даем права (теперь файл ТОЧНО есть)
RUN chmod +x /app/run.py

CMD [ "python3", "-u", "handler.py" ]
