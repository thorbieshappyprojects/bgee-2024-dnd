import sys,math; sys.path.insert(0,"/home/claude")
from glyph import *
out=[]
def done(g,c,n): out.append((n,g.render(c,n)))
def P(cx,cy,r,n,a0=-90,r2=None):
    """regular polygon / star points"""
    pts=[]
    for i in range(n*(2 if r2 else 1)):
        rr=r if (not r2 or i%2==0) else r2
        a=math.radians(a0+i*360/(n*(2 if r2 else 1)))
        pts.append((cx+math.cos(a)*rr,cy+math.sin(a)*rr))
    return pts
def dot(d,x,y,r): d.ellipse([x-r,y-r,x+r,y+r],fill=255)
def ray(d,c,ang,r0,r1,w0,w1=4):
    a=math.radians(ang); ux,uy=math.cos(a),math.sin(a); nx,ny=-uy,ux
    d.polygon([(c[0]+ux*r0+nx*w0,c[1]+uy*r0+ny*w0),(c[0]+ux*r1+nx*w1,c[1]+uy*r1+ny*w1),
               (c[0]+ux*r1-nx*w1,c[1]+uy*r1-ny*w1),(c[0]+ux*r0-nx*w0,c[1]+uy*r0-ny*w0)],fill=255)
def constel(g,stars,links,big=(1,)):
    for a,b in links: g.f.line([stars[a],stars[b]],fill=255,width=44)
    for i,(x,y) in enumerate(stars):
        r=72 if i in big else 58
        g.f.polygon(P(x,y,r,4,-90,r*0.45),fill=255); dot(g.f,x,y,r*0.62)
def sword(g,x0,y0,x1,y1,w=34,guard=90):
    """blade from hilt point (x0,y0) to tip (x1,y1)"""
    L=math.hypot(x1-x0,y1-y0); ux,uy=(x1-x0)/L,(y1-y0)/L; nx,ny=-uy,ux
    bx,by=x1-ux*w*2,y1-uy*w*2
    g.f.polygon([(x0+nx*w,y0+ny*w),(bx+nx*w,by+ny*w),(x1,y1),(bx-nx*w,by-ny*w),(x0-nx*w,y0-ny*w)],fill=255)
    g.f.line([(x0+nx*guard,y0+ny*guard),(x0-nx*guard,y0-ny*guard)],fill=255,width=40)
    g.f.line([(x0,y0),(x0-ux*110,y0-uy*110)],fill=255,width=40)
    dot(g.f,x0-ux*125,y0-uy*125,32)
    return ux,uy,nx,ny
def palm(g,dx=0):
    """flat palm, fingers together (monk), front view"""
    g.f.rounded_rectangle([130+dx,220,370+dx,440],radius=60,fill=255)
    for x,top in [(160,90),(220,50),(280,55),(340,95)]:
        g.f.rounded_rectangle([x-30+dx,top,x+30+dx,300],radius=30,fill=255)
    g.f.polygon([(140+dx,330),(55+dx,250),(85+dx,215),(180+dx,280)],fill=255)
    g.f.rectangle([180+dx,430,330+dx,500],fill=255)
    for x in (190,250,310): g.c.line([(x+dx,120),(x+dx,250)],fill=255,width=16)

# 1 Unbreakable Majesty: crown with gem, shards flying off
g=Glyph()
g.f.polygon([(40,140),(140,280),(256,90),(372,280),(472,140),(430,420),(82,420)],fill=255)
for x,y in [(40,120),(256,70),(472,120)]: dot(g.f,x,y,40)
g.f.rounded_rectangle([70,380,442,470],radius=20,fill=255)
g.c.polygon(P(256,330,56,4),fill=255)
g.c.ellipse([115,405,160,450],fill=255); g.c.ellipse([352,405,397,450],fill=255)
done(g,"teal","B24GUNBR")

# 2 Radiance of the Dawn: half sun on horizon, long rays
g=Glyph()
c=(256,360)
for a in range(-180,1,30): ray(g.f,c,a,120,250 if a%60==0 else 200,40)
g.f.pieslice([100,204,412,516],180,360,fill=255)
g.f.rectangle([20,370,492,420],fill=255)
g.f.rectangle([90,445,422,490],fill=255)
done(g,"cream","B24LRADI")

# 3 Warding Flare: shield with flash star
g=Glyph()
g.f.polygon([(70,80),(256,40),(442,80),(442,260),(256,490),(70,260)],fill=255)
g.c.polygon(P(256,220,150,4,-90,50),fill=255)
g.l.polygon(P(256,220,95,4,-45,30),fill=255)
done(g,"teal","B24LWARD")

