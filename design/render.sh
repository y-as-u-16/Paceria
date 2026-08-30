#!/usr/bin/env bash
#
# 検討中の各案を実寸に近いサイズで書き出す。
# アイコンは 1024px で見ると必ず良く見えるので、ホーム画面の実寸（約120px）で
# 判断できるようにするのが目的。
#
# Usage: ./render.sh [file.svg ...]   引数なしで design/*.svg を全部

set -uo pipefail
cd "$(dirname "$0")"

files=("$@")
[ ${#files[@]} -eq 0 ] && files=(*.svg)

for svg in "${files[@]}"; do
  name="${svg%.svg}"
  qlmanage -t -s 1024 -o . "$svg" >/dev/null 2>&1
  [ -f "$svg.png" ] || { echo "✗ $svg のレンダリングに失敗"; continue; }
  sips -Z 512 "$svg.png" --out "preview_$name.png" >/dev/null 2>&1
  sips -Z 120 "$svg.png" --out "preview_${name}_120.png" >/dev/null 2>&1
  rm -f "$svg.png"
  echo "✓ $name"
done
