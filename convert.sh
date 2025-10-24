#!/usr/bin/env bash
set -euo pipefail

# PhotoPainter 7-color converter (IM6-safe)
# Default: PORTRAIT 480x800. Usa automaticamente colors.act nella dir corrente.
# Output: BMP24 non compresso (BMP3), niente palette (DirectClass), cartella ./pic
# Opzioni: --landscape per 800x480

WIDTH=480; HEIGHT=800; ORIENT="portrait"
if [[ "${1:-}" == "--landscape" ]]; then
  WIDTH=800; HEIGHT=480; ORIENT="landscape"; shift
fi

IM_CMD="$(command -v convert || true)"
[[ -z "$IM_CMD" ]] && { echo "Installa ImageMagick: sudo apt install imagemagick"; exit 1; }

command -v python3 >/dev/null 2>&1 || { echo "Serve python3"; exit 1; }
python3 -c "import PIL" 2>/dev/null || { echo "Installa Pillow: python3 -m pip install --user pillow"; exit 1; }

OUTDIR="pic"; mkdir -p "$OUTDIR"
PALETTE_IMG="$(mktemp -t palette.XXXXXX.png)"
trap 'rm -f "$PALETTE_IMG"' EXIT

# --- Palette da colors.act (768/772 byte) o 7-color di default ---
if [[ -f "colors.act" ]]; then
  echo ">> Uso palette: colors.act"
  python3 - "$PALETTE_IMG" << 'PY'
import sys, struct
from PIL import Image
data = open("colors.act","rb").read()
n=len(data)
if n==768:
    rgb=data; color_count=256
elif n==772:
    rgb=data[:768]; color_count,transparent_index=struct.unpack(">HH",data[768:772])
    if not (0<=color_count<=256): color_count=256
else:
    if n%3!=0 or n==0: raise SystemExit("ACT non valido (size %d)"%n)
    rgb=data; color_count=n//3
limit=min(color_count,256)*3
rgb=rgb[:limit]
colors=[tuple(rgb[i:i+3]) for i in range(0,len(rgb),3)]
while len(colors)>1 and colors[-1]==(0,0,0):
    colors.pop()
if not colors: raise SystemExit("ACT vuoto")
img=Image.new("RGB",(len(colors),1)); img.putdata(colors); img.save(sys.argv[1])
PY
else
  echo ">> Nessun colors.act: uso palette 7-color standard"
  "$IM_CMD" -size 7x1 \
    xc:black xc:white xc:green xc:blue xc:red xc:yellow xc:"#FF8000" \
    +append "$PALETTE_IMG"
fi

convert_one() {
  local in="$1"
  local base="$(basename "$in")"
  local name_noext="${base%.*}"
  local out="$OUTDIR/${name_noext}.bmp"

  echo ">> [$ORIENT] $in -> $out"

  # Passo principale: remap + depalettizzazione forzata (TrueColor) prima di scrivere BMP3
  "$IM_CMD" "$in" \
    -colorspace sRGB -strip +profile "*" -alpha off \
    -resize "${WIDTH}x${HEIGHT}^" -gravity center -extent "${WIDTH}x${HEIGHT}" \
    -dither FloydSteinberg \
    -remap "$PALETTE_IMG" \
    -type TrueColor -depth 8 -colorspace sRGB -alpha off \
    BMP3:"$out"

  # Verifica, e fallback “lavaggio” se rimane PseudoClass (raro ma capita su IM6)
  if identify -verbose "$out" | grep -qi "Class: *PseudoClass"; then
    echo "   -> fallback depalettizzazione"
    # Ricodifica a PNG24 in pipe (perdere la palette) e riscrive BMP3 24-bit
    "$IM_CMD" "$out" -type TrueColor -depth 8 png24:- | "$IM_CMD" png:- BMP3:"$out"
  fi

  # Stampa stato finale
  identify -verbose "$out" | egrep -i 'Class|Geometry|Depth|Compression' || true
}

shopt -s nullglob nocaseglob
if [[ $# -ge 1 ]]; then
  for f in "$@"; do [[ -f "$f" ]] && convert_one "$f" || echo "File non trovato: $f" >&2; done
else
  files=( *.jpg *.jpeg )
  [[ ${#files[@]} -eq 0 ]] && { echo "Nessuna JPEG trovata nella directory corrente."; exit 0; }
  for f in "${files[@]}"; do convert_one "$f"; done
fi

echo "Fatto. BMP (24-bit, ${WIDTH}x${HEIGHT}) in: $OUTDIR/"

