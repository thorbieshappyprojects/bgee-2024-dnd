import sys,math; sys.path.insert(0,"/home/claude")
from glyph import *
out=[]
def done(g,c,n): out.append((n,g.render(c,n)))
def P(d,pts,w): d.line(pts,fill=255,width=w,joint="curve")
def dot(d,x,y,r): d.ellipse([x-r,y-r,x+r,y+r],fill=255)
def arc_pts(cx,cy,r,a0,a1,n=30):
    return [(cx+r*math.cos(math.radians(a0+(a1-a0)*i/n)),cy+r*math.sin(math.radians(a0+(a1-a0)*i/n))) for i in range(n+1)]
def spiral(cx,cy,r0,r1,turns,a0=0,n=120):
    return [(cx+(r0+(r1-r0)*i/n)*math.cos(a0+turns*2*math.pi*i/n),cy+(r0+(r1-r0)*i/n)*math.sin(a0+turns*2*math.pi*i/n)) for i in range(n+1)]
def star4(d,x,y,r,w=0.3):
    d.polygon([(x,y-r),(x+r*w,y-r*w),(x+r,y),(x+r*w,y+r*w),(x,y+r),(x-r*w,y+r*w),(x-r,y),(x-r*w,y-r*w)],fill=255)
def rot(pts,ang,cx=256,cy=256):
    a=math.radians(ang); c,s=math.cos(a),math.sin(a)
    return [(cx+(x-cx)*c-(y-cy)*s,cy+(x-cx)*s+(y-cy)*c) for x,y in pts]
def heart(d,cx,cy,s):
    d.ellipse([cx-s,cy-s*0.8,cx,cy+s*0.2],fill=255); d.ellipse([cx,cy-s*0.8,cx+s,cy+s*0.2],fill=255)
    d.polygon([(cx-s*0.97,cy-s*0.15),(cx+s*0.97,cy-s*0.15),(cx,cy+s*1.1)],fill=255)
def sword(g,ang=0,L=1.0,dx=0,dy=0,blade=40,layer=None):
    """upright longsword centered, point up, then rotated"""
    f=layer or g.f
    bl=[(256-blade,330),(256-blade,90),(256,10),(256+blade,90),(256+blade,330)]
    gd=[(150,330),(362,330),(362,372),(150,372)]
    gr=[(234,372),(278,372),(278,450),(234,450)]
    for p in (bl,gd,gr): f.polygon([(x+dx,y+dy) for x,y in rot(T(p,L),ang)],fill=255)
    px,py=rot([(256,480)],ang)[0]; px=(px-256)*L+256+dx; py=(py-256)*L+256+dy
    dot(f,px,py,34*L)

# 10 Second Wind: heart with a wind swirl breathing through it
g=Glyph()
heart(g.f,256,290,245)
P(g.c,spiral(256,250,10,110,1.25,math.pi),34)
done(g,"teal","B24SWIND")

# 11 Action Surge: sword mid-swing with two afterimage arcs
g=Glyph()
sword(g,45,1.15,40,30,blade=50)
for r,w in [(420,48),(320,44)]:
    P(g.f,arc_pts(480,480,r,192,258,30),w)
done(g,"red","B24ASURG")

# 12 Tactical Master: sword and flanged mace crossed
g=Glyph()
sword(g,-42,1.0,0,0,blade=38)
P(g.f,rot([(256,150),(256,500)],42),42)
cx,cy=rot([(256,110)],42)[0]
dot(g.f,cx,cy,82)
for k in range(8):
    a_=math.radians(k*45); g.f.polygon([(cx+math.cos(a_)*125,cy+math.sin(a_)*125),(cx+math.cos(a_+0.5)*70,cy+math.sin(a_+0.5)*70),(cx+math.cos(a_-0.5)*70,cy+math.sin(a_-0.5)*70)],fill=255)
done(g,"cream","B24TMAST")

# 13 ASI: big upward arrow on a stepped pedestal
g=Glyph()
g.f.polygon([(256,10),(450,210),(340,210),(340,360),(172,360),(172,210),(62,210)],fill=255)
g.f.rectangle([110,390,402,430],fill=255)
g.f.rectangle([60,450,452,500],fill=255)
g.l.polygon([(256,60),(390,190),(310,190),(310,330),(256,330)],fill=255)
done(g,"cream","B24ASI")

# 14 Fighting Style: heater shield over two crossed swords
g=Glyph()
sword(g,-45,1.12,0,0,blade=34); sword(g,45,1.12,0,0,blade=34)
shield=[(130,120),(382,120),(382,270),(256,440),(130,270)]
g.f.polygon(shield,fill=255)
g.d.line(shield+[shield[0]],fill=255,width=22)
g.d.polygon([(150,200),(256,280),(362,200),(362,250),(256,330),(150,250)],fill=255)
done(g,"cream","B24FSTY")

