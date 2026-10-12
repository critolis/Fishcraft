"""Generate original vector-style Fishcraft UI textures. Requires Pillow.

No game or reference-image pixels are copied. TGA textures are uncompressed RGBA,
power-of-two dimensions, so WoW can load them directly.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import math

ROOT = Path(__file__).resolve().parents[1]
MEDIA = ROOT / 'Media'
MEDIA.mkdir(exist_ok=True)
S = 4
def canvas():
    im = Image.new('RGBA', (128*S, 128*S))
    return im, ImageDraw.Draw(im)
def ellipse(d, box, fill, outline=None, width=1):
    d.ellipse(tuple(v*S for v in box), fill, outline, width*S)
def save(im, name):
    im = im.resize((128, 128), Image.Resampling.LANCZOS)
    im.save(MEDIA / (name + '.tga'))
    return im
orb, d = canvas()
ellipse(d, (3, 3, 125, 125), (0, 0, 0, 100))
ellipse(d, (8, 8, 120, 120), (11, 19, 24, 255))
for r in range(52, 0, -1):
    t = 1-r/52
    ellipse(d, (64-r, 64-r, 64+r, 64+r), (int(14+6*t), int(34+14*t), int(44+17*t), 255))
for r in (41, 46, 50):
    d.arc(tuple(v*S for v in (64-r,64-r,64+r,64+r)), 194, 274, (111,143,150,50), S)
save(orb, 'Orb')
rim, d = canvas()
for r, width, color in [(57,5,(37,25,14,255)),(56,2,(190,141,64,255)),(52,2,(77,53,28,255)),(50,1,(231,195,123,255)),(60,1,(86,62,30,255))]:
    ellipse(d, (64-r,64-r,64+r,64+r), None, color, width)
d.arc(tuple(v*S for v in (8,8,120,120)), 192, 286, (255,226,163,255), 2*S)
d.arc(tuple(v*S for v in (8,8,120,120)), 15, 102, (81,49,20,255), 2*S)
for angle in range(0,360,90):
    a=math.radians(angle)
    points=[]
    for r, da in [(63,0),(57,-4),(53,0),(57,4)]:
        aa=a+math.radians(da); points.append(((64+math.cos(aa)*r)*S,(64+math.sin(aa)*r)*S))
    d.polygon(points, fill=(201,164,91,255))
save(rim, 'Rim')
hook, d = canvas()
# Fishing hook follows a clean, recognizable J silhouette at small sizes.
path=[(77,29),(76,42),(73,57),(69,76),(64,91),(54,98),(44,96),(36,88),(34,76),(37,66)]
d.line([(x*S,y*S) for x,y in path], fill=(75,43,12,255), width=11*S, joint='curve')
d.line([(x*S,y*S) for x,y in path], fill=(227,173,70,255), width=7*S, joint='curve')
d.line([((x-1)*S,(y-1)*S) for x,y in path], fill=(255,226,151,255), width=2*S, joint='curve')
ellipse(d,(68,13,88,33),None,(222,172,78,255),5)
ellipse(d,(71,16,85,30),None,(255,225,155,255),1)
d.polygon([(37*S,61*S),(32*S,80*S),(46*S,72*S)],fill=(237,193,100,255))
save(hook,'Hook')
glow,d=canvas()
ellipse(d,(8,8,120,120),None,(255,199,90,210),4)
glow=glow.filter(ImageFilter.GaussianBlur(3*S)); save(glow,'Glow')
dot,d=canvas();ellipse(d,(12,12,116,116),(255,255,255,255));save(dot,'Dot')
play,d=canvas()
d.polygon([(28*S,15*S),(112*S,64*S),(28*S,113*S)],fill=(100,223,122,255))
save(play,'SessionStart')
stop,d=canvas()
d.rectangle((25*S,25*S,103*S,103*S),fill=(239,98,98,255))
save(stop,'SessionStop')
# Statistics use semantic line symbols instead of unrelated inventory art.
INK=(232,199,138,255)
def line(d,points,width=7,color=INK):
    d.line([(x*S,y*S) for x,y in points],fill=color,width=width*S,joint='curve')
def clock(d,cx=64,cy=64,r=44,width=7):
    ellipse(d,(cx-r,cy-r,cx+r,cy+r),None,INK,width)
    line(d,[(cx,cy-r*.60),(cx,cy),(cx+r*.42,cy+r*.28)],width)
def fish(d,x=14,y=33,w=100,h=62):
    # Outlined body and tail remain legible at the 32 px card size.
    pts=[(x+w*.70,y+h*.50),(x+w,y),(x+w,y+h),(x+w*.70,y+h*.50)]
    line(d,pts,6)
    ellipse(d,(x,y,x+w*.76,y+h),None,INK,6)
    ellipse(d,(x+w*.18,y+h*.29,x+w*.25,y+h*.41),INK)

im,d=canvas();clock(d);save(im,'StatTime')
im,d=canvas();fish(d);save(im,'StatFish')
im,d=canvas();ellipse(d,(16,16,112,112),None,INK,7)
line(d,[(34,65),(55,85),(94,44)],9);save(im,'StatSuccess')
im,d=canvas();fish(d,10,22,84,50)
ellipse(d,(60,60,120,120),(11,19,24,255));clock(d,90,90,26,5);save(im,'StatRate')
im,d=canvas();clock(d,64,73,39,7)
line(d,[(51,13),(77,13)],8);line(d,[(64,13),(64,31)],7)
line(d,[(94,34),(103,25)],7);save(im,'StatStopwatch')
im,d=canvas()
d.rounded_rectangle((20*S,16*S,108*S,112*S),radius=8*S,outline=INK,width=7*S)
line(d,[(40,19),(40,109)],5)
for y in (43,64,85):line(d,[(53,y),(91,y)],5)
save(im,'StatSessions')
im,d=canvas()
line(d,[(15,79),(15,16),(93,16)],6)
line(d,[(26,90),(26,28),(105,28)],6)
d.rounded_rectangle((37*S,41*S,119*S,110*S),radius=6*S,outline=INK,width=6*S)
fish(d,47,59,60,34);save(im,'StatCollection')
im,d=canvas();line(d,[(26,43),(64,81),(102,43)],10);save(im,'ChevronDown')
print('Built 15 original 128 × 128 RGBA TGA textures.')
