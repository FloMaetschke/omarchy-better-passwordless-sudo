#!/usr/bin/env bash
#
# Entfernt Skript und Menüeintrag. Ein gerade aktives passwordless sudo wird
# NICHT angetastet — das schaltet sich über seinen Timer von selbst ab, oder
# von Hand mit: omarchy sudo passwordless

set -euo pipefail

BIN_DST="$HOME/.local/bin/better-passwordless-sudo"
DATA_DST="$HOME/.local/share/better-passwordless-sudo"
EXT="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
BEGIN='  // >>> better-passwordless-sudo >>>'
END='  // <<< better-passwordless-sudo <<<'

TMP=""
cleanup() { rm -f "$TMP"; }
trap cleanup EXIT

if [[ -f $BIN_DST ]]; then
  rm -f "$BIN_DST"
  echo "✓ Skript entfernt: $BIN_DST"
else
  echo "· Skript war nicht installiert"
fi

if [[ -d $DATA_DST ]]; then
  case "$DATA_DST" in
  */better-passwordless-sudo) rm -rf "$DATA_DST"; echo "✓ Sprachen entfernt: $DATA_DST" ;;
  *) echo "· unerwarteter Pfad, nicht angefasst: $DATA_DST" ;;
  esac
else
  echo "· Keine Sprachdateien gefunden"
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
  echo "✓ Menüeintrag entfernt (Sicherung: $backup)"
  echo "  Omarchys Standardeintrag mit fester 15-Minuten-Vorgabe greift wieder."
else
  echo "· Kein Menüeintrag gefunden"
fi

omarchy menu refresh >/dev/null 2>&1 || true
echo "✓ Menü neu geladen"

if systemctl is-active --quiet "omarchy-nopasswd-expire-$USER.timer" 2>/dev/null; then
  echo
  echo "Achtung: passwordless sudo ist gerade noch aktiv."
  echo "Sofort abschalten mit: omarchy sudo passwordless"
fi
