# syntax=docker/dockerfile:1.7-labs

FROM ubuntu:25.10


ENV DEBIAN_FRONTEND=noninteractive
RUN --mount=type=cache,target=/var/cache/apt,id=claude-apt-cache,sharing=locked apt-get update
RUN --mount=type=cache,target=/var/cache/apt,id=claude-apt-cache,sharing=locked apt-get install -y libatomic1 curl build-essential


ENV PATH="$PATH:/root/.local/bin"
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && /root/.local/bin/uv python update-shell
RUN uv python install python3.11
RUN uv python install python3.12.12
RUN uv python install python3.14
RUN sh <<EOH
ln -f -s /root/.local/bin/* /usr/local/bin/ 
ln -f -s /root/local/bin/python3.14 /usr/local/bin/python3
ln -f -s /root/local/bin/python3.14 /usr/local/bin/python
EOH

# This is much faster then installing through apt
ENV NVM_DIR "/root/.nvm"
RUN curl 'https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh' | bash && echo '. /root/.nvm/nvm.sh' | tee -a ~/.bashrc ~/.profile ~/.zshrc /etc/profile
RUN . /root/.nvm/nvm.sh && nvm install node && nvm use node

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable && echo ' . "$HOME/.cargo/env"' | tee -a ~/.bashrc ~/.profile ~/.zshrc /etc/profile

RUN ln -f -s /root/.nvm/versions/node/*/bin/* /usr/local/bin/ 

COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
