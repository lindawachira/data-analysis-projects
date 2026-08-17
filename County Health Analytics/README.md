# County Health Analytics: Diseases, Treatment Costs & Patient Outcomes Across 5 Kenyan Counties

## Executive Summary

This project analyzes 198 patient visit records across five Kenyan counties (Nairobi, Kiambu, Kisumu, Nakuru, Machakos) to understand underlying diseases, treatment costs, insurance coverage, and patient outcomes. The dataset spans January–March 2026 and covers six conditions: Tuberculosis, Hypertension, Diabetes, Pneumonia, Malaria, and Maternal Health.

**Key findings:**
- Tuberculosis (40 cases) and Hypertension (39 cases) are the two highest-burden conditions in the sample, together accounting for 40% of all visits.
- Overall recovery rate is 89%, with Tuberculosis carrying the highest mortality rate among the six conditions (5%).
- Nakuru shows the highest average treatment cost (KES 14,723) while Nairobi the lowest-cost county (KES 12,699), a 16% difference .
- Over a third of records (36%) have no insurance status recorded, representing the largest data gap in the dataset.
- Data quality issues like clinically implausible Gender/Age–Disease combinations (e.g., male "Maternal Health" cases, pediatric Hypertension deaths). This indicates that this dataset should be treated as a **simulated/practice dataset**, not real clinical records. Findings below describe patterns *within this dataset*, not verified clinical conclusions.

---

## Methodology

**1. Data Cleaning & Quality Assessment**
- Checked for missing values, duplicate records, and inconsistent categorical entries.
- Identified a duplicate `Patient ID` (P0005) assigned to two different visit records — flagged rather than silently dropped, since both rows contain distinct, plausible data.
- Consolidated inconsistent missing-value representations in the `Insurance` column into a single `Unknown` category.
- Flagged implausible Gender/Age vs. Disease combinations, since "fixing" fabricated data would misrepresent the analysis as more reliable than it is.

**2. Exploratory & Descriptive Analysis**
### Treatment Cost
- Overall average: **KES 13,290** (range: KES 1,555 – 24,900)
![Average Costs](Images/average_costs.png)
- Highest average cost by county: **Nakuru (KES 14,723)**
- Lowest average cost by county: **Nairobi (KES 12,699)**
![County Treatment Costs](Images/county_average_costs.png)
- Maternal Health has the highest average cost by disease (KES 14,873); Diabetes the lowest (KES 11,189).
![Disease Average Costs](Images/disease_average_costs.png)

### Outcomes
- **89% Recovered**, **9% Referred**, **2% Deceased** (4 patients total)
- Tuberculosis has the highest mortality rate among all six diseases (5%, 2 of 40 cases).
- Admission rate varies by disease: Hypertension patients are admitted most often (62%), Maternal Health cases least often (32%).

### Insurance Coverage
- Privately insured patients have the highest average treatment cost (KES 14,005) vs. SHA-covered patients (KES 12,242).
- Unknown insurance coverage may include cash-paying patients, but the dataset lacks a payment-method field to confirm this.
### Visit Volume
- Stable across the three-month window: 64 (Jan), 68 (Feb), 66 (Mar) — no strong seasonal signal in this timeframe.
![Patient Volume](Images/volume.png)

---

## Recommendations

1. **Strengthen data validation at collection.** Cross-field checks (e.g., Disease vs. Gender/Age logic) would catch entry errors before they reach analysis — critical if this pipeline is later applied to real patient data.
2. **Standardize missing-value conventions** across all fields to avoid undercounting data gaps.
3. **Investigate the Nakuru cost premium** against case severity mix and facility-level pricing to determine whether it reflects real cost drivers or a data artifact.
4. **Close the insurance reporting gap** — prioritize capturing insurance status at intake, since it currently limits confidence in any cost-by-coverage analysis.
5. **Prioritize Tuberculosis case management resources**, given it has both the highest case volume and the highest mortality rate in this sample.

---

## Next Steps

- Extend the analysis window beyond three months to test for genuine seasonal patterns.
- Build an interactive Power BI/Tableau dashboard for county-level drill-down.
- If applied to real data, validate against ground-truth clinical records before drawing operational conclusions.
- Explore age-group segmentation (pediatric / adult / elderly) against disease and outcome for a more granular view.

---

## Data Note
Several data quality issues (detailed above) indicate it is not a verified real-world clinical dataset. Analysis and recommendations should be read as a demonstration of methodology, not as public health findings.
---
### Dashboard
![Overview Dashboard](Images/overview.png)
