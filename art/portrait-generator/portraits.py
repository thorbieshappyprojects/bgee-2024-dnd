"""13x13 pixel-art portrait (status) icons on black. Grids: '.' = black, other letters = palette."""
from PIL import Image, ImageDraw
import math
OUT="/home/claude/art/portraits"
icons=[]
def grid(name,rows,pal):
    assert len(rows)==13 and all(len(r)==13 for r in rows),(name,[len(r) for r in rows])
    im=Image.new("RGB",(13,13),(0,0,0))
    for y,r in enumerate(rows):
        for x,ch in enumerate(r):
            if ch!=".": im.putpixel((x,y),pal[ch])
    im.save(f"{OUT}/{name}.png"); icons.append((name,im))
def to_rows(layers):
    """layers: list of (char, draw_fn(d)) on a 130x130 canvas -> 13 grid rows (later layers on top)"""
    rows=[["."]*13 for _ in range(13)]
    for ch,fn in layers:
        m=Image.new("L",(130,130),0); fn(ImageDraw.Draw(m),m)
        m=m if not hasattr(fn,"rot") else m
        s=m.resize((13,13),Image.BOX)
        for y in range(13):
            for x in range(13):
                if s.getpixel((x,y))>=110: rows[y][x]=ch
    return ["".join(r) for r in rows]
def line(rows,p0,p1,ch,over=True):
    rows=[list(r) for r in rows]; (x0,y0),(x1,y1)=p0,p1
    n=max(abs(x1-x0),abs(y1-y0))
    for i in range(n+1):
        x=round(x0+(x1-x0)*i/n); y=round(y0+(y1-y0)*i/n)
        if over or rows[y][x]==".": rows[y][x]=ch
    return ["".join(r) for r in rows]

# 1 Concentrating: head with a violet ring circling the brow
grid("B24PCONC",[
"....GGGGG....",
"...GGGGGGG...",
".VVGGGGGGGVV.",
"V..GGGGGGG..V",
".VVVVVVVVVVV.",
"...GgGGGgG...",
"...GGGGGGG...",
"...GGGGGGG...",
"....GGGGG....",
".....GGG.....",
"...GGGGGGG...",
".GGGGGGGGGGG.",
"GGGGGGGGGGGGG",
],{"G":(185,185,198),"g":(70,70,85),"V":(200,110,255)})

# 2 Exhaustion: heavy drooping lid, bags, a tear
grid("B24PEXHA",[
".............",
".............",
"..bbbbbbbbb..",
".bBBBBBBBBBb.",
"bBBBBBBBBBBBb",
"bBBBBBBBBBBBb",
".bWWWPPPWWWb.",
"..bWWPPPWWb..",
"...bbbbbbb...",
"..b.......b..",
"...bbbbbbb..T",
"...........TT",
"..........TTT",
],{"b":(85,62,45),"B":(140,112,85),"W":(225,218,200),"P":(70,55,40),"T":(140,200,255)})

# 3 Prone: figure flat on its back on the ground
grid("B24PPRON",[
".............",
".............",
".............",
".........F...",
".FFF.....F...",
"FFFFF....F...",
"FFFFFFFFFFFFF",
"FFFFFFFFFFFFF",
".FFF.....F..F",
".............",
"DDDDDDDDDDDDD",
"DDDDDDDDDDDDD",
".............",
],{"F":(225,195,145),"D":(125,85,50)})

# 4 Grappled: a fist closed around a horizontal wrist
grid("B24PGRAP",[
"...OOOOOOO...",
"..OSOSOSOSO..",
"..OSSSSSSSO..",
"..OSOSOSOSO..",
"wwOSSSSSSSOww",
"wwOSSSSSSSOww",
"wwOOSSSSSOOww",
"wwwOOOOOOOwww",
"...OSSSSSO...",
"...OSSSSSO...",
"...OSSSSSO...",
"...OSSSSSO...",
"...OSSSSSO...",
],{"O":(175,80,30),"S":(230,185,135),"w":(160,120,85)})

# 5 Restrained: two heavy chain links locked into a loop
def link(box,ang):
    def f(d,m):
        L=Image.new("L",(130,130),0); ImageDraw.Draw(L).ellipse(box,outline=255,width=17)
        m.paste(L.rotate(ang,center=((box[0]+box[2])/2,(box[1]+box[3])/2)),(0,0),L.rotate(ang,center=((box[0]+box[2])/2,(box[1]+box[3])/2)))
    return f
r=to_rows([("C",link((-2,8,88,82),45)),("c",link((42,48,132,122),-45))])
grid("B24PREST",r,{"C":(175,180,192),"c":(150,90,50)})

