#!/usr/bin/env bash
set -e

USUARIO="tecStudent"
REPO_ORIGINAL="$1"
LEGACY_DIR="$HOME/legacy-projects"
TMP_DIR="$HOME/temp-legacy-import"

if [ -z "$REPO_ORIGINAL" ]; then
  echo "Uso: ./adicionar_ao_legacy.sh NOME_DO_REPO"
  exit 1
fi

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

echo "Clonando repositório original..."
gh repo clone "$USUARIO/$REPO_ORIGINAL" "$TMP_DIR/$REPO_ORIGINAL"

if [ ! -d "$LEGACY_DIR/.git" ]; then
  echo "Clonando legacy-projects..."
  gh repo clone "$USUARIO/legacy-projects" "$LEGACY_DIR"
fi

echo "Copiando conteúdo para o legacy-projects..."
mkdir -p "$LEGACY_DIR/$REPO_ORIGINAL"
cp -R "$TMP_DIR/$REPO_ORIGINAL/." "$LEGACY_DIR/$REPO_ORIGINAL/"
rm -rf "$LEGACY_DIR/$REPO_ORIGINAL/.git"

echo "Subindo alteração para o monorepo..."
cd "$LEGACY_DIR"
git add .
git commit -m "chore: add $REPO_ORIGINAL to legacy-projects"
git push

echo "Arquivando repositório original..."
gh repo archive "$USUARIO/$REPO_ORIGINAL" -y

echo "Concluído."
echo "Repo copiado para legacy-projects e original arquivado."