FROM python:3.10-slim
WORKDIR /app
COPY app.py .
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir flask
EXPOSE 5000
CMD ["python", "app.py"]
