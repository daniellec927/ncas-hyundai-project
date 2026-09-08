import pandas as pd

df_stations = pd.read_csv("data/raw/stations_raw.csv")
df_units = pd.read_csv("data/raw/units_raw.csv")

df_stations.columns = (
    df_stations.columns.str.strip()
    .str.lower()
    .str.replace(r"[\s\-]+","_",regex=True) # space, hypen to underscore
    .str.replace(r"[^\w]","",regex=True) # remove non-alphanumeric characters
)

df_units.columns = (
    df_units.columns.str.strip()
    .str.lower()
    .str.replace(r"[\s\-]+","_",regex=True) # space, hypen to underscore
    .str.replace(r"[^\w]","",regex=True) # remove non-alphanumeric characters
)

df_stations.to_csv("data/clean/stations.csv", index=False)
df_units.to_csv("data/clean/charging_units.csv", index=False)

if __name__ == "__main__":
    print("Cleaned data saved to data/clean/stations.csv and data/clean/charging_units.csv")