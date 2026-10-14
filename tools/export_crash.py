"""Convert the user's original PS1 Crash geometry/frames/textures to MD3."""
from pathlib import Path
import struct,re,json,math,hashlib
import numpy as np
from PIL import Image
PROJECT=Path(__file__).resolve().parents[1]
ROOT=PROJECT.parent
SRC=PROJECT/'desarrollo/c1/streams'
OUT=PROJECT/'mod/models/crash';OUT.mkdir(parents=True,exist_ok=True)
alpha='0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_!'
def name(eid):
    eid>>=1;s=''
    for _ in range(5):s=alpha[eid&63]+s;eid>>=6
    return s
entries={};pages={};origins={};kinds={}
for nsd in sorted(SRC.glob('*.nsd')):
    nsf=nsd.with_suffix('.nsf')
    if not nsf.exists():continue
    header=nsd.read_bytes();count=struct.unpack_from('<I',header,1024)[0]
    start=struct.unpack_from('<I',header,1048)[0]*2048
    raw=nsf.read_bytes()
    for p in range(count):
        page=raw[start+p*65536:start+(p+1)*65536]
        if len(page)!=65536:continue
        magic,typ,eid,n=struct.unpack_from('<HHII',page)
        if magic!=0x1234:continue
        if typ==1:
            pages.setdefault(eid,page);continue
        if n>256:continue
        offsets=struct.unpack_from('<'+'I'*(n+1),page,16)
        for a,b in zip(offsets,offsets[1:]):
            entry=page[a:b]
            if len(entry)<20 or struct.unpack_from('<I',entry)[0]!=0x100ffff:continue
            _,eid,kind,num=struct.unpack_from('<4I',entry)
            label=name(eid)
            kinds.setdefault(label,kind)
            offs=struct.unpack_from('<'+'I'*(num+1),entry,16)
            entries.setdefault(eid,[entry[x:y] for x,y in zip(offs,offs[1:])]);origins.setdefault(label,str(nsf.relative_to(ROOT)))
