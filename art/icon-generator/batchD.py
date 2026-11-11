import sys,math; sys.path.insert(0,"/home/claude")
from glyph import *
out=[]
def done(g,c,n): out.append((n,g.render(c,n)))

def rot(p,c,a):
    a=math.radians(a); x,y=p[0]-c[0],p[1]-c[1]
    return (c[0]+x*math.cos(a)-y*math.sin(a), c[1]+x*math.sin(a)+y*math.cos(a))
def sword(L,hilt,ang,blade=300,w=70,guard=170,grip=80,pommel=34,lite=None):
    """hilt=(x,y) centre of crossguard; ang: direction of the blade in degrees (0=right, -90=up)"""
    a=math.radians(ang); u=(math.cos(a),math.sin(a)); n=(-u[1],u[0])
    P=lambda s,t:(hilt[0]+u[0]*s+n[0]*t, hilt[1]+u[1]*s+n[1]*t)
    L.polygon([P(0,-w/2),P(blade-w*0.9,-w/2),P(blade,0),P(blade-w*0.9,w/2),P(0,w/2)],fill=255)
    L.polygon([P(-24,-guard/2),P(24,-guard/2),P(24,guard/2),P(-24,guard/2)],fill=255)
    L.polygon([P(0,-24),P(-grip,-24),P(-grip,24),P(0,24)],fill=255)
    c=P(-grip-pommel*0.6,0); L.ellipse([c[0]-pommel,c[1]-pommel,c[0]+pommel,c[1]+pommel],fill=255)
    if lite is not None: lite.line([P(40,0),P(blade-w*1.2,0)],fill=255,width=16)
    return P
def die(g,x=400,y=400,s=112):
    """small d6 in the lower-right corner, separated from the glyph by a clear gap"""
    g.f.rectangle([x-24,y-24,512,512],fill=0)
    g.f.rounded_rectangle([x,y,x+s-1,y+s-1],radius=14,fill=255)
    g.c.rectangle([x+16,y+16,x+47,y+47],fill=255); g.c.rectangle([x+64,y+64,x+95,y+95],fill=255)
def mindeye(g,cx,cy,s=1.0,clear=True):
    """psionic accent: small eye with a pupil"""
    w,h=int(72*s),int(44*s)
    if clear: g.f.ellipse([cx-w-20,cy-h-20,cx+w+20,cy+h+20],fill=0)
    g.f.polygon([(cx-w,cy),(cx-w*0.5,cy-h),(cx+w*0.5,cy-h),(cx+w,cy),(cx+w*0.5,cy+h),(cx-w*0.5,cy+h)],fill=255)
    g.c.ellipse([cx-17,cy-17,cx+17,cy+17],fill=255)
from PIL import ImageFilter
import numpy as np
def gap(g,G,px=41):
    """paste glyph G's body onto g, cutting a clear gap around it"""
    fm=np.array(G.fill)>0; ring=np.array(G.fill.filter(ImageFilter.MaxFilter(px)))>0
    g.fill.paste(0,mask=Image.fromarray(((ring&~fm)*255).astype(np.uint8)))
    g.fill.paste(255,mask=G.fill); g.cut.paste(0,mask=G.fill)
def star4(L,cx,cy,r,w=None):
    w=w or r*0.32
    L.polygon([(cx,cy-r),(cx+w,cy-w),(cx+r,cy),(cx+w,cy+w),(cx,cy+r),(cx-w,cy+w),(cx-r,cy),(cx-w,cy-w)],fill=255)
def arrow(L,a,b,w=40,head=95):
    ang=math.atan2(b[1]-a[1],b[0]-a[0]); u=(math.cos(ang),math.sin(ang)); n=(-u[1],u[0])
    base=(b[0]-u[0]*head,b[1]-u[1]*head)
    L.line([a,base],fill=255,width=w)
    L.polygon([b,(base[0]+n[0]*head*0.6,base[1]+n[1]*head*0.6),(base[0]-n[0]*head*0.6,base[1]-n[1]*head*0.6)],fill=255)

# ---------------- Battle Master maneuvers ----------------
# Trip Attack: big toppling figure, sword sweeping under its feet
def figure(L,cx,cy,ang,s=1.0,arms_up=False):
    P=lambda x,y:rot((cx+x*s,cy+y*s),(cx,cy),ang)
    h=P(0,-135); r=48*s; L.ellipse([h[0]-r,h[1]-r,h[0]+r,h[1]+r],fill=255)
    L.line([P(0,-85),P(0,40)],fill=255,width=int(72*s))
    if arms_up: L.line([P(-110,-170),P(-30,-70),P(30,-70),P(110,-170)],fill=255,width=int(44*s),joint="curve")
    else: L.line([P(-100,10),P(-35,-70),P(35,-70),P(100,10)],fill=255,width=int(44*s),joint="curve")
    L.line([P(-22,30),P(-60,160)],fill=255,width=int(48*s)); L.line([P(22,30),P(60,160)],fill=255,width=int(48*s))
