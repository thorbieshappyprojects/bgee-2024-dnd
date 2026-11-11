import sys,math; sys.path.insert(0,"/home/claude")
from glyph import *
out=[]
def done(g,c,n): out.append((n,g.render(c,n)))
def R(a): return math.radians(a)
def star(cx,cy,ro,ri,n=4,rot=-90):
    p=[]
    for i in range(2*n):
        r=ro if i%2==0 else ri; a=R(rot+i*180/n)
        p.append((cx+math.cos(a)*r,cy+math.sin(a)*r))
    return p
def ell(d,cx,cy,r,ry=None): d.ellipse([cx-r,cy-(ry or r),cx+r,cy+(ry or r)],fill=255)
def cross(cx,cy,L,w):
    h=w/2
    return [(cx-h,cy-L),(cx+h,cy-L),(cx+h,cy-h),(cx+L,cy-h),(cx+L,cy+h),(cx+h,cy+h),(cx+h,cy+L),(cx-h,cy+L),(cx-h,cy+h),(cx-L,cy+h),(cx-L,cy-h),(cx-h,cy-h)]
def flame(cx,base,h,w,lean=0):
    """fat flame with three tongues, base is the bottom y"""
    return [(cx-w,base-h*0.25),(cx-w*0.95,base-h*0.55),(cx-w*0.55,base-h*0.45),(cx-w*0.45,base-h*0.8),
            (cx-w*0.1,base-h*0.6),(cx+lean,base-h),(cx+w*0.35,base-h*0.6),(cx+w*0.6,base-h*0.75),
            (cx+w*0.65,base-h*0.4),(cx+w*0.95,base-h*0.5),(cx+w,base-h*0.25),(cx+w*0.75,base-h*0.03),
            (cx,base),(cx-w*0.75,base-h*0.03)]

def winged_cross(g,s,dx,dy,cut=True):
    """healing cross with a solid swept wing on each arm (feather steps on the lower edge)"""
    t=lambda p:T(p,s,dx,dy)
    for sg in (-1,1):
        x=lambda v:256+sg*v
        g.f.polygon(t([(x(100),200),(x(170),120),(x(256),50),(x(256),150),(x(215),150),(x(240),205),(x(185),210),(x(200),265),(x(110),260)]),fill=255)
    g.f.polygon(t(cross(256,290,175,112)),fill=255)
    if cut: g.c.polygon(t(cross(256,290,110,40)),fill=255)
    else: g.l.polygon(t(cross(256,290,120,72)),fill=255)

# B24HWORD Healing Word: winged cross in flight
g=Glyph(); winged_cross(g,1.0,0,20); done(g,"teal","B24HWORD")

# B24CWBRD Cure Wounds: heart with a cross cut out
g=Glyph()
ell(g.f,170,170,120); ell(g.f,342,170,120)
g.f.polygon([(56,215),(456,215),(256,480)],fill=255)
g.c.polygon(cross(256,235,95,64),fill=255)
done(g,"teal","B24CWBRD")

# B24GBOLT Guiding Bolt: thick bolt of light streaking diagonally into a star
g=Glyph()
g.f.polygon([(20,492),(0,450),(300,170),(342,212)],fill=255)
g.f.polygon([(110,500),(80,470),(300,240),(320,262)],fill=255)
g.f.polygon([(10,380),(0,360),(260,160),(280,180)],fill=255)
g.f.polygon(star(350,162,160,60,4,-45),fill=255)
g.f.polygon(star(350,162,110,48,4,0),fill=255)
g.d.polygon(star(350,162,48,20,4,-45),fill=255)
done(g,"cream","B24GBOLT")

# B24THWAV Thunderwave: shockwave rings blasting out from a central burst
g=Glyph()
g.f.polygon(star(256,256,105,48,6,-90),fill=255)
for r,w in [(170,48),(250,50)]:
    for a0 in (-55,125):
        g.f.arc([256-r,256-r,256+r,256+r],a0,a0+110,fill=255,width=w)
done(g,"red","B24THWAV")

