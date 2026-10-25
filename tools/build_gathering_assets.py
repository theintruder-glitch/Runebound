#!/usr/bin/env python3
"""Original editable field-prop atlas; run with Python, import SVG with Godot.
No external art, runtime generator, filters, shaders or extra scene nodes.
"""
from pathlib import Path
import math
import argparse

ROOT=Path(__file__).resolve().parents[1]
KINDS=['Wood','Stone','Fiber','Berries','Herbs','Iron','Resin','Crystal','Glowcap','Reeds','Frost shard','Pine resin','cart','watch','grove','cache']
INK='#182228'
def paint(c):
    if c.startswith('#') and len(c)==9:return f'fill="{c[:7]}" fill-opacity="{int(c[7:],16)/255:.4f}"'
    return f'fill="{c}"'
def path(d,c,stroke=INK,w=1.5):return f'<path d="{d}" {paint(c)} stroke="{stroke}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>'
def ellipse(x,y,rx,ry,c,stroke='none',w=1):return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" {paint(c)} stroke="{stroke}" stroke-width="{w}"/>'
def rect(x,y,w,h,c,stroke=INK,r=1):return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" {paint(c)} stroke="{stroke}" stroke-width="1.3"/>'
def line(x,y,a,b,c,w=1):return path(f'M{x} {y}L{a} {b}','none',c,w)
def shadow(rx=43):return ellipse(64,108,rx,9,'#08171e50')+ellipse(64,109,rx*.7,5,'#08171e3b')
def leaf(x,y,angle,size=1,c='url(#leaf)'):
    return f'<g transform="translate({x} {y}) rotate({angle}) scale({size})">'+path('M0 0Q-13-7-6-24Q8-21 0 0Z',c,'#203b30',1)+line(0,0,-4,-19,'#85a867',.8)+'</g>'
def ring(x,y,rx,ry):
    return ellipse(x,y,rx,ry,'url(#cut)','#49382a',2)+ellipse(x,y,rx*.65,ry*.63,'none','#9d734b',1)+ellipse(x,y,rx*.3,ry*.3,'none','#9d734b',.8)+path(f'M{x} {y}l{rx*.6} {ry*.4}','none','#775336',1)
def wood():
    s=shadow()
    for x,y,a in [(28,79,-22),(36,98,16),(58,74,-8)]:
        s+=f'<g transform="translate({x} {y}) rotate({a})">'+path('M0-11L55-11Q62-1 56 12L0 12Z','url(#bark)')
        for i in range(5):s+=path(f'M5 {-8+i*4}Q24 {-12+i*4} 52 {-8+i*4}','none','#bc90604d' if i%2 else '#392c27',1.5)
        s+=ring(0,0,9,12)+ellipse(57,0,5,11,'#614635','#352b26',1)+'</g>'
    return s+path('M87 83l10-12 4 2-9 17Z','url(#bark)')
def stone(iron=False):
    s=shadow();colors=['#656c76','#8c959d','#424c57'] if not iron else ['#565760','#77777d','#353b45']
    for x,y,k in [(27,86,.72),(70,88,1),(92,101,.5)]:
        s+=f'<g transform="translate({x} {y}) scale({k})">'+path('M-25 13L-31-3-18-27 7-32 27-13 31 12 5 22Z',colors[0])+path('M-31-3-18-27 7-32 0-7-11 2Z',colors[1],'none')+path('M0-7 27-13 31 12 5 22-11 2Z',colors[2],'none')+path('M-18-27-12-12-21-5M0-7 5-18 17-18','none','#c2c7cb73',1.5)
        if iron:
            s+=path('M-21 4-8-4 0 2 12-8 24-5','none','#a86643',5)+path('M-18 2-8-3 0 2 12-8','none','#d4a36c',1.5)
            for px,py in [(-12,8),(3,-3),(12,4)]:s+=ellipse(px,py,2.3,1.6,'#d8b78a')
        s+='</g>'
    return s