g=Glyph()
figure(g.f,250,200,-60,1.25)
sword(g.f,(60,430),0,blade=330,w=64,guard=150,grip=40,pommel=0)
die(g); done(g,"red","B24MTRIP")

# Pushing Attack: shield shoving right with shockwave arcs
g=Glyph()
g.f.polygon([(40,60),(240,40),(260,240),(220,390),(130,450),(60,360),(30,220)],fill=255)
g.c.line([(150,90),(160,370)],fill=255,width=30)
for i,r in enumerate([150,230]):
    g.f.arc([270-r,240-r,270+r,240+r],-55,45,fill=255,width=44)
arrow(g.f,(290,240),(500,240),w=44,head=100)
die(g); done(g,"red","B24MPUSH")

# Menacing Attack: big skull
g=Glyph()
g.f.ellipse([60,20,440,370],fill=255)
g.f.rounded_rectangle([140,300,360,440],radius=30,fill=255)
g.c.polygon([(120,190),(225,205),(215,280),(140,270)],fill=255)
g.c.polygon([(380,190),(275,205),(285,280),(360,270)],fill=255)
g.c.polygon([(250,290),(280,345),(220,345)],fill=255)
for x in (200,250,300): g.c.rectangle([x-12,385,x+12,440],fill=255)
die(g); done(g,"red","B24MMENA")

# Disarming Attack: sword knocked spinning, one curved spin arrow over it
g=Glyph()
sword(g.f,(130,400),-35,blade=300,w=76,guard=180,grip=60,pommel=36)
g.f.arc([40,40,440,440],180,320,fill=255,width=46)
a=math.radians(320); e=(240+math.cos(a)*200,240+math.sin(a)*200)
g.f.polygon([(e[0]-75,e[1]-45),(e[0]+65,e[1]-55),(e[0]+5,e[1]+75)],fill=255)
die(g); done(g,"red","B24MDISA")

# Distracting Strike: dazzling flash star with a spear coming in
g=Glyph()
star4(g.f,190,210,190,64)
star4(g.f,190,210,120,90)
g.c.ellipse([158,178,222,242],fill=255)
arrow(g.f,(500,70),(330,240),w=40,head=110)
die(g); done(g,"red","B24MDIST")

# Goading Attack: big helm with three arrows converging on it
g=Glyph()
g.f.rounded_rectangle([150,170,370,390],radius=60,fill=255)
g.f.ellipse([150,120,370,300],fill=255)
g.c.rectangle([180,245,340,283],fill=255); g.c.rectangle([241,283,279,350],fill=255)
arrow(g.f,(10,20),(150,150),w=48,head=100)
arrow(g.f,(502,20),(372,150),w=48,head=100)
arrow(g.f,(0,470),(150,350),w=48,head=100)
die(g); done(g,"red","B24MGOAD")

# Feinting Attack: a dashed false sword beside the real one
g=Glyph()
P=sword(g.f,(330,400),-90,blade=380,w=80,guard=190,grip=70,pommel=34)
g.l.line([(330,360),(330,110)],fill=255,width=18)
G=Glyph(); sword(G.f,(140,400),-90,blade=380,w=80,guard=190,grip=70,pommel=34)
for y in (120,230,345): G.c.rectangle([0,y,512,y+40],fill=255)
import numpy as np
m=np.array(G.fill)&~np.array(G.cut); g.fill.paste(255,mask=Image.fromarray(m))
die(g); done(g,"red","B24MFEIN")

# Precision Attack: bold bullseye, a short sword pointing into it
g=Glyph()
cx,cy=310,200
g.f.ellipse([cx-195,cy-195,cx+195,cy+195],fill=255); g.f.ellipse([cx-140,cy-140,cx+140,cy+140],fill=0)
g.f.ellipse([cx-90,cy-90,cx+90,cy+90],fill=255); g.f.ellipse([cx-36,cy-36,cx+36,cy+36],fill=0)
G=Glyph(); sword(G.f,(60,450),-40,blade=190,w=76,guard=170,grip=45,pommel=32)
gap(g,G,41)
die(g); done(g,"red","B24MPREC")

# Lunging Attack: long horizontal thrust with speed lines
g=Glyph()
sword(g.f,(170,230),-12,blade=330,w=76,guard=170,grip=60,pommel=30)
for y,x0 in [(150,10),(260,40),(350,10)]:
    g.f.rounded_rectangle([x0,y-22,x0+150 if y!=260 else x0+90,y+22],radius=22,fill=255)
die(g); done(g,"teal","B24MLUNG")

