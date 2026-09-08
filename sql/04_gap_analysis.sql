-- GAP ANALYSIS
WITH ordered_stops AS (
  SELECT DISTINCT
    latitude, longitude, seq,
    ST_MAKEPOINT(longitude, latitude) AS geo,
    ST_DISTANCE(geo, ST_MAKEPOINT(-118.2437, 34.0522)) AS dist_from_la
  FROM usable_stations
  WHERE model = 'Ioniq 5'
    AND year_start = 2025
    AND scenario = 'native only'
  ORDER BY ST_DISTANCE(geo, ST_MAKEPOINT(-118.2437, 34.0522))
),
gaps AS (
  SELECT
    seq,
    ST_DISTANCE(
      geo,
      ST_MAKEPOINT(LAG(ST_X(geo),1) OVER (ORDER BY dist_from_la), LAG(ST_Y(geo),1) OVER (ORDER BY dist_from_la))
    ) / 1609 AS miles_from_previous
  FROM ordered_stops
)
SELECT MAX(miles_from_previous) AS longest_gap_miles FROM gaps;
/*
    model, year_start, sequence: longest_gap_miles
    Ioniq 5, 2022, native only: 51.850240188
    Ioniq 5, 2022, with adapter: 50.877845947
    Ioniq 5, 2025, native only: 71.530312919
    Ioniq 5, 2025, with adapter: 50.877845947
*/
-- Find the stations that have longest gap
WITH ordered_stops AS (
  SELECT DISTINCT
    station_name, latitude, longitude, seq,
    ST_MAKEPOINT(longitude, latitude) AS geo,
    ST_DISTANCE(geo, ST_MAKEPOINT(-118.2437, 34.0522)) AS dist_from_la
  FROM usable_stations
  WHERE model = 'Ioniq 5'
    AND year_start = 2025
    AND scenario = 'with adapter'
    AND station_name NOT ILIKE '%Caltrans - Valley Wells%'
  ORDER BY ST_DISTANCE(geo, ST_MAKEPOINT(-118.2437, 34.0522))
),
gaps AS (
  SELECT
    station_name,
    LAG(station_name, 1) OVER (ORDER BY dist_from_la) AS previous_station,
    seq,
    latitude,
    longitude,
    ST_DISTANCE(
      geo,
      ST_MAKEPOINT(LAG(ST_X(geo),1) OVER (ORDER BY dist_from_la), LAG(ST_Y(geo),1) OVER (ORDER BY dist_from_la))
    ) / 1609 AS miles_from_previous
  FROM ordered_stops
)
SELECT previous_station, station_name, latitude, longitude, miles_from_previous
FROM gaps
ORDER BY miles_from_previous DESC
LIMIT 10;
/*
    Ioniq 5, 2022, native only: 51.850240188 ("Caltrans - Valley Wells Rest Area - Northbound" -> "Target T1524 (Spring Valley, NV)": 70.2 miles)
    Ioniq 5, 2022, with adapter: 50.877845947 ("Caltrans - Valley Wells Rest Area - Northbound" -> "Las Vegas, NV - South Fort Apache Road - Tesla Supercharger": 68.5 miles)
    Ioniq 5, 2025, native only: 71.530312919 ("Baker, CA - Mojave Pointe Rd - Tesla Supercharger" -> "Las Vegas, NV - South Fort Apache Road - Tesla Supercharger": 92.5 miles)
    Ioniq 5, 2025, with adapter: 50.877845947 ("Caltrans - Valley Wells Rest Area - Northbound" -> "Las Vegas, NV - South Fort Apache Road - Tesla Supercharger": 68.5 miles)

    *** Caltrans - Valley Wells Rest Area is temporarily unavailable, according to Google Maps.
    RERUN with them excluded.

    Ioniq 5, 2022, native only: 71.479203893 ("BAKER TRAVEL PLAZA" -> "Target T1524 (Spring Valley, NV)": 93.4 miles)
    Ioniq 5, 2022, with adapter: 70.77311057 ("BAKER TRAVEL PLAZAd" -> "Las Vegas, NV - South Fort Apache Road - Tesla Supercharger": 91.8 miles)
    Ioniq 5, 2025, native only: 71.530312919 ("Baker, CA - Mojave Pointe Rd - Tesla Supercharger" -> "Las Vegas, NV - South Fort Apache Road - Tesla Supercharger": 92.5 miles)
    Ioniq 5, 2025, with adapter: 70.77311057 ("BAKER TRAVEL PLAZA" -> "Las Vegas, NV - South Fort Apache Road - Tesla Supercharger": 91.8 miles)
*/