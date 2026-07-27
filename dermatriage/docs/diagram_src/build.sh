#!/usr/bin/env bash
# Regenerate every DermaTriage report diagram.
#   1. each gen_*.py emits <name>.svg into ../ (docs/)
#   2. headless Chrome rasterises each SVG to <name>.png at 2x
# Re-run this after editing any generator or svgkit.py.
set -e
cd "$(dirname "$0")"

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
[ -x "$CHROME" ] || CHROME="$(command -v chromium || command -v google-chrome)"
DOCS="$(cd .. && pwd)"

win() {  # canvas size per diagram — must match each Canvas(W, H)
  case "$1" in
    architecture)      echo "1580,1080" ;;
    class_diagram)     echo "1600,1230" ;;
    use_case)          echo "1600,1000" ;;
    sequence_diagram)  echo "1620,1120" ;;
    er_diagram)        echo "1500,900"  ;;
  esac
}

python3 gen_architecture.py
python3 gen_class.py
python3 gen_usecase.py
python3 gen_sequence.py
python3 gen_er.py

for name in architecture class_diagram use_case sequence_diagram er_diagram; do
  "$CHROME" --headless=new --no-sandbox --disable-gpu --hide-scrollbars \
    --force-device-scale-factor=2 --screenshot="$DOCS/$name.png" \
    --window-size="$(win "$name")" "$DOCS/$name.svg" >/dev/null 2>&1
  echo "rendered $name.png"
done
echo "done — svg + png written to $DOCS"
