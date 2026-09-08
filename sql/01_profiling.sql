-- Creating database and schema
CREATE DATABASE nacs;
CREATE SCHEMA nacs.charging;

-- Checking data (if they loaded correctly)
SELECT COUNT(*) FROM nacs.charging.vehicle_ports;
SELECT * FROM nacs.charging.vehicle_ports LIMIT 5;

-- Connector types
SELECT ev_connector_types, COUNT(*)
FROM stations
GROUP BY 1
ORDER BY 2 DESC;
/* 
    Connector Types: J1772, TESLA (NACS), CHADEMO, J1772COMBO (CCS1), NEMA1450, NEMA515, NEMA520, J3271 (MCS)
    - This query has 25 rows (including null). Most of them are multivalued (space-delimited).
*/

-- Tesla access
SELECT ev_network, access_code, groups_with_access_code, 
    CASE WHEN access_days_time ILIKE '%teslas only%' THEN 'exclusive' ELSE 'inclusive' END AS tesla_only, 
    COUNT(*)
FROM stations
WHERE ev_network ILIKE '%tesla%' AND ev_dc_fast_count > 0
GROUP BY 1,2,3,4;
/*
    Excluding the Tesla exclusive superchargers and the Tesla Destinations are necessary. (Tesla Destinations do not have DC fast chargers.)
    We will only look at the 490 Tesla superchargers.
*/

-- Finding availability
SELECT status_code, COUNT(*) FROM stations GROUP BY 1;
/*
    E (available): 21640, T (temporarily unavailable): 409, P (planned): 67
*/

-- Checking staleness
SELECT DATE_TRUNC('year', date_last_confirmed) AS yr, COUNT(*)
FROM stations GROUP BY 1 ORDER BY 1;
/*
    ~2023 + null: 228
    2024: 489,
    2025: 1320, 
    2026: 20059
*/

-- duplicates: same spot, multiple IDs
SELECT latitude, longitude, COUNT(*) AS n
FROM stations GROUP BY 1,2 HAVING COUNT(*) > 1 ORDER BY n DESC;
/*
    Some duplicates are the same stations, but some just happen to be in the same area, but are under different station names.
*/

-- Joining STATIONS and UNITS
SELECT COUNT(*) FROM stations s
JOIN charging_units u ON s.id = u.id;
/*
    82186 rows total after joiningNACS.CHARGING.CHARGING_UNITSNACS.CHARGING.STATIONSNACS.CHARGING.STATIONSNACS.CHARGING.STATIONS
*/