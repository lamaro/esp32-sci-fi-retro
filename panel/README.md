# Panel Next.js

Instalá las dependencias con `npm ci`. Copiá `.env.example` a `.env.local` y completá la URL de la placa y su token. Ejecutá `npm run dev -- --hostname 127.0.0.1` y abrí http://localhost:3000.

El panel consulta `GET /api/device` y usa `POST /api/device` para reenviar las órdenes de pantalla y reinicio desde el servidor. El token se lee en el servidor.

[Guía del proyecto](../GUIA.md).
