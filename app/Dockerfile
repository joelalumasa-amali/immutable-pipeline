FROM python:3.11-alpine
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
    && addgroup -S appgroup \
    && adduser -S appuser -G appgroup
COPY app.py .
USER appuser
EXPOSE 5000
CMD ["python", "app.py"]
