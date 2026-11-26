"""Clima actual de una ciudad, desde Open-Meteo (pública, sin clave).

Solo se consulta mientras la escena de clima está en pantalla: la pantalla
llama a fetch() cuando due() indica que los datos vencieron.
"""
import gc
import json
import time

try:
    import requests
except ImportError:          # simulador en la computadora
    requests = None

# Open-Meteo recalcula el clima actual cada 15 minutos: consultar más seguido
# no trae datos nuevos.
REFRESH_MS = 15 * 60 * 1000
RETRY_MS = 60 * 1000         # si falla, reintenta en un minuto
CITY_FILE = "weather_city.json"
DEFAULT_CITY = {"name": "BUENOS AIRES", "lat": -34.6037, "lon": -58.3816}
NAME_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .-'"
# HTTP sin TLS: con la pantalla y el servidor andando, a la placa no le alcanza
# la memoria para abrir HTTPS (ENOMEM). El clima es un dato público.
URL = ("http://api.open-meteo.com/v1/forecast?latitude=%.4f&longitude=%.4f"
       "&current=temperature_2m,relative_humidity_2m,apparent_temperature,"
       "weather_code,is_day"
       "&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max&timezone=auto&forecast_days=1")

# Códigos WMO -> (tipo de ícono, texto de hasta 21 caracteres)
def describe(code):
    if code == 0:
        return "clear", "DESPEJADO"
    if code == 1:
        return "partly", "MAYORMENTE DESPEJADO"
    if code == 2:
        return "partly", "PARCIAL NUBLADO"
    if code == 3:
        return "cloud", "NUBLADO"
    if code in (45, 48):
        return "fog", "NIEBLA"
    if 51 <= code <= 57:
        return "rain", "LLOVIZNA"
    if 61 <= code <= 67:
        return "rain", "LLUVIA"
    if 80 <= code <= 82:
        return "rain", "CHAPARRONES"
    if 71 <= code <= 77 or code in (85, 86):
        return "snow", "NIEVE"
    if code >= 95:
        return "storm", "TORMENTA"
    return "cloud", "SIN DATO"


def valid_city(city):
    """Devuelve la ciudad normalizada o None si no es válida."""
    try:
        name = city["name"].upper()[:20]
        lat, lon = float(city["lat"]), float(city["lon"])
    except (KeyError, TypeError, ValueError, AttributeError):
        return None
    if not name.strip() or any(c not in NAME_CHARS for c in name):
        return None
    if not (-90 <= lat <= 90 and -180 <= lon <= 180):
        return None
    return {"name": name, "lat": lat, "lon": lon}


def load_city():
    try:
        with open(CITY_FILE) as f:
            city = valid_city(json.load(f))
        if city:
            return city
    except (OSError, ValueError):
        pass
    return dict(DEFAULT_CITY)


class Weather:
    def __init__(self):
        self.city = load_city()
        self.data = None        # último dato bueno
        self.error = False      # la última consulta falló
        self.next_ms = None     # None = consultar apenas se muestre la escena

    def set_city(self, city):
        if city["name"] == self.city["name"] and city["lat"] == self.city["lat"] and city["lon"] == self.city["lon"]:
            return
        self.city = city
        self.data = None
        self.error = False
        self.next_ms = None
        try:
            with open(CITY_FILE, "w") as f:
                json.dump(city, f)
        except OSError:
            pass

    def due(self, now):
        return self.next_ms is None or time.ticks_diff(now, self.next_ms) >= 0

    def fetch(self):
        """Consulta la API (tarda 1-3 s). Se llama solo con la escena activa."""
        gc.collect()
        response = None
        try:
            response = requests.get(URL % (self.city["lat"], self.city["lon"]), timeout=8)
            if response.status_code != 200:
                raise OSError("HTTP %d" % response.status_code)
            payload = response.json()
            now = payload["current"]
            day = payload["daily"]
            self.data = {
                "temp": int(round(now["temperature_2m"])),
                "feels": int(round(now["apparent_temperature"])),
                "hum": int(round(now["relative_humidity_2m"])),
                "code": int(now["weather_code"]),
                "day": bool(now["is_day"]),
                "max": int(round(day["temperature_2m_max"][0])),
                "min": int(round(day["temperature_2m_min"][0])),
                # probabilidad máxima de precipitación del día (puede faltar)
                "rain": day["precipitation_probability_max"][0],
                "time": now["time"][11:16],
            }
            self.error = False
            self.next_ms = time.ticks_add(time.ticks_ms(), REFRESH_MS)
            print("Clima actualizado:", self.city["name"], self.data["temp"], "C")
        except Exception as error:
            print("No se pudo consultar el clima:", error)
            self.error = True
            self.next_ms = time.ticks_add(time.ticks_ms(), RETRY_MS)
        finally:
            if response is not None:
                response.close()
            gc.collect()
