import sys,math; sys.path.insert(0,"/home/claude")
from glyph import *
out=[]
def done(g,c,n): out.append((n,g.render(c,n)))
def star(cx,cy,R,r,n=4,rot=-90):
    pts=[]
    for i in range(n*2):
        a=math.radians(rot+i*180/n); rr=R if i%2==0 else r
        pts.append((cx+math.cos(a)*rr,cy+math.sin(a)*rr))
    return pts
def hand_up(g,dx=0,dy=0,s=1.0):
    t=lambda p:T(p,s,dx,dy)
    g.f.rounded_rectangle([*t([(140,230)])[0],*t([(380,470)])[0]],radius=int(70*s),fill=255)
    for x,top in [(170,120),(232,70),(294,80),(352,130)]:
        g.f.rounded_rectangle([*t([(x-30,top)])[0],*t([(x+30,300)])[0]],radius=int(30*s),fill=255)
    g.f.polygon(t([(150,330),(60,240),(85,210),(185,290)]),fill=255)
def sword(g,cx,top,bot,w=34,guard=110,flip=False):
    """vertical sword, point at `top` (or bottom if flip)"""
    if not flip:
        g.f.polygon([(cx,top),(cx+w,top+60),(cx+w,bot-120),(cx-w,bot-120),(cx-w,top+60)],fill=255)
        g.f.rounded_rectangle([cx-guard,bot-140,cx+guard,bot-100],radius=14,fill=255)
        g.f.rectangle([cx-20,bot-100,cx+20,bot-30],fill=255)
        g.f.ellipse([cx-34,bot-50,cx+34,bot+10],fill=255)
    else:
        g.f.polygon([(cx,bot),(cx+w,bot-60),(cx+w,top+120),(cx-w,top+120),(cx-w,bot-60)],fill=255)
        g.f.rounded_rectangle([cx-guard,top+100,cx+guard,top+140],radius=14,fill=255)
        g.f.rectangle([cx-20,top+30,cx+20,top+100],fill=255)
        g.f.ellipse([cx-34,top-10,cx+34,top+50],fill=255)

# Quivering Palm: open palm facing out with vibration arcs on both sides
g=Glyph(); hand_up(g,0,40,0.95)
for i in range(3): g.c.line([(201*0.95+12.8+i*59,190),(201*0.95+12.8+i*59,300)],fill=255,width=16)
for r in (215,290):
    g.f.arc([256-r,250-r,256+r,250+r],195,240,fill=255,width=40)
    g.f.arc([256-r,250-r,256+r,250+r],300,345,fill=255,width=40)
g.d.ellipse([206,320,306,420],outline=255,width=26)
done(g,"red","B24QPALM")

# Lay on Hands: hand pressing down (fingers down) onto a heart
g=Glyph()
g.f.rounded_rectangle([140,0,372,150],radius=60,fill=255)                 # back of hand
for x,bot in [(168,250),(226,275),(284,272),(342,240)]:
    g.f.rounded_rectangle([x-28,100,x+28,bot],radius=28,fill=255)
g.f.polygon([(370,70),(460,140),(435,170),(350,125)],fill=255)            # thumb
for i in range(3): g.c.line([(197+i*58,160),(197+i*58,250)],fill=255,width=16)
g.f.ellipse([116,300,262,440],fill=255); g.f.ellipse([250,300,396,440],fill=255)
g.f.polygon([(122,390),(390,390),(256,512)],fill=255)
done(g,"teal","B24LOH")

# Divine Smite: sword point-down striking into a starburst
g=Glyph()
g.f.polygon(star(256,400,150,55,8,-90),fill=255)
sword(g,256,0,380,w=56,guard=150,flip=True)
g.l.line([(256,160),(256,330)],fill=255,width=26)
done(g,"red","B24SMITE")

# Sacred Weapon: upright sword with radiant rays fanning from the blade
g=Glyph()
c=(256,180)
for a in (-170,-140,-110,-70,-40,-10):
    r=math.radians(a); p=(c[0]+math.cos(r)*250,c[1]+math.sin(r)*250)
    q=(c[0]+math.cos(r)*90,c[1]+math.sin(r)*90); n=(-math.sin(r)*50,math.cos(r)*50)
    g.f.polygon([(q[0]+n[0],q[1]+n[1]),p,(q[0]-n[0],q[1]-n[1])],fill=255)
g.c.rectangle([195,0,317,400],fill=255)
s2=Glyph(); sword(s2,256,0,512,w=52,guard=150)
g.fill.paste(255,mask=s2.fill); g.cut.paste(0,mask=s2.fill)
g.l.polygon([(256,30),(282,85),(282,360),(256,360)],fill=255)
done(g,"red","B24SACWP")

