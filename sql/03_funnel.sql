-- FUNNEL
CREATE OR REPLACE TABLE usable_stations AS

WITH in_corridor AS (
  -- from corridor_stations
  SELECT *
  FROM corridor_stations
),
operational AS (
  -- filter on status_code
  SELECT *
  FROM in_corridor
  WHERE status_code = 'E'
),
public_access AS (
  -- filter on access_code
  SELECT *
  FROM operational
  WHERE NOT (ev_network ILIKE '%tesla%' AND access_days_time ILIKE '%teslas only%') AND access_code = 'public'
),
dc_fast AS (
  -- DC fast only, not Level 2 (excluding private access)
  SELECT *
  FROM public_access
  WHERE ev_dc_fast_count > 0
),
vehicle_ports_fixed AS (
  -- fix dc port wording to match STATIONS
  SELECT model, year_start, year_end, 
    CASE WHEN native_dc_port = 'CCS1' THEN 'J1772COMBO' WHEN native_dc_port = 'NACS' THEN 'TESLA' END AS native_dc_port, adapter_notes, source_url
  FROM vehicle_ports
),
port_match AS (
  -- connector matches the vehicle's NATIVE port
  SELECT dc.*, v.model, v.year_start, v.year_end, v.native_dc_port
  FROM dc_fast dc
  JOIN vehicle_ports_fixed v ON ARRAY_CONTAINS(v.native_dc_port::VARIANT, SPLIT(dc.ev_connector_types, ' '))
),
port_reach AS (
  -- reachable ports with adapter
  SELECT * FROM VALUES
    ('TESLA', 'TESLA'),
    ('TESLA', 'J1772COMBO'),
    ('J1772COMBO', 'TESLA'),
    ('J1772COMBO', 'J1772COMBO')
  AS t(native_dc_port, reachable_connector)
),
with_adapters AS (
  -- ALSO reachable using adapters the driver owns
  SELECT dc.*, v.model, v.year_start, v.year_end, v.native_dc_port
  FROM dc_fast dc
  JOIN vehicle_ports_fixed v
    ON TRUE
  JOIN port_reach p
    ON p.native_dc_port = v.native_dc_port
   AND ARRAY_CONTAINS(p.reachable_connector::VARIANT, SPLIT(dc.ev_connector_types, ' '))
)

-- -- Checking station counts for each waypoint
-- SELECT DISTINCT * FROM port_match;
-- SELECT seq, COUNT(DISTINCT id) FROM port_match GROUP BY 1 ORDER BY 1;
-- SELECT DISTINCT * FROM with_adapters;
-- SELECT seq, COUNT(DISTINCT id) FROM with_adapters GROUP BY 1 ORDER BY 1; 

-- -- Checking rows for each funnel
-- SELECT 'in corridor' AS stage, COUNT(*) AS n FROM in_corridor -- 3060 rows
-- UNION ALL SELECT 'operational', COUNT(*) FROM operational -- 2987 rows
-- UNION ALL SELECT 'public access', COUNT(*) FROM public_access -- 2760 rows
-- UNION ALL SELECT 'dc fast', COUNT(*) FROM dc_fast; -- 320 rows

-- -- Checking available stations for each Hyundai model (native-dc)
-- SELECT
--   model,
--   year_start,
--   year_end,
--   native_dc_port,
--   COUNT(DISTINCT id) AS stations
-- FROM port_match
-- GROUP BY 1,2,3,4
-- ORDER BY model, year_start;

-- -- Checking available stations for each Hyundai model (with adapters)
-- SELECT 'native only' AS scenario, model, year_start, native_dc_port,
--        COUNT(DISTINCT id) AS stations
-- FROM port_match GROUP BY 1,2,3,4
-- UNION ALL
-- SELECT 'with adapter', model, year_start, native_dc_port,
--        COUNT(DISTINCT id)
-- FROM with_adapters GROUP BY 1,2,3,4
-- ORDER BY model, year_start, scenario;
/*
    The adapter allows both CCS1 and NACS, so all model has 318 stations available.
    For CCS1 native DC port, 246; for NACS native DC port, 114.
*/

-- Making port_match to a separate table with usable columns
SELECT DISTINCT
  id, station_name, latitude, longitude, seq,
  model, year_start, year_end, native_dc_port,
  'native only' AS scenario
FROM port_match

UNION ALL

SELECT DISTINCT
  id, station_name, latitude, longitude, seq,
  model, year_start, year_end, native_dc_port,
  'with adapter' AS scenario
FROM with_adapters;