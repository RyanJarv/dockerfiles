FROM alpine:3.19

RUN apk add --no-cache \
    python3 \
    py3-pip \
    git \
    bash \
    curl \
    vim

WORKDIR /workspace

RUN pip3 install --no-cache-dir --break-system-packages \
    google-generativeai \
    python-dotenv

CMD ["/bin/bash"]