# Abjure Foes: holy shield, two outward arrowheads driving foes away
g=Glyph()
g.f.polygon([(130,20),(382,20),(382,220),(256,390),(130,220)],fill=255)
g.c.polygon([(236,60),(276,60),(276,130),(332,130),(332,170),(276,170),(276,290),(256,315),(236,290),(236,170),(180,170),(180,130),(236,130)],fill=255)
g.f.polygon([(0,380),(120,260),(130,350),(200,350),(200,420),(130,420),(120,500)],fill=255)
g.f.polygon([(512,380),(392,260),(382,350),(312,350),(312,420),(382,420),(392,500)],fill=255)
done(g,"red","B24ABJUR")

# Holy Nimbus: figure inside a blazing sun ring
g=Glyph()
g.f.polygon(star(256,256,256,185,12,-90),fill=255)
g.f.ellipse([90,90,422,422],fill=0)
g.f.ellipse([206,110,306,210],fill=255)
g.f.polygon([(256,200),(350,235),(335,420),(290,420),(256,350),(222,420),(177,420),(162,235)],fill=255)
done(g,"cream","B24NIMBS")

# Hunter's Mark: crosshair reticle with bold center dot
g=Glyph()
g.f.ellipse([40,40,472,472],fill=255); g.f.ellipse([116,116,396,396],fill=0)
for p in [[(256,0),(256,170)],[(256,342),(256,512)],[(0,256),(170,256)],[(342,256),(512,256)]]:
    g.f.line(p,fill=255,width=48)
g.f.ellipse([206,206,306,306],fill=255)
done(g,"red","B24HMARK")

# Tireless: striding boot with speed lines
g=Glyph()
g.f.polygon([(200,40),(350,40),(345,300),(470,340),(490,400),(480,450),(170,450),(160,300)],fill=255)
g.f.rounded_rectangle([180,30,370,90],radius=16,fill=255)
g.c.rectangle([150,90,420,108],fill=255)
g.c.line([(160,400),(500,400)],fill=255,width=18)
for y,x0 in [(170,20),(260,40),(350,10)]:
    g.f.rounded_rectangle([x0,y-18,x0+110,y+18],radius=18,fill=255)
done(g,"teal","B24TIRLS")

# Nature's Veil: big leaf breaking into small leaves
g=Glyph()
g.f.polygon([(40,490),(30,330),(90,180),(220,70),(340,20),(320,170),(260,320),(160,440)],fill=255)
g.c.line([(70,460),(280,110)],fill=255,width=24)
def lf(x,y,r,a):
    a=math.radians(a); u=(math.cos(a)*r,math.sin(a)*r); v=(-math.sin(a)*r*0.5,math.cos(a)*r*0.5)
    g.f.polygon([(x-u[0],y-u[1]),(x+v[0],y+v[1]),(x+u[0],y+u[1]),(x-v[0],y-v[1])],fill=255)
for x,y,r,a in [(390,170,70,-40),(360,330,60,-20),(470,280,42,-60),(450,60,40,-30),(260,450,45,-10)]:
    lf(x,y,r,a)
done(g,"teal","B24NVEIL")

# Bardic Inspiration: lute, neck up-right, with a note
g=Glyph()
g.f.ellipse([40,220,320,490],fill=255)
g.f.polygon([(230,250),(380,90),(420,130),(290,300)],fill=255)
g.f.polygon([(370,60),(430,20),(480,80),(430,130)],fill=255)
g.c.ellipse([135,320,205,390],fill=255)
g.d.line([(95,450),(180,410)],fill=255,width=26)
g.f.ellipse([370,250,450,320],fill=255); g.f.rectangle([420,170,452,285],fill=255)
g.f.polygon([(420,170),(500,200),(500,240),(452,215)],fill=255)
done(g,"teal","B24BINSP")

# Divine Spark: four-point spark above cupped palm
g=Glyph()
g.f.polygon(star(256,170,170,50,4,-90),fill=255)
g.f.polygon(star(256,170,90,40,4,-45),fill=255)
g.f.chord([30,220,482,510],0,180,fill=255)
g.f.chord([130,190,382,420],0,180,fill=0)
done(g,"cream","B24DSPRK")

# Turn Undead: skull with holy rays bursting above
g=Glyph()
for i in range(5):
    a=math.radians(-90+(i-2)*32); c=(256,230)
    p=(c[0]+math.cos(a)*230,c[1]+math.sin(a)*230); n=(-math.sin(a)*42,math.cos(a)*42)
    g.f.polygon([(c[0]+n[0],c[1]+n[1]),p,(c[0]-n[0],c[1]-n[1])],fill=255)
g.f.ellipse([110,170,402,420],fill=255)
g.f.rounded_rectangle([170,360,342,500],radius=30,fill=255)
g.c.ellipse([155,260,240,345],fill=255); g.c.ellipse([272,260,357,345],fill=255)
g.c.polygon([(256,350),(232,395),(280,395)],fill=255)
for x in (218,256,294): g.c.line([(x,430),(x,500)],fill=255,width=22)
done(g,"cream","B24TURNU")

