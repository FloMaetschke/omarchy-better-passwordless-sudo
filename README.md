# omarchy-sudo-timer

Ersetzt Omarchys Menüeintrag **Setup → Security → Passwordless Sudo** durch eine
Auswahl der Laufzeit. Statt der fest eingebauten 15 Minuten stehen 15 min, 1, 2,
4, 8, 12 und 24 Stunden zur Wahl — mit den Pfeiltasten, 15 min vorausgewählt.

Die Oberfläche spricht die Sprache des Systems.

```
WARNUNG: Passwortloses sudo gibt JEDEM Prozess unter deinem Benutzer
vollen Root-Zugriff ohne Passwort — bis die Zeit abläuft.
Pfeiltasten wählen, Enter bestätigt, Esc bricht ab.

Passwordless sudo aktivieren für:
> 15 Min
  1 Std
  2 Std
  4 Std
  8 Std
  12 Std
  24 Std
  Abbrechen
```

Ist passwortloses sudo bereits aktiv, zeigt der Kopf die Restlaufzeit und die
Liste bekommt zusätzlich **Deaktivieren**; eine Zeitwahl setzt den Timer neu.

## Installation

```bash
git clone <url> omarchy-sudo-timer
cd omarchy-sudo-timer
./install.sh
```

Der Installer legt das Skript nach `~/.local/bin/`, die Übersetzungen nach
`~/.local/share/omarchy-sudo-timer/locale/` und trägt den Menüeintrag in
`~/.config/omarchy/extensions/omarchy-menu.jsonc` ein. Er ist mehrfach
ausführbar: ein vorhandener Eintrag wird ersetzt, nicht verdoppelt. Vor jeder
Änderung entsteht eine Sicherung der Menüdatei.

```bash
./uninstall.sh
```

entfernt alles drei wieder; danach greift Omarchys Standardeintrag mit den
festen 15 Minuten.

Voraussetzungen: eine Omarchy-Installation mit `gum`, `systemd` und `sudo` —
auf einem Omarchy-System alles vorhanden.

## Sprachen

68 Sprachen. Die Sprache kommt aus `LC_ALL`, sonst `LC_MESSAGES`, sonst
`LANG`. Zuerst wird die vollständige Form gesucht (`zh_TW`), dann der reine
Sprachcode (`zh`), zuletzt Englisch.

| | | |
|---|---|---|
| `af` Afrikaans | `ar` العربية | `bg` Български |
| `bn` বাংলা | `bs` Bosanski | `ca` Català |
| `cs` Čeština | `da` Dansk | `de` Deutsch |
| `el` Ελληνικά | `en` English | `es` Español |
| `et` Eesti | `eu` Euskara | `fa` فارسی |
| `fi` Suomi | `fr` Français | `ga` Gaeilge |
| `gu` ગુજરાતી | `he` עברית | `hi` हिन्दी |
| `hr` Hrvatski | `hu` Magyar | `hy` Հայերեն |
| `id` Bahasa Indonesia | `is` Íslenska | `it` Italiano |
| `ja` 日本語 | `ka` ქართული | `kk` Қазақша |
| `km` ភាសាខ្មែរ | `kn` ಕನ್ನಡ | `ko` 한국어 |
| `lt` Lietuvių | `lv` Latviešu | `mk` Македонски |
| `ml` മലയാളം | `mn` Монгол | `mr` मराठी |
| `ms` Bahasa Melayu | `mt` Malti | `my` မြန်မာ |
| `nb` Norsk bokmål | `ne` नेपाली | `nl` Nederlands |
| `pa` ਪੰਜਾਬੀ | `pl` Polski | `pt` Português |
| `ro` Română | `ru` Русский | `si` සිංහල |
| `sk` Slovenčina | `sl` Slovenščina | `sq` Shqip |
| `sr` Српски | `sv` Svenska | `sw` Kiswahili |
| `ta` தமிழ் | `te` తెలుగు | `th` ไทย |
| `tl` Filipino | `tr` Türkçe | `uk` Українська |
| `ur` اردو | `uz` Oʻzbekcha | `vi` Tiếng Việt |
| `zh` 简体中文 | `zh_TW` 繁體中文 |  |