byname={name(e):e for e in entries}
uvtext=(PROJECT/'desarrollo/c1/src/gfx.c').read_text()
uvtext=uvtext.split('uv_map[600] = {',1)[1].split('};',1)[0]
uv=np.array([list(map(int,re.findall(r'\d+',line))) for line in uvtext.splitlines() if '{ {' in line],dtype=int).reshape(600,4,2)
def color(v):return ((v&31)*255//31,((v>>5)&31)*255//31,((v>>10)&31)*255//31,0 if v==0 else 255)
def material(head,index):
    at=20+index*4;col=struct.unpack_from('<I',head,at)[0]
    if not col&0x80000000:
        rgb=tuple(head[at:at+3]);return Image.new('RGBA',(1,1),rgb+(255,)),np.zeros((3,2))
    pageid,rgn=struct.unpack_from('<2I',head,at+4)
    data=pages[pageid];mode=(rgn>>20)&3
    if mode>2:raise ValueError('Unexpected texture color mode')
    quad=uv[rgn>>22][:3];w,h=quad.max(axis=0)+1
    pp=8>>mode;width=1024>>mode
    ox=(((rgn>>18)&3)*32+((rgn>>13)&31))*pp;oy=(rgn&31)*4
    cx=(col>>24)&15;cy=(rgn>>6)&127
    pal=struct.unpack_from('<'+'H'*(16 if mode==0 else 256),data,cy*512+cx*32) if mode<2 else None
    im=Image.new('RGBA',(int(w),int(h)));px=im.load()
    for y in range(int(h)):
        for x in range(int(w)):
            i=(oy+y)*width+ox+x
            if mode==0:idx=(data[i//2]>>(4*(i&1)))&15;v=pal[idx]
            elif mode==1:v=pal[data[i]]
            else:v=struct.unpack_from('<H',data,i*2)[0]
            px[x,y]=color(v)
    # PS1 textured polygons modulate the palette by their original material RGB.
    # Neutral is 128; this carries Aku Aku's colored feathers, among other tints.
    rgba=np.asarray(im).copy()
    tint=np.array(list(head[at:at+3]),float)/128
    rgba[:,:,:3]=np.clip(rgba[:,:,:3].astype(float)*tint,0,255).astype(np.uint8)
    im=Image.fromarray(rgba)
    return im,quad
def mesh(geo):
    items=entries[geo];head=items[0];count,sx,sy,sz,tc=struct.unpack_from('<I3iI',head)
    polys=np.array([struct.unpack_from('<4H',items[1],i*8) for i in range(count)],dtype=int)
    indices=polys[:,:3]//6;mats=polys[:,3]&0x7fff
    atlas=Image.new('RGBA',(1024,1024));coords=np.zeros((count,3,2),dtype=float)
    for j,index in enumerate(sorted(set(mats))):
        im,q=material(head,int(index));x=(j%14)*72+2;y=(j//14)*72+2
        if y+im.height>1024:raise ValueError('Atlas too small')
        atlas.paste(im,(x,y));sel=mats==index
        coords[sel]=(q+np.array([x+.5,y+.5]))/1024
    atlas.save(OUT/f'{name(geo)}.png')
    return indices,coords,np.array([sx,sy,sz],float)/4096
def vertices(frame,scale):
    x,y,z=struct.unpack_from('<3i',frame,8)
    n=(len(frame)-56)//6
    verts=np.frombuffer(frame,dtype=np.uint8,count=n*6,offset=56).reshape(n,6)[:,:3].astype(float)
    verts=(verts+np.array([x-128,y-128,z-128]))*4*scale
    return verts
def md3(path,frames,indices,coords,skin):
    # Duplicate triangle corners to preserve the original independent UVs.
    fi=indices.flatten();nv=len(fi);nf=len(frames);nt=len(indices)
    assert nv<4096 and nf<1024
    triangle=np.arange(nv).reshape(nt,3)
    offsets=[108,108+nt*12,108+nt*12+68,108+nt*12+68+nv*8]
    size=offsets[3]+nf*nv*8
    surface=struct.pack('<4s64s10i',b'IDP3',b'crash',0,nf,1,nv,nt,*offsets,size)
    surface+=triangle.astype('<i4').tobytes()+struct.pack('<64si',skin.encode(),0)+coords.astype('<f4').tobytes()
    bounds=[]
    for i,v in enumerate(frames):
        faces=v[indices];normal=np.cross(faces[:,1]-faces[:,0],faces[:,2]-faces[:,0]);length=np.linalg.norm(normal,axis=1)
        normal/=np.maximum(length,1e-8)[:,None];normal=np.repeat(normal,3,axis=0)
        lat=np.arctan2(normal[:,1],normal[:,0])*255/(2*math.pi)
        lng=np.arccos(np.clip(normal[:,2],-1,1))*255/(2*math.pi)
        packed=((lat.astype(int)&255)<<8)|(lng.astype(int)&255)
        pos=np.rint(v[fi]*64).astype('<i2')
        buf=np.empty((nv,8),np.uint8);buf[:,:6]=pos.view(np.uint8).reshape(nv,6);buf[:,6:]=packed.astype('<u2').view(np.uint8).reshape(nv,2)
        surface+=buf.tobytes()
        bounds.append(struct.pack('<10f16s',*v.min(axis=0),*v.max(axis=0),0,0,0,float(np.linalg.norm(v,axis=1).max()),f'frame{i}'.encode()))
    frameoff=108;tagoff=frameoff+nf*56;surfoff=tagoff;end=surfoff+len(surface)
    header=struct.pack('<4si64s9i',b'IDP3',15,b'original_crash',0,nf,0,1,0,frameoff,tagoff,surfoff,end)
    path.write_bytes(header+b''.join(bounds)+surface)
manifest={'source':'Original USA Crash Bandicoot assets supplied by user','animations':{},'sources':origins}
# Convert every original main-mesh action into a single morph animation file.
actions=[('idle','WiS1V',[11,12]),('walk','WiWaV',None),('jump','WiJuV',None),('fall','WiJSV',None),('land','WiTSV',None),('death','WiK2V',None),('spin','WiBlV',None)]+[(f'dance{i}',f'WiS{i}V',None) for i in range(2,7)]
assets=[]
for action,label,selection in actions:
    frames=entries[byname[label]];geo=struct.unpack_from('<I',frames[0],4)[0]
    inds,coords,scale=mesh(geo)
    selection=selection or list(range(len(frames)))
    vv=[vertices(frames[i],scale) for i in selection]
    assets.append((action,geo,inds,coords,vv))
idle=assets[0][4][0];floor=idle[:,1].min();factor=52/(idle[:,1].max()-floor)
normal_frames=[]
for action,geo,inds,coords,vv in assets:
    converted=[]
    for v in vv:
        # PS1 Y is vertical. Original Crash faces toward negative Z.
        new=np.column_stack((-v[:,2],v[:,0],v[:,1]-floor))*factor
        converted.append(new)
    if action=='jump':
        # The PS1 engine rotates the entire character during the forward flip.
        # Bake this transform around the body's center into the original poses.
        for i,v in enumerate(converted):
            angle=-2*math.pi*max(0,min(1,(i-2)/12))
            c,s=math.cos(angle),math.sin(angle)
            x=v[:,0].copy();z=v[:,2].copy()-26
            v[:,0]=x*c+z*s;v[:,2]=-x*s+z*c+26
    if action=='death':
        for i,v in enumerate(converted):
            angle=4*math.pi*min(i/14,1);c,s=math.cos(angle),math.sin(angle)
            xy=v[:,:2].copy();v[:,0]=xy[:,0]*c-xy[:,1]*s;v[:,1]=xy[:,0]*s+xy[:,1]*c
            # Finish the original stagger/spin poses with the whole-body collapse.
            fall=(math.pi/2)*max(0,min(1,(i-14)/5));c,s=math.cos(fall),math.sin(fall)
            x=v[:,0].copy();z=v[:,2].copy()
            v[:,0]=x*c+z*s;v[:,2]=-x*s+z*c
            if i>14:v[:,2]-=v[:,2].min()
    if action=='spin':
        # The original engine rotates the whole spin mesh. Bake that visual rotation
        # into its morph frames without rotating the player's input/collision hull.
        for i,v in enumerate(converted):
            angle=i*math.pi/4;c,s=math.cos(angle),math.sin(angle)
            xy=v[:,:2].copy();v[:,0]=xy[:,0]*c-xy[:,1]*s;v[:,1]=xy[:,0]*s+xy[:,1]*c
        md3(OUT/'spin.md3',converted,inds,coords,'models/crash/WiBlG.png')
        first=0;model=1
    else:
        first=len(normal_frames);model=0;normal_frames.extend(converted)
    manifest['animations'][action]={'original':name(geo),'frames':len(vv),'triangles':len(inds),'model':model,'first_frame':first}
inds,coords,_=mesh(byname['WillG'])
md3(OUT/'crash.md3',normal_frames,inds,coords,'models/crash/WillG.png')
(PROJECT/'source/assets.json').write_text(json.dumps(manifest,indent=2))
if __name__=='__main__':print(json.dumps(manifest['animations'],indent=2))
