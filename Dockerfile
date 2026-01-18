FROM rixeb/facefusion-serverless:v72

WORKDIR /workspace

COPY handler.py /workspace/handler.py

CMD ["python", "-u", "handler.py"]
