# Referencia del Crash original

La referencia de esta actualización es el disco estadounidense aportado y el
código de ingeniería inversa de c1. No se hizo una comparación interactiva
jugando al original y la demo lado a lado; no se afirma fidelidad exacta.

## Giro

En la entrada GOOL `WillC`, item 2, la constante 9 referencia `spn0A`.
El item 1 contiene las instrucciones:

- PC 198: `0x8d100804`, ajuste de pitch, inmediato `0x804`.
- PC 199: `0x8dc00a0a`, ajuste de duración/parámetro de voz.
- PC 200: `0x8c06f009`, reproducción de la constante 9.

El inmediato entero GOOL se convierte a `(4 << 8) = 0x400`.
La SPU usa `0x1000` para 44100 Hz; `0x400` corresponde a 11025 Hz.
La anterior conversión a WAV declaraba incorrectamente 44100 Hz: conservaba
la muestra, pero la aceleraba cuatro veces. Ahora dura aproximadamente
0.645 segundos y conserva su tono de referencia. La muestra es la misma,
no se sustituyó por un archivo de internet.

Referencia de pitch SPU:
https://psx-spx.consoledev.net/soundprocessingunitspu/

## Movimiento

`desarrollo/c1/src/gool.c`, actualización de movimiento: cuando está activa
la bandera de control por D-pad, el juego vuelve a calcular la velocidad
horizontal a partir de la dirección y velocidad del personaje. Esa lógica
no se limita al suelo; la gravedad y las colisiones se procesan después.

En la adaptación, Crash tiene control aéreo propio (0.65 del impulso terrestre),
amortiguación horizontal por tic de 0.90 y un límite de velocidad aérea de 12.
Esto permite invertir y frenar en el aire sin reemplazar las colisiones de Doom.
Son parámetros de adaptación, no valores originales porteados literalmente.

## Ataque de salto

Se verifica que los pies atraviesen el plano superior del objetivo descendiendo,
que exista contacto horizontal y visibilidad nativa. Solo cajas de Aku Aku y
monstruos pueden recibir el pisotón; el contacto lateral no activa el ataque.
El rebote usa velocidad vertical 10.5, o 14.5 con Espacio mantenido.
Las pruebas ocurren dentro de GZDoom, con caída y recogida nativas; las posiciones
preparadas por la prueba solo se usan para aislar los escenarios de verificación.
