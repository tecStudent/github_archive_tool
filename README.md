# Organização de Repositórios Antigos no `legacy-projects`

Este documento descreve o processo adotado para organizar repositórios antigos da conta GitHub, centralizando o conteúdo em um monorepo privado chamado `legacy-projects`, mantendo os repositórios originais arquivados como referência e, se necessário, excluindo-os posteriormente.

---

## Índice

- [1. Objetivo](#1-objetivo)
- [2. Resultado esperado](#2-resultado-esperado)
- [3. Pré-requisitos](#3-pré-requisitos)
- [4. Histórico do processo executado](#4-histórico-do-processo-executado)
  - [4.1 Etapa 1 — baixar os repositórios antigos para uma pasta local](#41-etapa-1--baixar-os-repositórios-antigos-para-uma-pasta-local)
  - [4.2 Etapa 2 — preparar o monorepo privado `legacy-projects`](#42-etapa-2--preparar-o-monorepo-privado-legacy-projects)
  - [4.3 Etapa 3 — listar os repositórios arquivados](#43-etapa-3--listar-os-repositórios-arquivados)
  - [4.4 Etapa 4 — excluir os repositórios antigos](#44-etapa-4--excluir-os-repositórios-antigos)
- [5. Fluxo padrão para adicionar futuros repositórios ao `legacy-projects`](#5-fluxo-padrão-para-adicionar-futuros-repositórios-ao-legacy-projects)
  - [5.1 Passo 1 — clonar o repositório que vai para o legado](#51-passo-1--clonar-o-repositório-que-vai-para-o-legado)
  - [5.2 Passo 2 — garantir que o `legacy-projects` esteja clonado localmente](#52-passo-2--garantir-que-o-legacy-projects-esteja-clonado-localmente)
  - [5.3 Passo 3 — copiar o repositório para dentro do `legacy-projects`](#53-passo-3--copiar-o-repositório-para-dentro-do-legacy-projects)
  - [5.4 Passo 4 — versionar e subir a alteração no `legacy-projects`](#54-passo-4--versionar-e-subir-a-alteração-no-legacy-projects)
  - [5.5 Passo 5 — arquivar o repositório original](#55-passo-5--arquivar-o-repositório-original)
  - [5.6 Passo 6 — validar](#56-passo-6--validar)
  - [5.7 Passo 7 — excluir o repositório original, se desejar](#57-passo-7--excluir-o-repositório-original-se-desejar)
- [6. Script recomendado para adicionar um novo repositório ao legado](#6-script-recomendado-para-adicionar-um-novo-repositório-ao-legado)
- [7. Script opcional para excluir todos os arquivados, mantendo o `legacy-projects`](#7-script-opcional-para-excluir-todos-os-arquivados-mantendo-o-legacy-projects)
- [8. Boas práticas](#8-boas-práticas)
- [9. Estrutura esperada do monorepo](#9-estrutura-esperada-do-monorepo)
- [10. Resumo operacional](#10-resumo-operacional)
  - [10.1 Processo inicial](#101-processo-inicial)
  - [10.2 Processo futuro](#102-processo-futuro)

---

## 1. Objetivo

Centralizar projetos antigos em um único repositório privado chamado `legacy-projects`, mantendo os repositórios originais arquivados como referência.

Esse processo ajuda a:
- limpar o perfil público do GitHub;
- manter projetos antigos acessíveis em um único lugar;
- preservar uma cópia consolidada para consulta futura;
- reduzir a quantidade de repositórios soltos na conta.

---

## 2. Resultado esperado

Ao final do processo, a conta terá:

- um repositório privado chamado `legacy-projects`;
- dentro dele, uma pasta para cada projeto antigo;
- os repositórios originais arquivados no GitHub;
- opcionalmente, os repositórios originais excluídos depois da validação.

---

## 3. Pré-requisitos

Instalar e autenticar o GitHub CLI:

```bash
gh --version
gh auth login
````

Também é importante ter:

* Git instalado;
* acesso autenticado à conta GitHub;
* permissão para criar, arquivar e excluir repositórios.

Se for excluir repositórios via CLI depois, atualizar a autenticação com o escopo necessário:

```bash
gh auth refresh -s delete_repo
```

---

## 4. Histórico do processo executado

## 4.1 Etapa 1 — baixar os repositórios antigos para uma pasta local

Primeiro foi usado um script em PowerShell para listar os repositórios, filtrar os que estavam sem atualização há mais de 5 anos e cloná-los para uma pasta local.

### Código usado

```powershell
$usuario = "tecStudent"
$pastaDestino = "$HOME\repos-antigos"
$dataCorte = (Get-Date).AddYears(-5)

New-Item -ItemType Directory -Force -Path $pastaDestino | Out-Null

$repos = gh repo list $usuario --limit 200 --json nameWithOwner,updatedAt | ConvertFrom-Json

$reposAntigos = $repos | Where-Object {
    [datetime]$_.updatedAt -lt $dataCorte
}

foreach ($repo in $reposAntigos) {
    $nomeRepo = ($repo.nameWithOwner -split "/")[-1]
    $destinoRepo = Join-Path $pastaDestino $nomeRepo

    gh repo clone $repo.nameWithOwner $destinoRepo
}
```

### O que essa etapa fez

* criou a pasta local `repos-antigos`;
* listou os repositórios da conta;
* filtrou pela data de última atualização;
* clonou os repositórios antigos para a máquina.

### Observação importante

Essa etapa **não alterou nada no GitHub**.
Ela apenas criou uma cópia local dos repositórios.

---

## 4.2 Etapa 2 — preparar o monorepo privado `legacy-projects`

Depois foi adotada a estratégia de criar um repositório privado chamado `legacy-projects`, que funciona como um monorepo de arquivo.

### Código usado

```bash
#!/usr/bin/env bash
set -e

USUARIO="tecStudent"
REPO_NOME="legacy-projects"
ORIGEM="$HOME/repos-antigos"
DESTINO="$HOME/$REPO_NOME"

echo "Iniciando preparação do monorepo..."

if [ ! -d "$ORIGEM" ]; then
  echo "Pasta de origem não encontrada: $ORIGEM"
  exit 1
fi

if [ ! -d "$DESTINO" ]; then
  echo "Clonando repositório remoto para o caminho correto..."
  gh repo clone "$USUARIO/$REPO_NOME" "$DESTINO"
fi

cd "$DESTINO"

echo "Copiando projetos antigos para o monorepo..."
for repo in "$ORIGEM"/*; do
  if [ -d "$repo" ]; then
    nomeRepo="$(basename "$repo")"
    echo "Copiando $nomeRepo ..."

    mkdir -p "$DESTINO/$nomeRepo"
    cp -R "$repo/." "$DESTINO/$nomeRepo/"

    rm -rf "$DESTINO/$nomeRepo/.git"
  fi
done
```

### O que essa etapa fez

* validou se a pasta `repos-antigos` existia;
* garantiu que o repositório `legacy-projects` estivesse clonado localmente;
* copiou cada projeto para uma subpasta dentro do `legacy-projects`;
* removeu o `.git` interno de cada projeto para evitar repositório dentro de repositório.

### Continuação necessária

Depois da cópia, foi necessário adicionar, commitar e subir o conteúdo para o GitHub:

```bash
cd "$HOME/legacy-projects"

git add .
git commit -m "chore: consolidate archived legacy projects into monorepo"
git push -u origin main
```

### `.gitignore` recomendado

Para evitar subir dependências e arquivos desnecessários:

```bash
cat > .gitignore <<'EOF'
**/node_modules/
**/dist/
**/build/
**/.venv/
**/__pycache__/
.DS_Store
Thumbs.db
EOF
```

---

## 4.3 Etapa 3 — listar os repositórios arquivados

Depois foi utilizado um script para listar apenas os repositórios arquivados da conta, excluindo da lista o `legacy-projects`.

### Código usado

```bash
usuario="tecStudent"

gh repo list "$usuario" --archived --limit 200 --json nameWithOwner,isArchived \
  --jq '.[] | select(.nameWithOwner != "'"$usuario"'/legacy-projects") | .nameWithOwner'
```

### O que essa etapa fez

* listou apenas os repositórios arquivados;
* ignorou o `legacy-projects`;
* permitiu validar quais repositórios estavam prontos para eventual exclusão.

---

## 4.4 Etapa 4 — excluir os repositórios antigos

Por fim, foi criado um script para excluir os repositórios arquivados, mantendo o `legacy-projects`.

### Código usado

```bash
#!/usr/bin/env bash

usuario="tecStudent"
repo_manter="legacy-projects"

gh repo list "$usuario" --archived --limit 200 --json nameWithOwner \
  --jq '.[].nameWithOwner' |
while read -r repo; do
  if [ "$repo" != "$usuario/$repo_manter" ]; then
    echo "Excluindo $repo ..."
    gh repo delete "$repo" --yes
  fi
done
```

### Observação importante

Antes de usar esse script, é recomendado rodar:

```bash
gh auth refresh -s delete_repo
```

---

## 5. Fluxo padrão para adicionar futuros repositórios ao `legacy-projects`

A partir de agora, o processo recomendado para qualquer repositório que você queira mover para o legado é este.

### 5.1 Passo 1 — clonar o repositório que vai para o legado

Se o repositório ainda não estiver localmente:

```bash
gh repo clone tecStudent/NOME_DO_REPO "$HOME/temp-repo"
```

---

### 5.2 Passo 2 — garantir que o `legacy-projects` esteja clonado localmente

Se ainda não estiver:

```bash
gh repo clone tecStudent/legacy-projects "$HOME/legacy-projects"
```

---

### 5.3 Passo 3 — copiar o repositório para dentro do `legacy-projects`

```bash
mkdir -p "$HOME/legacy-projects/NOME_DO_REPO"
cp -R "$HOME/temp-repo/." "$HOME/legacy-projects/NOME_DO_REPO/"
rm -rf "$HOME/legacy-projects/NOME_DO_REPO/.git"
```

---

### 5.4 Passo 4 — versionar e subir a alteração no `legacy-projects`

```bash
cd "$HOME/legacy-projects"
git add .
git commit -m "chore: add NOME_DO_REPO to legacy-projects"
git push
```

---

### 5.5 Passo 5 — arquivar o repositório original

```bash
gh repo archive tecStudent/NOME_DO_REPO -y
```

---

### 5.6 Passo 6 — validar

```bash
gh repo view tecStudent/NOME_DO_REPO --json isArchived,nameWithOwner
```

---

### 5.7 Passo 7 — excluir o repositório original, se desejar

Somente depois de validar que:

* o conteúdo foi copiado corretamente para o `legacy-projects`;
* o commit foi enviado;
* o repositório original já foi arquivado.

```bash
gh auth refresh -s delete_repo
gh repo delete tecStudent/NOME_DO_REPO --yes
```

---

## 6. Script recomendado para adicionar um novo repositório ao legado

```bash
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
```

### Como usar

```bash
chmod +x adicionar_ao_legacy.sh
./adicionar_ao_legacy.sh NOME_DO_REPO
```

---

## 7. Script opcional para excluir todos os arquivados, mantendo o `legacy-projects`

Use somente depois de validar tudo.

```bash
#!/usr/bin/env bash

usuario="tecStudent"
repo_manter="legacy-projects"

gh auth refresh -s delete_repo

gh repo list "$usuario" --archived --limit 200 --json nameWithOwner \
  --jq '.[].nameWithOwner' |
while read -r repo; do
  if [ "$repo" != "$usuario/$repo_manter" ]; then
    echo "Excluindo $repo ..."
    gh repo delete "$repo" --yes
  fi
done
```

---

## 8. Boas práticas

* validar se o conteúdo entrou no `legacy-projects` antes de arquivar o original;
* confirmar se o `git push` foi concluído;
* evitar subir `node_modules`, `dist`, `build`, `.venv` e caches;
* excluir o original apenas depois de confirmar que o legado está completo;
* manter o `legacy-projects` privado.

---

## 9. Estrutura esperada do monorepo

```text
legacy-projects/
  README.md
  .gitignore
  alura-streamlit/
  alura-pandas/
  ebac/
  NlwEsports/
  webScraping/
  ...
```

---

## 10. Resumo operacional

### 10.1 Processo inicial

1. autenticar com `gh auth login`;
2. listar e clonar repositórios antigos;
3. criar e subir o conteúdo para `legacy-projects`;
4. arquivar os repositórios originais;
5. opcionalmente excluir os arquivados.

### 10.2 Processo futuro

1. clonar o repositório que vai para o legado;
2. copiar para dentro do `legacy-projects`;
3. remover `.git` interno;
4. `git add`, `git commit`, `git push`;
5. arquivar o original;
6. opcionalmente excluir depois.

---

## Observação final

O `legacy-projects` funciona como um repositório consolidado de projetos antigos.
Os repositórios originais podem continuar arquivados como referência ou serem excluídos depois da validação, dependendo da estratégia adotada.