# 4 Corona of Light: thick ring with many short rays
g=Glyph()
c=(256,256)
for a in range(0,360,30): ray(g.f,c,a,150,250,40)
g.f.ellipse([86,86,426,426],fill=255); g.c.ellipse([160,160,352,352],fill=255)
g.d.ellipse([110,110,402,402],outline=255,width=18)
done(g,"cream","B24LCORO")

# 5 Blessing of the Trickster: domino mask + sparkle
g=Glyph()
g.f.polygon([(20,220),(80,170),(200,175),(256,215),(312,175),(432,170),(492,220),(470,320),(380,380),(300,350),(256,300),(212,350),(132,380),(42,320)],fill=255)
g.c.ellipse([105,225,205,305],fill=255); g.c.ellipse([307,225,407,305],fill=255)
g.f.polygon(P(400,80,85,4,-90,25),fill=255)
g.f.polygon([(40,330),(10,450),(110,370)],fill=255)
done(g,"teal","B24TBLES")

# 6 Invoke Duplicity: solid hooded figure + striped ghost double
def figure(d,dx,dy=0,s=1.0):
    t=lambda p:T(p,s,dx,dy)
    d.ellipse(t([(196,50)])[0]+t([(316,170)])[0],fill=255)
    d.polygon(t([(186,170),(326,170),(400,470),(112,470)]),fill=255)
g=Glyph()
figure(g.f,110,20,0.95)
for y in range(110,470,64): g.c.rectangle([250,y,500,y+28],fill=255)
figure(g.f,-90,20,0.95)
g.l.ellipse(T([(196,150),(230,185)],0.95,-90,20)[0]+T([(196,150),(230,185)],0.95,-90,20)[1],fill=255)
done(g,"red","B24TDUPL")

# 7 Guided Strike: fist gripping upright sword, guiding sparks
g=Glyph()
g.f.polygon([(225,330),(225,90),(256,10),(287,90),(287,330)],fill=255)
g.f.rectangle([130,240,382,280],fill=255)
fist(g,0.75,0,150)
g.l.polygon([(256,40),(272,90),(272,230),(256,230)],fill=255)
for x,y in [(90,110),(422,110)]: g.f.polygon(P(x,y,70,4,-90,22),fill=255)
done(g,"red","B24WGSTR")

# 8 War God's Blessing: winged sword pointing up
g=Glyph()
g.f.polygon([(220,400),(220,110),(256,20),(292,110),(292,400)],fill=255)
g.f.rectangle([180,370,332,410],fill=255); g.f.rectangle([234,400,278,480],fill=255); dot(g.f,256,488,26)
for sgn in (-1,1):
    pts=[(256+sgn*30,400),(256+sgn*60,260),(256+sgn*150,170),(256+sgn*250,110),(256+sgn*240,200),(256+sgn*200,220),(256+sgn*215,270),(256+sgn*160,290),(256+sgn*170,340),(256+sgn*110,350),(256+sgn*100,400)]
    g.f.polygon(pts,fill=255)
    g.c.line([(256+sgn*45,240),(256+sgn*45,420)],fill=255,width=36)
g.l.polygon([(256,50),(272,110),(272,360),(256,360)],fill=255)
done(g,"red","B24WGBLS")

# 9 War Priest: two crossed flanged maces
g=Glyph()
for sgn in (-1,1):
    a=(256-sgn*190,470); b=(256+sgn*120,150)
    g.f.line([a,b],fill=255,width=56)
    hx,hy=256+sgn*150,120
    g.f.polygon(P(hx,hy,115,8,-90,75),fill=255)
    dot(g.f,a[0],a[1],40)
    g.l.ellipse([hx-28,hy-28,hx+28,hy+28],fill=255)
done(g,"red","B24WPRST")

# 10 Wrath of the Sea: big curling wave
g=Glyph()
g.f.polygon([(20,490),(20,380),(90,250),(190,130),(310,70),(420,90),(490,170),(480,280),(420,320),(360,300),(330,250),(360,200),(410,210),(400,160),(330,150),(250,210),(200,320),(220,420),(300,470),(420,450),(492,410),(492,490)],fill=255)
g.c.polygon([(80,470),(130,350),(180,280),(160,400),(200,470)],fill=255)
for x,y,r in [(470,40,30),(380,20,22)]: dot(g.f,x,y,r)
done(g,"red","B24SWRAT")

# 11 Starry Form Archer: bow arc + arrow of stars
g=Glyph()
constel(g,[(170,40),(70,256),(170,470),(470,256),(330,256)],[(0,1),(1,2),(0,2),(1,3)],big=(3,))
g.f.polygon([(470,256),(400,200),(400,312)],fill=255)
done(g,"red","B24STARC")

