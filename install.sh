#!/bin/sh
# install.sh: installs or updates this plasmoid in the user's Plasma (kpackagetool6, Plasma/Applet).
# Copied into every plasmoid from shared/tools/install-plasmoid.sh; edit that file, not the copies.
#
#   ./install.sh [--restart] [--dry-run] [--ui=full|terminal|simple|none] [-q]
#
#   --restart   restart plasmashell afterwards (default: no; the hint `plasmashell --replace & disown` is printed)
#   --dry-run   show the commands instead of running them
#   --ui, -q    output style of shared/tools/plasmoid.py (live graphics on sixel terminals; -q = plain text)
#
# With ../shared/tools/plasmoid.py next to this plasmoid and python3 available, that tool does the work (metadata and
# property icon checks, live progress, summary). Otherwise a plain fallback runs kpackagetool6 -u, or -i when the
# plasmoid is not installed yet.

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P) || exit 1
tool="$dir/../shared/tools/plasmoid.py"
if [ -f "$tool" ] && command -v python3 >/dev/null 2>&1; then
    exec python3 "$tool" install "$dir" "$@"
fi

restart=0
dry=
for arg in "$@"; do
    case $arg in
        --restart) restart=1 ;;
        --dry-run) dry=1 ;;
        --ui=*|-q|--quiet) ;;  # only meaningful for plasmoid.py
        *) echo "install.sh: unknown option: $arg" >&2; exit 2 ;;
    esac
done

# kpackagetool6 -u removes the installed tree first: never through a symlink to the sources.
id=$(sed -n 's/.*"Id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$dir/metadata.json" | head -n 1)
target="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids/$id"
if [ -n "$id" ] && [ -L "$target" ]; then
    echo "$target is a symlink to $(readlink "$target"): files are live, kpackagetool6 skipped"
else
    if [ -n "$dry" ]; then
        echo "kpackagetool6 -t Plasma/Applet -u $dir || kpackagetool6 -t Plasma/Applet -i $dir"
    else
        kpackagetool6 -t Plasma/Applet -u "$dir" || kpackagetool6 -t Plasma/Applet -i "$dir" || exit 1
    fi
fi

if [ "$restart" = 1 ]; then
    if [ -n "$dry" ]; then
        echo "kquitapp6 plasmashell; nohup plasmashell --replace >/dev/null 2>&1 &"
    else
        kquitapp6 plasmashell >/dev/null 2>&1
        nohup plasmashell --replace >/dev/null 2>&1 &
    fi
else
    echo "restart Plasma to load it: plasmashell --replace & disown"
fi
