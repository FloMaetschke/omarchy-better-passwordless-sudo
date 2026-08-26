#!/usr/bin/env bash
#
# Installs the passwordless sudo duration picker:
#   1. the script into ~/.local/bin
#   2. the translations into ~/.local/share/omarchy-better-passwordless-sudo
#   3. the menu entry in ~/.config/omarchy/extensions/omarchy-menu.jsonc
#
# Safe to run repeatedly — an existing entry is replaced, not duplicated.

set -euo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BIN_SRC="$HERE/bin/omarchy-better-passwordless-sudo"
BIN_DST="$HOME/.local/bin/omarchy-better-passwordless-sudo"
LOCALE_SRC="$HERE/locale"
LOCALE_DST="$HOME/.local/share/omarchy-better-passwordless-sudo/locale"
EXT="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
BEGIN='  // >>> omarchy-better-passwordless-sudo >>>'
END='  // <<< omarchy-better-passwordless-sudo <<<'

die() {
  echo "install.sh: $*" >&2
  exit 1
}

TMP1="" TMP2=""
cleanup() { rm -f "$TMP1" "$TMP2"; }
trap cleanup EXIT

# --- Prerequisites ---------------------------------------------------------

for c in gum systemctl systemd-run sudo awk grep; do
  command -v "$c" >/dev/null 2>&1 || die "required tool missing: $c"
done
command -v omarchy >/dev/null 2>&1 ||
  die "Omarchy not found — this package requires an Omarchy installation."
[[ -f $BIN_SRC ]] || die "script not found: $BIN_SRC"
[[ -d $LOCALE_SRC ]] || die "locale directory not found: $LOCALE_SRC"
compgen -G "$LOCALE_SRC/*.sh" >/dev/null || die "no locale files in $LOCALE_SRC"

# --- Script ----------------------------------------------------------------

mkdir -p "$HOME/.local/bin"
install -m 755 "$BIN_SRC" "$BIN_DST"
echo "✓ Script installed: $BIN_DST"

# --- Translations ----------------------------------------------------------

# Replace wholesale rather than merge, so files of a language that was dropped
# do not linger. The path is hard-coded and sits below our own data directory.
case "$LOCALE_DST" in
*/omarchy-better-passwordless-sudo/locale) ;;
*) die "unexpected locale target path: $LOCALE_DST" ;;
esac
rm -rf "$LOCALE_DST"
mkdir -p "$LOCALE_DST"
install -m 644 "$LOCALE_SRC"/*.sh "$LOCALE_DST/"
echo "✓ $(find "$LOCALE_DST" -name '*.sh' | wc -l) languages installed: $LOCALE_DST"

# --- Menu entry ------------------------------------------------------------

mkdir -p "$(dirname "$EXT")"
created=0
if [[ ! -f $EXT ]]; then
  printf '{\n}\n' >"$EXT"
  created=1
fi

TMP1=$(mktemp)
TMP2=$(mktemp)

# Strip a block from an earlier run so nothing ends up in there twice.
awk -v b="$BEGIN" -v e="$END" '
  index($0, b) { skip = 1; next }
  index($0, e) { skip = 0; next }
  !skip
' "$EXT" >"$TMP1"

# Insert before the final closing brace.
last=$(grep -n '^[[:space:]]*}[[:space:]]*$' "$TMP1" | tail -1 | cut -d: -f1)
[[ -n $last ]] || die "no closing '}' found in $EXT — check the file by hand"

head -n $((last - 1)) "$TMP1" >"$TMP2"
{
  echo "$BEGIN"
  cat <<'ENTRY'
  // Replaces Omarchy's stock entry (a fixed 15 minutes) with a duration picker.
  // "checked" queries the expiry timer rather than the sudoers file: that file
  // lives in a directory only root may read, so testing it would trigger a
  // password prompt every time the menu opens.
  "setup.security.passwordless-sudo": {"icon":"󰟵","label":"Passwordless Sudo","checked":"systemctl is-active --quiet omarchy-nopasswd-expire-$USER.timer","action":"omarchy-launch-floating-terminal-with-presentation $HOME/.local/bin/omarchy-better-passwordless-sudo"},
ENTRY
  echo "$END"
} >>"$TMP2"
tail -n +"$last" "$TMP1" >>"$TMP2"

if cmp -s "$TMP2" "$EXT"; then
  echo "✓ Menu entry already up to date"
elif ((created)); then
  # The file was only just created as an empty skeleton — nothing to back up.
  cat "$TMP2" >"$EXT"
  echo "✓ Menu file created and entry added"
else
  backup="$EXT.bak.$(date +%s)"
  cp "$EXT" "$backup"
  cat "$TMP2" >"$EXT"
  echo "✓ Menu entry added (backup: $backup)"
fi

# --- Finishing up ----------------------------------------------------------

omarchy menu refresh >/dev/null 2>&1 || true
echo "✓ Menu reloaded"

case ":$PATH:" in
*":$HOME/.local/bin:"*) ;;
*) echo "  Note: ~/.local/bin is not on your PATH. That does not matter for the"
   echo "  menu, which calls the full path, but it does for running it directly." ;;
esac

echo
echo "Open it from: Omarchy menu → Setup → Security → Passwordless Sudo"