# Preserve Life: big heart with plus, small rays
g=Glyph()
g.f.ellipse([50,90,270,310],fill=255); g.f.ellipse([242,90,462,310],fill=255)
g.f.polygon([(62,240),(450,240),(256,470)],fill=255)
g.c.polygon([(230,150),(282,150),(282,205),(337,205),(337,257),(282,257),(282,312),(230,312),(230,257),(175,257),(175,205),(230,205)],fill=255)
for p in [[(256,480),(256,512)]]: pass
for a in (-150,-30,90):
    pass
for x,y in [(30,40),(482,40),(60,440),(452,440)]:
    g.f.polygon(star(x,y,60,20,4,-90),fill=255)
done(g,"teal","B24PRSLF")

# Land's Aid: thorny vine ring with leaf sprout in middle
g=Glyph()
g.f.ellipse([60,60,452,452],fill=255); g.f.ellipse([124,124,388,388],fill=0)
for i in range(8):
    a=math.radians(i*45+22); c=(256,256)
    b1=(c[0]+math.cos(a-0.2)*190,c[1]+math.sin(a-0.2)*190); b2=(c[0]+math.cos(a+0.2)*190,c[1]+math.sin(a+0.2)*190)
    tip=(c[0]+math.cos(a+0.1)*270,c[1]+math.sin(a+0.1)*270)
    g.f.polygon([b1,tip,b2],fill=255)
g.f.polygon([(256,140),(330,210),(345,280),(256,380),(167,280),(182,210)],fill=255)
g.d.line([(256,360),(256,190)],fill=255,width=20)
g.c.ellipse([0,0,1,1],fill=0)
done(g,"teal","B24LAID")

# Innate Sorcery: fat flame with spiral cut (inner magic)
g=Glyph()
g.f.polygon([(110,330),(90,220),(150,120),(150,210),(210,90),(260,10),(280,130),(340,60),(350,170),(400,120),(420,240),(400,340)],fill=255)
g.f.ellipse([100,200,412,500],fill=255)
g.c.polygon(star(256,350,105,34,4,-90),fill=255)
done(g,"red","B24INSOR")

# Class Feature: ornate key
g=Glyph()
g.f.ellipse([20,20,240,240],fill=255); g.c.ellipse([85,85,175,175],fill=255)
g.f.polygon([(180,140),(230,90),(500,360),(450,410)],fill=255)
g.f.polygon([(400,330),(460,270),(512,322),(452,382)],fill=255)
g.f.polygon([(320,250),(380,190),(425,235),(365,295)],fill=255)
done(g,"cream","B24OPTN")

# Cantrip: hand with raised index finger, spark above the fingertip
g=Glyph()
g.f.polygon(star(256,105,110,32,4,-90),fill=255)
g.f.rounded_rectangle([206,200,290,400],radius=42,fill=255)
g.f.rounded_rectangle([150,320,380,512],radius=60,fill=255)
g.d.line([(290,360),(370,360)],fill=255,width=20)
g.d.line([(290,420),(370,420)],fill=255,width=20)
g.d.line([(160,380),(210,440)],fill=255,width=20)
g.f.polygon(star(410,200,56,18,4,-90),fill=255); g.f.polygon(star(100,210,48,16,4,-90),fill=255)
done(g,"cream","B24CANTP")

# Spellbook: open book with quill
g=Glyph()
g.f.polygon([(20,170),(140,130),(256,180),(372,130),(492,170),(492,450),(372,415),(256,470),(140,415),(20,450)],fill=255)
g.c.line([(256,190),(256,450)],fill=255,width=20)
for y in (230,290,350): g.d.line([(70,y),(200,y-15)],fill=255,width=20)
g.f.polygon([(305,380),(320,300),(400,140),(470,30),(512,0),(500,70),(450,200),(360,320)],fill=255)
g.d.line([(312,365),(490,30)],fill=255,width=18)
g.c.line([(325,320),(470,60)],fill=255,width=0)
done(g,"cream","B24SPBK")

# Class Feature Choice: scroll with three seals
g=Glyph()
g.f.rounded_rectangle([90,60,422,452],radius=10,fill=255)
g.f.rounded_rectangle([50,30,462,110],radius=40,fill=255)
g.f.rounded_rectangle([50,400,462,480],radius=40,fill=255)
g.c.line([(70,112),(442,112)],fill=255,width=16); g.c.line([(70,398),(442,398)],fill=255,width=16)
for y in (175,256,337):
    g.d.ellipse([118,y-36,198,y+36],fill=255)
    g.d.line([(230,y),(380,y)],fill=255,width=22)
done(g,"cream","B24PICK")

preview(out,"/home/claude/preview/batchB.png")
cols=8; rows=(len(out)+cols-1)//cols
Z=Image.new("RGB",(cols*272,rows*272),(212,163,110))
for i,(n,ic) in enumerate(out):
    b=ic.resize((256,256),Image.NEAREST); Z.paste(b,((i%cols)*272+8,(i//cols)*272+8),b)
Z.save("/home/claude/preview/batchB_zoom.png")
