#!/usr/bin/env python3
"""Generate contents/fonts/Rubik.ttf: Rubik variable font (weights 300-900) cut down to Latin.

Download Rubik[wght].ttf and OFL.txt from https://github.com/google/fonts/tree/main/ofl/rubik
Requires fontTools (pip install fonttools). Usage:
    python3 tools/gen_font.py path/to/Rubik[wght].ttf
"""
import os, sys
from fontTools.ttLib import TTFont
from fontTools import subset

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "contents", "fonts", "Rubik.ttf")

# ASCII, Latin-1 (á é í ó ú ñ ü ¿ ¡ …), dashes, quotes, bullet, ellipsis (used when names are cut), euro
UNICODES = (list(range(0x20, 0x7F)) + list(range(0xA0, 0x100))
            + [0x2013, 0x2014, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2026, 0x20AC])
FEATURES = ["kern", "liga", "ccmp", "locl", "mark", "mkmk", "rvrn", "tnum", "pnum", "case"]


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else sys.exit(__doc__)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    font = TTFont(src)
    options = subset.Options()
    options.layout_features = FEATURES
    options.name_IDs = ["*"]
    options.notdef_outline = True
    sub = subset.Subsetter(options)
    sub.populate(unicodes=UNICODES)
    sub.subset(font)
    font.save(OUT)
    print(OUT, os.path.getsize(OUT), "bytes")


if __name__ == "__main__":
    main()