# 12 Starry Form Chalice
g=Glyph()
constel(g,[(70,60),(442,60),(130,240),(382,240),(256,330),(256,440),(110,470),(402,470)],
       [(0,2),(2,4),(4,3),(3,1),(0,1),(4,5),(5,6),(5,7)],big=(4,))
done(g,"teal","B24STCHL")

# 13 Starry Form Dragon: S-coil with head
g=Glyph()
constel(g,[(400,70),(280,60),(170,150),(290,250),(390,340),(250,450),(90,400),(470,150)],
       [(7,0),(0,1),(1,2),(2,3),(3,4),(4,5),(5,6)],big=(0,))
g.f.polygon([(400,70),(500,30),(460,120)],fill=255)
done(g,"teal","B24STDRG")

# 14 Luminous Arrow: diagonal arrow with sparkle trail
g=Glyph()
g.f.line([(110,400),(400,110)],fill=255,width=64)
g.f.polygon([(490,20),(330,80),(432,182)],fill=255)
# fletching
g.f.polygon([(150,360),(60,320),(30,370),(110,400)],fill=255)
g.f.polygon([(150,360),(190,450),(140,480),(110,400)],fill=255)
g.f.polygon(P(95,95,100,4,-90,34),fill=255)
g.f.polygon(P(410,410,85,4,-90,30),fill=255)
done(g,"cream","B24STARW")

# 15/16 Hand of Harm / Hand of Healing
g=Glyph(); palm(g,-30)
g.c.polygon(P(225,320,70,5,-90,30),fill=255)
g.f.polygon(P(430,95,90,7,-90,45),fill=255); g.d.ellipse([405,70,455,120],fill=255)
done(g,"red","B24MHARM")
g=Glyph(); palm(g,-30)
g.c.ellipse([165,270,230,335],fill=255); g.c.ellipse([220,270,285,335],fill=255); g.c.polygon([(168,315),(282,315),(225,395)],fill=255)
g.f.polygon([(410,40),(450,40),(450,90),(500,90),(500,130),(450,130),(450,180),(410,180),(410,130),(360,130),(360,90),(410,90)],fill=255)
done(g,"teal","B24MHHEL")

# 17 Shadow Arts: monk figure dissolving into horizontal strands at the bottom
g=Glyph()
dot(g.f,256,80,62)
g.f.polygon([(150,160),(362,160),(470,300),(430,330),(350,250),(340,330),(172,330),(162,250),(82,330),(42,300)],fill=255)
for i,(x0,x1) in enumerate([(160,350),(130,320),(190,400),(140,300)]):
    y=350+i*40; g.f.rounded_rectangle([x0+i*12,y,x1+i*12,y+26],radius=13,fill=255)
done(g,"teal","B24MSART")

# 18 Cloak of Shadows: tall hood with glowing eyes
g=Glyph()
g.f.polygon([(256,20),(360,90),(400,220),(470,490),(42,490),(112,220),(152,90)],fill=255)
g.c.polygon([(256,120),(330,170),(340,280),(256,320),(172,280),(182,170)],fill=255)
g.f.polygon([(196,215),(246,230),(236,260),(196,250)],fill=255)
g.f.polygon([(316,215),(266,230),(276,260),(316,250)],fill=255)
g.l.polygon([(196,215),(246,230),(236,260),(196,250)],fill=255); g.l.polygon([(316,215),(266,230),(276,260),(316,250)],fill=255)
g.c.line([(256,340),(256,480)],fill=255,width=36)
done(g,"teal","B24MCLOA")

# 19 Shadow Step: two shadow pools linked by a leaping arrow
g=Glyph()
g.f.ellipse([10,400,240,500],fill=255); g.f.ellipse([272,400,502,500],fill=255)
g.l.ellipse([55,428,195,472],fill=255); g.l.ellipse([317,428,457,472],fill=255)
g.f.arc([100,80,440,600],200,315,fill=255,width=68)
g.f.polygon([(330,170),(470,170),(440,320)],fill=255) if False else g.f.polygon([(300,150),(490,170),(400,350)],fill=255)
done(g,"teal","B24MSSTP")

# 20 Elemental Attunement: fist inside swirling wind arcs
g=Glyph(); fist(g,0.78,0,30)
g.f.arc([20,30,492,490],195,325,fill=255,width=60)
g.f.arc([20,30,492,490],15,145,fill=255,width=60)
g.f.polygon([(400,40),(505,95),(420,170)],fill=255)
g.f.polygon([(112,472),(7,417),(92,342)],fill=255)
done(g,"red","B24MATTN")

