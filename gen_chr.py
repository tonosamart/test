#!/usr/bin/env python3
"""Generate CHR ROM data for Yakyuken NES game.
Includes full-screen character portrait generation.
"""

import math

def make_tile(rows):
    """Create a NES 8x8 tile from 8 rows of pixel data.
    Each row is a string of 8 chars: '0'=transparent, '1'=color1, '2'=color2, '3'=color3
    Returns 16 bytes (8 plane0 + 8 plane1).
    """
    if len(rows) != 8:
        rows = rows + ['00000000'] * (8 - len(rows))
    plane0 = []
    plane1 = []
    for row in rows:
        row = row.ljust(8, '0')[:8]
        b0 = 0
        b1 = 0
        for i, ch in enumerate(row):
            c = int(ch)
            if c & 1:
                b0 |= (0x80 >> i)
            if c & 2:
                b1 |= (0x80 >> i)
        plane0.append(b0)
        plane1.append(b1)
    return bytes(plane0 + plane1)

BLANK = make_tile(['00000000'] * 8)

# --- Font: A-Z (tiles $01-$1A) ---
font_data = {
    'A': ['00111000',
          '01101100',
          '11000110',
          '11000110',
          '11111110',
          '11000110',
          '11000110',
          '00000000'],
    'B': ['11111100',
          '11000110',
          '11000110',
          '11111100',
          '11000110',
          '11000110',
          '11111100',
          '00000000'],
    'C': ['00111100',
          '01100110',
          '11000000',
          '11000000',
          '11000000',
          '01100110',
          '00111100',
          '00000000'],
    'D': ['11111000',
          '11001100',
          '11000110',
          '11000110',
          '11000110',
          '11001100',
          '11111000',
          '00000000'],
    'E': ['11111110',
          '11000000',
          '11000000',
          '11111100',
          '11000000',
          '11000000',
          '11111110',
          '00000000'],
    'F': ['11111110',
          '11000000',
          '11000000',
          '11111100',
          '11000000',
          '11000000',
          '11000000',
          '00000000'],
    'G': ['00111100',
          '01100110',
          '11000000',
          '11001110',
          '11000110',
          '01100110',
          '00111100',
          '00000000'],
    'H': ['11000110',
          '11000110',
          '11000110',
          '11111110',
          '11000110',
          '11000110',
          '11000110',
          '00000000'],
    'I': ['01111110',
          '00011000',
          '00011000',
          '00011000',
          '00011000',
          '00011000',
          '01111110',
          '00000000'],
    'J': ['00111110',
          '00000110',
          '00000110',
          '00000110',
          '11000110',
          '01100110',
          '00111100',
          '00000000'],
    'K': ['11000110',
          '11001100',
          '11011000',
          '11110000',
          '11011000',
          '11001100',
          '11000110',
          '00000000'],
    'L': ['11000000',
          '11000000',
          '11000000',
          '11000000',
          '11000000',
          '11000000',
          '11111110',
          '00000000'],
    'M': ['11000110',
          '11101110',
          '11111110',
          '11010110',
          '11000110',
          '11000110',
          '11000110',
          '00000000'],
    'N': ['11000110',
          '11100110',
          '11110110',
          '11011110',
          '11001110',
          '11000110',
          '11000110',
          '00000000'],
    'O': ['00111100',
          '01100110',
          '11000110',
          '11000110',
          '11000110',
          '01100110',
          '00111100',
          '00000000'],
    'P': ['11111100',
          '11000110',
          '11000110',
          '11111100',
          '11000000',
          '11000000',
          '11000000',
          '00000000'],
    'Q': ['00111100',
          '01100110',
          '11000110',
          '11000110',
          '11010110',
          '01100110',
          '00111110',
          '00000000'],
    'R': ['11111100',
          '11000110',
          '11000110',
          '11111100',
          '11011000',
          '11001100',
          '11000110',
          '00000000'],
    'S': ['00111100',
          '01100110',
          '01110000',
          '00111100',
          '00001110',
          '01100110',
          '00111100',
          '00000000'],
    'T': ['11111110',
          '00011000',
          '00011000',
          '00011000',
          '00011000',
          '00011000',
          '00011000',
          '00000000'],
    'U': ['11000110',
          '11000110',
          '11000110',
          '11000110',
          '11000110',
          '01100110',
          '00111100',
          '00000000'],
    'V': ['11000110',
          '11000110',
          '11000110',
          '11000110',
          '01101100',
          '00111000',
          '00010000',
          '00000000'],
    'W': ['11000110',
          '11000110',
          '11000110',
          '11010110',
          '11111110',
          '11101110',
          '11000110',
          '00000000'],
    'X': ['11000110',
          '01101100',
          '00111000',
          '00111000',
          '00111000',
          '01101100',
          '11000110',
          '00000000'],
    'Y': ['11000110',
          '11000110',
          '01101100',
          '00111000',
          '00011000',
          '00011000',
          '00011000',
          '00000000'],
    'Z': ['11111110',
          '00001100',
          '00011000',
          '00110000',
          '01100000',
          '11000000',
          '11111110',
          '00000000'],
}

