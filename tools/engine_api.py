from pathlib import Path
import zipfile
ROOT=Path(__file__).resolve().parents[1]
with zipfile.ZipFile(ROOT/'tools/gzdoom/gzdoom.pk3') as z:
    for item in z.namelist():
        if not item.lower().endswith(('.zs','.txt')):continue
        text=z.read(item).decode('utf8','replace')
        if any(k in text for k in ('ConsoleCommand','class Console','class ThinkerIterator','class ActorIterator')):
            out=ROOT/'source'/Path(item).name
            out.write_text(text)
            for i,line in enumerate(text.splitlines()):
                if any(k in line for k in ('ConsoleCommand','class Console','class ThinkerIterator','class ActorIterator')):
                    print(item,i,'\n'.join(text.splitlines()[i:i+18]))
