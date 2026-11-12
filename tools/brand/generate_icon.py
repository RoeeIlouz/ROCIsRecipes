"""ROCIs Recipes app icon in the ROCIs brand language, with a cooking metaphor.

Same construction as the sibling apps (ROCIs-tasks tools/brand/generate_brand.py): a rounded tile, a
darker header band that carries the app's metaphor object (Tasks: a clipboard clip, Schedule: calendar
rings, Recipes: steam rising from a pot), a large white outlined Unbounded Bold letter, and a coloured
accent badge at the foot of the letter (Tasks: a red check, Schedule: a green square, Recipes: an amber
chef's hat). Geometry is on the 120 grid; Android adaptive layers use the 108dp grid with the design
mapped onto the visible 72dp centre. Unbounded is under the SIL OFL (see Unbounded-OFL.txt); the glyph
is stored as outlines.

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
HAT_BAND = shade(ACCENT, 0.8)


def r_letter(fill, cx, cy, h):
    x0, y0, x1, y1 = R['bounds']
    s = h / CAP
    tx = cx - s * (x0 + x1) / 2
    ty = cy + s * (y0 + y1) / 2
    box = (cx - s * (x1 - x0) / 2, cy - s * (y1 - y0) / 2, s * (x1 - x0), s * (y1 - y0))
    return f'<path fill="{fill}" transform="translate({tx:.3f} {ty:.3f}) scale({s:.5f} {-s:.5f})" d="{R["d"]}"/>', box


def steam(color):
    """Three wavy wisps of steam in the header band, reaching a little below it like the Schedule rings."""
    wisps = ((40, 6, 25), (60, 3, 28), (80, 6, 25))
    parts = []
    for x, top, bottom in wisps:
        mid = (top + bottom) / 2
        parts.append(
            f'<path d="M{x} {bottom} C{x + 7} {mid + 4} {x - 7} {mid - 4} {x} {top}" fill="none" '
            f'stroke="{color}" stroke-width="5.5" stroke-linecap="round"/>')
    return ''.join(parts)


def hat(hat_fill, band_fill, ring, w=34):
    """A small chef's toque. One ring in the tile colour is drawn behind the whole hat (not per shape),
    so it separates cleanly from the letter without seams."""
    s = w / 70.0
    geometry = (('circle', 'cx="41" cy="50" r="17"'),
                ('circle', 'cx="60" cy="40" r="20"'),
                ('circle', 'cx="79" cy="50" r="17"'),
                ('path', 'd="M41 52 H79 L77 88 H43 Z"'),
                ('rect', 'x="38" y="86" width="44" height="14" rx="5"'))
    ring_layer = ''.join(f'<{tag} {attrs} fill="{ring}" stroke="{ring}" stroke-width="9" stroke-linejoin="round"/>'
                         for tag, attrs in geometry)
    fills = ''.join(f'<{tag} {attrs} fill="{band_fill if tag == "rect" else hat_fill}"/>' for tag, attrs in geometry)
    return ring_layer + fills, s


def badge(cx, cy, hat_fill, band_fill, ring):
    shapes, s = hat(hat_fill, band_fill, ring)
    return f'<g transform="translate({cx - 60 * s:.2f} {cy - 60 * s:.2f}) scale({s:.4f})">{shapes}</g>'


def content(letter_fill=WHITE, steam_fill=WHITE):
    letter, (x, y, w, h) = r_letter(letter_fill, 56, 75, 58)
    cx, cy = x + w * 1.0, y + h * 0.88
    return steam(steam_fill) + letter + badge(cx, cy, ACCENT, HAT_BAND, TILE)


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
    letter, (x, y, w, h) = r_letter('white', 56, 75, 58)
    cx, cy = x + w * 1.0, y + h * 0.88
    shape = steam('white') + letter + badge(cx, cy, 'white', 'white', 'black')
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108"><defs>'
            f'<mask id="m" maskUnits="userSpaceOnUse" x="0" y="0" width="108" height="108">'
            f'<g transform="translate(18 18) scale(0.6)">{shape}</g></mask></defs>'
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