# 15 Weapon Mastery: upright longsword with rune cut-outs
g=Glyph()
g.f.polygon([(196,370),(196,90),(256,0),(316,90),(316,370)],fill=255)
g.f.polygon([(90,360),(422,360),(422,410),(90,410)],fill=255)
dot(g.f,90,385,40); dot(g.f,422,385,40)
g.f.rectangle([230,410,282,470],fill=255); dot(g.f,256,480,32)
for y in (130,230): g.c.polygon([(256,y-40),(286,y),(256,y+40),(226,y)],fill=255)
done(g,"cream","B24WMAS")

# 16 Subclass: path forking into three arrows
g=Glyph()
P(g.f,[(256,500),(256,300)],70)
P(g.f,[(256,320),(256,120)],60); g.f.polygon([(256,10),(340,130),(172,130)],fill=255)
for s in (-1,1):
    tip=(256+s*215,90); base=(256+s*95,230)
    P(g.f,[(256,330),base],60)
    a=math.atan2(tip[1]-base[1],tip[0]-base[0]); n=(math.cos(a+1.57)*85,math.sin(a+1.57)*85)
    b2=(base[0]+math.cos(a)*10,base[1]+math.sin(a)*10)
    g.f.polygon([tip,(b2[0]+n[0],b2[1]+n[1]),(b2[0]-n[0],b2[1]-n[1])],fill=255)
done(g,"cream","B24SUBC")

# 17 Rage: screaming face in a flaring aura
g=Glyph()
for i in range(9):
    a=math.radians(-90+(i-4)*30)
    tip=(256+math.cos(a)*250,270+math.sin(a)*250); n=(math.cos(a+1.57)*55,math.sin(a+1.57)*55)
    g.f.polygon([(256+n[0],270+n[1]),tip,(256-n[0],270-n[1])],fill=255)
g.f.ellipse([120,110,392,480],fill=255)
g.c.polygon([(160,215),(245,255),(240,290),(165,265)],fill=255)
g.c.polygon([(352,215),(267,255),(272,290),(347,265)],fill=255)
g.c.ellipse([200,335,312,450],fill=255)
done(g,"red","B24RAGE")

# 18 Reckless Attack: big double-bit greataxe, tilted mid-swing, motion streaks
g=Glyph()
R=lambda p:[(x+20,y+10) for x,y in rot(p,-28,256,256)]
P(g.f,R([(256,40),(256,520)]),48)
for sgn in (-1,1):
    g.f.polygon(R([(256,90),(256+sgn*70,100),(256+sgn*170,30),(256+sgn*195,150),(256+sgn*170,270),(256+sgn*70,200),(256,210)]),fill=255)
done(g,"red","B24RECKL")

# 19 Intimidating Presence: horned helm with glowing eye slits
g=Glyph()
g.f.rounded_rectangle([140,170,372,450],radius=60,fill=255)
g.f.polygon([(140,330),(372,330),(330,500),(182,500)],fill=255)
for s in (-1,1):
    pts=[(256+s*110,220),(256+s*200,180),(256+s*240,100),(256+s*230,10),(256+s*175,110),(256+s*110,150)]
    g.f.polygon(pts,fill=255)
g.c.polygon([(170,280),(245,300),(245,330),(175,320)],fill=255)
g.c.polygon([(342,280),(267,300),(267,330),(337,320)],fill=255)
g.c.rectangle([238,350,274,450],fill=255)
done(g,"red","B24INTIM")

# 20 Cunning Action: hooded figure dashing right, speed streaks
g=Glyph()
g.f.polygon([(330,60),(410,110),(430,190),(380,230),(300,220),(270,150)],fill=255)       # hood
g.f.polygon([(290,190),(400,220),(370,330),(470,470),(400,480),(310,360),(250,420),(170,480),(140,430),(250,320)],fill=255)
g.f.polygon([(260,250),(140,300),(150,330),(290,290)],fill=255)                         # trailing arm
g.c.polygon([(350,120),(400,140),(395,180),(360,175)],fill=255)
for y,x0 in [(160,40),(260,10),(360,60)]: P(g.f,[(x0,y),(x0+150,y)],34)
done(g,"teal","B24CUNNG")

# 21 Steady Aim: crossbow pointing up, bolt in a target ring
g=Glyph()
P(g.f,arc_pts(256,420,230,205,335,30),46)
P(g.f,[(256,180),(256,500)],56)
P(g.f,[(60,330),(256,240),(452,330)],14)
P(g.f,[(256,90),(256,240)],28); g.f.polygon([(256,40),(300,130),(212,130)],fill=255)
P(g.f,arc_pts(256,110,100,0,360,40),30)
done(g,"red","B24STAIM")

