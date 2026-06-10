FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      curl ca-certificates git sudo gnupg \
      build-essential python3 python3-pip \
      openssh-client locales \
 && locale-gen en_US.UTF-8 \
 && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && curl -fsSL https://code-server.dev/install.sh | sh \
 && npm install -g @anthropic-ai/claude-code \
 && install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
 && chmod a+r /etc/apt/keyrings/docker.asc \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable" \
      > /etc/apt/sources.list.d/docker.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      docker-ce-cli docker-buildx-plugin docker-compose-plugin \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
CMD ["bash", "/init.sh"]
