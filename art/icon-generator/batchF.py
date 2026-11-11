import sys,math; sys.path.insert(0,"/home/claude")
from glyph import *
out=[]
def done(g,c,n): out.append((n,g.render(c,n)))

# ---------- helpers ----------
def rot(pts,ang,cx,cy):
    a=math.radians(ang); ca,sa=math.cos(a),math.sin(a)
    return [(cx+(x-cx)*ca-(y-cy)*sa, cy+(x-cx)*sa+(y-cy)*ca) for x,y in pts]
def disc(d,cx,cy,r,v=255): d.ellipse([cx-r,cy-r,cx+r,cy+r],fill=v)
def gear(d,cx,cy,r,teeth=8,tw=None,th=None,v=255,off=0):
    """solid gear (disc + trapezoid teeth) drawn with value v on drawer d"""
    tw=tw or r*0.45; th=th or r*0.32
    disc(d,cx,cy,r,v)
    for i in range(teeth):
        p=[(cx-tw/2,cy-r+8),(cx+tw/2,cy-r+8),(cx+tw/2*0.75,cy-r-th),(cx-tw/2*0.75,cy-r-th)]
        d.polygon(rot(p,off+i*360/teeth,cx,cy),fill=v)
def almond(cx,cy,w,h,ang=0):
    """L mask of an eye/lens shape, width w, height h, rotated by ang degrees"""
    R=((w/2)**2+(h/2)**2)/h
    yy,xx=np.mgrid[0:SS,0:SS].astype(float)
    a=math.radians(ang); X=(xx-cx)*math.cos(a)+(yy-cy)*math.sin(a); Y=-(xx-cx)*math.sin(a)+(yy-cy)*math.cos(a)
    m=((X**2+(Y-(R-h/2))**2)<=R*R)&((X**2+(Y+(R-h/2))**2)<=R*R)
    return Image.fromarray((m*255).astype(np.uint8),"L")
def put(img,mask,v=255): img.paste(v,mask=mask)
def leaf(d,cx,cy,L,W,ang):
    d.polygon(rot([(cx,cy-L/2),(cx+W/2,cy),(cx,cy+L/2),(cx-W/2,cy)],ang,cx,cy),fill=255)
def spiral_line(d,cx,cy,r,w=28,turns=1.6):
    """psionic accent: an open mind-spiral"""
    pts=[]
    for i in range(90):
        t=i/89; a=t*math.pi*2*turns; rr=r*0.12+t*r*0.88
        pts.append((cx+math.cos(a)*rr,cy+math.sin(a)*rr))
    d.line(pts,fill=255,width=w,joint="curve")
    disc(d,*pts[-1],w/2); disc(d,*pts[0],w/2+4)

# ---- Living Legend: laurel wreath (outer leaves only) around a star (teal)
g=Glyph()
for side in (-1,1):
    P=lambda a,r:(256+side*r*math.sin(math.radians(a)),270+r*math.cos(math.radians(a)))
    g.f.line([P(a,190) for a in range(20,165,2)],fill=255,width=28,joint="curve")
    for a in range(35,170,30):
        x,y=P(a,238); t=math.degrees(math.atan2(math.cos(math.radians(a)),side*math.sin(math.radians(a))))
        leaf(g.f,x,y,120,64,t+90-side*35)
st=[]
for i in range(10):
    r=138 if i%2==0 else 60; a=math.radians(-90+i*36); st.append((256+r*math.cos(a),262+r*math.sin(a)))
g.f.polygon(st,fill=255)
done(g,"teal","B24GLEGD")

# ---- Elder Champion: head with spreading antlers and leafy crown, blossom on brow (teal)
g=Glyph()
g.f.ellipse([180,250,332,440],fill=255)
g.f.polygon([(205,420),(307,420),(335,505),(177,505)],fill=255)
for side in (-1,1):
    X=lambda x:256+side*x
    g.f.line([(X(40),280),(X(120),210),(X(170),120),(X(185),22)],fill=255,width=42,joint="curve")
    g.f.line([(X(125),200),(X(225),175),(X(250),95)],fill=255,width=38,joint="curve")
    g.f.line([(X(165),130),(X(238),58)],fill=255,width=34)
    g.f.line([(X(80),245),(X(45),150)],fill=255,width=34)