Übersetzungen liegen als eigene Dateien unter `locale/<code>.sh` und werden nach
`~/.local/share/omarchy-sudo-timer/locale/` installiert. Das Skript sucht sie in
dieser Reihenfolge: `$OMARCHY_SUDO_TIMER_LOCALE_DIR`, das Installationsverzeichnis,
dann `../locale` neben dem Skript — so läuft es auch direkt aus dem Repo.

Eine Sprache ergänzen heißt: eine Datei mit denselben fünfzehn `T_*`-Variablen
anlegen. Die Beschriftungen der Laufzeiten sind an den **Index** der Minutenwerte
gebunden, nicht an ihren Text — übersetzte Einheiten können also nichts
verschieben. In `T_ACTIVE`, `T_CHOSEN`, `T_UPDATED` und `T_NOW_ON` steht genau ein
`%s` für die Zeitangabe; ersetzt wird per Textersetzung, nicht über `printf`, damit
ein `%` in einer Übersetzung nichts kaputtmacht.

Ein Vorbehalt zu den Übersetzungen: Englisch und Deutsch sind geprüft, alle
übrigen sind maschinell erzeugt und nicht von Muttersprachlern gegengelesen.
Korrekturen sind willkommen. Bei den von rechts nach links geschriebenen
Sprachen (`ar`, `fa`, `he`, `ur`) hängt die Darstellung davon ab, wie gut das
Terminal bidirektionalen Text setzt; die Auswahl funktioniert, das Schriftbild
kann verrutschen. Schriften außerhalb des lateinischen Alphabets brauchen eine
Terminalschrift mit den passenden Zeichen.

## Wie es arbeitet

Wie Omarchys Original: eine Datei `/etc/sudoers.d/99-omarchy-nopasswd-$USER`
mit `NOPASSWD: ALL` plus ein transienter systemd-Timer
`omarchy-nopasswd-expire-$USER.timer`, der sie nach Ablauf wieder löscht.
Restlaufzeit prüfen:

```bash
systemctl list-timers 'omarchy-nopasswd*' --all
```

Zwei Details, die beim Nachbauen leicht schiefgehen:

- Der Timer wird mit `--on-active` gestellt und ist damit **monoton**.
  `NextElapseUSecRealtime` bleibt deshalb leer; die Restzeit kommt aus
  `systemctl list-timers -o json`, Feld `next`.
- Der Menüeintrag prüft für sein Häkchen den **Timer**, nicht die
  sudoers-Datei. Die liegt in einem nur für root lesbaren Verzeichnis — eine
  Prüfung darauf löste bei jedem Öffnen des Menüs eine Passwortabfrage aus.

Das Skript leert vor der Auswahl den Bildschirm und setzt die Listenhöhe exakt
auf die Zahl der Einträge. Der Präsentations-Wrapper des Menüs gibt vorher rund
dreizehn Zeilen Logo aus; kommt darunter noch ein längerer Vorspann, scrollt das
Terminal genau während gum zeichnet.

## Warum kein Omarchy-Plugin

Ein Omarchy-Shell-Plugin ist Quickshell/QML: jede `kind` (`bar`, `bar-widget`,
`menu`, `overlay`, `panel`, `service`) verlangt einen QML-Einstiegspunkt, und
`omarchy plugin validate` weist alles andere ab. Menüeinträge kann ein Plugin
ohnehin nicht liefern — `Menu.qml` liest genau zwei Dateien, den Default und die
eine Extension-Datei des Benutzers. Ein Bash-Skript plus Menüeintrag passt
darum nicht in dieses Format und wird hier stattdessen mit einem Installer
ausgeliefert.

## Sicherheit

Passwortloses sudo hebelt eine echte Schutzschicht aus: **jeder** Prozess unter
deinem Benutzerkonto kann in dieser Zeit ohne Rückfrage root werden. Nimm die
kürzeste Laufzeit, die für die Aufgabe reicht.

Der Timer überlebt keinen Neustart. Bleibt die sudoers-Datei nach einem
Reboot ohne zugehörigen Timer zurück, löscht das Skript sie beim nächsten
Aufruf sofort — dieselbe Vorsichtsmaßnahme wie im Original.

## Lizenz

MIT, siehe [LICENSE](LICENSE).
