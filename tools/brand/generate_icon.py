"""ROCIs Recipes app icon in the ROCIs brand language (outlined Unbounded Bold R, header band, accent badge).

Geometry follows the sibling apps (ROCIs-tasks tools/brand/generate_brand.py) on the 120 grid;
Android adaptive layers use the 108dp grid with the design mapped onto the visible 72dp centre.
Unbounded is under the SIL OFL (see Unbounded-OFL.txt); the glyph is stored as outlines.

Usage: python tools/brand/generate_icon.py   -> writes assets/icon/*.svg
Then render PNGs with tools/brand/render_icon.py (headless Edge or Chrome).
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'assets', 'icon')
os.makedirs(OUT, exist_ok=True)
G = json.load(open(os.path.join(HERE, 'unbounded_glyphs.json'), encoding='utf-8'))
R = G['R700']
CAP = 750.0

TILE, ACCENT, WHITE = '#1F7A4D', '#F5A524', '#FFFFFF'  # kitchen green, warm amber


def shade(hex_, f):
    n = int(hex_[1:], 16)
    return '#' + ''.join(f'{round(((n >> s) & 255) * f):02X}' for s in (16, 8, 0))


BAND = shade(TILE, 0.78)


def r_letter(fill, cx, cy, h):
    x0, y0, x1, y1 = R['bounds']
    s = h / CAP
    tx = cx - s * (x0 + x1) / 2
    ty = cy + s * (y0 + y1) / 2
    box = (cx - s * (x1 - x0) / 2, cy - s * (y1 - y0) / 2, s * (x1 - x0), s * (y1 - y0))
    return f'<path fill="{fill}" transform="translate({tx:.3f} {ty:.3f}) scale({s:.5f} {-s:.5f})" d="{R["d"]}"/>', box


def cue(fill):
    """Three short steam bars on the header band."""
    return ''.join(f'<rect x="{x}" y="9" width="9" height="{h}" rx="4.5" fill="{fill}"/>'
                   for x, h in ((36, 20), (55.5, 24), (75, 20)))


def content(letter_fill=WHITE, badge_fill=ACCENT, cue_fill=WHITE):
    letter, (x, y, w, h) = r_letter(letter_fill, 58, 75, 58)
    # Amber "plate" badge at the foot of the R's leg, ringed in the tile colour.
    cx, cy, r = x + w * 0.98, y + h * 0.9, 12.5
    badge = f'<circle cx="{cx:.2f}" cy="{cy:.2f}" r="{r + 3.5}" fill="{TILE}"/><circle cx="{cx:.2f}" cy="{cy:.2f}" r="{r}" fill="{badge_fill}"/>'
    return cue(cue_fill) + letter + badge


def app_icon(rx):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120">'
            f'<defs><clipPath id="t"><rect width="120" height="120" rx="{rx}"/></clipPath></defs>'
            f'<g clip-path="url(#t)"><rect width="120" height="120" fill="{TILE}"/><rect width="120" height="24" fill="{BAND}"/></g>'
            f'{content()}</svg>')


def adaptive_background():
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108">'
            f'<rect width="108" height="108" fill="{TILE}"/><rect width="108" height="32.4" fill="{BAND}"/></svg>')


def adaptive_foreground():
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108">'
            f'<g transform="translate(18 18) scale(0.6)">{content()}</g></svg>')


def adaptive_monochrome():
    letter, (x, y, w, h) = r_letter(WHITE, 58, 75, 58)
    cx, cy, r = x + w * 0.98, y + h * 0.9, 12.5
    badge = f'<circle cx="{cx:.2f}" cy="{cy:.2f}" r="{r + 3.5}" fill="black"/><circle cx="{cx:.2f}" cy="{cy:.2f}" r="{r}" fill="white"/>'
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108"><defs>'
            f'<mask id="m" maskUnits="userSpaceOnUse" x="0" y="0" width="108" height="108">'
            f'<g transform="translate(18 18) scale(0.6)">{cue("white")}{letter}{badge}</g></mask></defs>'
            f'<rect width="108" height="108" fill="{WHITE}" mask="url(#m)"/></svg>')


FILES = {
    'icon.svg': app_icon(27),
    'icon-square.svg': app_icon(0),
    'adaptive-background.svg': adaptive_background(),
    'adaptive-foreground.svg': adaptive_foreground(),
    'adaptive-monochrome.svg': adaptive_monochrome(),
}

if __name__ == '__main__':
    for name, svg in FILES.items():
        with open(os.path.join(OUT, name), 'w', encoding='utf-8', newline='\n') as f:
            f.write(svg + '\n')
    print(len(FILES), 'files ->', os.path.abspath(OUT))