# 22 Expertise: open book with bright star above
g=Glyph()
g.f.polygon([(20,300),(150,270),(256,320),(362,270),(492,300),(492,470),(362,440),(256,490),(150,440),(20,470)],fill=255)
g.c.line([(256,330),(256,480)],fill=255,width=20)
for y in (330,380): g.l.line([(70,y),(150,y-20),(220,y+10)],fill=255,width=16); g.l.line([(292,y+10),(362,y-20),(442,y)],fill=255,width=16)
star4(g.f,256,140,140,0.25)
done(g,"cream","B24EXPRT")

# 23 Flurry of Blows: three fists in a fan
g=Glyph()
fist(g,0.62,-150,50); fist(g,0.62,150,50); fist(g,0.72,0,-35)
done(g,"red","B24FLURY")

# 24 Patient Defense: raised palm, fingers together, inside a ring
g=Glyph()
P(g.f,arc_pts(256,256,225,0,360,60),40)
g.f.rounded_rectangle([190,100,330,390],radius=60,fill=255)
g.f.polygon([(190,280),(130,200),(160,180),(220,250)],fill=255)
g.c.line([(237,110),(237,230)],fill=255,width=12); g.c.line([(285,110),(285,230)],fill=255,width=12)
g.f.rectangle([215,380,305,470],fill=255)
done(g,"teal","B24PDEF")

# 25 Step of the Wind: big footprint trailing wind streaks
g=Glyph()
sole=[(330,120),(420,170),(440,290),(390,400),(380,470),(310,505),(250,465),(260,370),(270,250),(280,150)]
g.f.polygon(sole,fill=255)
for x,y,r in [(260,70,48),(345,50,36),(410,80,30),(455,130,24)]: dot(g.f,x,y,r)
P(g.f,[(230,200),(60,200)]+arc_pts(60,160,40,90,270,12)[:9],36)
P(g.f,[(230,310),(10,310)],36)
P(g.f,[(230,420),(80,420)]+arc_pts(80,460,40,-90,-270,12)[:9],36)
done(g,"teal","B24STEPW")

# 26 Stunning Strike: impact starburst with dizzy stars above
g=Glyph()
pts=[]
for i in range(16):
    a=math.radians(i*22.5-90); r=210 if i%2==0 else 110
    pts.append((256+math.cos(a)*r,300+math.sin(a)*r))
g.f.polygon(pts,fill=255)
g.c.ellipse([206,250,306,350],fill=255); dot(g.f,256,300,30)
for x,y in [(70,70),(256,40),(442,70)]: star4(g.f,x,y,58,0.32)
done(g,"red","B24STUN")

# 27 Uncanny Metabolism: big spiral with rising embers
g=Glyph()
P(g.f,spiral(256,300,12,200,2.2,0),42)
for x,y,r in [(256,40,30),(150,80,22),(362,80,22)]: dot(g.f,x,y,r)
done(g,"teal","B24UMETA")

# 28 Wholeness of Body: lotus flower
g=Glyph()
g.f.polygon([(256,30),(330,150),(340,330),(256,420),(172,330),(182,150)],fill=255)
for s in (-1,1):
    g.f.polygon([(256,420),(256+s*90,250),(256+s*200,130),(256+s*230,260),(256+s*170,390)],fill=255)
    g.f.polygon([(256,440),(256+s*170,370),(256+s*250,360),(256+s*200,440)],fill=255)
g.f.rounded_rectangle([80,440,432,490],radius=24,fill=255)
g.l.polygon([(256,80),(300,160),(300,320),(256,380)],fill=255)
done(g,"teal","B24WHOLE")

# 29 Superior Defense: crystal with monk figure, arrows glancing off
g=Glyph()
hexa=[(256,20),(440,130),(440,382),(256,492),(72,382),(72,130)]
g.f.polygon(hexa,fill=255)
dot(g.c,256,170,46)
g.c.polygon([(256,220),(340,250),(370,330),(320,330),(300,300),(330,420),(182,420),(212,300),(192,330),(142,330),(172,250)],fill=255)
done(g,"teal","B24SUPDF")

def sheets(tag):
    preview(out,f"/home/claude/preview/{tag}.png")
    cols=8; rows=(len(out)+cols-1)//cols
    Z=Image.new("RGB",(cols*272,rows*272),(212,163,110))
    for i,(n,ic) in enumerate(out):
        b=ic.resize((256,256),Image.NEAREST); Z.paste(b,((i%cols)*272+8,(i//cols)*272+8),b)
    Z.save(f"/home/claude/preview/{tag}_zoom.png")
sheets("batchA")
