"""Refresh the single shareable delivery without including commercial WADs."""
from pathlib import Path
import shutil,zipfile
PROJECT=Path(__file__).resolve().parents[1]
DELIVERY=PROJECT/'compartir'
DELIVERY.mkdir(exist_ok=True)
for name in ['crash-in-doom.pk3','start.cfg']:
    shutil.copy2(PROJECT/name,DELIVERY/name)
shutil.copytree(PROJECT/'tools/gzdoom',DELIVERY/'motor',dirs_exist_ok=True)
instructions=DELIVERY/'INSTRUCCIONES.txt'
text=instructions.read_text(encoding='utf-8-sig')
marker='\nACTUALIZACION - SONIDO, SALTO Y AKU AKU\n'
if marker in text:text=text.split(marker)[0]
text+=marker+'''El giro usa su sonido original, con la velocidad corregida a 11025 Hz.
Crash es un 25% mas pequeno que en la actualizacion anterior (escala 0.9).
Tiene mas control aereo para frenar y cambiar de direccion durante el salto.
Caer desde arriba sobre cajas o enemigos los rompe o mata y hace rebotar
a Crash. Mantener Espacio al impactar da un rebote mas alto.
El contacto lateral no cuenta como ataque de salto.
Crash gira hacia donde se mueve; al retroceder se ve de frente. La camara
y los controles mantienen su orientacion. Aku Aku orbita mas abajo,
ajustado al nuevo tamano. Apoyarse sobre un enemigo tambien lo aplasta.
El salto es mas alto y muestra una pirueta completa.
Hay hasta cuatro cajas de Aku Aku por mapa, en posiciones validas y separadas.
Rompe la caja con el giro (Ctrl / clic derecho), saltando encima o con las armas y acercate
a la mascara: recibirás 20 segundos de invulnerabilidad. Aku Aku gira a tu
alrededor y parpadea antes de desaparecer. Otra mascara renueva el tiempo.
No es el sistema de acumular tres mascaras del juego original.
Los sonidos de giro, rotura y obtencion, y la caja y mascara, son recursos
originales del disco de Crash suministrado. No se genero arte nuevo.
Para ver las nuevas cajas, empieza una partida nueva.

BAILE DE VICTORIA: pulsa V estando quieto en el suelo.
Version corta (1,5 s), con la voz original badabaaa, sin los gestos de la gema.
Al morir, la vista queda bloqueada y el mapa se reinicia solo a los 2 segundos.
Se cancela al moverte, saltar, atacar o recibir dano. No da invulnerabilidad.

ULTIMA ACTUALIZACION: SONIDOS, WUMPA Y MUERTE
Crash ya no usa los gemidos del marine. Se reutilizan sus sonidos originales
de salto, dolor y muerte; la voz de dolor tiene una breve pausa entre repeticiones.
Espacio: toque corto para salto bajo, mantener para salto alto.
El giro lanza a los enemigos normales derrotados con un sonido original.
Las curas aparecen como frutas Wumpa animadas. Cada una suma 1 al contador,
incluso con la salud llena, y cura segun el objeto original de Doom.
El icono de fruta y los numeros naranjas del contador son recursos originales.
El contador se guarda con la partida; no se implementaron las vidas por 100 frutas.
La muerte usa las poses del primer Crash con giro y desplome; la camara queda fija.
No incluye la animacion del angelito de las secuelas.
Empieza una partida nueva para ver los objetos de salud reemplazados.
'''
instructions.write_text(text,encoding='utf-8-sig')
archive=PROJECT/'Crash en Doom.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for path in sorted(DELIVERY.rglob('*')):
        rel=path.relative_to(DELIVERY)
        if not path.is_file():continue
        if rel.parts[0]=='saves' or path.suffix.lower()=='.wad':continue
        if rel.as_posix() in ('crash.ini','last-run.log'):continue
        z.write(path,'Crash en Doom/'+rel.as_posix())
print(archive,archive.stat().st_size)