# Sweeping Attack: broad crescent slash beneath a sword
g=Glyph()
g.f.ellipse([10,60,490,490],fill=255); g.f.ellipse([0,-40,512,390],fill=0)
g.f.rectangle([0,0,512,240],fill=0)
G=Glyph(); sword(G.f,(110,250),-30,blade=320,w=76,guard=180,grip=60,pommel=36)
gap(g,G,41)
die(g); done(g,"red","B24MSWEE")

# Parry: crossed swords with a spark at the crossing
g=Glyph()
sword(g.f,(140,380),-45,blade=350,w=72,guard=150,grip=55,pommel=30)
sword(g.f,(372,380),-135,blade=350,w=72,guard=150,grip=55,pommel=30)
star4(g.f,256,130,110,40)
die(g); done(g,"teal","B24MPARR")

# Rally: war banner on a pole
g=Glyph()
g.f.rectangle([90,20,140,500],fill=255); g.f.ellipse([80,0,150,60],fill=255)
g.f.polygon([(140,60),(330,40),(470,90),(420,170),(470,250),(330,230),(140,250)],fill=255)
g.c.polygon([(240,100),(280,140),(240,180),(200,140)],fill=255)
die(g); done(g,"teal","B24MRALY")

# Evasive Footwork: boot sidestepping with afterimage streaks
g=Glyph()
g.f.polygon([(250,40),(370,40),(370,260),(470,300),(490,370),(250,370)],fill=255)
g.d.line([(250,320),(490,320)],fill=0)
g.l.rectangle([270,70,350,100],fill=255)
for y,x0,x1 in [(90,30,210),(200,60,210),(310,30,210)]:
    g.f.rounded_rectangle([x0,y-20,x1,y+20],radius=20,fill=255)
die(g); done(g,"teal","B24MEVAS")

# Commander's Strike: hand pointing forward, a sword charging past
g=Glyph()
g.f.rounded_rectangle([30,280,210,440],radius=40,fill=255)
g.f.rounded_rectangle([150,290,400,340],radius=25,fill=255)
for y in (360,410): g.f.rounded_rectangle([150,y-22,250,y+22],radius=22,fill=255)
g.c.line([(150,350),(250,350)],fill=255,width=10); g.c.line([(150,320),(150,340)],fill=255,width=0)
sword(g.f,(90,150),-10,blade=360,w=56,guard=150,grip=55,pommel=28)
die(g); done(g,"red","B24MCOMM")

# ---------------- Psionic ----------------
g=Glyph()  # Psionic Strike: sword blade into a force burst, mind eye accent
star4(g.f,360,150,150,60); star4(g.f,360,150,95,95)
sword(g.f,(120,400),-45,blade=300,w=76,guard=180,grip=60,pommel=34)
mindeye(g,100,90,1.0)
done(g,"red","B24PSTRK")

g=Glyph()  # Guarded Mind: shield bearing a big mind-eye
g.f.polygon([(50,40),(256,10),(462,40),(450,260),(380,400),(256,500),(132,400),(62,260)],fill=255)
eye=[(100,220),(180,140),(332,140),(412,220),(332,300),(180,300)]
g.c.line(eye+[eye[0]],fill=255,width=34,joint="curve")
g.c.ellipse([196,160,316,280],fill=255); g.f.ellipse([0,0,0,0],fill=255)
g.c.ellipse([180,144,332,296],fill=0)
g.c.ellipse([200,164,312,276],fill=255); g.c.ellipse([234,198,278,242],fill=0)
done(g,"teal","B24PGMND")

g=Glyph()  # Bulwark of Force: dome over three figures, eye on top
g.f.arc([20,90,492,560],180,360,fill=255,width=46)
g.f.rectangle([10,440,502,490],fill=255)
for x,s in [(150,0.62),(256,0.72),(362,0.62)]:
    hy=300 if s<0.7 else 270; r=int(38*s/0.62)
    g.f.ellipse([x-r,hy-r,x+r,hy+r],fill=255)
    g.f.rounded_rectangle([x-int(60*s/0.62),hy+r+10,x+int(60*s/0.62),440],radius=30,fill=255)
mindeye(g,256,70,0.9)
done(g,"teal","B24PBULW")

# ---------------- Barbarian ----------------
g=Glyph()  # Branches of the Tree: thick trunk, roots, branches curling into grasping hooks
g.f.polygon([(190,512),(215,300),(297,300),(322,512)],fill=255)
g.f.polygon([(20,512),(180,430),(210,512)],fill=255); g.f.polygon([(492,512),(332,430),(302,512)],fill=255)
g.f.line([(256,320),(256,70)],fill=255,width=64)
for side in (-1,1):
    pts=[(256,330),(256+side*90,270),(256+side*170,180),(256+side*190,90),(256+side*140,50),(256+side*110,100)]
    g.f.line(pts,fill=255,width=50,joint="curve")
    pts=[(256,400),(256+side*120,390),(256+side*200,330),(256+side*220,260),(256+side*180,240)]
    g.f.line(pts,fill=255,width=44,joint="curve")
