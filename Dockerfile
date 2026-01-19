# Базовый образ с CUDA 11.8 и PyTorch для стабильной работы с RTX картами
FROM runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libgl1-mesa-glx \
    libgomp1 \
    python3-tk \
    wget \
    git \
    && rm -rf /var/lib/apt/lists/*

# Установка рабочей директории
WORKDIR /app

# Клонирование FaceFusion
RUN git clone https://github.com/facefusion/facefusion.git .

# КРИТИЧЕСКИ ВАЖНО: Удаляем все версии numpy и onnxruntime
RUN pip uninstall -y numpy onnxruntime onnxruntime-gpu || true

# Устанавливаем СТРОГО numpy 1.26.4 (НЕ 2.x!)
RUN pip install --no-cache-dir "numpy==1.26.4"

# Устанавливаем onnxruntime-gpu строго совместимую с CUDA 11.8
RUN pip install --no-cache-dir "onnxruntime-gpu==1.17.1"

# Устанавливаем основные зависимости с фиксацией версий
RUN pip install --no-cache-dir \
    "opencv-python>=4.8.0,<5.0.0" \
    "pillow>=10.0.0,<11.0.0" \
    "tqdm>=4.66.0" \
    "requests>=2.31.0" \
    "insightface>=0.7.3" \
    "onnx>=1.15.0,<2.0.0"

# Устанавливаем остальные зависимости без обновления numpy
RUN pip install --no-cache-dir -r requirements.txt --no-deps --ignore-installed 2>/dev/null || true

# ФИНАЛЬНАЯ ПРОВЕРКА: Принудительно откатываем numpy если что-то её обновило
RUN pip uninstall -y numpy && pip install --no-cache-dir "numpy==1.26.4"

# Установка RunPod SDK для работы с serverless
RUN pip install --no-cache-dir runpod

# Создание директории для моделей
RUN mkdir -p /root/.facefusion/models

# Модели будут скачаны автоматически FaceFusion при первом запуске
# Это надежнее чем пытаться скачать их вручную при сборке образа

# Копирование обработчика
COPY handler.py /app/handler.py

# Настройка переменных окружения для корректной работы CUDA
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=/usr/local/cuda/bin:$PATH

# Запуск handler при старте контейнера
CMD ["python", "-u", "handler.py"]