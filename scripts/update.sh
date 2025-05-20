#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

CONFIG_FILE="config.json"
UPDATED=1  # 0 = updated, 1 = no update

mkdir -p tmp
rm -rf tmp/*

update_formula() {
  local name="$1"
  local type repo prefix tag latest_tag files formula_path current_tag url archive sha

  echo "🔍 Processing $name..."

  type=$(jq -r ".\"$name\".type" "$CONFIG_FILE")
  repo=$(jq -r ".\"$name\".repo" "$CONFIG_FILE")
  prefix=$(jq -r ".\"$name\".version_prefix" "$CONFIG_FILE")
  files=$(jq -r ".\"$name\".files[]" "$CONFIG_FILE" || true)

  latest_tag=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | jq -r .tag_name)
  tag="${prefix}${latest_tag#${prefix}}"

  formula_path="Formula/$name.rb"
  [ "$type" = "cask" ] && formula_path="Casks/$name.rb"

  current_tag=$(grep -Eo 'version "[^"]+"' "$formula_path" | awk '{print $2}' | tr -d '"')

  if [ "$tag" = "$current_tag" ]; then
    echo "⏩ $name is already up to date (tag: $tag)"
    return 1
  fi

  echo "📦 Updating $name from $current_tag → $tag"

  url="https://github.com/$repo/archive/refs/tags/$tag.tar.gz"
  archive="tmp/$name.tar.gz"
  mkdir -p "tmp/$name"

  curl -L -o "$archive" "$url"
  sha=$(shasum -a 256 "$archive" | awk '{print $1}')
  echo "📦 SHA256: $sha"

  tar -xzf "$archive" -C "tmp/$name" --strip-components=1

  if [ -n "$files" ]; then
    mkdir -p "tmp/$name/filtered"
    for f in $files; do
      src="tmp/$name/$f"
      dst="tmp/$name/filtered/$(basename "$f")"
      if [ -e "$src" ]; then
        cp "$src" "$dst"
      fi
    done
    mv "tmp/$name/filtered" "tmp/$name/files"
  else
    mv "tmp/$name" "tmp/$name/files"
  fi

  sed -i -E "s|^  url \".*\"|  url \"$url\"|" "$formula_path"
  sed -i -E "s|^  sha256 \".*\"|  sha256 \"$sha\"|" "$formula_path"
  sed -i -E "s|^  version \".*\"|  version \"${tag#v}\"|" "$formula_path"

  return 0
}

main() {
  for name in $(jq -r 'keys[]' "$CONFIG_FILE"); do
    if update_formula "$name"; then
      UPDATED=0
    fi
  done

  if [ $UPDATED -eq 0 ]; then
    echo "🚀 Committing changes..."
    git config user.name "github-actions[bot]"
    git config user.email "github-actions[bot]@users.noreply.github.com"
    git commit -am "[github-actions] auto-update formula for version bump"
    git push
  else
    echo "✅ No changes detected. Done."
  fi
}

main "$@"