def plant(kind):
    s=shadow(35)
    if kind=='Fiber':
        for i,(x,y) in enumerate([(36,97),(48,103),(62,101),(75,101),(87,104)]):
            end=x-15+i*5;top=30+(i*13)%33
            s+=path(f'M{x} {y}Q{x-5} 60 {end} {top}Q{end+15} 67 {x+4} {y}Z','url(#grass)','#314433',1)
            s+=path(f'M{x} {y}Q{x+20} 55 {x+24} 45Q{x+26} 78 {x+4} {y}Z','#71875d','#344933',.8)
        for x in [47,68,80]:s+=line(x,103,x-3,38,'#b7ac77',1.4)+ellipse(x-3,35,2.5,9,'#bea77a')
        return s
    if kind=='Reeds':
        for i,x in enumerate([32,46,60,75,91]):
            y=25+(i*11)%25;s+=path(f'M{x} 107Q{x+8} 66 {x-2} {y}','none','#8e9c6b',2)+path(f'M{x} 104Q{x-24} 76 {x-12} 54Q{x-5} 76 {x} 104Z','url(#grass)','#344e3a',1)+ellipse(x-2,y,3,10,'#6b4934','#b29160',1)
        return s
    # Broad, layered leaves keep the plant readable at pickup size.
    for x,y,a,k in [(37,93,-65,.9),(84,96,68,1),(58,104,-29,1.2),(76,84,35,1.1),(46,75,-38,1.1),(62,73,14,1.25),(86,71,62,.8),(30,83,-70,.8)]:
        s+=line(63,107,x,y-6,'#4a6641',2)+leaf(x,y,a,k)
    if kind=='Berries':
        for x,y in [(35,77),(42,83),(39,70),(68,65),(75,70),(71,78),(83,89),(91,84),(56,94)]:
            s+=ellipse(x,y,5,5.5,'url(#berry)','#692b3a',1)+ellipse(x-1.5,y-2,1.4,1.2,'#f3b1a5')
    else:
        for i,x in enumerate([44,62,80]):
            y=42+i%2*9;s+=line(x-3,97,x,y,'#7c9964',1.5)
            for j in range(5):s+=ellipse(x+(-2 if j%2 else 2),y+j*4,3,2.6,'#b5a3d3','#5f6476',.6)
    return s

def mushrooms():
    s=shadow(35)
    for x,y,k in [(41,95,.7),(75,104,1.1),(94,94,.6)]:
        s+=f'<g transform="translate({x} {y}) scale({k})">'+path('M-5 2Q-9-12-5-30L5-31Q0-11 7 2Z','url(#stem)','#4f7464',1)+ellipse(0,-30,23,8,'#466d61','#2e5148',1)+path('M-24-31Q-23-61 1-63Q22-58 25-31Q1-20-24-31Z','url(#cap)','#344e4e',1.8)
        for px,py in [(-10,-43),(5,-51),(12,-36),(-4,-32)]:s+=ellipse(px,py,2.8,1.8,'#c4e4ac')
        s+=path('M-18-30Q0-21 19-30','none','#9ebd8b',1)+'</g>'
    return s

def resin(pine=False):
    s=shadow(34)+path('M35 103L39 40Q60 31 80 42L89 104 74 112 49 112Z','url(#bark)')
    for i in range(7):
        x=41+i*6;s+=path(f'M{x} 44Q{x-7} 76 {x+2} 107','none','#392d29',2)+path(f'M{x+2} 48Q{x+9} 79 {x+5} 100','none','#b48b595c',1)
    s+=ellipse(59,41,21,8,'url(#cut)','#47362c',2)+ellipse(59,41,12,4,'none','#ac8055',1)
    for x,y,k in [(64,62,1),(53,85,.65),(73,95,.5)]:
        s+=f'<g transform="translate({x} {y}) scale({k})">'+path('M0-14Q-1-6-7 0Q-11 12 0 15Q12 12 7 0Z','url(#amber)','#855127',1.4)+ellipse(-2,4,2,5,'#ffe8a0')+'</g>'
    if pine:
        s+=line(24,87,57,41,'#695640',2)
        for i in range(6):
            x=29+i*4;y=79-i*6;s+=line(x,y,x-13,y-6,'#709477',2)+line(x,y,x+13,y+2,'#8ba38a',1.5)
        s+=ellipse(34,99,7,10,'#745c43','#383b31',1)
    return s

def crystals(ice=False):
    s=shadow(35);colors=['#6e6799','#c8b5e9','#9283c3'] if not ice else ['#719eae','#e1f4ef','#aacfd9']
    for x,y,h,w in [(35,105,38,13),(62,109,77,18),(87,106,49,15)]:
        top=y-h;s+=path(f'M{x-w} {y-8}L{x-w} {top+14} {x} {top} {x+w} {top+17} {x+w-2} {y-7} {x} {y}Z',colors[0])+path(f'M{x-w} {top+14} {x} {top} {x-3} {top+23} {x-3} {y-4} {x-w} {y-8}Z',colors[1],'none')+path(f'M{x-3} {top+23} {x+w} {top+17} {x+w-2} {y-7} {x-3} {y-4}Z',colors[2],'none')+line(x-w+2,top+17,x-w+2,y-15,'#f1eff1',1)
    return s+ellipse(64,111,30,3,'#c3d9f01a')

