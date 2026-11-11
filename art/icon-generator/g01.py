import sys; sys.path.insert(0,"/home/claude")
from glyph import *
g=Glyph()
head=[(256,55),(325,68),(380,112),(405,180),(410,260),(398,335),(372,400),(320,450),(256,468),(192,450),(140,400),(114,335),(102,260),(107,180),(132,112),(187,68)]
g.f.polygon(head,fill=255)
g.f.polygon([(112,200),(40,150),(108,265)],fill=255); g.f.polygon([(400,200),(472,150),(404,265)],fill=255)
# heavy brow as a dark band, eyes cut below it
g.d.polygon([(130,190),(256,215),(382,190),(375,215),(256,240),(137,215)],fill=255)
g.c.polygon([(150,230),(228,252),(222,280),(160,265)],fill=255)
g.c.polygon([(362,230),(284,252),(290,280),(352,265)],fill=255)
g.d.polygon([(236,270),(276,270),(292,318),(220,318)],fill=255)   # nose
# smaller snarling mouth
g.c.polygon([(180,350),(256,338),(332,350),(318,405),(256,418),(194,405)],fill=255)
# big tusks from lower jaw, past the upper lip
g.f.polygon([(176,420),(222,420),(196,300)],fill=255); g.f.polygon([(290,420),(336,420),(316,300)],fill=255)
ic=g.render("red","B24ADREN")
preview([("B24ADREN",ic)],"/home/claude/preview/sheet.png")
