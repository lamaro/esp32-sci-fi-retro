# Comandos rápidos

Configurá el puerto y el entorno según la [guía](GUIA.md). Desde la raíz del repo:

```sh
source .venv/bin/activate
cd 01-console/firmware
mpremote connect list
mpremote connect "$PORT" run demo_pantalla.py
```

Para actualizar la app de la placa:

```sh
mpremote connect "$PORT" fs cp font5x7.py :font5x7.py &&
mpremote connect "$PORT" fs cp display_ui.py :display_ui.py &&
mpremote connect "$PORT" fs cp main.py :main.py &&
mpremote connect "$PORT" reset
```

Los cambios de firmware se copian por USB. El panel web está en [esp32-sci-fi-retro-panel](https://github.com/lamaro/esp32-sci-fi-retro-panel): si cambia la IP de la placa, editá su `.env.local` y reiniciá Next.js.