g.f.ellipse([216,30,296,110],fill=255)
done(g,"red","B24WTBRN")

g=Glyph()  # Warrior of the Gods: figure, arms raised, under three rays from above
for x0,x1 in [(60,140),(256,256),(452,372)]:
    g.f.polygon([(x0-50,0),(x0+50,0),(x1+20,140),(x1-20,140)],fill=255)
G=Glyph(); figure(G.f,256,330,0,1.15,arms_up=True); G.f.rectangle([0,500,512,512],fill=0)
gap(g,G,49)
done(g,"teal","B24ZWARG")

g=Glyph()  # Zealous Presence: roaring head in profile, war-cry waves
g.f.ellipse([30,60,300,330],fill=255)
g.f.polygon([(110,300),(240,300),(250,460),(120,470)],fill=255)
g.f.polygon([(280,150),(320,200),(290,215)],fill=255)
g.c.polygon([(300,230),(210,260),(300,320)],fill=255)
g.c.ellipse([200,140,240,180],fill=255)
for r,w in [(90,34),(160,34),(230,34)]:
    g.f.arc([270-r,270-r,270+r,270+r],-50,50,fill=255,width=w)
done(g,"red","B24ZPRES")

# ---------------- Glamour Bard ----------------
g=Glyph()  # Beguiling Magic: masquerade mask with flared tips
g.f.polygon([(10,120),(120,170),(256,200),(392,170),(502,120),(470,260),(380,360),(300,340),(256,300),(212,340),(132,360),(42,260)],fill=255)
g.c.polygon([(110,230),(170,205),(220,240),(170,290),(120,270)],fill=255)
g.c.polygon([(402,230),(342,205),(292,240),(342,290),(392,270)],fill=255)
g.f.line([(256,300),(256,470)],fill=255,width=40)
star4(g.f,90,40,55); star4(g.f,422,40,55)
done(g,"red","B24GBEGU")

g=Glyph()  # Mantle of Inspiration: flared cloak with clasp, sparkles
g.f.polygon([(170,80),(342,80),(400,250),(470,470),(400,440),(330,480),(256,440),(182,480),(112,440),(42,470),(112,250)],fill=255)
g.c.ellipse([216,30,296,130],fill=255)
g.f.ellipse([236,140,276,180],fill=255)
g.l.line([(200,200),(150,430)],fill=255,width=18); g.l.line([(312,200),(362,430)],fill=255,width=18)
star4(g.f,70,90,62); star4(g.f,450,110,55)
done(g,"teal","B24GMANT")

g=Glyph()  # Mantle of Majesty: radiant crown, three light wedges above
g.f.polygon([(50,470),(50,250),(150,340),(256,200),(362,340),(462,250),(462,470)],fill=255)
for x,y in [(50,240),(256,190),(462,240)]: g.f.ellipse([x-40,y-40,x+40,y+40],fill=255)
g.c.polygon([(256,320),(290,370),(256,420),(222,370)],fill=255)
g.f.polygon([(256,0),(222,120),(290,120)],fill=255)
g.f.polygon([(90,60),(100,170),(160,140)],fill=255); g.f.polygon([(422,60),(412,170),(352,140)],fill=255)
done(g,"cream","B24GMAJE")

g=Glyph()  # Command: big hand pointing down at a figure kneeling with bowed head
g.f.rounded_rectangle([170,10,390,160],radius=50,fill=255)
g.f.rounded_rectangle([200,110,262,300],radius=31,fill=255)
for x in (295,350): g.f.rounded_rectangle([x-28,120,x+28,220],radius=28,fill=255)
g.f.polygon([(175,80),(110,160),(140,190),(210,130)],fill=255)
g.c.line([(266,150),(266,215)],fill=255,width=14); g.c.line([(322,150),(322,215)],fill=255,width=14)
g.f.ellipse([120,350,210,440],fill=255)                                   # bowed head
g.f.polygon([(200,370),(330,330),(390,370),(370,440),(220,450)],fill=255) # bent back
g.f.polygon([(320,400),(420,420),(450,500),(260,500),(260,440)],fill=255) # folded legs
g.f.line([(230,440),(170,500)],fill=255,width=40)                          # arm to ground
done(g,"red","B24GCMND")

preview(out,"/home/claude/preview/batchD.png")
cols=8; rows=(len(out)+cols-1)//cols
Z=Image.new("RGB",(cols*272,rows*272),(212,163,110))
for i,(n,ic) in enumerate(out):
    b=ic.resize((256,256),Image.NEAREST); Z.paste(b,((i%cols)*272+8,(i//cols)*272+8),b)
Z.save("/home/claude/preview/batchD_zoom.png")
