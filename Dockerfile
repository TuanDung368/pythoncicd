# Dockerfile
FROM python:3.9-slim-buster

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Nếu bạn có các bài kiểm thử và muốn chạy chúng trong môi trường build hoặc run:
# ENV FLASK_APP=app.py

EXPOSE 5000

CMD ["python", "app.py"]
