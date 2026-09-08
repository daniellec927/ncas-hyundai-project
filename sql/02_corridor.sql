-- Building the corridor
CREATE OR REPLACE TABLE corridor_stations AS
WITH distances AS (
  SELECT
    s.*,
    w.seq,
    w.name AS waypoint_name,
    ST_DISTANCE(
      ST_MAKEPOINT(s.longitude, s.latitude),
      ST_MAKEPOINT(w.longitude, w.latitude)
    ) AS meters_to_waypoint
  FROM stations s
  CROSS JOIN waypoints w
),
nearest AS (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY meters_to_waypoint) AS rn
  FROM distances
)
SELECT * FROM nearest
WHERE rn = 1
  AND meters_to_waypoint < 16000;   -- ~10 miles

SELECT COUNT(*) FROM corridor_stations; -- 3060 rows
-- Checking options for each waypoint
SELECT seq, COUNT(*) FROM corridor_stations GROUP BY 1 ORDER BY 1;