"""Render assets/icon/*.svg to PNG with headless Edge or Chrome (no Python dependencies).

Usage: python tools/brand/render_icon.py
"""
import os
import shutil
import subprocess
import sys

ICON = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'icon'))
BROWSERS = [
    os.path.expandvars(r'%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe'),
    r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
    r'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
    r'C:\Program Files\Google\Chrome\Application\chrome.exe',
]
# (svg, png, size, transparent background)
EXPORTS = [
    ('icon.svg', 'icon.png', 1024, True),
    ('icon-square.svg', 'play-store-512.png', 512, False),
    ('adaptive-foreground.svg', 'icon_foreground.png', 1024, True),
    ('adaptive-background.svg', 'icon_background.png', 1024, False),
    ('adaptive-monochrome.svg', 'icon_monochrome.png', 1024, True),
]


def render(browser, svg, png, size, transparent):
    # Wrap in HTML so the SVG fills the window exactly.
    html = os.path.join(ICON, '_render.html')
    url = 'file:///' + os.path.join(ICON, svg).replace('\\', '/')
    with open(html, 'w', encoding='utf-8') as f:
        f.write(f'<body style="margin:0;background:transparent"><img src="{url}" width="{size}" height="{size}" style="display:block"></body>')
    args = [browser, '--headless=new', '--disable-gpu', '--hide-scrollbars', f'--window-size={size},{size}',
            f'--screenshot={os.path.join(ICON, png)}', '--default-background-color=' + ('00000000' if transparent else 'FFFFFFFF'),
            'file:///' + html.replace('\\', '/')]
    subprocess.run(args, check=True, capture_output=True, timeout=60, env=dict(os.environ))
    os.remove(html)


if __name__ == '__main__':
    browser = next((b for b in BROWSERS if os.path.exists(b)), shutil.which('msedge') or shutil.which('chrome'))
    if not browser:
        sys.exit('no Edge or Chrome found')
    for e in EXPORTS:
        render(browser, *e)
        print('wrote', e[1])
