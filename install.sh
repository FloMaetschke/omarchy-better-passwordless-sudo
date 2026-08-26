#!/usr/bin/env bash
#
# Installs the passwordless sudo duration picker into your home directory:
#   1. the script into ~/.local/bin
#   2. the translations into ~/.local/share/omarchy-better-passwordless-sudo
#   3. the menu entry, by calling the installed script's --setup-menu
#
# Safe to run repeatedly — an existing entry is replaced, not duplicated.
#
# Installing from a package instead? Then this script is not involved; run
# `omarchy-better-passwordless-sudo --setup-menu` once by hand.

set -euo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BIN_SRC="$HERE/bin/omarchy-better-passwordless-sudo"
BIN_DST="$HOME/.local/bin/omarchy-better-passwordless-sudo"
LOCALE_SRC="$HERE/locale"
LOCALE_DST="$HOME/.local/share/omarchy-better-passwordless-sudo/locale"

die() {
  echo "install.sh: $*" >&2
  exit 1
}

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

# Let the installed copy write the entry, so it points at itself and the logic
# lives in exactly one place.
"$BIN_DST" --setup-menu

case ":$PATH:" in
*":$HOME/.local/bin:"*) ;;
*) echo
   echo "  Note: ~/.local/bin is not on your PATH. That does not matter for the"
   echo "  menu, which calls the full path, but it does for running it directly." ;;
esac
