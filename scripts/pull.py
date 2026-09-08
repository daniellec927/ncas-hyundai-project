import requests
from dotenv import load_dotenv
import os

load_dotenv()

NRL_API_KEY = os.getenv("NRL_API_KEY")

if NRL_API_KEY is None:
    raise ValueError("NRL_API_KEY not found.")

url_stations = "https://developer.nlr.gov/api/alt-fuel-stations/v1.csv"
url_units = "https://developer.nlr.gov/api/alt-fuel-stations/v1/ev-charging-units.csv"


params_stations = {
    "api_key": NRL_API_KEY,
    "limit": "all",
    "state": "CA,NV",
    "fuel_type": "ELEC"
}
params_units = {
    "api_key": NRL_API_KEY,
    "limit": "all",
    "state": "CA,NV"
}

response_stations = requests.get(url_stations, params=params_stations)
response_units = requests.get(url_units, params=params_units)


if response_stations.status_code == 200:
    with open("data/raw/stations_raw.csv", "wb") as f:
        f.write(response_stations.content)
    print("Success: ", "data/raw/stations_raw.csv")
else:
    print(f"Error {response_stations.status_code}: {response_stations.text}")

if response_units.status_code == 200:
    with open("data/raw/units_raw.csv", "wb") as f:
        f.write(response_units.content)
    print("Success: ", "data/raw/units_raw.csv")
else:
    print(f"Error {response_units.status_code}: {response_units.text}")
