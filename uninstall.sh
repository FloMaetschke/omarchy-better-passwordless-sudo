#!/usr/bin/env bash
#
# Removes the script, the translations and the menu entry. A currently active
# passwordless sudo is left alone — it expires through its own timer, or can be
# switched off by hand with: omarchy sudo passwordless

set -euo pipefail

BIN_DST="$HOME/.local/bin/omarchy-better-passwordless-sudo"
DATA_DST="$HOME/.local/share/omarchy-better-passwordless-sudo"
EXT="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
BEGIN='  // >>> omarchy-better-passwordless-sudo >>>'
END='  // <<< omarchy-better-passwordless-sudo <<<'

TMP=""
cleanup() { rm -f "$TMP"; }
trap cleanup EXIT

if [[ -f $BIN_DST ]]; then
  rm -f "$BIN_DST"
  echo "✓ Script removed: $BIN_DST"
else
  echo "· Script was not installed"
fi

if [[ -d $DATA_DST ]]; then
  case "$DATA_DST" in
  */omarchy-better-passwordless-sudo) rm -rf "$DATA_DST"; echo "✓ Translations removed: $DATA_DST" ;;
  *) echo "· unexpected path, left untouched: $DATA_DST" ;;
  esac
else
  echo "· No translations found"
fi

if [[ -f $EXT ]] && grep -qF "${BEGIN# *}" "$EXT" 2>/dev/null; then
  TMP=$(mktemp)
  awk -v b="$BEGIN" -v e="$END" '
    index($0, b) { skip = 1; next }
    index($0, e) { skip = 0; next }
    !skip
  ' "$EXT" >"$TMP"
  backup="$EXT.bak.$(date +%s)"
  cp "$EXT" "$backup"
  cat "$TMP" >"$EXT"
  echo "✓ Menu entry removed (backup: $backup)"
  echo "  Omarchy's stock entry with its fixed 15 minutes applies again."
else
  echo "· No menu entry found"
fi

omarchy menu refresh >/dev/null 2>&1 || true
echo "✓ Menu reloaded"

if systemctl is-active --quiet "omarchy-nopasswd-expire-$USER.timer" 2>/dev/null; then
  echo
  echo "Heads up: passwordless sudo is still active right now."
  echo "Switch it off immediately with: omarchy sudo passwordless"
fi
