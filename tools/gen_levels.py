def grid(w, h): return [['.'] * w for _ in range(h)]
def R(g, x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            g[y][x] = c
def P(g, x, y, c): g[y][x] = c
def border(g):
    h, w = len(g), len(g[0])
    R(g, 0, 0, w - 1, 0, '#'); R(g, 0, 0, 0, h - 1, '#'); R(g, w - 1, 0, w - 1, h - 1, '#')

def L1():
    w, h, F = 64, 24, 20
    g = grid(w, h); border(g)
    R(g, 1, F, w - 2, h - 1, '#')
    def pit(a, b):
        R(g, a, F, b, F + 1, '.'); R(g, a, F + 1, b, F + 1, '^')
    pit(11, 14); pit(33, 39); pit(48, 51)
    R(g, 35, F, 36, F, '#')                 # Trittstein in Grube B
    R(g, 18, F - 1, 21, F - 1, '#')         # Stufe
    R(g, 26, F - 1, 28, F - 1, '^')         # Spike-Feld
    P(g, 43, F - 1, 'C')
    R(g, 46, F - 6, 54, F - 5, '#'); R(g, 46, F - 4, 54, F - 4, 'v')   # Überhang mit Spikes
    R(g, 56, F - 1, 57, F - 1, '#'); R(g, 58, F - 2, 62, F - 1, '#')   # Treppe
    P(g, 3, F - 1, 'S'); P(g, 61, F - 3, 'G')
    return "Erste Schüsse", g

def L2():
    w, h = 40, 64
    g = grid(w, h); border(g)
    R(g, 1, 62, w - 2, h - 1, '#')
    cols = {'A': (2, 9), 'B': (15, 24), 'C': (30, 37)}
    pat = ['B', 'A', 'B', 'C']
    for i in range(14):
        r = 59 - 3 * i; k = pat[i % 4]; a, b = cols[k]
        R(g, a, r, b, r, '#')
        if i >= 6 and k == 'C': R(g, 38, r - 2, 38, r - 1, '<')
        if i >= 6 and k == 'A' and i < 13: R(g, 1, r - 2, 1, r - 1, '>')
        if i >= 8 and k == 'B': R(g, 18, r + 1, 21, r + 1, 'v')
        if i in (6, 11): P(g, 33, r - 1, 'C')
    P(g, 4, 61, 'S'); P(g, 5, 19, 'G')
    return "Der Aufstieg", g

def L3():
    w, h = 90, 28
    g = grid(w, h); border(g)
    R(g, 1, 26, w - 2, 26, '^'); R(g, 0, 27, w - 1, 27, '#')
    R(g, 1, 16, 8, 26, '#'); P(g, 3, 15, 'S')
    R(g, 14, 16, 15, 16, '#')
    P(g, 24, 15, 'M')
    R(g, 33, 13, 34, 13, '#')
    P(g, 41, 15, 'V')
    R(g, 47, 10, 50, 10, '#'); P(g, 48, 9, 'C')
    P(g, 58, 11, 'M')
    R(g, 68, 3, 84, 5, '#'); R(g, 68, 11, 84, 12, '#')              # Tunnel
    for x in (72, 73, 77, 78, 82): P(g, x, 10, '^')
    for x in (74, 75, 80): P(g, x, 6, 'v')
    R(g, 85, 11, 88, 26, '#'); P(g, 86, 10, 'G')
    return "Der Abgrund", g

def L4():
    w, h = 40, 70
    g = grid(w, h); R(g, 0, 0, w - 1, h - 1, '#'); R(g, 14, 1, 25, 65, '.')
    bars = [59, 52, 45, 38, 31, 24, 17, 10]
    for k, r in enumerate(bars):
        a, b = (14, 19) if k % 2 == 0 else (20, 25)   # Balken-Seite (Lücke ist gegenüber)
        R(g, a, r, b, r, '#'); R(g, a, r - 1, b, r - 1, '^'); R(g, a, r + 1, b, r + 1, 'v')
        # Ruhe-Leiste auf der Seite der NÄCHSTEN Lücke
        if k < len(bars) - 1:
            la, lb = (14, 16) if k % 2 == 0 else (23, 25)
            R(g, la, r - 3, lb, r - 3, '#')
            if k in (2, 5): P(g, la + 1, r - 4, 'C')
    R(g, 17, 4, 25, 4, '#')
    P(g, 16, 65, 'S'); P(g, 21, 3, 'G')
    return "Der Schacht", g

def L5():
    w, h = 70, 40
    g = grid(w, h); border(g)
    R(g, 1, 37, w - 2, 37, '^'); R(g, 0, 38, w - 1, 39, '#')
    R(g, 1, 34, 10, 37, '#'); P(g, 3, 33, 'S')
    P(g, 14, 31, 'M'); R(g, 20, 28, 21, 28, '#'); P(g, 13, 25, 'M')
    R(g, 6, 22, 7, 22, '#'); R(g, 12, 19, 13, 19, '#'); P(g, 19, 16, 'M')
    R(g, 22, 1, 56, 7, '#'); R(g, 22, 8, 56, 8, 'v')
    for a, b in ((24, 26), (31, 33), (38, 40), (45, 47)): R(g, a, 12, b, 12, '#')
    R(g, 52, 12, 56, 12, '#'); P(g, 54, 11, 'C')
    R(g, 57, 13, 57, 37, '#')
    for r, side in ((17, 'L'), (23, 'R'), (29, 'L')):
        a, b = (58, 62) if side == 'L' else (64, 68)
        R(g, a, r, b, r, '#'); R(g, a, r - 1, b, r - 1, '^')
    R(g, 58, 36, 68, 37, '#'); P(g, 62, 35, 'G')
    return "Gauntlet", g

levels = [L1(), L2(), L3(), L4(), L5()]
out = ["class_name LevelData", "extends RefCounted",
       "## ASCII-Level. Legende: # Fels | ^ v < > Spikes | S Start | G Ziel | C Checkpoint | M/V bewegliche Plattform (horizontal/vertikal)",
       "## (Generiert aus tools/gen_levels.py – kann aber auch direkt von Hand editiert werden.)", "", "const LEVELS: Array = ["]
for name, g in levels:
    w = {len(r) for r in g}; assert len(w) == 1, name
    flat = ''.join(''.join(r) for r in g)
    assert flat.count('S') == 1 and flat.count('G') == 1, name
    assert set(flat) <= set(".#^v<>SGCMV"), name
    out.append('\t{"name": "%s", "rows": [' % name)
    for r in g: out.append('\t\t"%s",' % ''.join(r))
    out.append('\t]},')
out.append("]")
open('scripts/level_data.gd', 'w').write('\n'.join(out) + '\n')
for n, g in levels: print(n, len(g[0]), 'x', len(g))
print('\n'.join(''.join(r) for r in L1()[1]))
