#!/usr/bin/env bash
set -e

REPO_DIR="/workspace/repo"

# 1. Instala dependências apenas se ainda não estiverem presentes
if ! command -v code-server >/dev/null 2>&1; then
  echo "==> Instalando dependências (primeira execução do container)..."
  apt-get update
  apt-get install -y --no-install-recommends \
    curl ca-certificates git sudo gnupg \
    build-essential python3 python3-pip \
    openssh-client locales

  locale-gen en_US.UTF-8

  # Node.js 20 (necessário para Claude Code)
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y nodejs

  # code-server
  curl -fsSL https://code-server.dev/install.sh | sh

  # Claude Code
  npm install -g @anthropic-ai/claude-code || true
fi

# 2. Copia ~/.ssh do host (montado read-only) para um local gravável dentro do container.
#    Necessário porque o git precisa atualizar known_hosts e o mount é :ro.
if [ -d /host-ssh ]; then
  echo "==> Configurando chaves SSH..."
  mkdir -p /root/.ssh
  cp -r /host-ssh/. /root/.ssh/ 2>/dev/null || true
  chmod 700 /root/.ssh
  find /root/.ssh -type f -exec chmod 600 {} \;
  # Garante que github.com está em known_hosts
  ssh-keyscan -t rsa,ecdsa,ed25519 github.com >> /root/.ssh/known_hosts 2>/dev/null || true
  sort -u /root/.ssh/known_hosts -o /root/.ssh/known_hosts 2>/dev/null || true
fi

# 3. Git config
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"
git config --global --add safe.directory "$REPO_DIR"

# 4. Clone do repositório na branch desta instância
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "==> [$INSTANCE_NAME] Clonando $REPO_URL na branch $REPO_BRANCH..."
  if ! git clone --branch "$REPO_BRANCH" "$REPO_URL" "$REPO_DIR"; then
    echo "Branch '$REPO_BRANCH' não encontrada no remote, clonando padrão..."
    git clone "$REPO_URL" "$REPO_DIR"
    cd "$REPO_DIR"
    git checkout -b "$REPO_BRANCH" || git checkout "$REPO_BRANCH" || true
  fi
else
  echo "==> [$INSTANCE_NAME] Repositório já existe em $REPO_DIR, pulando clone."
fi

echo "==> [$INSTANCE_NAME] Pronto. Branch atual:"
(cd "$REPO_DIR" && git rev-parse --abbrev-ref HEAD || true)

# 5. Inicia o code-server (binda em 8080 dentro do container; o host mapeia para portas diferentes)
exec code-server \
  --bind-addr 0.0.0.0:8080 \
  --auth password \
  --disable-telemetry \
  "$REPO_DIR"
