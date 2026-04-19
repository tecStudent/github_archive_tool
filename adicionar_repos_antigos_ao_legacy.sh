#!/usr/bin/env bash
set -euo pipefail

USUARIO="tecStudent"
ANOS=2
LEGACY_DIR="$HOME/legacy-projects"
TMP_DIR="$HOME/temp-legacy-import"
DATA_CORTE=$(date -d "$ANOS years ago" +%s)

# garante que o legacy-projects exista localmente
if [ ! -d "$LEGACY_DIR/.git" ]; then
  echo "Clonando legacy-projects..."
  gh repo clone "$USUARIO/legacy-projects" "$LEGACY_DIR"
fi

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

repos_importados=()
repos_para_arquivar=()

while IFS=$'\t' read -r repo updatedAt; do
  [ -z "$repo" ] && continue

  # ignora o próprio monorepo
  if [ "$repo" = "$USUARIO/legacy-projects" ]; then
    continue
  fi

  repoEpoch=$(date -d "$updatedAt" +%s)

  # pega apenas repos com último update anterior ao corte de 2 anos
  if [ "$repoEpoch" -lt "$DATA_CORTE" ]; then
    nomeRepo="${repo##*/}"

    # evita sobrescrever pasta já existente no monorepo
    if [ -e "$LEGACY_DIR/$nomeRepo" ]; then
      echo "Pulando $repo porque já existe em $LEGACY_DIR/$nomeRepo"
      continue
    fi

    echo "Importando $repo (último update: $updatedAt)..."

    gh repo clone "$repo" "$TMP_DIR/$nomeRepo"

    mkdir -p "$LEGACY_DIR/$nomeRepo"
    cp -R "$TMP_DIR/$nomeRepo/." "$LEGACY_DIR/$nomeRepo/"
    rm -rf "$LEGACY_DIR/$nomeRepo/.git"
    rm -rf "$TMP_DIR/$nomeRepo"

    repos_importados+=("$nomeRepo")
    repos_para_arquivar+=("$repo")
  fi
done < <(
  gh repo list "$USUARIO" \
    --source \
    --no-archived \
    --limit 200 \
    --json nameWithOwner,updatedAt \
    --jq '.[] | [.nameWithOwner, .updatedAt] | @tsv'
)

if [ ${#repos_importados[@]} -eq 0 ]; then
  echo "Nenhum repositório com mais de $ANOS anos sem update foi encontrado."
  exit 0
fi

echo "Subindo alteração para o legacy-projects..."
cd "$LEGACY_DIR"
git add .

if git diff --cached --quiet; then
  echo "Nenhuma alteração para commit."
  exit 0
fi

git commit -m "chore: add legacy repositories older than $ANOS years"
git push

echo "Arquivando repositórios originais..."
for repo in "${repos_para_arquivar[@]}"; do
  echo "Arquivando $repo ..."
  gh repo archive "$repo" -y
done

echo "Concluído."
echo "Repos importados:"
printf -- "- %s\n" "${repos_importados[@]}"