# B24SHATR Shatter: orb bursting into shards
g=Glyph()
ell(g.f,256,256,140)
g.c.line([(256,110),(230,190),(285,250),(235,320),(270,400)],fill=255,width=30)
g.c.line([(120,230),(200,240),(285,250)],fill=255,width=26)
g.c.line([(285,250),(360,215),(395,180)],fill=255,width=26)
for cx,cy,a,L in [(70,70,225,70),(442,80,315,70),(60,440,135,70),(450,430,45,70),(256,30,270,55),(256,490,90,55)]:
    ca,sa=math.cos(R(a)),math.sin(R(a))
    tip=(cx+ca*L*0.6,cy+sa*L*0.6); b=(cx-ca*L*0.6,cy-sa*L*0.6)
    n=(-sa*30,ca*30)
    g.f.polygon([tip,(b[0]+n[0],b[1]+n[1]),(b[0]-n[0],b[1]-n[1])],fill=255)
done(g,"red","B24SHATR")

# B24SPGRD Spirit Guardians: great wings around a spear
g=Glyph()
for sg in (-1,1):
    x=lambda v:256+sg*v
    g.f.polygon([(x(60),480),(x(60),330),(x(110),180),(x(170),80),(x(210),30),(x(210),140),(x(195),250),(x(170),350),(x(130),440)],fill=255)
    for i,y in enumerate([200,300]):
        g.c.line([(x(230),y-50),(x(150-i*30),y+30)],fill=255,width=36)
g.f.rectangle([228,90,284,505],fill=255)
g.f.polygon([(256,0),(325,115),(256,150),(187,115)],fill=255)
g.f.rectangle([190,150,322,185],fill=255)
done(g,"cream","B24SPGRD")

# B24MHWRD Mass Healing Word: three of the Healing Word crosses
g=Glyph()
for dx,dy in [(0,-125),(-128,115),(128,115)]:
    winged_cross(g,0.54,dx,dy,False)
done(g,"teal","B24MHWRD")

# B24CACID Acid Splash: bursting blob with a crown of droplets
g=Glyph()
ell(g.f,256,360,170,115)
for a in range(-165,-10,30):
    ca,sa=math.cos(R(a)),math.sin(R(a))
    g.f.polygon([(256+ca*120-sa*45,340+sa*80+ca*45),(256+ca*230,330+sa*230),(256+ca*120+sa*45,340+sa*80-ca*45)],fill=255)
for x,y,r in [(65,110,34),(447,110,34),(256,40,36),(150,55,26),(362,55,26)]: ell(g.f,x,y,r)
g.l.ellipse([150,300,230,360],fill=255)
g.c.ellipse([280,380,350,440],fill=255)
done(g,"red","B24CACID")

# B24CCHIL Chill Touch: skeletal hand reaching up
g=Glyph()
g.f.polygon([(130,240),(390,240),(360,370),(160,370)],fill=255)        # palm
g.f.rectangle([190,395,245,505],fill=255); g.f.rectangle([275,395,330,505],fill=255)  # forearm bones
for x,top in [(150,80),(230,25),(310,35),(390,95)]:
    for y0,y1 in [(top,top+70),(top+90,250)]:
        g.f.rounded_rectangle([x-27,y0,x+27,y1],radius=18,fill=255)
        ell(g.f,x,y1,30)
g.f.polygon([(150,340),(70,250),(40,190),(85,170),(135,230),(190,290)],fill=255)  # thumb
g.c.line([(110,305),(420,305)],fill=255,width=34)
for x,top in [(150,80),(230,25),(310,35),(390,95)]: g.c.line([(x-32,top+80),(x+32,top+80)],fill=255,width=32)
done(g,"red","B24CCHIL")

# B24CFIRE Fire Bolt: fireball streaking diagonally with fat flame trail
g=Glyph()
ell(g.f,345,345,125)
g.f.polygon([(20,20),(230,140),(255,215),(140,110),(130,170),(215,265),(100,215),(205,320),(255,400),(140,330),(180,260),(70,140),(265,250),(290,240)],fill=255)
g.f.polygon([(20,20),(330,230),(240,330)],fill=255)
g.f.polygon([(150,20),(380,230),(290,240)],fill=255)
g.f.polygon([(20,150),(260,380),(230,290)],fill=255)
g.l.ellipse([300,300,390,390],fill=255)
done(g,"red","B24CFIRE")

