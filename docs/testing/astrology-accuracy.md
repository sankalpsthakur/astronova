# Astronova – Quantitative Astrology Accuracy (Backend)

Generated: `2025-12-18T16:49:00Z`

This report measures the **objective/astronomical accuracy** of Astronova’s backend calculations against **Swiss Ephemeris** (pyswisseph).

## Scope (what we can measure)
- **Measured quantitatively (objective):** planetary longitudes, lunar nodes (Rahu/Ketu), and Ascendant/Lagna longitudes.
- **Measured deterministically:** Vimshottari starting Mahadasha lord + balance years from sidereal Moon longitude.
- **Not objectively measurable:** narrative interpretations (chat/report prose), “strength” scoring heuristics, house “influence” text.

## Ground truth
- Swiss Ephemeris library: `2.10.03`
- pyswisseph build: `20230604`
- Vedic/Kundali: **sidereal Lahiri** (`SIDM_LAHIRI`) + whole-sign houses derived from Lagna (house assignment is a modeling choice; Lagna longitude is what’s validated).

## Method
- **Dataset:** `60` UTC timestamps (seed `42`) sampled uniformly over `1970..2035` (months 1..12, days 1..28, time HH:MM) × `5` locations = `300` chart instances.
- **Locations:**
  - Mumbai: `19.0760,72.8777`
  - New York: `40.7128,-74.0060`
  - London: `51.5074,-0.1278`
  - Sydney: `-33.8688,151.2093`
  - Gulf of Guinea: `0.0000,0.0000`
- **Bodies compared:** Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto, Rahu (True Node), derived Ketu (+180°), Ascendant.
- **Error metric:** angular distance in degrees: `abs((a-b+180) % 360 - 180)`.
- **Precision note:** API/service outputs are rounded to **0.01°**, so the theoretical maximum rounding error is **0.005° (~18 arcsec)**.

## Results (Swiss Ephemeris available)

### Western (tropical)
- Comparisons: `3900`
- Sign match rate: `100.00%`
- Longitude error (deg): MAE `0.002541`, P95 `0.004755`, Max `0.004999`
- Longitude error (arcsec): MAE `9.15`, P95 `17.12`, Max `18.00`

### Vedic (sidereal Lahiri)
- Comparisons: `3900`
- Sign match rate: `100.00%`
- Longitude error (deg): MAE `0.002567`, P95 `0.004738`, Max `0.004987`
- Longitude error (arcsec): MAE `9.24`, P95 `17.06`, Max `17.95`

**Interpretation:** for both Western and Vedic modes, the measured error is consistent with the expected rounding-only error band; the underlying Swiss Ephemeris values match.

## Vimshottari dasha accuracy (Time Travel math)
- Samples: `60`
- Starting Mahadasha lord match rate: `100.00%`
- Balance years error (years): MAE `0.00002481`, Max `0.00004984`
- Balance years error (~minutes): MAE `13.05`, Max `26.21`

**Interpretation:** starting dasha lord is exact; balance-year error is purely from rounding to 4 decimals in the API payload.

## Fallback mode accuracy (Swiss Ephemeris missing)
When `pyswisseph` is not installed, Astronova uses simplified fallback calculations (intentionally marked as rough approximations).

- Western fallback (deg): MAE `90.25`, P95 `169.86`, Max `179.80`
- Vedic fallback (deg): MAE `90.16`, P95 `170.08`, Max `179.89`

**Interpretation:** fallback mode is **not suitable** for accuracy-sensitive astrology; production should ensure Swiss Ephemeris is available.

## Where these calculations surface in the API
- Swagger UI: `GET /docs` (spec: `GET /api/v1/openapi.yaml`)
- Ephemeris: `GET /api/v1/ephemeris/current?system=western|vedic`
- Birth charts: `POST /api/v1/chart/generate` (returns `westernChart` + `vedicChart` with Lagna/houses/dashas)
- Time Travel dashas: `POST /api/v1/astrology/dashas/complete`

## How to reproduce locally
1) Run the generator:
   - `./.venv/bin/python tools/generate_astrology_accuracy_report.py`
2) Run the backend test suite:
   - `./.venv/bin/python -m pytest -q server/tests`
