FROM python:3.12-alpine
WORKDIR /app
COPY app.py ./
RUN addgroup -S app && adduser -S -G app app \
    && mkdir -p /data && chown app:app /data
USER app
EXPOSE 8080
CMD ["python", "app.py"]
