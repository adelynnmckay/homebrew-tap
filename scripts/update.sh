#!/usr/bin/env bash

set -euo pipefail

CONFIG_FILE="config.json"
UPDATED=false

mkdir -p tmp
rm -rf tmp/*

jq -r 'keys[]' "$CONFIG_FILE" | while read -r name; do
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
    continue
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

  UPDATED=true
done

if [ "$UPDATED" = true ]; then
  echo "🚀 Committing changes..."
  git config user.name "github-actions[bot]"
  git config user.email "github-actions[bot]@users.noreply.github.com"
  git commit -am "🔄 Auto-update formulas from config.json"
  git push
else
  echo "✅ No changes detected. Done."
fi
