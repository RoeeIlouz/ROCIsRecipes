"""ROCIs Recipes app icon: a chef's toque on the kitchen-green tile with an amber band.

Drawn on the 120 grid; Android adaptive layers use the 108dp grid with the design mapped onto the
visible 72dp centre. Pure vector shapes, no font needed.

Usage: python tools/brand/generate_icon.py   -> writes assets/icon/*.svg
Then render PNGs with tools/brand/render_icon.py (headless Edge or Chrome).
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'assets', 'icon')
os.makedirs(OUT, exist_ok=True)

TILE, ACCENT, WHITE = '#1F7A4D', '#F5A524', '#FFFFFF'  # kitchen green, warm amber
FOLD = '#CFE8DA'  # pale green pleat lines on the white hat


def toque(hat=WHITE, band=ACCENT, fold=FOLD):
    """Three puffs, a pleated body and a band, centred on x=60 and spanning y=20..100."""
    puffs = (f'<circle cx="41" cy="50" r="17" fill="{hat}"/>'
             f'<circle cx="60" cy="40" r="20" fill="{hat}"/>'
             f'<circle cx="79" cy="50" r="17" fill="{hat}"/>')
    body = f'<path fill="{hat}" d="M41 52 H79 L77 88 H43 Z"/>'
    pleats = ''.join(f'<path d="M{x} 62 V82" stroke="{fold}" stroke-width="3.2" stroke-linecap="round" fill="none"/>'
                     for x in (52, 60, 68))
    base = f'<rect x="38" y="86" width="44" height="14" rx="5" fill="{band}"/>'
    return puffs + body + pleats + base


def app_icon(rx):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120">'
            f'<defs><clipPath id="t"><rect width="120" height="120" rx="{rx}"/></clipPath></defs>'
            f'<g clip-path="url(#t)"><rect width="120" height="120" fill="{TILE}"/></g>'
            f'{toque()}</svg>')


def adaptive_background():
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108">'
            f'<rect width="108" height="108" fill="{TILE}"/></svg>')


def adaptive_foreground():
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108">'
            f'<g transform="translate(18 18) scale(0.6)">{toque()}</g></svg>')


def adaptive_monochrome():
    # White silhouette with the pleats and the band cut out as black in the mask.
    shape = toque(hat='white', band='white', fold='black')
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