def wheel(x,y,r=14):
    s=ellipse(x,y,r,r*1.08,'#342b28','#181f23',2)+ellipse(x,y,r-3,r*.88,'#9d794a','#b9a17c',1)+ellipse(x,y,r-5,r*.73,'#302c2b')
    for i in range(7):
        a=i*math.tau/7;s+=line(x,y,round(x+math.cos(a)*(r-4),2),round(y+math.sin(a)*(r-3),2),'#9d8058',2)
    return s+ellipse(x,y,3,4,'#a8acaa','#343b3e',1)

def caravan():
    s=shadow(55)+path('M13 104L39 89 117 99 91 117Z','#302f2b','none')
    # Axle, chassis and covered wagon, with a large unmistakable side panel.
    s+=line(32,92,111,86,'#2a2827',6)+line(98,85,119,106,'#8c6842',6)+line(99,83,119,103,'#c39d65',1.5)
    s+=path('M22 66L91 54 112 72 39 87Z','url(#cut)')+path('M22 66L22 84 39 99 39 87Z','#6c5136')+path('M39 87L112 72 109 94 39 109Z','url(#bark)')
    for y in [92,99,106]:s+=line(42,y,107,y-14,'#c9a16a',1)+line(42,y+2,107,y-12,'#352c28',1)
    for x,y in [(45,90),(102,78),(45,104),(102,91)]:s+=ellipse(x,y,1.5,1.5,'#8d9593')
    s+=path('M24 67Q18 30 42 24L85 28Q108 31 109 66L95 72 88 65 80 76 70 69 63 81 51 74 39 80Z','url(#cloth)','#514d44',1.5)
    s+=path('M42 25Q67 33 64 78M83 30Q100 39 95 70','none','#8c887b',2)+path('M31 38Q27 53 31 64M46 29Q60 40 56 57M73 36Q85 44 84 60','none','#ded7bf',1.5)
    s+=path('M54 54L65 47 61 66 54 62Z','#3b3835','#716b5c',1)+line(55,52,51,58,'#e3d4ae',.8)
    s+=wheel(48,103,14)+wheel(97,92,14)
    # Detached broken rim, spilled sack and loose planks anchor the wreck on ground.
    s+=path('M7 106Q9 94 22 96Q31 100 28 114Q19 125 10 116','none','#9b7549',4)+line(14,101,22,117,'#8f724b',2)
    s+=path('M72 116Q64 104 72 95L79 98Q92 104 89 116Q80 123 72 116Z','url(#sack)','#534c3e',1.5)+line(72,97,80,100,'#3a3932',2)
    s+=path('M16 85L32 80 40 84 24 91Z','url(#cut)')+path('M91 115L116 110 120 114 95 121Z','url(#bark)')
    return s

def watch():
    s=shadow(49)+path('M15 105L48 57 103 103 72 117Z','#353735','none')
    s+=path('M21 101L49 34 78 102Z','url(#cloth)','#514d44',2)+path('M49 34L94 59 111 101 78 102Z','#7c7a68','#454b43',2)+path('M44 61L49 43 69 94 59 86 54 96 46 84 39 98Z','#263633','#555c4e',1)
    s+=line(49,37,49,104,'#9c7850',3)+line(24,102,13,111,'#9b8c69',1)+line(105,101,115,111,'#9b8c69',1)
    s+=path('M28 107L44 101 59 109 44 117Z','#ac9a77','#3f3c34',1)+path('M28 107L42 107 44 117M44 104L57 109','none','#eee0b7',1)+line(43,105,44,116,'#554c3d',1)
    s+=path('M82 91L94 88 101 103 92 115 82 107Z','#6a7a7b','#343e42',2)+path('M86 95L94 94 96 102 91 109 86 104Z','#b7a27a','none')
    return s

def grove():
    s=shadow(48)+ellipse(64,103,48,14,'#6d6b6057')
    for x,y,k in [(20,105,1),(99,99,.8),(91,115,.6)]:s+=ellipse(x,y,6*k,3*k,'#aaa595','#565952',1)
    s+=path('M34 109L40 53 49 63 56 42 66 59 75 45 87 55 92 108 77 116 48 116Z','#3b3633','#1b2828',2)
    for x,y in [(44,63),(55,57),(70,67),(80,60)]:s+=path(f'M{x} {y}l-4 43m6-23 3 29','none','#766257',2)
    s+=ellipse(64,63,22,9,'#766855','#252c2b',2)+ellipse(64,63,14,5,'#a08a69','#3d3b32',1)
    s+=ellipse(65,59,12,5,'#a6c97f3c')+path('M65 62Q62 47 69 38','none','#a8cb80',2)+leaf(65,49,-54,.6,'#91bd75')+leaf(66,49,61,.65,'#b6d591')+ellipse(65,60,4,3,'#dce7a1')
    s+=path('M16 95L34 101 38 107 21 103Z','#5b4c41')+line(19,96,35,103,'#937657',1)
    return s

