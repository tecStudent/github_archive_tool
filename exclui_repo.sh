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