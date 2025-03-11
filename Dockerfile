FROM alpine:latest

RUN apk add --no-cache python3 py3-pip

WORKDIR /app

COPY pass_gen.py /app/pass_gen.py

ARG USER_NAME=Captain
ENV USER_NAME=$USER_NAME

CMD ["sh", "-c", "echo Hello, $USER_NAME! && python3 /app/pass_gen.py"]