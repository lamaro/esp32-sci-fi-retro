# Comandos rápidos

Configurá el puerto y el entorno según la [guía](GUIA.md). En `hello/`:

```sh
source .venv/bin/activate
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

Para iniciar el sitio, en `panel/`:

```sh
npm run dev -- --hostname 127.0.0.1
```

Los cambios de firmware se copian por USB. Los cambios de interfaz se aplican en Next.js. Si cambia la IP, editá `panel/.env.local` y reiniciá Next.js.
