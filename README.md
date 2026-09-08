# The NACS Transition and the Charging Gap

**A single stale charger record accounted for the entire apparent disadvantage between two Hyundai charging cohorts.**

On the LA → Las Vegas corridor, a 2025 Ioniq 5 (native NACS) without its adapter appears to face a 92.5-mile stretch between usable DC fast chargers, against 70.2 for the 2022 CCS1 car it replaced — a counterintuitive result, since NACS is supposed to unlock the largest fast-charging network in the country. That gap disappears once one station is removed: a rest-area charger the source data lists as operational, and Google Maps reports as temporarily unavailable. Corrected, all four cohorts face roughly 92 miles. The finding is not about the port transition. It is about how little the underlying data guarantees.

📊 **[Tableau Public dashboard](https://public.tableau.com/views/nacs-project/dashboard?:language=en-US&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)** · 🗂 **[Data source: NLR Alternative Fuel Data Center](https://developer.nlr.gov/docs/transportation/alt-fuel-stations-v1/)**

---

## The question

When Hyundai switched the Ioniq 5 from a CCS1 port (2022–2024) to a native NACS port (2025+), it split its own US owner base into two groups with different charging rulebooks — same nameplate, same route, different set of usable stations.

This analysis asks: **on the Los Angeles → Las Vegas corridor, how far can each cohort actually drive between chargers it can use?**

The question matters because public charging data does not, on its own, encode vehicle-specific usability. Determining what a given car can actually plug into requires joining station connector data to model-year port specifications — a join this analysis performs and that the raw data does not contain.

---

## Finding

### First pass: as the published data stands

Worst-case gap between usable DC fast chargers, LA → Las Vegas:

| Cohort | Straight-line (mi) | Driving (mi) | Gap endpoints |
|---|---|---|---|
| Ioniq 5, 2022 — native port only | 51.9 | 70.2 | Valley Wells Rest Area → Target T1524, Spring Valley NV |
| Ioniq 5, 2022 — with adapter | 50.9 | 68.5 | Valley Wells Rest Area → S Fort Apache Rd Supercharger |
| **Ioniq 5, 2025 — native port only** | **71.5** | **92.5** | **Baker CA Supercharger → S Fort Apache Rd Supercharger** |
| Ioniq 5, 2025 — with adapter | 50.9 | 68.5 | Valley Wells Rest Area → S Fort Apache Rd Supercharger |

Read at face value, the 2025 native-only cohort looks materially worse off. The two adapter rows are identical, which is expected — with an adapter, both cohorts reach both connector types, so the port a car was born with stops mattering.

### Correction: one station

Valley Wells Rest Area is listed by AFDC as operational, last confirmed 2024, but reported by Google Maps as temporarily unavailable at the time of analysis. It bounds three of the four gaps above.

| Cohort | Straight-line (mi) | Driving (mi) | Gap endpoints |
|---|---|---|---|
| Ioniq 5, 2022 — native port only | 71.48 | 93.4 | Baker Travel Plaza → Target T1524, Spring Valley NV |
| Ioniq 5, 2022 — with adapter | 70.77 | 91.8 | Baker Travel Plaza → S Fort Apache Rd Supercharger |
| **Ioniq 5, 2025 — native port only** | **71.53** | **92.5** | **Baker CA Supercharger → S Fort Apache Rd Supercharger** |
| Ioniq 5, 2025 — with adapter | 70.77 | 91.8 | Baker Travel Plaza → S Fort Apache Rd Supercharger |

Excluding it, the four cohorts converge at roughly 91–93 miles. The NACS disadvantage was an artifact of one unverified record, not a property of the network.

### What this means

First, the port transition costs a driver nothing on this corridor provided they have their adapter — and adapter possession depended on purchase date, an active MyHyundai account, and responding to an email within 60 days, none of which a vehicle can know.
Second, and more consequentially: a compatibility analysis is only as reliable as the station status data underneath it, and that data carries no uptime or availability information at all. A single stale row moved the headline number by 22 miles.

This is also a snapshot of a transition. As CCS sites add NACS connectors, the native-only picture will shift — but transition periods are precisely when compatibility is least predictable for drivers, and this one is not close to over.

### Funnel

| In Corridor | Operational | Public Access | DC Fast |
|---|---|---|---|
| 3060 | 2987 | 2760 | 320 |

---

## Data sources

| Source | What it provides | Notes |
|---|---|---|
| [NLR AFDC Alternative Fuel Stations API](https://developer.nlr.gov/docs/transportation/alt-fuel-stations-v1/) | US charging station locations, connector types, networks, access, status | US Dept. of Energy, free, public |
| AFDC EV Charging Units endpoint | One row per charging unit, power by connector | Used to avoid over-counting mixed-hardware sites |
| `data/hand/waypoints.csv` | ~11 points along the LA→Vegas route | Hand-built from Google Maps |
| `data/hand/vehicle_ports.csv` | Model year → native DC port, adapter notes | Hand-built from Hyundai sources; see `source_url` column |

**Note on the route:** the corridor is LA → Las Vegas, which uses I-10 out of the basin before joining I-15 at Ontario. I-15 does not itself reach Los Angeles.

---

## Sample data

`data/raw/` and `data/clean/` contains masked samples of the stations and charging units files so you can check the data format without an API key. **They are samples only — findings above are computed from the full pull.** To reproduce the numbers, pull the real data as below.

---

## Reproducing this analysis

### 1. Get an NLR API key

Free and instant at [developer.nlr.gov/signup](https://developer.nlr.gov/signup/).

Create a `.env` file in the repo root:

```
NLR_API_KEY=your_key_here
```

`.env` is gitignored. Do not commit it.

### 2. Install dependencies

```bash
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

`requirements.txt`:

```
requests
pandas
python-dotenv
```

### 3. Pull and clean

```bash
python scripts/pull.py     # → data/raw/   (raw API responses, date-stamped)
python scripts/clean.py    # → data/clean/ (lowercased snake_case headers)
```

`pull.py` only fetches and saves. `clean.py` only transforms. Raw files are treated as immutable — AFDC updates continuously, so re-pulling mid-analysis would desynchronize the numbers from the map.

Column headers are normalized in `clean.py` (`EV Connector Types` → `ev_connector_types`) because Snowflake uppercases unquoted identifiers, and quoted mixed-case column names make every downstream query fragile.

**Pull date for the figures in this README:** _2026-09-06_
### 4. Load into Snowflake

Analysis was run in **Snowflake** (free trial, Standard edition).

```sql
CREATE DATABASE nacs;
CREATE SCHEMA nacs.charging;
```

Load four CSVs via **Data → Databases → NACS → CHARGING → Tables → Load Data**:

| File | Table |
|---|---|
| `data/clean/stations.csv` | `STATIONS` |
| `data/clean/charging_units.csv` | `CHARGING_UNITS` |
| `data/hand/waypoints.csv` | `WAYPOINTS` |
| `data/hand/vehicle_ports.csv` | `VEHICLE_PORTS` |

Check the inferred schema before accepting: `latitude` and `longitude` must be numeric, and station `id` must be an integer type rather than a float, or the geospatial functions and the station↔unit join will fail silently.

### 5. Run the SQL, in order

| File | Purpose |
|---|---|
| `sql/01_profiling.sql` | Data quality checks — connector vocabulary, network access, staleness, duplicates |
| `sql/02_corridor.sql` | Matches stations to route waypoints; builds `corridor_stations` |
| `sql/03_funnel.sql` | Applies usability filters per cohort; builds `usable_stations` |
| `sql/04_gaps.sql` | Longest gap between consecutive usable stations, per cohort |

### 6. Visualize

Export result tables to `data/tableau/` and open in Tableau Public.

---

## Method notes

**Connector vocabulary.** AFDC predates the NACS name and encodes the Tesla connector as `TESLA`; CCS1 appears as `J1772COMBO`. `vehicle_ports` is mapped to AFDC's vocabulary in SQL rather than at load time, so the mapping is visible in the query.

**Tesla access.** `access_code` marks all 718 Supercharger stations as public, but `access_days_time` distinguishes 228 Tesla-only sites. These two fields disagree; the analysis uses the more restrictive one.

**Level 2 exclusion.** Tesla Destination chargers share the NACS connector but are AC Level 2. They are excluded via `ev_dc_fast_count > 0` rather than by network name.

**Adapter scenarios.** Adapter possession is not a property of the vehicle — Hyundai's free CCS-to-NACS adapter required purchase on or before 2025-01-31, an active MyHyundai account, and redemption within 60 days. It is therefore modeled as a scenario, not a vehicle attribute.

**Deduplication.** Stations are deduplicated by coordinate for the gap analysis (two chargers in one lot is one stop) but counted separately in the funnel (two chargers is two options).

**Distance.** Gaps are computed as straight-line distance and reported alongside driving distance from Google Maps. The correction factor is ~1.3, but might vary in different situations.

---

## Limitations

- AFDC entries are self-reported and confirmation dates vary; at least one station bounding a reported gap appears to be inaccurate (see above)
- **No real-time availability or uptime data exists in this dataset** — a station counted as usable may be occupied, broken, or queued
- Adapter ownership is assumed by scenario, not observed
- Straight-line distance between stops, corrected approximately rather than routed
- The corridor is approximated by waypoints, so curved sections are imprecise
- Pricing, charging speed, and station capacity are not compared
- Only stations bounding the worst gaps were manually verified; the full set was not

---

## What I'd do next

- Real-time availability. The absence of uptime data is the largest gap between this analysis and what a driver actually experiences, and it is precisely the layer a connected-vehicle platform is positioned to supply.
- True routed distances via a directions API rather than a straight-line correction.

---

## Repo structure

```
.
├── data/
│   ├── hand/        # waypoints, vehicle ports — committed
│   ├── raw/         # sample data included
│   ├── clean/       # sample data included
│   └── tableau/     # exported result tables
├── scripts/
│   ├── pull.py
│   └── clean.py
├── sql/
│   ├── 01_profiling.sql
│   ├── 02_corridor.sql
│   ├── 03_funnel.sql
│   └── 04_gaps.sql
├── requirements.txt
├── .gitignore
└── README.md
```