# B24CPOIS Poison Spray: jet widening into a toxic cloud, drops falling
g=Glyph()
g.f.polygon([(20,492),(190,260),(260,330)],fill=255)
for x,y,r in [(230,250,90),(330,190,100),(250,130,80),(400,120,80),(420,260,75),(330,60,60)]:
    ell(g.f,x,y,r)
for x,y,r in [(240,140,40),(400,110,40),(320,220,45)]:
    g.l.ellipse([x-r,y-r,x+r,y+r],fill=255)
for x,y in [(330,420),(440,400),(390,480)]:
    g.f.polygon([(x,y-55),(x-28,y),(x+28,y)],fill=255); ell(g.f,x,y,28)
done(g,"red","B24CPOIS")

# B24CFROS Ray of Frost: beam ending in a big snowflake
g=Glyph()
g.f.line([(20,492),(230,282)],fill=255,width=56)
cx,cy=310,200
for k in range(6):
    a=R(k*60+15); ca,sa=math.cos(a),math.sin(a)
    g.f.line([(cx,cy),(cx+ca*190,cy+sa*190)],fill=255,width=44)
    bx,by=cx+ca*115,cy+sa*115
    for b in (50,-50):
        ba=a+R(b); g.f.line([(bx,by),(bx+math.cos(ba)*80,by+math.sin(ba)*80)],fill=255,width=34)
ell(g.f,cx,cy,55)
g.c.ellipse([cx-24,cy-24,cx+24,cy+24],fill=255)
done(g,"red","B24CFROS")

# B24CSHOC Shocking Grasp: clawed grasping hand with lightning bolts
g=Glyph()
g.f.rounded_rectangle([150,270,350,430],radius=50,fill=255)
g.f.polygon([(200,420),(310,420),(300,505),(210,505)],fill=255)
for x,top,lean in [(165,190,-30),(225,160,-8),(285,165,8),(340,200,30)]:
    g.f.polygon([(x-27,300),(x-22+lean*0.5,top+40),(x+lean,top),(x+22+lean*0.5,top+40),(x+27,300)],fill=255)
g.f.polygon([(160,380),(80,320),(70,270),(110,280),(185,340)],fill=255)
for p in [[(220,0),(270,60),(215,85),(260,140)],[(50,40),(120,85),(80,115),(150,160)],[(470,40),(400,85),(440,115),(370,165)],[(500,250),(430,240),(450,290),(390,300)]]:
    g.f.line(p,fill=255,width=38,joint="curve")
done(g,"red","B24CSHOC")

# B24CBURS Sorcerous Burst: 8-point starburst explosion around a hollow orb
g=Glyph()
g.f.polygon(star(256,256,250,110,8,-90),fill=255)
g.f.polygon(star(256,256,190,120,8,-67.5),fill=255)
g.c.ellipse([186,186,326,326],fill=255)
ell(g.f,256,256,45)
done(g,"red","B24CBURS")

# B24CSACR Sacred Flame: holy flame with a cross cut into it
g=Glyph()
g.f.polygon(flame(256,490,480,215),fill=255)
g.c.polygon(cross(256,340,85,46),fill=255)
done(g,"cream","B24CSACR")

# B24CTOLL Toll the Dead: tolling bell with sound arcs
g=Glyph()
g.f.polygon([(150,370),(165,180),(200,110),(256,90),(312,110),(347,180),(362,370),(420,420),(92,420)],fill=255)
g.f.ellipse([226,40,286,100],fill=255); g.c.ellipse([244,58,268,82],fill=0)
ell(g.f,256,450,42)
g.d.line([(150,375),(362,375)],fill=255,width=22)
for sg in (-1,1):
    for r in (175,235):
        a0=-35 if sg>0 else 145
        g.f.arc([256-r,250-r,256+r,250+r],a0,a0+70,fill=255,width=30)
done(g,"red","B24CTOLL")

