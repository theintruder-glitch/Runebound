#!/usr/bin/env python3
"""Author RUNEBOUND's small vector atlases; no external art or runtime dependency."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / 'assets'
INK = '#10171e'

def paint(color):
    if color.startswith('#') and len(color)==9:
        return f'fill="{color[:7]}" fill-opacity="{int(color[7:],16)/255:.4f}"'
    return f'fill="{color}"'

def path(d, fill, stroke=INK, width=2):
    return f'<path d="{d}" {paint(fill)} stroke="{stroke}" stroke-width="{width}" stroke-linejoin="round" stroke-linecap="round"/>'

def ellipse(x, y, rx, ry, fill, stroke='none', width=1):
    return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" {paint(fill)} stroke="{stroke}" stroke-width="{width}"/>'

def glow(x, y, color='#ed8c68', wide=4):
    return ellipse(x, y, wide+3, 5, color+'22')+ellipse(x, y, wide, 2, color)+ellipse(x-1, y, 1, 1, '#fff1c2')

DEFS = '''<defs>
<linearGradient id="hide" x2=".8" y2="1"><stop stop-color="#879482"/><stop offset=".48" stop-color="#465a55"/><stop offset="1" stop-color="#26343a"/></linearGradient>
<linearGradient id="bone" x2=".8" y2="1"><stop stop-color="#e5d8af"/><stop offset=".45" stop-color="#b7af94"/><stop offset="1" stop-color="#5b6b68"/></linearGradient>
<linearGradient id="iron" x2=".85" y2="1"><stop stop-color="#a4aeb1"/><stop offset=".4" stop-color="#596b74"/><stop offset="1" stop-color="#26333e"/></linearGradient>
<linearGradient id="cloak" x2=".7" y2="1"><stop stop-color="#63776c"/><stop offset=".4" stop-color="#304a45"/><stop offset="1" stop-color="#19292e"/></linearGradient>
<linearGradient id="ice" x2=".8" y2="1"><stop stop-color="#c5ece8"/><stop offset=".4" stop-color="#72b6c4"/><stop offset="1" stop-color="#39526d"/></linearGradient>
<linearGradient id="slime" x2=".5" y2="1"><stop stop-color="#8dba8a"/><stop offset=".5" stop-color="#426f65"/><stop offset="1" stop-color="#1a3a40"/></linearGradient>
<linearGradient id="violet" x2=".7" y2="1"><stop stop-color="#dfb9e0"/><stop offset=".45" stop-color="#8b6ca9"/><stop offset="1" stop-color="#393b63"/></linearGradient>
<linearGradient id="wood" x2=".8" y2="1"><stop stop-color="#ba9c69"/><stop offset=".45" stop-color="#746344"/><stop offset="1" stop-color="#343c35"/></linearGradient>
<linearGradient id="leaf" x2=".9" y2="1"><stop stop-color="#7c9a69"/><stop offset=".4" stop-color="#3f6b57"/><stop offset="1" stop-color="#183d39"/></linearGradient>
<radialGradient id="aura"><stop stop-color="#cba2de" stop-opacity=".3"/><stop offset="1" stop-color="#8369ad" stop-opacity="0"/></radialGradient>
</defs>'''

def humanoid(kind):
    skeleton = kind in ['skeleton', 'ice_archer']
    archer = kind in ['archer', 'ice_archer']
    armor = kind == 'guardian'
    skin = 'url(#bone)' if skeleton else 'url(#iron)' if armor else 'url(#hide)'
    out = ellipse(64, 129, 32, 9, '#08141b77')
    # Bent legs, torn hems, long hooked arms and distinct shoulder silhouettes.
    out += path('M47 100 L44 119 L36 128 L55 129 L61 108 M68 108 L76 129 L95 129 L84 119 L81 99', 'url(#iron)' if armor else '#35413d')
    out += path('M39 64 L28 75 L24 101 L16 112 L25 108 L29 115 L32 103 L40 86 M87 64 L99 77 L103 100 L112 112 L104 108 L99 115 L96 101 L86 85', skin)
    out += path('M44 57 Q64 48 84 57 L89 94 L96 115 L82 110 L77 119 L64 111 L53 118 L44 110 L33 114 L41 91 Z', 'url(#cloak)')
    out += path('M52 61 L48 100 M74 62 L82 106 M62 67 L63 108', 'none', '#819084', 1)
    if skeleton:
        out += path('M60 65 L63 97 M47 69 Q62 76 79 68 M48 77 Q63 83 79 76 M49 85 Q64 91 78 84 M53 94 Q64 99 75 93', 'none', '#c5c3a7', 3)
    else:
        out += path('M43 62 L55 57 L63 73 L73 57 L86 64 L78 94 L50 93 Z', skin)
        out += path('M50 65 L58 71 L55 88 M78 65 L69 73 L72 87', 'none', '#b7b59a' if armor else '#929780', 1.5)
    out += path('M41 96 L86 96 L86 103 L42 103 Z', '#574b3b', '#19292d', 1)
    out += path('M59 96 L68 96 L68 103 L59 103 Z', '#c6ab73', '#242e2e', 1)
    if archer:
        out += path('M37 61 Q37 19 64 15 Q92 23 91 64 L78 55 L51 57 Z', 'url(#ice)' if kind == 'ice_archer' else 'url(#cloak)')
        out += path('M45 50 Q45 25 64 25 Q81 27 82 52 L72 62 L53 60 Z', '#15232b')
        out += path('M78 31 L87 47 L82 69 L89 92 L79 87 L73 62', 'url(#ice)' if kind == 'ice_archer' else 'url(#hide)')
        out += path('M102 49 Q126 85 101 123 M102 49 L104 123 M92 90 L119 85', 'none', '#9cc8cb' if skeleton else '#c4a06b', 3)
        out += path('M117 81 L124 84 L118 89', '#b9c6c4', '#3c555b', 1)
    elif armor:
        out += path('M37 60 L26 58 L31 42 L47 47 L57 63 M77 62 L86 45 L103 42 L100 62 L89 65', 'url(#iron)')
        out += path('M44 47 L42 24 L51 14 L64 17 L77 14 L86 24 L83 49 L74 61 L55 60 Z', 'url(#iron)')
        out += path('M45 26 L30 15 L37 37 M83 26 L99 15 L91 39', '#7d8173')
        out += path('M47 41 L59 43 L64 55 L68 43 L81 40 L77 55 L64 64 L52 56', '#263841')
        out += path('M20 87 L29 92 L24 132 L18 140 L17 109 Z', 'url(#iron)')
    else:
        out += path('M47 28 L31 24 L42 43 L48 45 M80 29 L100 24 L88 45 L80 46', 'url(#hide)')
        out += path('M47 22 Q65 10 82 25 L85 48 L76 61 L55 58 L43 44 Z', skin)
        out += path('M45 29 L50 18 L57 26 L65 14 L69 25 L80 22', '#343c36')
        out += path('M50 50 L77 47 L73 57 L59 60 Z', '#19272b', '#19272b', 1)
        out += path('M53 49 L56 55 L59 49 M68 49 L71 55 L74 48', '#e4d8ae', '#e4d8ae', 1)
        out += path('M100 93 L107 83 L106 117 L99 128 Z', 'url(#iron)')
    if skeleton and not archer:
        out += path('M47 23 Q65 11 80 24 L82 43 L74 48 L74 59 L55 59 L54 49 L45 42 Z', 'url(#bone)')
        out += path('M62 42 L58 50 L66 49 M56 55 L56 60 M62 55 L62 61 M68 55 L68 60', 'none', '#4b5b55', 2)
        out += path('M44 22 L53 16 L59 19 L70 15 L80 23', 'none', '#626c5f', 2)
    out += glow(54, 37, '#8ce8ed' if kind == 'ice_archer' else '#f1ab6d')
    out += glow(74, 36, '#8ce8ed' if kind == 'ice_archer' else '#f1ab6d')
    out += path('M47 30 L58 33 M71 32 L82 28', 'none', '#17272b', 3)
    return out

def ooze(toad=False):
    out = ellipse(64, 128, 43, 9, '#091a2077')
    out += path('M23 122 Q11 109 28 88 Q33 55 56 65 Q65 39 83 65 Q99 60 102 90 Q121 108 109 121 Q91 130 64 124 Q37 131 23 122 Z', 'url(#slime)')
    if toad:
        out += path('M31 103 Q10 103 9 126 L36 126 L47 117 M93 104 Q117 102 120 126 L93 126 L83 116', 'url(#hide)')
        out += ellipse(43, 76, 15, 15, 'url(#hide)', INK, 2)+ellipse(85, 76, 15, 15, 'url(#hide)', INK, 2)
    out += path('M34 91 L57 93 L52 102 L36 99 M75 93 L97 87 L95 98 L78 101', '#152b2c')
    out += glow(44, 95, '#d9e698')+glow(86, 94, '#d9e698')
    out += path('M38 111 Q64 99 93 110 L83 119 L49 121 Z', '#182a2b')
    out += path('M46 110 L49 116 L53 108 M58 107 L61 114 L66 106 M76 107 L79 115 L83 109', '#d9d7ae', '#d9d7ae', 1)
    out += path('M29 93 Q27 79 42 74 M49 70 L56 68', 'none', '#b3d2a0', 2)
    for x,y,r in [(35,108,3),(93,108,4),(68,80,5),(56,87,2),(78,71,3),(66,118,2)]:out+=ellipse(x,y,r,r,'#a5b68b55')
    return out

def spirit(crystal=False):
    out = ellipse(64, 78, 57, 65, 'url(#aura)')+ellipse(64, 132, 23, 6, '#111a2933')
    out += path('M53 27 Q25 38 36 67 Q15 83 32 100 L40 91 L33 119 L50 103 L47 138 L67 116 L76 133 L78 109 L99 119 L90 99 Q113 84 92 66 Q104 35 76 27 L69 12 Z', 'url(#ice)' if crystal else 'url(#violet)')
    out += path('M49 48 Q65 36 83 48 L80 72 L68 90 L48 70 Z', '#30394d')
    out += glow(53, 55, '#a3edee', 5)+glow(76, 54, '#a3edee', 5)
    out += path('M60 68 L65 62 L71 68 L68 79 L63 78 Z', '#0e2330', '#0e2330', 1)
    out += path('M42 79 L33 91 M87 76 L97 89 M56 93 L53 119 M76 92 L78 110', 'none', '#dac2e4', 2)
    if crystal:
        for x,y in [(24,63),(95,39),(104,94)]:out+=path(f'M{x} {y-15} L{x+6} {y} L{x} {y+12} L{x-5} {y} Z', 'url(#ice)', '#bfedef', 1)
    return out

def wolf(frost=False):
    out = ellipse(64, 128, 46, 9, '#08151d77')
    fur='url(#ice)' if frost else 'url(#hide)'
    out += path('M32 91 L16 81 L7 63 L22 69 L39 73 M37 100 L28 119 L18 130 L39 131 L49 106 M73 104 L80 124 L99 131 L104 126 L92 117 L94 94', fur)
    out += path('M24 90 L36 71 L53 66 L59 54 L67 64 L74 55 L79 65 L91 65 L106 80 L99 101 L86 114 L45 108 L33 114 Z', fur)
    out += path('M72 78 L76 54 L72 35 L87 48 L99 41 L100 63 L116 84 L109 102 L96 111 L81 96 Z', fur)
    out += path('M78 53 L78 44 L85 52 M91 56 L96 48 L96 60', '#1a3039')
    out += path('M93 82 L116 85 L113 97 L98 99 L88 91', '#273c42')
    out += path('M97 93 L112 93 L107 105 L100 99 Z', '#101f2a')
    out += path('M98 93 L100 101 L103 94 M106 94 L108 100 L110 94', '#ece1bd', '#ece1bd', 1)
    out += glow(93, 74, '#a3f0f4' if frost else '#edb06e')
    out += path('M79 69 L88 76 L99 69 M44 78 L37 91 M50 74 L43 89 M60 75 L53 90', 'none', '#253c42', 2)
    out += path('M38 119 L35 128 M85 123 L91 129 M91 123 L97 130', 'none', '#b9c7bd', 1)
    return out

def root_boss(heart=False):
    out = ellipse(64, 132, 48, 12, '#08141d88')
    wood='url(#violet)' if heart else 'url(#wood)'
    out += path('M47 91 L38 111 L20 133 L46 128 L57 118 L62 133 L72 119 L87 130 L111 134 L91 110 L82 89', wood)
    out += path('M41 61 L27 73 L18 102 L7 117 L21 111 L24 121 L31 100 L43 87 M85 58 L100 72 L108 99 L122 115 L109 110 L105 123 L97 102 L82 85', wood)
    out += path('M39 57 L49 45 L76 43 L92 58 L86 100 L74 114 L56 113 L40 96 Z', wood)
    out += path('M51 49 L45 33 L29 26 L18 10 L33 19 L42 19 L35 5 L51 24 L55 42 M76 44 L83 26 L97 20 L109 5 L104 22 L120 16 L103 31 L88 35 L83 51', wood)
    out += path('M48 39 L52 23 L66 18 L79 29 L80 47 L70 58 L57 58 Z', '#3c4241')
    out += glow(56, 40, '#e7a0d6' if heart else '#bad897')+glow(74, 39, '#e7a0d6' if heart else '#bad897')
    out += path('M55 49 L70 47 L66 54 L60 55 Z', '#182b30', '#182b30', 1)
    out += path('M44 68 L55 73 L49 93 M83 67 L72 76 L80 96 M54 99 L49 111 M74 100 L82 115', 'none', '#2c3339', 3)
    out += ellipse(65, 79, 17, 25, '#1c2939', '#bba77d' if not heart else '#b59acc', 2)
    out += path('M64 61 C42 65 56 90 64 100 C87 85 85 63 73 65 L67 70 Z', 'url(#violet)' if heart else 'url(#slime)', '#d9bbe3' if heart else '#c6deb1', 1)
    out += path('M64 71 L60 79 L68 83 L64 91', 'none', '#ffe0eb' if heart else '#daf4c9', 2)
    for x,y in [(39,51),(85,51),(30,84),(94,84)]:out+=path(f'M{x} {y} l-6 -17 l13 10 Z', wood)
    return out

def environment():
    tree=ellipse(64,135,55,18,'#091c2170')
    tree+=path('M58 136 L62 86 L49 62 L57 59 L69 80 L77 48 L84 53 L76 90 L77 132 L92 142 L72 138 L59 143 L39 140 Z','url(#wood)')
    # Overlapping curved foliage masses create a gnarled crown, rather than triangles.
    for d in ['M19 94 Q1 75 22 62 Q11 45 33 34 Q36 12 57 23 Q77 5 88 29 Q117 25 113 48 Q132 66 112 81 Q118 99 94 104 Q68 113 49 102 Q28 112 19 94 Z', 'M19 76 Q35 55 59 65 Q80 49 106 66 L98 91 Q76 103 59 89 Q39 99 20 88 Z', 'M31 47 Q42 28 58 35 Q72 22 87 39 Q105 36 108 54 Q88 65 69 52 Q51 63 31 54 Z']:
        tree+=path(d,'url(#leaf)','#1b3e39',1.4)
    tree+=path('M30 47 Q42 36 53 40 M68 32 Q78 27 84 37 M20 73 Q31 64 43 69 M75 73 Q88 62 101 70 M63 112 L65 132','none','#a2b884',1.4)
    rock=ellipse(64,132,38,11,'#101d2570')+path('M26 129 L20 110 L36 87 L68 77 L95 91 L108 117 L90 134 L51 140 Z','url(#iron)')
    rock+=path('M36 87 L51 108 L68 77 M51 108 L87 113 L95 91 M87 113 L90 134 M51 108 L51 140','none','#a7b4ab',1.4)
    rock+=path('M28 118 L37 110 L48 119 L47 131 L35 131 Z','#576f56','none')
    rock+=path('M69 89 L64 101 L73 105 L68 119','none','#273b42',2)
    def chest(opened):
        out=ellipse(64,136,40,10,'#0b202777')
        out+=path('M28 100 L98 100 L99 135 L31 137 Z','url(#wood)')
        out+=path('M27 100 L28 85 Q62 65 100 83 L101 101 Z' if not opened else 'M25 83 L22 52 Q61 38 100 53 L99 82 Z','url(#wood)')
        if opened:out+=path('M31 100 L96 100 L87 87 L37 88 Z','#203034')
        out+=path('M35 87 L44 83 L45 136 L36 136 M83 82 L93 84 L94 135 L85 136','url(#iron)','#283c42',1)
        out+=path('M28 100 L100 100 M31 133 L98 132','none','#d4ba81',2)
        out+=path('M58 95 L70 94 L72 113 L59 114 Z','#b8a06e','#263d44',1)
        out+=path('M63 100 L67 100 L67 107 L64 109 Z','#1b313b','#1b313b',1)
        return out
    return [tree,rock,chest(False),chest(True)]

def svg(width,height,groups):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">'+DEFS+''.join(groups)+'</svg>\n'

def main():
    names=['goblin','skeleton','archer','ice_archer','guardian','slime','bog_toad','wisp','crystal_wisp','wolf','frost_wolf','root_warden','hollow_heart']
    drawings=[humanoid(n) for n in names[:5]]+[ooze(),ooze(True),spirit(),spirit(True),wolf(),wolf(True),root_boss(),root_boss(True)]
    (ROOT/'enemies.svg').write_text(svg(640,480,[f'<g id="{name}" transform="translate({i%5*128} {i//5*160})">{drawing}</g>' for i,(name,drawing) in enumerate(zip(names,drawings))]))
    (ROOT/'environment.svg').write_text(svg(512,192,[f'<g transform="translate({i*128} 0)">{drawing}</g>' for i,drawing in enumerate(environment())]))

if __name__=='__main__':main()
