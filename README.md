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

Der Installer legt das Skript nach `~/.local/bin/` und trägt den Menüeintrag in
`~/.config/omarchy/extensions/omarchy-menu.jsonc` ein. Er ist mehrfach
ausführbar: ein vorhandener Eintrag wird ersetzt, nicht verdoppelt. Vor jeder
Änderung entsteht eine Sicherung der Menüdatei.

```bash
./uninstall.sh
```

entfernt beides wieder; danach greift Omarchys Standardeintrag mit den festen
15 Minuten.

Voraussetzungen: eine Omarchy-Installation mit `gum`, `systemd` und `sudo` —
auf einem Omarchy-System alles vorhanden.

## Sprachen

Deutsch, Englisch, Spanisch, Französisch, Italienisch, Portugiesisch und
Niederländisch. Die Sprache kommt aus `LC_ALL`, sonst `LC_MESSAGES`, sonst
`LANG`; alles Unbekannte fällt auf Englisch zurück.

Eine weitere Sprache ergänzt man als `case`-Zweig in
`bin/omarchy-sudo-passwordless-menu`. Beschriftungen der Laufzeiten sind an den
Index der Minutenwerte gebunden und nicht an ihren Text — übersetzte Einheiten
können also nichts verschieben.

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
