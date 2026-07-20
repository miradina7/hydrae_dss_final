# Hydrae Mamdani Validation

## Method

The corrected engine executes fuzzification, parallel MIN rule activation,
MAX output aggregation, and centroid defuzzification over the 0–100 domain.
All 35 antecedents, alert levels, and recommendations were checked against the
uploaded rule workbook.

## Thesis scenarios

| Scenario | Activated rules | Aggregation (S/W/C) | Risk | Status |
|---|---|---:|---:|---|
| 1 | R1=0.85, R13=0.15 | 0.85 / 0.15 / 0.00 | 20.7% | Stable |
| 2 | R1=0.30, R3=0.30, R32=0.70 | 0.30 / 0.70 / 0.00 | 38.3% | Stable |
| 3 | R19=0.40, R31=0.80 | 0.00 / 0.00 / 0.80 | 88.2% | Critical |

The original 12.5%, 64.5%, and 92.3% overrides were removed. The model was not
tuned to reproduce them.

## Boundary checks

- Temperature membership is fully Optimal at both 26°C and 30°C.
- High-oxygen membership is 1.0 at 5 mg/L and remains 1.0 above it.
- At pH 6.5: Acidic=0.35 and Optimal=0.65.
- At DO 4.2 mg/L: Low=0.40, Moderate=1.00, and High=0.60.
- Status boundaries: below 40 Stable; 40 to below 75 Warning; 75+ Critical.
- Conventional Tank scores are identical for Active Flow, Slack Tide, and N/A.
- Repeated identical inputs return identical results.

## Input validation added after supervisor stress test

- Manual water-quality inputs are limited to temperature 20–35°C, pH 4.0–10.0,
  and DO 2–10 mg/L. Entries outside these operational slider ranges display
  `INPUT TIDAK SAH`; no Optimal status or invented risk score is shown.
- Ammonia is explicitly labelled as a log-only field because it is not an
  antecedent in the Chapter 3 Mamdani model. Its prototype entry range is
  limited to 0–5 ppm; an out-of-range value blocks calculation and saving.
- Numeric-only formatters and system-specific dimension checks reject
  unrealistic farm configurations before the dashboard opens.
- Initial dimension assumptions: Pond side/diameter 1–500 m and depth 0.5–5 m;
  Cage side/diameter 1–100 m and depth 1–30 m; Conventional Tank
  side/diameter 0.5–30 m and depth 0.3–5 m.
- Species names are checked against a small prototype aquaculture whitelist
  consistent with the selected animal category. These setup limits are
  implementation assumptions because Chapter 3 does not prescribe exact farm
  dimension or species-entry boundaries.

## Implementation assumptions

- Exact outer coordinates absent from Chapter 3 use initial values derived from
  the prior code: temperature [0, 22, 26, 30, 34, 100], pH
  [0, 5.2, 7.2, 9.2, 14], and DO [0, 3, 4.2, 5, 5.4, 20].
- Moderate DO is retained as a triangular transition set peaking at 4.2 mg/L
  because the authoritative 35-rule matrix explicitly contains Low, Moderate,
  and High DO categories.
- Tide is treated as a don't-care antecedent for Conventional Tank, so both
  tidal memberships equal 1.0 and external tide selection cannot alter its score.

## Verification limitation

Structural checks, YAML parsing, rule-matrix comparison, and independent
mathematical tracing passed. A real Flutter compilation was not executed in the
preparation environment; run the commands in `README_PATCH.txt` in the project.
