import sys,math; sys.path.insert(0,"/home/claude")
from glyph import *
out=[]
def done(g,c,n): out.append((n,g.render(c,n)))

# 2 Battle Medic
g=Glyph()
g.f.rounded_rectangle([70,170,442,450],radius=44,fill=255)
g.f.polygon([(70,200),(256,110),(442,200)],fill=255)
g.f.arc([170,40,342,200],180,360,fill=255,width=36)
g.c.polygon([(216,225),(296,225),(296,280),(356,280),(356,350),(296,350),(296,410),(216,410),(216,350),(156,350),(156,280),(216,280)],fill=255)
g.d.line([(70,205),(442,205)],fill=255,width=18)
done(g,"teal","B24HEALR")

# 3 Healing Hands: open palm, fingers up, cross of light in the palm, rays from the fingertips
g=Glyph()
g.f.rounded_rectangle([140,230,380,470],radius=70,fill=255)              # palm
for i,(x,top) in enumerate([(170,120),(232,70),(294,80),(352,130)]):
    g.f.rounded_rectangle([x-30,top,x+30,300],radius=30,fill=255)        # fingers
g.f.polygon([(150,330),(60,240),(85,210),(185,290)],fill=255)            # thumb
g.c.polygon([(240,290),(280,290),(280,325),(315,325),(315,365),(280,365),(280,400),(240,400),(240,365),(205,365),(205,325),(240,325)],fill=255)
for i in range(3): g.c.line([(201+i*62,150),(201+i*62,270)],fill=255,width=14)
for p in [[(262,10),(262,45)],[(140,40),(160,75)],[(390,50),(365,85)]]:
    g.f.line(p,fill=255,width=26)
done(g,"teal","B24HEALH")

# 4 Fire's Burn
g=Glyph(); fist(g,0.92,0,85)
for x,h,lean in [(130,200,-40),(256,290,10),(382,210,40)]:
    g.f.polygon([(x-85,280),(x-80,280-h*0.45),(x-40,280-h*0.75),(x+lean,280-h),(x+40,280-h*0.6),(x+80,280-h*0.35),(x+85,280)],fill=255)
g.f.rectangle([60,200,452,280],fill=255)
g.l.polygon([(200,270),(215,180),(250,130),(270,190),(300,170),(312,270)],fill=255)
done(g,"red","B24GLFIR")

# 5 Frost's Chill
g=Glyph(); fist(g,0.92,0,95)
for ang,L in [(-55,230),(0,265),(55,230)]:
    a=math.radians(ang-90); c=(256,280)
    tip=(c[0]+math.cos(a)*L,c[1]+math.sin(a)*L); n=(math.cos(a+1.57)*62,math.sin(a+1.57)*62)
    g.f.polygon([(c[0]+n[0],c[1]+n[1]),tip,(c[0]-n[0],c[1]-n[1])],fill=255)
    g.l.line([c,((c[0]+tip[0])/2,(c[1]+tip[1])/2)],fill=255,width=22)
done(g,"red","B24GLFRO")

# 6 Hill's Tumble
g=Glyph(); fist(g,0.95,0,-35)
g.f.polygon([(30,420),(482,420),(460,480),(52,480)],fill=255)
g.c.polygon([(256,420),(226,480),(286,480)],fill=255)
for x,y,r in [(75,330,30),(437,320,28),(60,230,20),(452,215,20)]:
    g.f.ellipse([x-r,y-r,x+r,y+r],fill=255)
done(g,"red","B24GLHIL")

# 7 Stone's Endurance: cracked stone fist, chips flying
g=Glyph(); fist(g,1.05,0,10)
g.c.line([(180,270),(220,310),(205,345)],fill=255,width=11); g.c.line([(335,265),(345,300),(372,315)],fill=255,width=11)
for p in [[(40,110),(95,90),(110,150)],[(420,60),(480,95),(440,140)],[(30,300),(80,280),(70,340)],[(445,330),(495,345),(465,395)]]:
    g.f.polygon(p,fill=255)
done(g,"teal","B24GLSTO")

# 8 Storm's Thunder
g=Glyph(); fist(g,0.85,-60,100)
g.f.polygon([(270,10),(440,10),(350,150),(470,150),(220,330),(285,200),(180,200)],fill=255)
g.l.polygon([(300,40),(395,40),(320,170),(410,170),(290,260),(320,180)],fill=255)
done(g,"red","B24GLSTM")

# 9 Short Rest: big campfire on crossed logs, crescent moon
g=Glyph()
g.f.polygon([(40,400),(90,360),(472,450),(432,495)],fill=255); g.f.polygon([(472,400),(422,360),(40,450),(80,495)],fill=255)
g.f.polygon([(110,400),(120,300),(170,330),(185,220),(240,250),(270,90),(320,230),(360,190),(385,300),(400,400)],fill=255)
g.l.polygon([(190,400),(200,330),(240,345),(265,240),(300,330),(325,310),(330,400)],fill=255)
g.f.ellipse([340,20,480,160],fill=255); g.c.ellipse([305,5,450,140],fill=255)
done(g,"teal","B24SREST")

preview(out,"/home/claude/preview/batch1.png")
# 8x inspection sheet
Z=Image.new("RGB",(len(out)*272,272),(212,163,110))
for i,(n,ic) in enumerate(out):
    b=ic.resize((256,256),Image.NEAREST); Z.paste(b,(i*272+8,8),b)
Z.save("/home/claude/preview/batch1_zoom.png")
