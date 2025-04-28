FROM python:3.11-slim

RUN apt-get update && apt-get install -y fail2ban --no-install-recommends \
    curl \
    net-tools \
    procps \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . .

RUN pip install --no-cache-dir flask

EXPOSE 5000

CMD ["python", "app.py"]
