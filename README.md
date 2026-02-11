# Prosper Loan Data – Portfolio Performance Analysis (SQL)

## Project Overview

This project presents a comprehensive **SQL-based portfolio analysis** of peer-to-peer loans from **Prosper**, one of the largest P2P lending platforms in the US.  
The objective is to analyze **credit risk, loan performance, borrower behavior, and investor returns** using progressively complex SQL queries.

All analyses are performed directly in SQL, focusing on **business-oriented insights** that could be relevant for risk, product, or investment decision-making.

The queries are structured from **basic to expert level**, making this repository suitable both as:
- A **portfolio project** for Data / Business Analyst roles
- A **reference library** of advanced SQL analytical patterns

---

## Dataset

- **Source:** Kaggle – Prosper Loan Dataset  
- **Download link:**  
  https://www.kaggle.com/datasets/nurudeenabdulsalaam/prosper-loan-dataset

The dataset contains detailed information about:
- Loan characteristics
- Borrower demographics and credit profiles
- Loan performance and status
- Investor payments, losses, and returns

---

## Tools & Technologies

- **SQL Server**
- Analytical SQL features:
  - Window functions
  - CTEs
  - Conditional aggregations
  - Cohort and vintage analysis
  - Risk segmentation logic

No BI tools are required to run the analysis, although results are suitable for visualization in tools like Power BI or Tableau.

---

## Project Structure

The analysis is organized by **complexity tiers**, from basic exploratory queries to expert-level portfolio modeling.

### Complexity Tiers

- **Tier 1 – Basic**
  - Simple SELECT statements
  - Filtering and basic aggregations
  - Initial loan performance exploration

- **Tier 2 – Intermediate**
  - GROUP BY with CASE expressions
  - Risk segmentation
  - Default rate and return comparisons

- **Tier 3 – Advanced**
  - CTE-based cohort and vintage analysis
  - Time-based trends
  - Repeat borrower behavior analysis

- **Tier 4 – Expert**
  - Multi-factor risk models
  - Stress testing scenarios
  - Composite borrower risk scoring
  - Portfolio-level concentration analysis

Queries are ordered from **least to most complex** to clearly demonstrate analytical progression.

---

## Key Business Questions Addressed

- How well do Prosper risk ratings predict real defaults?
- How does borrower income and DTI impact loan performance?
- Are repeat borrowers less risky than first-time borrowers?
- How do defaults evolve over time by origination cohort?
- What is the real net return for lenders after losses?
- Which borrower attributes correlate most with default risk?
- How concentrated is portfolio risk by geography or borrower type?

---

## Skills Demonstrated

- Advanced SQL analytics
- Financial and credit risk analysis
- Loan portfolio performance evaluation
- Business-oriented data modeling
- Clean, documented, production-ready SQL code

---

## How to Use This Repository

1. Download the dataset from Kaggle
2. Import the CSV into **SQL Server**
3. Run the queries in order (from Tier 1 to Tier 4)
4. Optionally export results for visualization or reporting

---

## Author

**David Stocco**

- GitHub:  
  https://github.com/davidstocco2024-cell
- LinkedIn:  
  https://www.linkedin.com/in/david-stocco-35ba40278/

---

## Notes

This project is for **educational and portfolio purposes only**.  
The analysis reflects historical data and does not constitute financial advice.
