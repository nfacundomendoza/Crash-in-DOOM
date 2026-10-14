from pathlib import Path
import sys,struct,math
import numpy as np
from PIL import Image,ImageDraw
import export_crash as e
names=['WD10V','WD20V','WD30V','BN10V','BA10V','BT10V','BE10V','BC10V','BS10V','BD10V','BT20V','BF10V']
last='--last' in sys.argv
if len(sys.argv)>1:names=[n for n in sys.argv[1:] if n!='--last']
sheet=Image.new('RGB',(1000,750),(35,40,45));draw=ImageDraw.Draw(sheet)
for index,name in enumerate(names):
    frame=e.entries[e.byname[name]][-1 if last else 0];geo=struct.unpack_from('<I',frame,4)[0]
    inds,uv,scale=e.mesh(geo);v=e.vertices(frame,scale)
    v-=((v.min(axis=0)+v.max(axis=0))/2)
    x=v[:,0]*.75-v[:,2]*.66;y=v[:,1]*.93+(v[:,0]*.66+v[:,2]*.75)*.36
    depth=v[:,0]*.66+v[:,2]*.75-v[:,1]*.36
    factor=175/max(np.ptp(x),np.ptp(y));origin=(index%4*250+125,index//4*250+125)
    xy=np.column_stack((x*factor+origin[0],-y*factor+origin[1]))
    atlas=np.asarray(Image.open(e.OUT/(e.name(geo)+'.png')))
    for tri in np.argsort(depth[inds].mean(axis=1)):
        coords=(uv[tri].mean(axis=0)*1024).astype(int)
        col=tuple(atlas[coords[1],coords[0],:3]);draw.polygon([tuple(p) for p in xy[inds[tri]]],fill=col)
    draw.text((index%4*250+15,index//4*250+220),name+' / '+e.name(geo),fill='white')
sheet.save(e.PROJECT/'verification/resources.png')
