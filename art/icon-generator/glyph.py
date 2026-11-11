"""Render BG-style spellbook glyphs: one color family, transparent background, 32x32."""
import numpy as np
from PIL import Image, ImageDraw
SS=512; N=32; K=SS//N
PAL={ # (shadow, base, highlight)
 "red":  ((150,45,40),(205,80,68),(240,150,110)),
 "teal": ((0,58,66),(0,92,102),(40,135,140)),
 "cream":((190,160,125),(240,225,200),(255,250,238)),
}
class Glyph:
    def __init__(s):
        s.fill=Image.new("L",(SS,SS),0); s.f=ImageDraw.Draw(s.fill)       # body
        s.cut=Image.new("L",(SS,SS),0); s.c=ImageDraw.Draw(s.cut)         # holes
        s.dark=Image.new("L",(SS,SS),0); s.d=ImageDraw.Draw(s.dark)       # dark details
        s.lite=Image.new("L",(SS,SS),0); s.l=ImageDraw.Draw(s.lite)       # light details
    def render(s,color,name,outline=True):
        def m(im,t=0.5): return np.array(im.resize((N,N),Image.BOX),float)/255>t
        body=m(s.fill)&~m(s.cut,0.45)
        sh,ba,hi=[np.array(c) for c in PAL[color]]
        out=np.zeros((N,N,4),np.uint8)
        rgb=np.zeros((N,N,3)); rgb[:]=ba
        # emboss: light on top-left edges, shadow on bottom-right edges
        pad=np.pad(body,1)
        tl=~pad[:-2,1:-1]|~pad[1:-1,:-2]          # neighbour above or left is empty
        br=~pad[2:,1:-1]|~pad[1:-1,2:]            # neighbour below or right is empty
        if outline:
            rgb[body&br]=sh
            rgb[body&tl&~br]=hi*0.6+ba*0.4
        rgb[m(s.dark,0.4)&body]=sh
        rgb[m(s.lite,0.4)&body]=hi
        out[...,:3]=rgb.astype(np.uint8); out[...,3]=body*255
        im=Image.fromarray(out,"RGBA")
        im.resize((64,64),Image.NEAREST).save(f"/home/claude/art/icons/{name}.png")
        return im
def preview(icons,path,paper="/mnt/user-data/attachments/b345eaf1-a086-5a99-ada4-9e6d57703395/d628d930-image.png"):
    """icons: list of (name, 32px RGBA). Shows them on papyrus at 1x and 4x next to vanilla icons."""
    src=Image.open(paper).convert("RGB")
    vanilla=src.crop((8,22,248,250))           # 4x4 vanilla icons
    tile=src.crop((800,190,1010,330))          # empty papyrus
    W=(520+len(icons)*140+40)//2
    P=Image.new("RGB",(W*2,560),(30,30,30))
    big=vanilla.resize((480,456),Image.NEAREST); P.paste(big,(0,0))
    bg=tile.resize((W*2-500,456)); P.paste(bg,(500,0))
    for i,(n,ic) in enumerate(icons):
        b=ic.resize((96,96),Image.NEAREST); P.paste(b,(530+i*140,40),b)
        P.paste(ic,(568+i*140,220),ic)
        P.paste(ic.resize((64,64),Image.NEAREST),(552+i*140,280),ic.resize((64,64),Image.NEAREST))
    # same on stone (spell-caster rune bar)
    for i,(n,ic) in enumerate(icons):
        P.paste(Image.new("RGB",(48,48),(45,40,36)),(560+i*140,470)); P.paste(ic,(568+i*140,478),ic)
    P.save(path)

def T(pts,s=1.0,dx=0,dy=0,cx=256,cy=256):
    return [((x-cx)*s+cx+dx,(y-cy)*s+cy+dy) for x,y in pts]
def fist(g,s=1.0,dx=0,dy=0,stone=False):
    """front view of a clenched fist, knuckles up"""
    t=lambda p:T(p,s,dx,dy)
    for i in range(4):
        x=170+i*57; g.f.ellipse([*t([(x-34,165)])[0],*t([(x+34,235)])[0]],fill=255)
    g.f.rounded_rectangle([*t([(138,195)])[0],*t([(372,345)])[0]],radius=int(40*s),fill=255)
    g.f.polygon(t([(190,340),(330,340),(320,470),(200,470)]),fill=255)          # wrist
    w=max(6,int(16*s))
    for i in range(3):                                                           # finger gaps
        x=198+i*57; g.d.line(t([(x,175),(x,255)]),fill=255,width=w)
    g.d.line(t([(150,285),(300,285),(330,262)]),fill=255,width=w)                # thumb over fingers
    g.d.line(t([(200,345),(320,345)]),fill=255,width=w)
