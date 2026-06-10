#!/usr/bin/env bash
set -e

REPO_DIR="/workspace/repo"

# 1. Copia ~/.ssh do host (montado read-only) para um local gravável dentro do container.
#    Necessário porque o git precisa atualizar known_hosts e o mount é :ro.
if [ -d /host-ssh ]; then
  echo "==> Configurando chaves SSH..."
  mkdir -p /root/.ssh
  cp -r /host-ssh/. /root/.ssh/ 2>/dev/null || true
  chmod 700 /root/.ssh
  find /root/.ssh -type f -exec chmod 600 {} \;
  ssh-keyscan -t rsa,ecdsa,ed25519 github.com >> /root/.ssh/known_hosts 2>/dev/null || true
  sort -u /root/.ssh/known_hosts -o /root/.ssh/known_hosts 2>/dev/null || true
fi

# 2. Git config
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"
git config --global --add safe.directory "$REPO_DIR"

# 3. Clone do repositório na branch desta instância
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

# 4. Inicia o code-server (binda em 8080 dentro do container; o host mapeia para portas diferentes)
exec code-server \
  --bind-addr 0.0.0.0:8080 \
  --auth password \
  --disable-telemetry \
  "$REPO_DIR"