# --- Numbers 0-9 (tiles $1B-$24) ---
number_data = {
    '0': ['00111100',
          '01100110',
          '11001110',
          '11010110',
          '11100110',
          '01100110',
          '00111100',
          '00000000'],
    '1': ['00011000',
          '01111000',
          '00011000',
          '00011000',
          '00011000',
          '00011000',
          '01111110',
          '00000000'],
    '2': ['00111100',
          '01100110',
          '00000110',
          '00011100',
          '01100000',
          '11000000',
          '11111110',
          '00000000'],
    '3': ['00111100',
          '01100110',
          '00000110',
          '00011100',
          '00000110',
          '01100110',
          '00111100',
          '00000000'],
    '4': ['00001100',
          '00011100',
          '00111100',
          '01101100',
          '11111110',
          '00001100',
          '00001100',
          '00000000'],
    '5': ['11111110',
          '11000000',
          '11111100',
          '00000110',
          '00000110',
          '01100110',
          '00111100',
          '00000000'],
    '6': ['00111100',
          '01100000',
          '11000000',
          '11111100',
          '11000110',
          '11000110',
          '01111100',
          '00000000'],
    '7': ['11111110',
          '00000110',
          '00001100',
          '00011000',
          '00110000',
          '00110000',
          '00110000',
          '00000000'],
    '8': ['00111100',
          '01100110',
          '01100110',
          '00111100',
          '01100110',
          '01100110',
          '00111100',
          '00000000'],
    '9': ['00111100',
          '01100110',
          '01100110',
          '00111110',
          '00000110',
          '00001100',
          '00111000',
          '00000000'],
}

# --- Special characters ---
# $25: colon ':'
colon_tile = make_tile([
    '00000000',
    '00011000',
    '00011000',
    '00000000',
    '00011000',
    '00011000',
    '00000000',
    '00000000'])

# $26: exclamation '!'
excl_tile = make_tile([
    '00011000',
    '00011000',
    '00011000',
    '00011000',
    '00011000',
    '00000000',
    '00011000',
    '00000000'])

# $27: dash/hyphen '-'
dash_tile = make_tile([
    '00000000',
    '00000000',
    '00000000',
    '01111110',
    '00000000',
    '00000000',
    '00000000',
    '00000000'])

# $28: arrow cursor '>'
arrow_tile = make_tile([
    '01100000',
    '00110000',
    '00011000',
    '00001100',
    '00011000',
    '00110000',
    '01100000',
    '00000000'])

# $29: period '.'
period_tile = make_tile([
    '00000000',
    '00000000',
    '00000000',
    '00000000',
    '00000000',
    '00011000',
    '00011000',
    '00000000'])

# $2A: question mark '?'
question_tile = make_tile([
    '00111100',
    '01100110',
    '00000110',
    '00011100',
    '00011000',
    '00000000',
    '00011000',
    '00000000'])

# --- Katakana tiles ---
# $30: グ (gu - with dakuten built-in, simplified)
gu_tile = make_tile([
    '01111101',
    '00000110',
    '11111110',
    '00000110',
    '00001100',
    '00011000',
    '01100000',
    '00000000'])

# $31: ー (long vowel mark, horizontal bar)
chouon_tile = make_tile([
    '00000000',
    '00000000',
    '11111110',
    '00000000',
    '00000000',
    '00000000',
    '00000000',
    '00000000'])

# $32: チ (chi)
chi_tile = make_tile([
    '01111110',
    '00001000',
    '11111110',
    '00001000',
    '00001000',
    '00010000',
    '01100000',
    '00000000'])

# $33: ョ (small yo)
syo_tile = make_tile([
    '00000000',
    '01111100',
    '00000100',
    '01111100',
    '00000100',
    '00000100',
    '01111100',
    '00000000'])