# 6 Temporary Hit Points: red heart inside a pale blue shield
grid("B24PTHP",[
"BBBBBBBBBBBBB",
"B...........B",
"B.RRR...RRR.B",
"B.RRRR.RRRR.B",
"B.RRRRRRRRR.B",
"B.RRRRRRRRR.B",
"B..RRRRRRR..B",
".B..RRRRR..B.",
".B...RRR...B.",
"..B...R...B..",
"...B.....B...",
"....BB.BB....",
"......B......",
],{"B":(150,205,255),"R":(225,40,40)})

# 7 Dying: skull with a falling drop of blood
grid("B24PDYIN",[
"...WWWWWWW...",
"..WWWWWWWWW..",
".WWWWWWWWWWW.",
".WW..WWW..WW.",
".WW..WWW..WW.",
".WWWWW.WWWWW.",
"..WWW...WWW..",
"...WWWWWWW...",
"...W.W.W.W...",
"......R......",
".....RRR.....",
".....RRR.....",
"......R......",
],{"W":(235,228,210),"R":(210,20,20)})

# 8 Stable: heart with a (nearly) flat pulse line through it
grid("B24PSTAB",[
".............",
"..HHH...HHH..",
".HHHHH.HHHHH.",
".HHHHHHHHHHH.",
".HHHHHLHHHHH.",
".HHHHLHLHHHH.",
"LLLLLHHHLLLLL",
"..HHHHHHHHH..",
"...HHHHHHH...",
"....HHHHH....",
".....HHH.....",
"......H......",
".............",
],{"H":(180,55,55),"L":(160,240,160)})

# 9 Your turn: hourglass, gold sand, wooden frame
grid("B24PTURN",[
"KKKKKKKKKKKKK",
".KKKKKKKKKKK.",
"..G.......G..",
"..GYYYYYYYG..",
"...GYYYYYG...",
"....GYYYG....",
".....GYG.....",
"....G.Y.G....",
"...G..Y..G...",
"..G..YYY..G..",
"..GYYYYYYYG..",
".KKKKKKKKKKK.",
"KKKKKKKKKKKKK",
],{"K":(150,95,45),"G":(170,190,200),"Y":(255,205,60)})

# 10 Raging: snarling face, blazing eyes, bared teeth
grid("B24PRAGE",[
"..C..C.C..C..",
".CCCCCCCCCCC.",
"CCCCCCCCCCCCC",
"CCddCCCCCddCC",
"CCCYYdCdYYCCC",
"CCCCCCCCCCCCC",
"CCCCCdCdCCCCC",
".CWdWdWdWdWC.",
".CdddddddddC.",
".CWdWdWdWdWC.",
"..CCCCCCCCC..",
"...CCCCCCC...",
".............",
],{"C":(205,30,30),"d":(95,10,10),"Y":(255,230,60),"W":(240,235,220)})

# 11 Reckless Attack: double-bit greataxe, red spark off the edge
grid("B24PRECK",[
"SS....H....SS",
"SSS...H...SSS",
"SSSSssHssSSSS",
"SSSSssHssSSSS",
"SSSSssHssSSSS",
"SSS...H...SSS",
"SS....H....SS",
"......H....R.",
"......H...R..",
"......H....R.",
"......H...R..",
".....HHH.....",
".............",
],{"S":(165,170,182),"s":(90,95,108),"H":(140,85,40),"R":(255,45,35)})

# 12 Hunter's Mark: target ring, crosshair, arrowhead in the middle
grid("B24PHMRK",[
"....GGWGG....",
"..GG..W..GG..",
".G....W....G.",
".G....W....G.",
"G.....W.....G",
"G....WWW....G",
"WWWWWWWWWWWWW",
"G.....W.....G",
"G.....W.....G",
".G....W....G.",
".G....W....G.",
"..GG..W..GG..",
"....GGWGG....",
],{"G":(50,170,70),"W":(240,245,235)})

# 13 Bardic Inspiration: musical note with a star spark
grid("B24PBINS",[
".W...........",
"WWW...YY.....",
".W....YYYY...",
"......Y.YYY..",
"......Y...YY.",
"......Y....Y.",
"......Y......",
"......Y......",
"..YYYYY......",
".YYYYYY......",
".YYYYYY......",
"..YYYY.......",
".............",
],{"Y":(255,205,60),"W":(255,255,240)})

