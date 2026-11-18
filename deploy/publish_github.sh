#!/usr/bin/env bash
# Publish Neon Drift to github.com/fierce-bri/neon-drift and enable GitHub Pages.
# Prerequisites: the repo exists (empty, public) and the Abacus.AI GitHub App has access to it.
# Re-run after a new export to refresh the gh-pages build.
set -euo pipefail
cd "$(dirname "$0")/.."
REPO=fierce-bri/neon-drift
export GH_TOKEN=$(printf 'protocol=https\nhost=github.com\n\n' | git credential fill | sed -n 's/^password=//p')

git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$REPO.git"
git push -u origin main

# Rebuild the gh-pages branch from build/web
TMP=$(mktemp -d)
git worktree add -f "$TMP" gh-pages
find "$TMP" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
cp build/web/* "$TMP"/ && touch "$TMP/.nojekyll"
git -C "$TMP" add -A
git -C "$TMP" -c user.name="Aphiwe Mzulwini" -c user.email="fierce-bri@users.noreply.github.com" \
  commit -qm "Deploy web build to GitHub Pages" || true
git -C "$TMP" push -f origin gh-pages
git worktree remove --force "$TMP"

gh api -X POST "repos/$REPO/pages" -f 'source[branch]=gh-pages' -f 'source[path]=/' >/dev/null 2>&1 \
  || gh api -X PUT "repos/$REPO/pages" -f 'source[branch]=gh-pages' -f 'source[path]=/' >/dev/null
gh repo edit "$REPO" --homepage "https://fierce-bri.github.io/neon-drift/" \
  --description "Neon top-down arena survival shooter made in Godot 4 - play it in the browser" || true

echo "Waiting for https://fierce-bri.github.io/neon-drift/ ..."
for i in $(seq 1 30); do
  code=$(curl -s -o /dev/null -w '%{http_code}' https://fierce-bri.github.io/neon-drift/)
  [ "$code" = 200 ] && { echo "Live (200)"; exit 0; }
  sleep 20
done
echo "Pages not live yet (last status $code); check the repo's Settings > Pages."