# $34: キ (ki)
ki_tile = make_tile([
    '00010000',
    '11111110',
    '00010000',
    '11111110',
    '00010000',
    '00010000',
    '00010000',
    '00000000'])

# $35: パ (pa - with handakuten built-in, simplified)
pa_tile = make_tile([
    '01111101',
    '00100010',
    '01000100',
    '01000100',
    '01000100',
    '01000100',
    '10000100',
    '00000000'])

# --- Rock hand tiles (4 tiles: $40-$43, arranged 2x2) ---
rock_tl = make_tile([  # top-left
    '00000000',
    '00000000',
    '00000011',
    '00001111',
    '00011111',
    '00111110',
    '00111111',
    '01111111'])

rock_tr = make_tile([  # top-right
    '00000000',
    '00000000',
    '11100000',
    '11111000',
    '11111100',
    '01111100',
    '11111100',
    '11111110'])

rock_bl = make_tile([  # bottom-left
    '01111111',
    '00111111',
    '00111111',
    '00011111',
    '00001111',
    '00000011',
    '00000000',
    '00000000'])

rock_br = make_tile([  # bottom-right
    '11111110',
    '11111100',
    '11111100',
    '11111000',
    '11110000',
    '11000000',
    '00000000',
    '00000000'])

# --- Scissors hand tiles (4 tiles: $44-$47, arranged 2x2) ---
scis_tl = make_tile([  # top-left
    '00000011',
    '00000011',
    '00000011',
    '00000011',
    '00001111',
    '00011111',
    '00111110',
    '01111110'])

scis_tr = make_tile([  # top-right
    '01100000',
    '01100000',
    '01100000',
    '01100000',
    '11110000',
    '11111000',
    '01111100',
    '01111100'])

scis_bl = make_tile([  # bottom-left
    '00111111',
    '00111111',
    '00011111',
    '00001111',
    '00000111',
    '00000001',
    '00000000',
    '00000000'])

scis_br = make_tile([  # bottom-right
    '11111100',
    '11111100',
    '11111000',
    '11110000',
    '11100000',
    '10000000',
    '00000000',
    '00000000'])

# --- Paper hand tiles (4 tiles: $48-$4B, arranged 2x2) ---
paper_tl = make_tile([  # top-left
    '00010101',
    '00010101',
    '00010101',
    '00011111',
    '00111111',
    '00111111',
    '01111111',
    '01111110'])

paper_tr = make_tile([  # top-right
    '01000000',
    '01000000',
    '01000000',
    '11100000',
    '11110000',
    '11110000',
    '11111000',
    '01111000'])

paper_bl = make_tile([  # bottom-left
    '00111110',
    '00111111',
    '00011111',
    '00001111',
    '00000111',
    '00000001',
    '00000000',
    '00000000'])

paper_br = make_tile([  # bottom-right
    '01111000',
    '11111000',
    '11110000',
    '11110000',
    '11100000',
    '10000000',
    '00000000',
    '00000000'])

# --- Decorative tiles ---
# $50: horizontal line top
hline_top = make_tile([
    '11111111',
    '11111111',
    '00000000',
    '00000000',
    '00000000',
    '00000000',
    '00000000',
    '00000000'])

# $51: horizontal line bottom
hline_bot = make_tile([
    '00000000',
    '00000000',
    '00000000',
    '00000000',
    '00000000',
    '00000000',
    '11111111',
    '11111111'])

# $52: vertical line left
vline_l = make_tile([
    '11000000',
    '11000000',
    '11000000',
    '11000000',
    '11000000',
    '11000000',
    '11000000',
    '11000000'])

# $53: vertical line right
vline_r = make_tile([
    '00000011',
    '00000011',
    '00000011',
    '00000011',
    '00000011',
    '00000011',
    '00000011',
    '00000011'])

# $54: corner top-left
corner_tl = make_tile([
    '11111111',
    '11111111',
    '11000000',
    '11000000',
    '11000000',
    '11000000',
    '11000000',
    '11000000'])

# $55: corner top-right
corner_tr = make_tile([
    '11111111',
    '11111111',
    '00000011',
    '00000011',
    '00000011',
    '00000011',
    '00000011',
    '00000011'])

# $56: corner bottom-left
corner_bl = make_tile([
    '11000000',
    '11000000',
    '11000000',
    '11000000',
    '11000000',
    '11000000',
    '11111111',
    '11111111'])