g.f.polygon([(170,305),(170,232),(213,268),(256,215),(299,268),(342,232),(342,305)],fill=255)
for a in range(0,360,72):
    disc(g.l,256+math.cos(math.radians(a-90))*30,345+math.sin(math.radians(a-90))*30,21)
disc(g.c,256,345,13)
done(g,"teal","B24AELDR")

# ---- Avenging Angel: spread wings behind a downward sword (red)
g=Glyph()
for side in (-1,1):
    X=lambda x:256+side*x
    for i,(L,y0) in enumerate([(240,115),(220,185),(190,255),(150,320)]):
        g.f.polygon([(X(30),y0+10),(X(30+L*0.55),y0-55+i*12),(X(30+L),y0-100+i*30),(X(30+L*0.8),y0+25),(X(30),y0+65)],fill=255)
    for i,y0 in enumerate([185,255,320]):
        g.d.line([(X(75),y0+25),(X(75+140-i*30),y0-25+i*8)],fill=255,width=16)
g.c.polygon([(200,95),(312,95),(306,395),(256,512),(206,395)],fill=255)
g.c.polygon([(222,95),(290,95),(284,385),(256,490),(228,385)],fill=0)
g.f.polygon([(222,95),(290,95),(284,385),(256,490),(228,385)],fill=255)
g.c.rounded_rectangle([140,60,372,106],radius=18,fill=0)
g.f.rounded_rectangle([140,60,372,106],radius=18,fill=255)
g.f.rectangle([236,10,276,70],fill=255); disc(g.f,256,24,28)
g.d.line([(256,115),(256,390)],fill=255,width=16)
done(g,"red","B24VANGL")

# ---- Primal Companion: wolf head in profile, snarling (red)
g=Glyph()
wolf=[(40,505),(70,370),(110,260),(150,190),(165,40),(250,140),(300,150),(350,175),(420,215),(495,245),
      (500,290),(450,320),(380,325),(330,345),(300,420),(330,505)]
g.f.polygon(wolf,fill=255)
g.c.polygon([(500,296),(430,290),(370,315),(380,330),(450,322)],fill=255)   # mouth
g.c.polygon([(270,185),(330,192),(305,220)],fill=255)                       # eye
for y in (300,375,445):
    g.f.polygon([(80,y-20),(10,y+30),(75,y+45)],fill=255)                  # ruff
g.d.polygon([(175,85),(215,150),(185,170)],fill=255)                       # inner ear
done(g,"red","B24BEAST")

# ---- Psychic Blades: broad psionic dagger + mind spiral (red)
g=Glyph(); A=45; R=lambda p:rot(p,A,256,270)
g.f.polygon(R([(204,70),(256,-15),(308,70),(300,340),(212,340)]),fill=255)
g.f.polygon(R([(150,335),(362,335),(362,385),(150,385)]),fill=255)
g.f.polygon(R([(230,385),(282,385),(282,470),(230,470)]),fill=255)
disc(g.f,*R([(256,490)])[0],36)
g.l.line(R([(256,25),(256,315)]),fill=255,width=26)
spiral_line(g.f,112,112,98)
done(g,"red","B24PSBLA")

# ---- Psychic Veil: head-and-shoulders figure dissolving into veil bands + mind spiral (teal)
g=Glyph()
disc(g.f,256,175,82)
g.f.rounded_rectangle([96,265,416,520],radius=90,fill=255)
for y,h in ((300,28),(370,38),(445,52)):
    g.c.rectangle([30,y,480,y+h],fill=255)
spiral_line(g.f,90,95,82,w=28)
done(g,"teal","B24PSVEL")

# ---- Create Spell Slot 1-5: faceted gem + 1..5 pips (teal)
def gem(g):
    g.f.polygon([(140,25),(372,25),(482,145),(256,390),(30,145)],fill=255)
    g.l.polygon([(160,38),(352,38),(322,128),(190,128)],fill=255)
    g.c.line([(40,148),(472,148)],fill=255,width=26)
    g.c.polygon([(256,185),(330,170),(256,350)],fill=255)