# 14 Divine Smite ready: sword point down, burst of light at the tip
grid("B24PSMIT",[
".....YYY.....",
"......Y......",
"......Y......",
"..YYYYYYYYY..",
".....WWW.....",
".....WWW.....",
".....WWW.....",
".....WWW.....",
"......W......",
"..Y..YWY..Y..",
"...YYWWWYY...",
"..Y..YWY..Y..",
"......Y......",
],{"Y":(255,205,60),"W":(255,255,245)})

# 15 Sacred Weapon: upright sword inside a halo of light
grid("B24PSACW",[
"......W......",
".....WWW.....",
"..YYYWWWYYY..",
".Y...WWW...Y.",
".Y...WWW...Y.",
"..YYYWWWYYY..",
".....WWW.....",
".....WWW.....",
".....WWW.....",
"..YYYYYYYYY..",
"......Y......",
"......Y......",
".....YYY.....",
],{"Y":(235,210,140),"W":(255,255,250)})

# 16 Holy Nimbus: sun disc with short straight rays
grid("B24PNIMB",[
"......Y......",
"..Y...Y...Y..",
"...Y.YYY.Y...",
"....YYYYY....",
"...YYWWWYY...",
"..YYWWWWWYY..",
"YYYYWWWWWYYYY",
"..YYWWWWWYY..",
"...YYWWWYY...",
"....YYYYY....",
"...Y.YYY.Y...",
"..Y...Y...Y..",
"......Y......",
],{"Y":(255,195,40),"W":(255,250,220)})

# 17 Dodging: figure leaning aside, two fading afterimages
fig=["...HH","...HH","..BB.",".BBBB","B.BB.","..BB.","..BBB",".B..B",".B..B","B...B","B...."]
rows=[["."]*13 for _ in range(13)]
for off,ch in [(1,"a"),(4,"b"),(8,"c")]:
    for y,r in enumerate(fig):
        for x,p in enumerate(r):
            if p!="." and 0<=x+off<13: rows[y+1][x+off]=ch
grid("B24PDODG",["".join(r) for r in rows],{"a":(55,65,85),"b":(100,115,140),"c":(185,205,230)})

# 18 Starry Form: three bright stars joined like a constellation
rows=["."*13]*13
for a,b in [((2,10),(6,3)),((6,3),(10,8))]: rows=line(rows,a,b,"L")
rows=[list(r) for r in rows]
for cx,cy in [(2,10),(6,3),(10,8)]:
    for dx,dy in [(0,0),(1,0),(-1,0),(0,1),(0,-1)]:
        rows[cy+dy][cx+dx]="W" if (dx,dy)==(0,0) else "S"
rows=["".join(r) for r in rows]
grid("B24PSTAR",rows,{"L":(95,95,215),"S":(195,200,225),"W":(255,255,255)})

# 19 Innate Sorcery: spiral flame, violet core, electric blue edge
grid("B24PINSO",[
"......B......",
".....BB......",
".....BBB..B..",
"....BBVB..B..",
"...BBVVBBBB..",
"..BBVVVVVVB..",
"..BVVVLLVVBB.",
".BBVVLVVLVVB.",
".BVVVLVLLVVB.",
".BVVVLVVVVVB.",
".BBVVVLLLVBB.",
"..BBVVVVVBB..",
"...BBBBBBB...",
],{"B":(70,160,255),"V":(160,70,235),"L":(235,190,255)})

# 20 Portent: crystal ball with golden mist swirl, on a stand
grid("B24PPORT",[
"....ccccc....",
"...cCCCCCc...",
"..cWCYYYCCc..",
".cCCYCCCYCCc.",
".cCCCCCYYCCc.",
".cCCCYYCCCCc.",
".cCCYCCCCYCc.",
".cCCCYYYYCCc.",
"..cCCCCCCCc..",
"...cCCCCCc...",
"....ccccc....",
"..KKKKKKKKK..",
".KKKKKKKKKKK.",
],{"c":(30,120,150),"C":(80,200,225),"W":(230,255,255),"Y":(255,205,60),"K":(140,90,45)})

# preview: 10x zoom grid, plus actual size on a portrait-like strip
Z=10; cols=10
P=Image.new("RGB",(cols*(13*Z+12)+12,2*(13*Z+12)+12+60),(60,55,50))
for i,(n,im) in enumerate(icons):
    x=12+(i%cols)*(13*Z+12); y=12+(i//cols)*(13*Z+12)
    P.paste(im.resize((13*Z,13*Z),Image.NEAREST),(x,y))
    P.paste(im,(12+i*15,2*(13*Z+12)+30))
    P.paste(im.resize((26,26),Image.NEAREST),(340+i*30,2*(13*Z+12)+24))
P.save("/home/claude/preview/portraits.png"); print(len(icons))
