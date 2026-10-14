"""Read the user's Mode-2 PS1 disc, preserving original stream files."""
from pathlib import Path
import struct
PROJECT=Path(__file__).resolve().parents[1]
DISC=PROJECT.parent/'ISO Crash Bandicoot (USA)/Crash Bandicoot (USA).bin'
OUT=PROJECT/'desarrollo/c1/streams'
OUT.mkdir(parents=True,exist_ok=True)
with DISC.open('rb') as disc:
    def read(lba,size):
        result=bytearray()
        while size>0:
            disc.seek(lba*2352+24)
            chunk=disc.read(min(size,2048));result.extend(chunk)
            size-=len(chunk);lba+=1
        return bytes(result)
    pvd=read(16,2048)
    assert pvd[1:6]==b'CD001'
    def directory(lba,size,prefix=''):
        data=read(lba,size);at=0
        while at<len(data):
            length=data[at]
            if not length:at=(at//2048+1)*2048;continue
            rec=data[at:at+length];at+=length
            nam=rec[33:33+rec[32]]
            if nam in (b'\0',b'\1'):continue
            name=nam.decode('ascii').split(';')[0]
            sector=struct.unpack_from('<I',rec,2)[0];count=struct.unpack_from('<I',rec,10)[0]
            if rec[25]&2:directory(sector,count,prefix+name+'/')
            elif name.lower().endswith(('.nsf','.nsd')):
                target=OUT/name.lower()
                if not target.exists():target.write_bytes(read(sector,count))
                print(prefix+name,count)
    root=pvd[156:190]
    directory(struct.unpack_from('<I',root,2)[0],struct.unpack_from('<I',root,10)[0])
