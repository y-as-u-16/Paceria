#!/usr/bin/env bash
#
# Enforces the dependency rules in docs/02_ARCHITECTURE.md.
# docs/02_ARCHITECTURE.md の依存方向ルールを機械的に検証する。
#
# A written rule that nothing checks is a rule that decays. This script is the
# executable half of the architecture document.
# 検証されない規約は必ず腐る。本スクリプトは設計書の実行可能な半身である。
#
# Feature-based layout means Domain is not one directory but many:
# Paceria/Features/*/Domain and Paceria/Core/Domain. Checks glob over all of them.
# Feature-based のため Domain は一箇所ではなく Paceria/Features/*/Domain と
# Paceria/Core/Domain に分散する。検査は両方を走査する。
#
# Usage: ./scripts/check-architecture.sh

set -uo pipefail

violations=0

fail() {
  echo "::error file=$1,line=$2::$3"
  violations=$((violations + 1))
}

# Collects every Domain directory across features plus Core.
# Feature 横断で Domain ディレクトリを集める。
domain_dirs() {
  find Paceria -type d -name Domain 2>/dev/null
}

# --- Rule: Domain must not import UI/persistence frameworks ----------------
# Domain 層はフレームワークを import してはならない（02_ARCHITECTURE.md #3, #19）
FORBIDDEN_IN_DOMAIN='^import (SwiftUI|SwiftData|UIKit|HealthKit|CloudKit|Combine)$'

while IFS= read -r dir; do
  [ -z "$dir" ] && continue
  while IFS=: read -r file line _; do
    [ -z "$file" ] && continue
    fail "$file" "$line" "Domain must not import UI/persistence frameworks (02_ARCHITECTURE.md #3, #19) / Domain 層はフレームワークを import できません"
  done < <(grep -rnE "$FORBIDDEN_IN_DOMAIN" "$dir" --include='*.swift' 2>/dev/null)
done < <(domain_dirs)

# --- Rule: Domain entities must not be SwiftData models -------------------
# Domain Entity に @Model を付けてはならない（02_ARCHITECTURE.md #11）
while IFS= read -r dir; do
  [ -z "$dir" ] && continue
  while IFS=: read -r file line _; do
    [ -z "$file" ] && continue
    fail "$file" "$line" "Domain entities must not be @Model; map via a Mapper (02_ARCHITECTURE.md #11) / Domain Entity に @Model は使えません。Mapper で変換してください"
  done < <(grep -rn '@Model' "$dir" --include='*.swift' 2>/dev/null)
done < <(domain_dirs)

# --- Rule: Views must not query SwiftData directly ------------------------
# View から SwiftData を直接触らない（02_ARCHITECTURE.md #7, #19）
if [ -d Paceria/Features ]; then
  while IFS=: read -r file line _; do
    [ -z "$file" ] && continue
    fail "$file" "$line" "Presentation must not use @Query/ModelContext directly (02_ARCHITECTURE.md #7, #19) / Presentation 層で SwiftData を直接操作しないでください"
  done < <(find Paceria/Features -type d -name Presentation -exec grep -rnE '@Query|ModelContext|FetchDescriptor' {} --include='*.swift' \; 2>/dev/null)
fi

# --- Rule: no Manager / Utils catch-all types -----------------------------
# Manager 万能クラスと Utils.swift は禁止（02_ARCHITECTURE.md #19 AVOID）
while IFS=: read -r file line _; do
  [ -z "$file" ] && continue
  fail "$file" "$line" "Avoid catch-all Manager types; name the responsibility (02_ARCHITECTURE.md #19) / 万能な Manager クラスは避け、責務を名前で表してください"
done < <(grep -rnE '(class|struct|final class) +[A-Z][A-Za-z]*Manager\b' Paceria --include='*.swift' 2>/dev/null)

while IFS= read -r file; do
  [ -z "$file" ] && continue
  fail "$file" "1" "Utils.swift is a catch-all; split by responsibility (02_ARCHITECTURE.md #19) / Utils.swift は雑多置き場です。責務ごとに分割してください"
done < <(find Paceria -name 'Utils.swift' 2>/dev/null)

# --- Result ---------------------------------------------------------------
if [ "$violations" -gt 0 ]; then
  echo ""
  echo "Architecture check failed: $violations violation(s)."
  echo "アーキテクチャ検査に失敗しました: 違反 $violations 件"
  echo "See docs/02_ARCHITECTURE.md / 詳細は docs/02_ARCHITECTURE.md を参照してください"
  exit 1
fi

echo "Architecture check passed. / アーキテクチャ検査に合格しました。"
