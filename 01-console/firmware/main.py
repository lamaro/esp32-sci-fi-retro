"""Conecta el ESP32 a la red local y sirve una API pequeña protegida por token."""

import json
import gc
import machine
import network
import socket
import time
from machine import Pin
from wifi_secrets import API_TOKEN, WIFI_PASSWORD, WIFI_SSID
from display_ui import Display, MODES
from weather import valid_city

LED_PIN = 23
led = Pin(LED_PIN, Pin.OUT)
started_at = time.ticks_ms()
ip_address = ""
display = None


def connect_wifi():
    global ip_address
    if not WIFI_SSID or not API_TOKEN:
        raise RuntimeError("Completá WIFI_SSID y WIFI_PASSWORD en wifi_secrets.py antes de subir el programa.")

    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)
    if not wlan.isconnected():
        print("Conectando al Wi-Fi de 2,4 GHz...")
        wlan.connect(WIFI_SSID, WIFI_PASSWORD)

    deadline = time.ticks_add(time.ticks_ms(), 25000)
    while not wlan.isconnected() and time.ticks_diff(deadline, time.ticks_ms()) > 0:
        time.sleep_ms(250)

    while not wlan.isconnected():
        print("No se conectó. Revisá wifi_secrets.py; vuelvo a intentar en 10 s.")
        time.sleep(10)
        wlan.disconnect()    # sin esto, el reintento falla con "sta is connecting"
        wlan.connect(WIFI_SSID, WIFI_PASSWORD)
        deadline = time.ticks_add(time.ticks_ms(), 25000)
        while not wlan.isconnected() and time.ticks_diff(deadline, time.ticks_ms()) > 0:
            time.sleep_ms(250)

    ip_address = wlan.ifconfig()[0]
    print("Wi-Fi conectado. IP local:", ip_address)
    return wlan


def send_json(client, status, payload):
    body = json.dumps(payload).encode()
    reason = "OK" if status == 200 else "Bad Request" if status == 400 else "Unauthorized" if status == 401 else "Not Found"
    header = (
        "HTTP/1.1 %d %s\r\n" % (status, reason)
        + "Content-Type: application/json\r\n"
        + "Content-Length: %d\r\n" % len(body)
        + "Cache-Control: no-store\r\n"
        + "Connection: close\r\n\r\n"
    ).encode()
    remaining = header + body
    while remaining:
        sent = client.send(remaining)
        if sent <= 0:
            break
        remaining = remaining[sent:]


def receive_request(client):
    data = b""
    while b"\r\n\r\n" not in data:
        chunk = client.recv(512)
        if not chunk:
            return None
        data += chunk

    header_bytes, body = data.split(b"\r\n\r\n", 1)
    lines = header_bytes.decode().split("\r\n")
    request_line = lines[0].split()
    if len(request_line) < 2:
        return None

    headers = {}
    for line in lines[1:]:
        if ":" in line:
            key, value = line.split(":", 1)
            headers[key.strip().lower()] = value.strip()

    length = int(headers.get("content-length", "0"))
    while len(body) < length:
        chunk = client.recv(512)
        if not chunk:
            return None
        body += chunk

    return request_line[0], request_line[1].split("?", 1)[0], headers, body[:length]


def serve_client(client):
    client.settimeout(3)
    request = receive_request(client)
    if request is None:
        send_json(client, 400, {"error": "invalid_request"})
        return

    method, path, headers, body = request
    if headers.get("authorization", "") != "Bearer " + API_TOKEN:
        send_json(client, 401, {"error": "unauthorized"})
        return

    if method == "GET" and path == "/api/status":
        uptime = time.ticks_diff(time.ticks_ms(), started_at) // 1000
        send_json(client, 200, {"online": True, "led": bool(led.value()), "uptime": uptime, "ip": ip_address, "display": display.mode, "scene": display.current(), "textSupported": True, "weatherCity": display.weather.city["name"]})
        return False

    if method == "POST" and path == "/api/display":
        try:
            command = json.loads(body.decode())
            mode = command.get("mode")
            if mode not in MODES:
                raise ValueError("unsupported display mode")
        except (ValueError, TypeError, AttributeError):
            send_json(client, 400, {"error": "invalid_display_mode"})
            return False
        message = command.get("text", "")
        if mode == "text":
            allowed = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .!?:-"
            lines = message.split("\n") if isinstance(message, str) else []
            if not 1 <= len(lines) <= 2 or any(
                not line.strip() or len(line) > 15 or any(char not in allowed for char in line)
                for line in lines
            ):
                send_json(client, 400, {"error": "invalid_display_text"})
                return False
        if mode == "weather" and "city" in command:
            city = valid_city(command["city"])
            if city is None:
                send_json(client, 400, {"error": "invalid_city"})
                return False
            display.weather.set_city(city)
        display.set_mode(mode, message)
        # Dibujar la nueva escena antes de confirmar el comando al panel.
        display.update()
        send_json(client, 200, {"online": True, "display": mode})
        return False

    if method == "POST" and path == "/api/led":
        try:
            command = json.loads(body.decode())
            if not isinstance(command.get("on"), bool):
                raise ValueError("on must be boolean")
        except (ValueError, TypeError, AttributeError):
            send_json(client, 400, {"error": "expected_json_boolean_on"})
            return False
        led.value(1 if command["on"] else 0)
        send_json(client, 200, {"online": True, "led": bool(led.value())})
        return False

    if method == "POST" and path == "/api/restart":
        send_json(client, 200, {"online": True, "restarting": True})
        return True

    send_json(client, 404, {"error": "not_found"})
    return False


def main():
    connect_wifi()
    gc.collect()
    global display
    display = Display(ip_address)
    display.update()
    led.value(0)
    server = socket.socket()
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(("0.0.0.0", 80))
    server.listen(2)
    server.settimeout(0)     # sin espera: la pantalla se redibuja en cada vuelta
    print("API local lista en el puerto 80. Token requerido para cada orden.")

    while True:
        try:
            client, _address = server.accept()
            client.setblocking(True)
        except OSError:
            display.update()
            time.sleep_ms(2)     # deja respirar al Wi-Fi sin frenar la pantalla
            continue
        restart = False
        try:
            restart = serve_client(client)
        except Exception as error:
            print("Error al atender una petición:", error)
        finally:
            client.close()
        if restart:
            time.sleep_ms(200)
            machine.reset()


main()