def cache():
    s=shadow(40)+path('M29 72L70 58 104 76 62 92Z','#79717d')+path('M29 72L29 103 62 118 62 92Z','#4d4c60')+path('M62 92L104 76 103 104 62 118Z','#626174')
    s+=path('M28 70Q29 48 49 43L76 36Q100 44 105 73L63 88Z','url(#stone)','#353745',2)+path('M47 44L66 53 63 86M77 38Q96 45 102 72','none','#a79caf',3)
    s+=path('M63 85L72 81 74 104 63 108Z','#998a6f','#453e44',1)+path('M68 89L72 95 68 101 65 96Z','#c8a2e4','#6d5b87',1)
    s+=path('M40 77L36 84 43 89M86 91l-5 4 7 4M78 64l5-7 5 4','none','#d1b8db',1.8)
    return s

DEFS='''<defs>
<linearGradient id="bark" x2="1" y2=".5"><stop stop-color="#b38a58"/><stop offset=".45" stop-color="#775438"/><stop offset="1" stop-color="#49372c"/></linearGradient>
<linearGradient id="cut" x2=".2" y2="1"><stop stop-color="#e0c58e"/><stop offset="1" stop-color="#a27a50"/></linearGradient>
<linearGradient id="leaf" x2="1" y2="1"><stop stop-color="#a0b97b"/><stop offset=".48" stop-color="#5c8051"/><stop offset="1" stop-color="#294e3d"/></linearGradient>
<linearGradient id="grass" x2="1" y2=".4"><stop stop-color="#9eae71"/><stop offset="1" stop-color="#3c6445"/></linearGradient>
<radialGradient id="berry" cx=".3" cy=".25"><stop stop-color="#e4a28e"/><stop offset=".4" stop-color="#b94e67"/><stop offset="1" stop-color="#702d4d"/></radialGradient>
<linearGradient id="amber" x2="1" y2="1"><stop stop-color="#ffecad"/><stop offset=".35" stop-color="#d7a34d"/><stop offset="1" stop-color="#92542e"/></linearGradient>
<linearGradient id="cloth" x2=".5" y2="1"><stop stop-color="#dad4bb"/><stop offset=".55" stop-color="#b7b49f"/><stop offset="1" stop-color="#858b7a"/></linearGradient>
<linearGradient id="sack" x2="1" y2="1"><stop stop-color="#c6b690"/><stop offset="1" stop-color="#8a8064"/></linearGradient>
<linearGradient id="stem" x2="1" y2="0"><stop stop-color="#708f7e"/><stop offset=".5" stop-color="#d1d9b2"/><stop offset="1" stop-color="#789d86"/></linearGradient>
<radialGradient id="cap" cx=".4" cy=".25"><stop stop-color="#b1c9a2"/><stop offset=".5" stop-color="#76a798"/><stop offset="1" stop-color="#406d69"/></radialGradient>
<linearGradient id="stone" x2=".4" y2="1"><stop stop-color="#b7adb9"/><stop offset="1" stop-color="#68677a"/></linearGradient>
</defs>'''

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check",action="store_true",help="Fail if the committed atlas differs from its generator")
    args=parser.parse_args()
    art=[wood(),stone(),plant('Fiber'),plant('Berries'),plant('Herbs'),stone(True),resin(),crystals(),mushrooms(),plant('Reeds'),crystals(True),resin(True),caravan(),watch(),grove(),cache()]
    groups=[]
    for i,(kind,body) in enumerate(zip(KINDS,art)):
        groups.append(f'<g id="prop-{i}" transform="translate({i%4*128} {i//4*128})">{body}</g>')
    svg='<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">'+DEFS+''.join(groups)+'</svg>\n'
    target=ROOT/'assets/field_props.svg'
    if args.check:
        if not target.is_file() or target.read_text()!=svg:
            raise SystemExit('Field props atlas differs: run tools/build_gathering_assets.py')
        print('Verified deterministic field-props atlas');return
    target.write_text(svg)
    print('Wrote 16 original field props, 512 × 512, 1 MiB base RGBA')
if __name__=='__main__':main()
