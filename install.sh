#!/usr/bin/env bash
#
# Installiert die Zeitauswahl für Passwordless Sudo:
#   1. Skript nach ~/.local/bin
#   2. Menüeintrag in ~/.config/omarchy/extensions/omarchy-menu.jsonc
#
# Mehrfach ausführbar — ein vorhandener Eintrag wird ersetzt, nicht verdoppelt.

set -euo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BIN_SRC="$HERE/bin/omarchy-sudo-passwordless-menu"
BIN_DST="$HOME/.local/bin/omarchy-sudo-passwordless-menu"
EXT="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
BEGIN='  // >>> omarchy-sudo-timer >>>'
END='  // <<< omarchy-sudo-timer <<<'

die() {
  echo "install.sh: $*" >&2
  exit 1
}

TMP1="" TMP2=""
cleanup() { rm -f "$TMP1" "$TMP2"; }
trap cleanup EXIT

# --- Voraussetzungen -------------------------------------------------------

for c in gum systemctl systemd-run sudo awk grep; do
  command -v "$c" >/dev/null 2>&1 || die "Pflichtwerkzeug fehlt: $c"
done
command -v omarchy >/dev/null 2>&1 ||
  die "Omarchy nicht gefunden — dieses Paket setzt eine Omarchy-Installation voraus."
[[ -f $BIN_SRC ]] || die "Skript nicht gefunden: $BIN_SRC"

# --- Skript ----------------------------------------------------------------

mkdir -p "$HOME/.local/bin"
install -m 755 "$BIN_SRC" "$BIN_DST"
echo "✓ Skript installiert: $BIN_DST"

# --- Menüeintrag -----------------------------------------------------------

mkdir -p "$(dirname "$EXT")"
created=0
if [[ ! -f $EXT ]]; then
  printf '{\n}\n' >"$EXT"
  created=1
fi

TMP1=$(mktemp)
TMP2=$(mktemp)

# Einen früher gesetzten Block entfernen, damit nichts doppelt landet.
awk -v b="$BEGIN" -v e="$END" '
  index($0, b) { skip = 1; next }
  index($0, e) { skip = 0; next }
  !skip
' "$EXT" >"$TMP1"

# Vor der letzten schließenden Klammer einfügen.
last=$(grep -n '^[[:space:]]*}[[:space:]]*$' "$TMP1" | tail -1 | cut -d: -f1)
[[ -n $last ]] || die "keine abschließende '}' in $EXT gefunden — Datei von Hand prüfen"

head -n $((last - 1)) "$TMP1" >"$TMP2"
{
  echo "$BEGIN"
  cat <<'ENTRY'
  // Ersetzt Omarchys Standardeintrag (feste 15 Minuten) durch eine Zeitauswahl.
  // "checked" fragt den Ablauf-Timer ab statt der sudoers-Datei — die liegt in
  // einem nur für root lesbaren Verzeichnis und würde beim Öffnen des Menüs
  // eine Passwortabfrage auslösen.
  "setup.security.passwordless-sudo": {"icon":"󰟵","label":"Passwordless Sudo","checked":"systemctl is-active --quiet omarchy-nopasswd-expire-$USER.timer","action":"omarchy-launch-floating-terminal-with-presentation $HOME/.local/bin/omarchy-sudo-passwordless-menu"},
ENTRY
  echo "$END"
} >>"$TMP2"
tail -n +"$last" "$TMP1" >>"$TMP2"

if cmp -s "$TMP2" "$EXT"; then
  echo "✓ Menüeintrag war bereits aktuell"
elif ((created)); then
  # Die Datei ist gerade erst als leeres Gerüst entstanden — nichts zu sichern.
  cat "$TMP2" >"$EXT"
  echo "✓ Menüdatei angelegt und Eintrag gesetzt"
else
  backup="$EXT.bak.$(date +%s)"
  cp "$EXT" "$backup"
  cat "$TMP2" >"$EXT"
  echo "✓ Menüeintrag ergänzt (Sicherung: $backup)"
fi

# --- Abschluss -------------------------------------------------------------

omarchy menu refresh >/dev/null 2>&1 || true
echo "✓ Menü neu geladen"

case ":$PATH:" in
*":$HOME/.local/bin:"*) ;;
*) echo "  Hinweis: ~/.local/bin liegt nicht in PATH. Für das Menü egal (es ruft"
   echo "  den vollen Pfad auf), für den direkten Aufruf im Terminal aber schon." ;;
esac

echo
echo "Aufruf: Omarchy-Menü → Setup → Security → Passwordless Sudo"
