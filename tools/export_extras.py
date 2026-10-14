"""Original PS1 mask, Aku crate and sound effects; no synthesized assets."""
import struct,json,wave,hashlib
import numpy as np
import export_crash as e

metadata={}
for label,filename,height in [('WD10V','aku',28),('BD10V','aku-crate',30)]:
    items=e.entries[e.byname[label]];geo=struct.unpack_from('<I',items[0],4)[0]
    inds,uv,scale=e.mesh(geo);verts=e.vertices(items[0],scale)
    center=(verts.min(axis=0)+verts.max(axis=0))/2
    # Use the original mesh, with its base at local Z=0.
    verts-=np.array([center[0],verts[:,1].min(),center[2]])
    factor=height/np.ptp(verts[:,1])
    converted=np.column_stack((-verts[:,2],verts[:,0],verts[:,1]))*factor
    e.md3(e.OUT/(filename+'.md3'),[converted],inds,uv,'models/crash/'+e.name(geo)+'.png')
    metadata[filename]={'original':label,'geometry':e.name(geo),'height':height,'triangles':len(inds)}

coefficients=[(0,0),(60,0),(115,-52),(98,-55),(122,-60)]
def decode(data):
    output=[];older=previous=0
    for offset in range(0,len(data)-15,16):
        block=data[offset:offset+16];shift=block[0]&15;predictor=block[0]>>4
        if predictor>=len(coefficients):raise ValueError('Invalid PS1 ADPCM predictor')
        c0,c1=coefficients[predictor]
        for byte in block[2:]:
            for nibble in (byte&15,byte>>4):
                value=nibble if nibble<8 else nibble-16
                value=((value<<12)>>shift)+((previous*c0+older*c1+32)>>6)
                value=max(-32768,min(32767,value))
                older,previous=previous,value;output.append(value)
        if block[1]&1:break
    return np.array(output,dtype='<i2')

sounds=e.PROJECT/'mod/sounds/crash';sounds.mkdir(parents=True,exist_ok=True)
for label,filename in [('spn0A','spin'),('brk0A','crate-break'),('WD10A','aku-pickup'),('jmp0A','jump'),('arg0A','hurt'),('WOt0A','death'),('phw0A','launch'),('frt0A','wumpa'),('1up0A','oneup'),('bdb0A','victory')]:
    data=e.entries[e.byname[label]][0];samples=decode(data)
    # WillC instruction 198 (0x8d100804) sets the SPU pitch to 4<<8,
    # immediately before instruction 200 plays constant 9: spn0A.
    # SPU pitch 0x1000 is 44100 Hz; 0x400 is 11025 Hz, not 44100 Hz.
    # GamOC in s000002d: PC2691 sets pitch from constant228 = 0x5ce;
    # PC2693 plays constant108, bdb0A. This corresponds to approximately 16000 Hz.
    sample_rate=round(44100*0x5ce/4096) if label=='bdb0A' else 11025
    with wave.open(str(sounds/(filename+'.wav')),'wb') as wav:
        wav.setnchannels(1);wav.setsampwidth(2);wav.setframerate(sample_rate);wav.writeframes(samples.tobytes())
    metadata[filename]={'original':label,'sample_rate':sample_rate,'seconds':len(samples)/sample_rate,'original_sha256':hashlib.sha256(data).hexdigest()}
(e.PROJECT/'source/extras.json').write_text(json.dumps(metadata,indent=2))
print(json.dumps(metadata,indent=2))
with wave.open(str(sounds/'quiet.wav'),'wb') as wav:
    wav.setnchannels(1);wav.setsampwidth(2);wav.setframerate(11025)
    # Silence is taken from the original sample's leading zero block.
    wav.writeframes(decode(e.entries[e.byname['spn0A']][0])[:28].tobytes())