for n in range(1,6):
    g=Glyph(); gem(g)
    W=68; gap=22; tot=n*W+(n-1)*gap; x0=256-tot/2
    for i in range(n):
        x=x0+i*(W+gap); g.f.ellipse([x,428,x+W,496],fill=255)
    done(g,"teal",f"B24FOM{n}")

# ---- Revelation in Flesh: tentacles rising from a palm with an eye (cream)
g=Glyph()
g.f.ellipse([95,250,417,505],fill=255)
for x,top,bend,w in [(130,55,-30,84),(256,8,34,90),(382,55,30,84)]:
    pts=[(x+bend*math.sin(t*math.pi*1.3),330-t*(330-top)) for t in [k/40 for k in range(41)]]
    for i,p in enumerate(pts): disc(g.f,*p,w/2*(1-0.4*i/40))
put(g.cut,almond(256,385,270,150))
disc(g.c,256,385,55,0); disc(g.c,256,385,24)
done(g,"cream","B24AREVL")

# ---- Warping Implosion: fat wedges collapsing into a ring core (red)
g=Glyph()
for i in range(8):
    p=[(190,8),(322,8),(256,175)] if i%2==0 else [(205,60),(307,60),(256,180)]
    g.f.polygon(rot(p,i*45+10,256,256),fill=255)
disc(g.f,256,256,100); disc(g.c,256,256,58)
done(g,"red","B24AWARP")

# ---- Restore Balance: level scale, gear at the pivot (teal)
g=Glyph()
g.f.rectangle([232,120,280,450],fill=255)
g.f.polygon([(140,505),(372,505),(325,440),(187,440)],fill=255)
g.f.rectangle([22,150,490,190],fill=255)
for x in (95,417):
    g.f.line([(x,170),(x-58,330)],fill=255,width=18); g.f.line([(x,170),(x+58,330)],fill=255,width=18)
    g.f.chord([x-90,245,x+90,405],0,180,fill=255)
gear(g.f,256,110,72,8); disc(g.c,256,110,28)
done(g,"teal","B24CBALN")

# ---- Bastion of Law: shield rim with a gear emblem (teal)
g=Glyph()
g.f.polygon([(42,28),(470,28),(470,250),(410,390),(256,505),(102,390),(42,250)],fill=255)
g.c.polygon([(88,72),(424,72),(424,245),(372,362),(256,452),(140,362),(88,245)],fill=255)
gear(g.c,256,250,100,8,tw=56,th=44,v=0); disc(g.c,256,250,40)
done(g,"teal","B24CBAST")

# ---- Trance of Order: meditating figure inside a gear ring (teal)
g=Glyph()
gear(g.f,256,256,205,10,tw=78,th=50); disc(g.c,256,256,162)
disc(g.c,256,170,46,0)
g.c.polygon([(200,225),(312,225),(335,335),(177,335)],fill=0)
g.c.ellipse([120,305,392,385],fill=0)
g.c.line([(205,240),(150,330)],fill=0,width=40); g.c.line([(307,240),(362,330)],fill=0,width=40)
done(g,"teal","B24CTRAN")

# ---- Clockwork Cavalcade: horse head with a separate gear at lower right (teal)
g=Glyph()
horse=[(120,505),(130,420),(175,330),(150,300),(90,330),(45,345),(20,300),(40,250),(120,170),(190,110),
       (205,20),(250,70),(300,60),(380,120),(420,230),(420,300),(330,505)]
g.f.polygon(T(horse,0.95,-10,0),fill=255)
g.c.polygon(T([(160,170),(210,150),(205,190)],0.95,-10,0),fill=255)
disc(g.c,*T([(58,300)],0.95,-10,0)[0],18)
for i in range(3):
    g.d.line(T([(230+i*45,95+i*35),(280+i*45,140+i*40)],0.95,-10,0),fill=255,width=0)
gear(g.c,385,395,122,8,tw=58,th=44)                                        # gap ring
gear(g.c,385,395,96,8,tw=48,th=36,v=0); gear(g.f,385,395,96,8,tw=48,th=36)
disc(g.c,385,395,34)
done(g,"teal","B24CCAVL")

