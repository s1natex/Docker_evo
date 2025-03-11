FROM alpine:latest

RUN apk add --no-cache python3 py3-pip

WORKDIR /app

COPY pass_gen.py /app/pass_gen.py

CMD ["python3", "/app/pass_gen.py"]