# $57: corner bottom-right
corner_br = make_tile([
    '00000011',
    '00000011',
    '00000011',
    '00000011',
    '00000011',
    '00000011',
    '11111111',
    '11111111'])

# $58: star/sparkle
star_tile = make_tile([
    '00010000',
    '00010000',
    '01010100',
    '00111000',
    '01010100',
    '00010000',
    '00010000',
    '00000000'])

# $59: VS tile
vs_tile = make_tile([
    '00000000',
    '10001111',
    '10010000',
    '01001110',
    '01000001',
    '00101111',
    '00100000',
    '00000000'])

# ============================================================
# FULL-SCREEN CHARACTER PORTRAIT GENERATOR
# ============================================================

def fill_ellipse(grid, cx, cy, rx, ry, color):
    H, W = len(grid), len(grid[0])
    for y in range(max(0, int(cy - ry - 1)), min(H, int(cy + ry + 2))):
        for x in range(max(0, int(cx - rx - 1)), min(W, int(cx + rx + 2))):
            dx = (x - cx) / max(rx, 0.1)
            dy = (y - cy) / max(ry, 0.1)
            if dx*dx + dy*dy <= 1.0:
                grid[y][x] = color

def fill_rect(grid, x1, y1, x2, y2, color):
    H, W = len(grid), len(grid[0])
    for y in range(max(0, y1), min(H, y2 + 1)):
        for x in range(max(0, x1), min(W, x2 + 1)):
            grid[y][x] = color