# ---- Tides of Chaos: three-armed chaos swirl (red)
g=Glyph()
for k in range(3):
    for i in range(50):
        t=i/49; a=math.radians(k*120)+t*math.pi*1.15; r=40+t*190; w=14+t*48
        disc(g.f,256+math.cos(a)*r,256+math.sin(a)*r,w)
disc(g.f,256,256,70); disc(g.c,256,256,30)
done(g,"red","B24WTIDE")

# ---- Portent: all-seeing eye above two dice (cream)
g=Glyph()
put(g.fill,almond(256,130,490,210))
disc(g.c,256,130,72); disc(g.c,256,130,38,0)
for cx,cy,ang,pips in [(140,385,-14,[(-45,-45),(0,0),(45,45)]),(372,385,14,[(-45,-45),(45,-45),(-45,45),(45,45)])]:
    g.f.polygon(rot([(cx-100,cy-100),(cx+100,cy-100),(cx+100,cy+100),(cx-100,cy+100)],ang,cx,cy),fill=255)
    for p in rot([(cx+dx,cy+dy) for dx,dy in pips],ang,cx,cy): disc(g.c,*p,19)
done(g,"cream","B24PORTN")

# ---- The Third Eye: vertical eye with bold rays (cream)
g=Glyph()
for a in range(0,360,45):
    p=[(200,110),(312,110),(256,4)] if a in (90,270,0,180) else [(210,120),(302,120),(256,30)]
    g.f.polygon(rot(p,a,256,256),fill=255)
put(g.cut,almond(256,256,400,236,90),255)
put(g.cut,almond(256,256,370,206,90),0); put(g.fill,almond(256,256,370,206,90))
disc(g.c,256,256,64); disc(g.c,256,256,34,0)
done(g,"cream","B24THEYE")

# ---- Speedy Recovery: heart with a plus and speed lines (teal)
g=Glyph()
g.f.ellipse([150,60,330,240],fill=255); g.f.ellipse([300,60,480,240],fill=255)
g.f.polygon([(158,190),(472,190),(315,455)],fill=255)
g.c.polygon([(294,160),(336,160),(336,210),(386,210),(386,252),(336,252),(336,302),(294,302),(294,252),(244,252),(244,210),(294,210)],fill=255)
for y,x0,L in [(150,30,160),(255,10,180),(360,70,140)]:
    g.f.rounded_rectangle([x0,y-20,x0+L,y+20],radius=20,fill=255)
done(g,"teal","B24GDURB")

# ---- Grapple: big fist clenched around an opponent's forearm (red)
g=Glyph()
fist(g,1.05,0,30)
g.f.polygon([(0,200),(512,170),(512,300),(0,330)],fill=255)
for x in (122,390):
    g.c.line([(x,160),(x,340)],fill=255,width=24)
g.d.line([(0,312),(105,305)],fill=255,width=18); g.d.line([(405,290),(512,283)],fill=255,width=18)
done(g,"red","B24GGRAP")

# ---- Telekinetic Shove: open palm pushing force waves (red)
g=Glyph()
g.f.rounded_rectangle([30,220,225,450],radius=55,fill=255)
for x,top in [(42,115),(90,72),(138,82),(186,130)]:
    g.f.rounded_rectangle([x-4,top,x+40,300],radius=22,fill=255)
g.f.polygon([(222,360),(295,285),(322,310),(240,420)],fill=255)
for i,r in enumerate([110,185,260]):
    g.f.arc([240-r,290-r,240+r,290+r],-50,50,fill=255,width=44)
done(g,"red","B24GTELE")

preview(out,"/home/claude/preview/batchF.png")
cols=8; rows=(len(out)+cols-1)//cols
Z=Image.new("RGB",(cols*272,rows*272),(212,163,110))
for i,(n,ic) in enumerate(out):
    b=ic.resize((256,256),Image.NEAREST); Z.paste(b,((i%cols)*272+8,(i//cols)*272+8),b)
Z.save("/home/claude/preview/batchF_zoom.png")