# 21 Elemental Burst: fat snowflake burst
g=Glyph(); c=(256,256)
for a in range(0,360,60):
    ray(g.f,c,a-90,0,250,40,26)
    r=math.radians(a-90); bx,by=c[0]+math.cos(r)*165,c[1]+math.sin(r)*165
    for s in (-45,45):
        ray(g.f,(bx,by),a-90+s,0,80,20,16)
dot(g.f,256,256,90); g.c.polygon(P(256,256,48,6),fill=255)
done(g,"red","B24MBRST")

# 22 Inspiring Smite: sword up through a laurel wreath
g=Glyph()
cx,cy,R=256,290,180
for sgn in (-1,1):
    g.f.arc([cx-R,cy-R,cx+R,cy+R],(100 if sgn<0 else 300),(235 if sgn<0 else 80),fill=255,width=30)
    for k in range(4):
        th=math.radians(30+k*40)          # from bottom
        x=cx+sgn*R*math.sin(th); y=cy+R*math.cos(th)
        ox,oy=sgn*math.sin(th),math.cos(th)
        lx,ly=x+ox*55,y+oy*55-20
        g.f.polygon([(x,y),(lx-ox*0+sgn*0,ly),(x+ox*20,y+oy*20-70)],fill=255)
        g.f.ellipse([lx-38,ly-38,lx+38,ly+38],fill=255) if False else None
        # leaf as fat ellipse rotated via polygon
        a=math.atan2(oy-0.8,ox); L,W=62,30
        pts=[(x+math.cos(a)*L*math.cos(t)-math.sin(a)*W*math.sin(t)+math.cos(a)*40,
              y+math.sin(a)*L*math.cos(t)+math.cos(a)*W*math.sin(t)+math.sin(a)*40) for t in [i*math.pi/8 for i in range(16)]]
        g.f.polygon(pts,fill=255)
g.f.polygon([(230,420),(230,90),(256,10),(282,90),(282,420)],fill=255)
g.f.rectangle([166,380,346,420],fill=255); g.f.rectangle([236,420,276,490],fill=255); dot(g.f,256,492,22)
g.l.polygon([(256,40),(268,90),(268,370),(256,370)],fill=255)
done(g,"teal","B24GINSP")

# 23 Nature's Wrath: thorny vine rising from the ground into a binding spiral
g=Glyph()
g.f.polygon([(20,500),(50,450),(462,450),(492,500)],fill=255)
pts=[(150,460),(150,330)]
for i in range(60):
    t=i/59*1.75*2*math.pi; r=190-t*16
    pts.append((256-math.cos(t)*r*1.0+0, 230+math.sin(t)*r*-1.0 if False else 230-math.sin(t)*r*0+math.sin(-t)*r))
pts=[(150,460),(130,350)]+[(256-math.cos(t)*r,220-math.sin(t)*r) for t,r in [(i/59*1.45*2*math.pi,(200-i*2.6)) for i in range(60)]]
for ang in (40,100,160,215):
    a=math.radians(ang); x,y=256-math.cos(a)*200,220-math.sin(a)*200
    g.f.polygon([(x-math.sin(a)*40,y+math.cos(a)*40),(x-math.cos(a)*85,y-math.sin(a)*85),(x+math.sin(a)*40,y-math.cos(a)*40)],fill=255)
g.f.line(pts,fill=255,width=56,joint="curve")
for x,y in [pts[0],pts[-1]]: dot(g.f,x,y,28)
for p in [[(140,400),(40,330),(110,320)]]:
    g.f.polygon(p,fill=255)
done(g,"red","B24ANWRA")

# 24 Vow of Enmity: target ring with four inward fangs, dark pupil centre
g=Glyph()
g.f.ellipse([25,25,487,487],outline=255,width=68)
for a in range(45,360,90):
    r=math.radians(a); ux,uy=math.cos(r),math.sin(r); nx,ny=-uy,ux
    g.f.polygon([(256+ux*200+nx*60,256+uy*200+ny*60),(256+ux*80,256+uy*80),(256+ux*200-nx*60,256+uy*200-ny*60)],fill=255)
g.f.ellipse([206,206,306,306],fill=255); g.d.ellipse([228,228,284,284],fill=255)
done(g,"red","B24VVOWE")

preview(out,"/home/claude/preview/batchE.png")
cols=8; rows=(len(out)+cols-1)//cols
Z=Image.new("RGB",(cols*272,rows*272),(212,163,110))
for i,(n,ic) in enumerate(out):
    b=ic.resize((256,256),Image.NEAREST); Z.paste(b,((i%cols)*272+8,(i//cols)*272+8),b)
Z.save("/home/claude/preview/batchE_zoom.png")