def draw_full_portrait():
    """Draw a full-screen anime girl portrait (256x208 pixels = 32x26 tiles).
    Colors: 0=bg(black), 1=dark(hair/outline), 2=skin, 3=white/highlight
    """
    W, H = 256, 208
    grid = [[0] * W for _ in range(H)]
    cx = 128

    # --- Back hair (large mass) ---
    fill_ellipse(grid, cx, 75, 60, 75, 1)
    # Side hair flowing down
    fill_rect(grid, cx - 62, 55, cx - 42, 188, 1)
    fill_rect(grid, cx + 42, 55, cx + 62, 188, 1)
    fill_ellipse(grid, cx - 52, 188, 12, 14, 1)
    fill_ellipse(grid, cx + 52, 188, 12, 14, 1)

    # --- Shoulders / body ---
    fill_ellipse(grid, cx, 194, 68, 28, 1)
    fill_ellipse(grid, cx, 193, 65, 25, 2)
    fill_rect(grid, cx - 65, 192, cx + 65, 208, 2)

    # --- Neck ---
    fill_rect(grid, cx - 16, 142, cx + 16, 180, 2)

    # --- Face ---
    fill_ellipse(grid, cx, 98, 45, 53, 2)

    # --- Hair top ---
    fill_ellipse(grid, cx, 42, 58, 40, 1)
    fill_rect(grid, cx - 56, 28, cx + 56, 58, 1)

    # --- Bangs ---
    fill_rect(grid, cx - 50, 46, cx + 50, 70, 1)
    # Show forehead below bangs
    fill_rect(grid, cx - 38, 66, cx + 38, 82, 2)
    # Bang tips (triangular fringe)
    for bx_off in [-36, -24, -12, 0, 12, 24, 36]:
        for dy in range(16):
            hw = max(0, 6 - dy // 2)
            for dx in range(-hw, hw + 1):
                x, y = cx + bx_off + dx, 70 + dy
                if 0 <= x < W and 0 <= y < H:
                    grid[y][x] = 1

    # --- Eyes ---
    ey = 96

    # Left eye
    ex_l = cx - 22
    fill_ellipse(grid, ex_l, ey, 16, 12, 3)      # sclera
    fill_ellipse(grid, ex_l + 2, ey + 1, 11, 10, 1)  # iris outline
    fill_ellipse(grid, ex_l + 2, ey + 1, 9, 8, 2)   # iris color
    fill_ellipse(grid, ex_l + 3, ey + 2, 5, 4, 0)   # pupil
    fill_ellipse(grid, ex_l - 3, ey - 4, 4, 3, 3)   # highlight
    fill_ellipse(grid, ex_l + 6, ey + 5, 2, 2, 3)   # small highlight

    # Right eye (mirrored)
    ex_r = cx + 22
    fill_ellipse(grid, ex_r, ey, 16, 12, 3)
    fill_ellipse(grid, ex_r - 2, ey + 1, 11, 10, 1)
    fill_ellipse(grid, ex_r - 2, ey + 1, 9, 8, 2)
    fill_ellipse(grid, ex_r - 3, ey + 2, 5, 4, 0)
    fill_ellipse(grid, ex_r + 3, ey - 4, 4, 3, 3)
    fill_ellipse(grid, ex_r - 6, ey + 5, 2, 2, 3)

    # Eyelashes (thick top line)
    for eye_cx in [ex_l, ex_r]:
        for dx in range(-14, 15):
            x = eye_cx + dx
            base_y = ey - 12 + (dx * dx) // 22
            for t in range(3):
                yy = base_y + t
                if 0 <= x < W and 0 <= yy < H:
                    grid[yy][x] = 1

    # Eyebrows
    for eye_cx in [ex_l, ex_r]:
        for dx in range(-14, 15):
            x = eye_cx + dx
            y = ey - 20 + abs(dx) // 4
            for t in range(2):
                if 0 <= x < W and 0 <= y + t < H:
                    grid[y + t][x] = 1

    # --- Nose ---
    for dy in range(4):
        grid[114 + dy][cx] = 1
    grid[117][cx + 1] = 1
    grid[117][cx + 2] = 1

    # --- Mouth (happy smile) ---
    for dx in range(-14, 15):
        x = cx + dx
        y = 125 + (dx * dx) // 28
        if 0 <= x < W and 0 <= y < H:
            grid[y][x] = 1
    # Inside mouth
    for dx in range(-11, 12):
        x = cx + dx
        y_top = 126 + (dx * dx) // 35
        for y in range(y_top, min(y_top + 4, H)):
            if 0 <= x < W:
                grid[y][x] = 0
    # Teeth
    for dx in range(-8, 9):
        x = cx + dx
        y = 126 + (dx * dx) // 40
        if 0 <= x < W and 0 <= y < H:
            grid[y][x] = 3

    # --- Blush marks ---
    fill_ellipse(grid, cx - 34, 112, 8, 4, 3)
    fill_ellipse(grid, cx + 34, 112, 8, 4, 3)

    # --- Collar (white V-shape) ---
    for dy in range(20):
        hw = max(0, 16 - dy)
        for dx in range(-hw, hw + 1):
            x, y = cx + dx, 168 + dy
            if 0 <= x < W and 0 <= y < H:
                grid[y][x] = 3

    return grid


def extract_and_dedup(grid, fixed_tiles):
    """Extract 8x8 tiles from grid, deduplicate against fixed tiles.
    fixed_tiles: dict of {tile_bytes: tile_index} for pre-existing tiles.
    Returns: (all_tile_bytes[256], nametable[rows][cols])
    """
    H, W = len(grid), len(grid[0])
    tile_rows = H // 8
    tile_cols = W // 8

    # Build tile array: start with fixed tiles
    tile_array = [BLANK] * 256  # 256 tile slots
    for tile_data, idx in fixed_tiles.items():
        tile_array[idx] = tile_data

    # Track used indices
    used = set(fixed_tiles.values())

    # Available slots for portrait tiles
    available = [i for i in range(256) if i not in used]
    avail_idx = 0

    # Map tile_bytes -> assigned index (including fixed)
    tile_map = dict(fixed_tiles)

    nametable = []
    for ty in range(tile_rows):
        row = []
        for tx in range(tile_cols):
            # Extract 8x8 tile
            rows = []
            for py in range(8):
                r = ''
                for px in range(8):
                    r += str(grid[ty * 8 + py][tx * 8 + px])
                rows.append(r)
            td = make_tile(rows)

            if td in tile_map:
                row.append(tile_map[td])
            else:
                if avail_idx < len(available):
                    idx = available[avail_idx]
                    avail_idx += 1
                    tile_map[td] = idx
                    tile_array[idx] = td
                    row.append(idx)
                else:
                    row.append(0)  # fallback
        nametable.append(row)

    unique_portrait = avail_idx
    print(f"Portrait uses {unique_portrait} unique tiles "
          f"(budget: {len(available)})")
    return tile_array, nametable


def build_cg_attribute_table():
    """Build attribute table for the CG result screen (64 bytes)."""
    attrs = bytearray()
    # Row 0-4 (tile rows 0-19): palette 1 for character center
    for _ in range(5):
        attrs += bytes([0x00, 0x00, 0x55, 0x55, 0x55, 0x55, 0x00, 0x00])
    # Row 5 (tile rows 20-23): top=pal1(neck), bottom=pal2(outfit)
    # TL=1,TR=1,BL=2,BR=2 -> %10_10_01_01 = $A5
    attrs += bytes([0x00, 0x00, 0xA5, 0xA5, 0xA5, 0xA5, 0x00, 0x00])
    # Row 6 (tile rows 24-27): top=pal2(outfit), bottom=pal0(text)
    # TL=2,TR=2,BL=0,BR=0 -> %00_00_10_10 = $0A
    attrs += bytes([0x00, 0x00, 0x0A, 0x0A, 0x0A, 0x0A, 0x00, 0x00])
    # Row 7 (tile rows 28-29): palette 0 (text)
    attrs += bytes([0x00] * 8)
    return attrs


# --- Build CHR ROM ---
def build_chr():
    tiles = bytearray()

    # --- Fixed tiles (game UI) ---
    # $00: blank
    tiles += BLANK

    # $01-$1A: A-Z
    for ch in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ':
        tiles += make_tile(font_data[ch])

    # $1B-$24: 0-9
    for ch in '0123456789':
        tiles += make_tile(number_data[ch])

    # $25-$2A: special characters
    tiles += colon_tile
    tiles += excl_tile
    tiles += dash_tile
    tiles += arrow_tile
    tiles += period_tile
    tiles += question_tile

    # $2B-$2F: padding
    for _ in range(5):
        tiles += BLANK

    # $30-$35: Katakana
    tiles += gu_tile
    tiles += chouon_tile
    tiles += chi_tile
    tiles += syo_tile
    tiles += ki_tile
    tiles += pa_tile

    # $36-$3F: padding
    for _ in range(10):
        tiles += BLANK

    # $40-$4B: Hand tiles
    tiles += rock_tl
    tiles += rock_tr
    tiles += rock_bl
    tiles += rock_br
    tiles += scis_tl
    tiles += scis_tr
    tiles += scis_bl
    tiles += scis_br
    tiles += paper_tl
    tiles += paper_tr
    tiles += paper_bl
    tiles += paper_br

    # $4C-$4F: padding
    for _ in range(4):
        tiles += BLANK

    # $50-$59: decorative tiles
    tiles += hline_top
    tiles += hline_bot
    tiles += vline_l
    tiles += vline_r
    tiles += corner_tl
    tiles += corner_tr
    tiles += corner_bl
    tiles += corner_br
    tiles += star_tile
    tiles += vs_tile

    # Pad to $5A
    current = len(tiles) // 16
    for _ in range(0x5A - current):
        tiles += BLANK

    # --- Record fixed tiles for dedup ---
    fixed_tiles = {}
    for i in range(len(tiles) // 16):
        td = bytes(tiles[i * 16:(i + 1) * 16])
        if td not in fixed_tiles:
            fixed_tiles[td] = i

    # --- Generate portrait and fill remaining tile slots ---
    portrait_grid = draw_full_portrait()
    all_tiles, cg_nametable = extract_and_dedup(portrait_grid, fixed_tiles)

    # Build final pattern table 0 from all_tiles
    pt0 = bytearray()
    for i in range(256):
        pt0 += all_tiles[i]
    assert len(pt0) == 4096

    # Pattern Table 1 (Sprites): blank
    pt1 = bytearray(BLANK * 256)

    chr_data = bytes(pt0 + pt1)
    assert len(chr_data) == 8192

    # --- Export portrait nametable (32*26 = 832 bytes) ---
    # Pad to full 32*30 = 960 bytes (rows 26-29 = blank for text overlay)
    nametable_bytes = bytearray()
    for row in cg_nametable:
        for idx in row:
            nametable_bytes.append(idx)
    # Rows 26-29: blank
    for _ in range(4 * 32):
        nametable_bytes.append(0x00)
    assert len(nametable_bytes) == 960

    with open('cg_map.bin', 'wb') as f:
        f.write(nametable_bytes)
    print(f"Generated cg_map.bin ({len(nametable_bytes)} bytes)")

    # --- Export CG attribute table (64 bytes) ---
    cg_attrs = build_cg_attribute_table()
    with open('cg_attr.bin', 'wb') as f:
        f.write(cg_attrs)
    print(f"Generated cg_attr.bin ({len(cg_attrs)} bytes)")

    return chr_data


if __name__ == '__main__':
    chr_data = build_chr()
    with open('chr.bin', 'wb') as f:
        f.write(chr_data)
    print(f"Generated chr.bin ({len(chr_data)} bytes)")