# B24CWORD Word of Radiance: holy disc radiating a ring of rays
g=Glyph()
for i in range(12):
    a=R(i*30-90); ca,sa=math.cos(a),math.sin(a); n=(-sa,ca)
    w=55 if i%2==0 else 42; L=256 if i%2==0 else 215
    g.f.polygon([(256+ca*140+n[0]*w,256+sa*140+n[1]*w),(256+ca*L,256+sa*L),(256+ca*140-n[0]*w,256+sa*140-n[1]*w)],fill=255)
ell(g.f,256,256,160)
g.c.ellipse([144,144,368,368],fill=255)
ell(g.f,256,256,80)
done(g,"cream","B24CWORD")

# B24CFLAM Produce Flame: cupped palm with a flame resting on it
g=Glyph()
g.f.polygon(flame(256,320,310,150,10),fill=255)
g.l.polygon(flame(256,310,170,70,0),fill=255)
g.f.polygon([(40,300),(110,310),(150,340),(360,340),(410,320),(470,260),(500,290),(440,390),(380,430),(150,430),(70,380)],fill=255)
g.f.polygon([(150,430),(360,430),(330,500),(180,500)],fill=255)
g.d.line([(150,340),(400,340)],fill=255,width=20)
g.d.line([(110,380),(230,380)],fill=255,width=16)
done(g,"red","B24CFLAM")

# B24CTHRN Thorn Whip: S-curving thorny vine lash
g=Glyph()
pts=[]
for i in range(41):
    t=i/40; y=480-t*430; x=256+math.sin(t*math.pi*2.0)*140*(0.6+0.4*t)
    pts.append((x,y))
g.f.line(pts,fill=255,width=60,joint="curve")
for i in range(4,40,5):
    (x0,y0),(x1,y1)=pts[i-1],pts[i+1]
    dx,dy=x1-x0,y1-y0; L=math.hypot(dx,dy); dx,dy=dx/L,dy/L
    x,y=pts[i]; sg=1 if (i//5)%2 else -1
    nx,ny=-dy*sg,dx*sg
    g.f.polygon([(x-dx*45,y-dy*45),(x+nx*100+dx*20,y+ny*100+dy*20),(x+dx*35,y+dy*35)],fill=255)
g.f.polygon([(pts[-1][0]-60,pts[-1][1]+10),(pts[-1][0]+20,0),(pts[-1][0]+40,pts[-1][1]+30)],fill=255)
done(g,"red","B24CTHRN")

# B24CWISP Starry Wisp: a big four-point star with a trail of star motes
g=Glyph()
g.f.polygon(star(320,190,190,62,4,-90),fill=255)
g.f.polygon(star(320,190,90,40,4,-45),fill=255)
g.f.polygon(star(150,350,75,30,4,-90),fill=255)
g.f.polygon(star(60,450,50,24,4,-90),fill=255)
g.d.ellipse([295,165,345,215],fill=255)
done(g,"cream","B24CWISP")

# B24CMOCK Vicious Mockery: grinning jester face with three-point cap
g=Glyph()
g.f.polygon([(100,250),(40,150),(10,60),(140,140),(256,10),(372,140),(502,60),(472,150),(412,250)],fill=255)
for x,y in [(20,60),(256,15),(492,60)]: ell(g.f,x,y,36)
g.f.ellipse([95,190,417,500],fill=255)
g.d.line([(100,250),(412,250)],fill=255,width=26)
g.c.polygon([(140,300),(235,330),(220,360),(160,350)],fill=255)       # slanted mocking eyes
g.c.polygon([(372,300),(277,330),(292,360),(352,350)],fill=255)
g.c.chord([130,280,382,470],0,180,fill=255)                          # wide grin (crescent)
g.f.chord([150,240,362,420],0,180,fill=255)
done(g,"red","B24CMOCK")

preview(out,"/home/claude/preview/batchC.png")
cols=8; rows=(len(out)+cols-1)//cols
Z=Image.new("RGB",(cols*272,rows*272),(212,163,110))
for i,(n,ic) in enumerate(out):
    b=ic.resize((256,256),Image.NEAREST); Z.paste(b,((i%cols)*272+8,(i//cols)*272+8),b)
Z.save("/home/claude/preview/batchC_zoom.png")
print([n for n,_ in out])
