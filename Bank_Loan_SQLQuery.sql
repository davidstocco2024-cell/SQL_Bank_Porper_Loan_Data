/*
================================================================================
  PROJECT      : Prosper Loan Data - Portfolio Performance Analysis
  DATABASE     : prosperLoanData (dbo)
  AUTHOR       : David Stocco
  CREATED      : 2026-02-10
  DESCRIPTION  : Comprehensive SQL analysis of peer-to-peer loan data from Prosper.
                 Queries are ordered from LEAST to MOST complex.

  COMPLEXITY TIERS:
  ─────────────────────────────────────────────────────────────────────────────
  ★☆☆☆  TIER 1 — Basic SELECT + WHERE + simple aggregations (no joins, no CTEs)
  ★★☆☆  TIER 2 — GROUP BY + CASE + calculated columns + subqueries
  ★★★☆  TIER 3 — Single CTE + window functions or multi-column GROUP BY
  ★★★★  TIER 4 — Multiple CTEs + window functions + cross-joins + subqueries

  SECTIONS:
  ─────────────────────────────────────────────────────────────────────────────
  TIER 1 — BASIC (Sections 01–06)
    01. Loan Performance Tracking (Post-2009)
    02. Net Return Per Loan
    03. Time to Default (Survival Analysis)
    04. Loan Performance Summary by Status
    05. Top Explanatory Factors for Default
    06. Year-over-Year Temporal Trend Analysis

  TIER 2 — INTERMEDIATE (Sections 07–15)
    07. Loan Distribution by Risk Rating vs. Real Performance
    08. Expected Loss vs. Actual (Realized) Loss by Rating
    09. Social Investment vs. Standard Investment
    10. DTI Segmentation & Default Rate Analysis
    11. Loan Term & Rate Optimization Analysis
    12. Homeownership & Occupation Risk Profiles
    13. Investor Concentration & Diversification Risk
    14. Principal Loss & Recovery Rate Analysis
    15. Risk-Return Ranking by Rating & Term

  TIER 3 — ADVANCED (Sections 16–26)
    16. Repeat Borrower Analysis (Basic)
    17. Cohort Analysis by Origination Year
    18. DTI Buckets & Delinquency Correlation
    19. Vintage Analysis (Cohort by Quarter)
    20. Loan Term Comparison (36 vs 60 months)
    21. Risk-Adjusted Yield Matrix (Lender's Perspective)
    22. Risk Analysis by Credit Score Range & Employment Status
    23. Repeat Borrower Behavior & Credit History Analysis
    24. Monthly Seasonality & Trend Analysis
    25. Investment Returns & Yield Analysis by Investor Tier
    26. Portfolio Geographic Concentration (State-Level)

  TIER 4 — EXPERT (Sections 27–38)
    27. Credit Utilization Analysis
    28. Delinquency History Impact Analysis
    29. Investor Performance Analysis
    30. Portfolio Stress Test (Scenario Analysis)
    31. Geographic Risk Analysis
    32. Borrower Characteristics Analysis
    33. Monthly Payment to Income Analysis
    34. Occupational Risk Segmentation with Income Correlation
    35. Default Propensity Model (Multi-Factor Segmentation)
    36. Borrower Migration & Performance Progression
    37. Composite Borrower Risk Score Model
    38. Comprehensive Risk Scorecard
================================================================================
*/


-- ============================================================================
-- ★☆☆☆  TIER 1 — BASIC
-- Simple SELECT, WHERE, GROUP BY, and flat aggregations.
-- No CTEs. No window functions. No self-referencing subqueries.
-- ============================================================================


-- ============================================================================
-- SECTION 01: LOAN PERFORMANCE TRACKING (Post-2009 Loans)           ★☆☆☆
-- ============================================================================
-- Complexity: Plain SELECT + WHERE filter on a date column.
-- Purpose   : Baseline snapshot of disbursements and returns after 2009.
-- ============================================================================
SELECT
      [LoanOriginationDate]
    , [LoanOriginalAmount]
    , [LP_CustomerPayments]
    , [EstimatedReturn]
    , [EstimatedLoss]
FROM [dbo].[prosperLoanData]
WHERE [LoanOriginationDate] >= '2009-12-31';


-- ============================================================================
-- SECTION 02: NET RETURN PER LOAN                                    ★☆☆☆
-- ============================================================================
-- Complexity: SELECT with a single arithmetic column. WHERE on LoanStatus.
-- Purpose   : Calculates profitability per loan.
--             Net Return = Customer Payments - Gross Principal Loss.
-- ============================================================================
SELECT
      LoanNumber
    , LoanOriginalAmount
    , LenderYield
    , LP_CustomerPayments
    , LP_GrossPrincipalLoss
    , (LP_CustomerPayments - LP_GrossPrincipalLoss)                                AS NetReturn
FROM dbo.prosperLoanData
WHERE LoanStatus IN ('Completed', 'Chargedoff', 'Defaulted');


-- ============================================================================
-- SECTION 03: TIME TO DEFAULT — SURVIVAL ANALYSIS                    ★☆☆☆
-- ============================================================================
-- Complexity: SELECT + DATEDIFF + two WHERE conditions.
-- Purpose   : Measures days from origination to closure for bad loans.
--             Foundation for survival/hazard rate modeling.
-- ============================================================================
SELECT
      LoanNumber
    , LoanOriginationDate
    , ClosedDate
    , DATEDIFF(DAY, LoanOriginationDate, ClosedDate)                               AS DaysToDefault
    , LoanStatus
FROM dbo.prosperLoanData
WHERE LoanStatus IN ('Defaulted', 'Chargedoff')
  AND ClosedDate  IS NOT NULL;


-- ============================================================================
-- SECTION 04: LOAN PERFORMANCE SUMMARY BY STATUS                     ★☆☆☆
-- ============================================================================
-- Complexity: GROUP BY with COUNT, AVG, MIN, MAX, and a scalar subquery
--             for portfolio share. No CTEs or window functions.
-- Purpose   : High-level breakdown of portfolio by loan status.
--             Essential starting point for any executive dashboard.
-- ============================================================================
SELECT
      LoanStatus
    , COUNT(*)                                                                     AS TotalLoans
    , COUNT(DISTINCT MemberKey)                                                    AS UniqueBorrowers
    , AVG(LoanOriginalAmount)                                                      AS AvgLoanAmount
    , MIN(LoanOriginalAmount)                                                      AS MinLoanAmount
    , MAX(LoanOriginalAmount)                                                      AS MaxLoanAmount
    , AVG(CAST(BorrowerAPR AS DECIMAL(10, 4)))                                     AS AvgBorrowerAPR
    , AVG(MonthlyLoanPayment)                                                      AS AvgMonthlyPayment
    , ROUND(
        CAST(COUNT(*) AS FLOAT)
        / (SELECT COUNT(*) FROM dbo.prosperLoanData) * 100
      , 2)                                                                         AS PortfolioShare_Pct
FROM dbo.prosperLoanData
GROUP BY LoanStatus
ORDER BY TotalLoans DESC;


-- ============================================================================
-- SECTION 05: TOP EXPLANATORY FACTORS FOR DEFAULT                    ★☆☆☆
-- ============================================================================
-- Complexity: GROUP BY on a single column with four AVG aggregations.
-- Purpose   : Profiles average borrower characteristics by loan outcome.
--             Quick first-pass for identifying default predictors.
-- ============================================================================
SELECT
      LoanStatus
    , AVG(BorrowerAPR)                                                             AS AvgBorrowerAPR
    , AVG(DebtToIncomeRatio)                                                       AS AvgDTI
    , AVG(StatedMonthlyIncome)                                                     AS AvgMonthlyIncome
    , AVG(OpenCreditLines)                                                         AS AvgOpenCreditLines
    , COUNT(*)                                                                     AS TotalLoans
FROM dbo.prosperLoanData
GROUP BY LoanStatus;


-- ============================================================================
-- SECTION 06: YEAR-OVER-YEAR TEMPORAL TREND ANALYSIS                 ★☆☆☆
-- ============================================================================
-- Complexity: GROUP BY on YEAR() extraction. Multiple aggregations.
--             TRY_CONVERT handles inconsistent date formats safely.
-- Purpose   : Tracks origination volume and default rates across years.
--             Shows macroeconomic cycles and platform growth.
-- ============================================================================
SELECT
      YEAR(TRY_CONVERT(DATETIME, LoanOriginationDate))                             AS OriginationYear
    , COUNT(*)                                                                     AS LoansOriginated
    , AVG(LoanOriginalAmount)                                                      AS AvgLoanAmount
    , AVG(CAST(BorrowerRate AS DECIMAL(10, 4)))                                    AS AvgInterestRate
    , CAST(ROUND(
        SUM(CASE WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*)
      , 2) AS DECIMAL(5, 2))                                                       AS DefaultRate_Pct
    , AVG(Investors)                                                               AS AvgInvestorsPerLoan
    , SUM(LoanOriginalAmount)                                                      AS TotalLoanVolume
    , CAST(ROUND(
        SUM(CASE WHEN LoanStatus = 'Current' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*)
      , 2) AS DECIMAL(5, 2))                                                       AS CurrentLoans_Pct
FROM dbo.prosperLoanData
WHERE LoanOriginationDate IS NOT NULL
GROUP BY YEAR(TRY_CONVERT(DATETIME, LoanOriginationDate))
ORDER BY OriginationYear DESC;


-- ============================================================================
-- ★★☆☆  TIER 2 — INTERMEDIATE
-- Multi-column GROUP BY, CASE bucketing, HAVING, and inline subqueries.
-- Still flat SQL — no CTEs, no window functions.
-- ============================================================================


-- ============================================================================
-- SECTION 07: LOAN DISTRIBUTION BY RISK RATING VS. REAL PERFORMANCE  ★★☆☆
-- ============================================================================
-- Complexity: GROUP BY with conditional AVG using CASE WHEN inside aggregate.
-- Purpose   : Validates Prosper's rating model against actual default behavior.
-- ============================================================================
SELECT
      ProsperRating_Alpha
    , COUNT(*)                                                                     AS TotalLoans
    , AVG(BorrowerAPR)                                                             AS AvgBorrowerAPR
    , AVG(
        CASE
            WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1.0
            ELSE 0
        END
      )                                                                            AS DefaultRate
    , AVG(LenderYield)                                                             AS AvgLenderYield
FROM dbo.prosperLoanData
WHERE ProsperRating_Alpha IS NOT NULL
GROUP BY ProsperRating_Alpha
ORDER BY ProsperRating_Alpha;


-- ============================================================================
-- SECTION 08: EXPECTED LOSS VS. ACTUAL (REALIZED) LOSS BY RATING     ★★☆☆
-- ============================================================================
-- Complexity: Conditional AVG with NULLIF division guard inside aggregate.
-- Purpose   : Detects model miscalibration between estimated and real losses.
-- ============================================================================
SELECT
      ProsperRating_Alpha
    , AVG(EstimatedLoss)                                                           AS AvgEstimatedLoss
    , AVG(
        CASE
            WHEN LoanStatus IN ('Chargedoff', 'Defaulted')
                THEN LP_GrossPrincipalLoss / NULLIF(LoanOriginalAmount, 0)
            ELSE 0
        END
      )                                                                            AS AvgRealizedLossRatio
FROM dbo.prosperLoanData
GROUP BY ProsperRating_Alpha
ORDER BY ProsperRating_Alpha;


-- ============================================================================
-- SECTION 09: SOCIAL INVESTMENT VS. STANDARD INVESTMENT              ★★☆☆
-- ============================================================================
-- Complexity: GROUP BY on InvestmentFromFriendsCount with conditional AVG.
-- Purpose   : Tests if peer-backed loans show lower APR or default rates.
-- ============================================================================
SELECT
      InvestmentFromFriendsCount
    , COUNT(*)                                                                     AS TotalLoans
    , AVG(BorrowerAPR)                                                             AS AvgBorrowerAPR
    , AVG(
        CASE
            WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1.0
            ELSE 0
        END
      )                                                                            AS DefaultRate
FROM dbo.prosperLoanData
GROUP BY InvestmentFromFriendsCount
ORDER BY InvestmentFromFriendsCount;


-- ============================================================================
-- SECTION 10: DTI SEGMENTATION & DEFAULT RATE ANALYSIS               ★★☆☆
-- ============================================================================
-- Complexity: CASE expression used both in SELECT and GROUP BY for bucketing.
-- Purpose   : Tests hypothesis that higher debt load correlates with default.
-- ============================================================================
SELECT
      CASE
          WHEN DebtToIncomeRatio < 0.20  THEN 'Low DTI  (< 20%)'
          WHEN DebtToIncomeRatio < 0.35  THEN 'Mid DTI  (20–35%)'
          ELSE                                'High DTI (> 35%)'
      END                                                                          AS DTISegment
    , COUNT(*)                                                                     AS TotalLoans
    , AVG(BorrowerAPR)                                                             AS AvgBorrowerAPR
    , AVG(
        CASE
            WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1.0
            ELSE 0
        END
      )                                                                            AS DefaultRate
FROM dbo.prosperLoanData
WHERE DebtToIncomeRatio IS NOT NULL
GROUP BY
    CASE
        WHEN DebtToIncomeRatio < 0.20  THEN 'Low DTI  (< 20%)'
        WHEN DebtToIncomeRatio < 0.35  THEN 'Mid DTI  (20–35%)'
        ELSE                                'High DTI (> 35%)'
    END;


-- ============================================================================
-- SECTION 11: LOAN TERM & RATE OPTIMIZATION ANALYSIS                 ★★☆☆
-- ============================================================================
-- Complexity: GROUP BY on Term with multiple CAST/ROUND metrics and two rates.
-- Purpose   : Tests if longer terms carry disproportionate default risk.
-- ============================================================================
SELECT
      Term
    , COUNT(*)                                                                     AS TotalLoans
    , AVG(LoanOriginalAmount)                                                      AS AvgLoanAmount
    , AVG(CAST(BorrowerRate AS DECIMAL(10, 4)))                                    AS AvgBorrowerRate
    , AVG(CAST(BorrowerAPR  AS DECIMAL(10, 4)))                                    AS AvgBorrowerAPR
    , CAST(ROUND(
        SUM(CASE WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*)
      , 2) AS DECIMAL(5, 2))                                                       AS DefaultRate_Pct
    , CAST(ROUND(
        SUM(CASE WHEN LoanStatus = 'Completed' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*)
      , 2) AS DECIMAL(5, 2))                                                       AS CompletionRate_Pct
    , AVG(MonthlyLoanPayment)                                                      AS AvgMonthlyPayment
    , SUM(MonthlyLoanPayment)                                                      AS TotalMonthlyPayments
    , AVG(Investors)                                                               AS AvgInvestorsPerLoan
FROM dbo.prosperLoanData
WHERE Term IS NOT NULL
GROUP BY Term
ORDER BY Term;


-- ============================================================================
-- SECTION 12: HOMEOWNERSHIP & OCCUPATION RISK PROFILES               ★★☆☆
-- ============================================================================
-- Complexity: GROUP BY on two columns. HAVING filters for statistical minimum.
-- Purpose   : Identifies high-risk occupation/homeownership combinations.
-- ============================================================================
SELECT
      IsBorrowerHomeowner
    , Occupation
    , COUNT(*)                                                                     AS LoanCount
    , CAST(ROUND(
        SUM(CASE WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*)
      , 2) AS DECIMAL(5, 2))                                                       AS DefaultRate_Pct
    , AVG(LoanOriginalAmount)                                                      AS AvgLoanAmount
    , AVG(CAST(BorrowerRate AS DECIMAL(10, 4)))                                    AS AvgInterestRate
    , AVG(CreditScoreRangeLower)                                                   AS AvgCreditScore
    , AVG(CAST(DebtToIncomeRatio AS DECIMAL(10, 2)))                               AS AvgDTI
FROM dbo.prosperLoanData
WHERE Occupation IS NOT NULL
  AND Occupation <> 'Other'
GROUP BY IsBorrowerHomeowner, Occupation
HAVING COUNT(*) >= 100
ORDER BY DefaultRate_Pct DESC;


-- ============================================================================
-- SECTION 13: INVESTOR CONCENTRATION & DIVERSIFICATION RISK          ★★☆☆
-- ============================================================================
-- Complexity: CASE bucketing in both SELECT and GROUP BY. Scalar subquery
--             for portfolio share calculation.
-- Purpose   : Tests whether investor concentration correlates with outcomes.
-- ============================================================================
SELECT
      CASE
          WHEN Investors = 1                    THEN '1 Investor'
          WHEN Investors BETWEEN 2   AND 10     THEN '2–10 Investors'
          WHEN Investors BETWEEN 11  AND 50     THEN '11–50 Investors'
          WHEN Investors BETWEEN 51  AND 100    THEN '51–100 Investors'
          WHEN Investors BETWEEN 101 AND 500    THEN '101–500 Investors'
          ELSE                                       '500+ Investors'
      END                                                                          AS InvestorTier
    , COUNT(*)                                                                     AS LoanCount
    , CAST(ROUND(
        CAST(COUNT(*) AS FLOAT)
        / (SELECT COUNT(*) FROM dbo.prosperLoanData) * 100
      , 2) AS DECIMAL(5, 2))                                                       AS PortfolioShare_Pct
    , AVG(LoanOriginalAmount)                                                      AS AvgLoanAmount
    , AVG(PercentFunded)                                                           AS AvgPercentFunded
    , CAST(ROUND(
        SUM(CASE WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*)
      , 2) AS DECIMAL(5, 2))                                                       AS DefaultRate_Pct
    , AVG(CAST(BorrowerRate AS DECIMAL(10, 4)))                                    AS AvgBorrowerRate
    , SUM(LoanOriginalAmount)                                                      AS TotalLoanVolume
FROM dbo.prosperLoanData
WHERE Investors IS NOT NULL
GROUP BY
    CASE
        WHEN Investors = 1                    THEN '1 Investor'
        WHEN Investors BETWEEN 2   AND 10     THEN '2–10 Investors'
        WHEN Investors BETWEEN 11  AND 50     THEN '11–50 Investors'
        WHEN Investors BETWEEN 51  AND 100    THEN '51–100 Investors'
        WHEN Investors BETWEEN 101 AND 500    THEN '101–500 Investors'
        ELSE                                       '500+ Investors'
    END
ORDER BY LoanCount DESC;


-- ============================================================================
-- SECTION 14: PRINCIPAL LOSS & RECOVERY RATE ANALYSIS                ★★☆☆
-- ============================================================================
-- Complexity: CASE bucketing in GROUP BY. NULLIF division guard.
--             Multiple SUM and AVG across financial loss columns.
-- Purpose   : Calculates recovery effectiveness on defaulted loans.
--             Recovery Rate = Non-Principal Recoveries / Gross Principal Loss.
-- ============================================================================
SELECT
      CASE
          WHEN LoanStatus = 'Completed'                        THEN 'Completed'
          WHEN LoanStatus = 'Current'                          THEN 'Current'
          WHEN LoanStatus IN ('Defaulted', 'Chargedoff')       THEN 'Defaulted / Charged-Off'
          ELSE                                                      'Other'
      END                                                                          AS LoanOutcome
    , COUNT(*)                                                                     AS LoanCount
    , SUM(LoanOriginalAmount)                                                      AS TotalOriginalAmount
    , AVG(CAST(LP_GrossPrincipalLoss           AS DECIMAL(15, 2)))                 AS AvgGrossPrincipalLoss
    , AVG(CAST(LP_NetPrincipalLoss             AS DECIMAL(15, 2)))                 AS AvgNetPrincipalLoss
    , SUM(CAST(LP_GrossPrincipalLoss           AS DECIMAL(15, 2)))                 AS TotalGrossLoss
    , SUM(CAST(LP_NetPrincipalLoss             AS DECIMAL(15, 2)))                 AS TotalNetLoss
    , AVG(CAST(LP_NonPrincipalRecoverypayments AS DECIMAL(15, 2)))                 AS AvgRecoveries
    , CAST(ROUND(
        AVG(CAST(LP_NonPrincipalRecoverypayments AS DECIMAL(15, 2)))
        / NULLIF(AVG(CAST(LP_GrossPrincipalLoss  AS DECIMAL(15, 2))), 0) * 100
      , 2) AS DECIMAL(5, 2))                                                       AS RecoveryRate_Pct
    , AVG(Investors)                                                               AS AvgInvestors
FROM dbo.prosperLoanData
WHERE LP_GrossPrincipalLoss IS NOT NULL
GROUP BY
    CASE
        WHEN LoanStatus = 'Completed'                  THEN 'Completed'
        WHEN LoanStatus = 'Current'                    THEN 'Current'
        WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 'Defaulted / Charged-Off'
        ELSE                                               'Other'
    END
ORDER BY LoanCount DESC;


-- ============================================================================
-- SECTION 15: RISK-RETURN RANKING BY RATING & TERM                   ★★☆☆
-- ============================================================================
-- Complexity: GROUP BY on two columns. Arithmetic expression mixing two
--             conditional averages to produce a derived metric.
-- Purpose   : Risk-Adjusted Return = Lender Yield - Default Rate.
--             Identifies optimal rating/term combinations for investors.
-- ============================================================================
SELECT
      ProsperRating_Alpha
    , Term
    , COUNT(*)                                                                     AS TotalLoans
    , AVG(LenderYield)                                                             AS AvgLenderYield
    , AVG(
        CASE
            WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1.0
            ELSE 0
        END
      )                                                                            AS DefaultRate
    , AVG(LenderYield)
      - AVG(
            CASE
                WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1.0
                ELSE 0
            END
        )                                                                          AS RiskAdjustedReturn
FROM dbo.prosperLoanData
GROUP BY ProsperRating_Alpha, Term
ORDER BY RiskAdjustedReturn DESC;


-- ============================================================================
-- ★★★☆  TIER 3 — ADVANCED
-- Single or dual CTEs. Window functions (ROW_NUMBER, SUM OVER, AVG OVER).
-- Multi-dimensional GROUP BY. HAVING + ORDER BY on computed expressions.
-- ============================================================================


-- ============================================================================
-- SECTION 16: REPEAT BORROWER ANALYSIS (Basic)                       ★★★☆
-- ============================================================================
-- Complexity: Single CTE aggregates per MemberKey, outer query re-aggregates.
--             Two-level aggregation (loan → borrower → group).
-- Purpose   : Checks if repeat borrowers have higher or lower default rates.
-- ============================================================================
WITH BorrowerLoans AS (
    SELECT
          MemberKey
        , COUNT(*)                                                                 AS TotalLoans
        , SUM(
            CASE
                WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1
                ELSE 0
            END
          )                                                                        AS BadLoans
    FROM dbo.prosperLoanData
    WHERE MemberKey IS NOT NULL
    GROUP BY MemberKey
)
SELECT
      TotalLoans
    , COUNT(*)                                                                     AS BorrowerCount
    , AVG(BadLoans * 1.0 / TotalLoans)                                             AS AvgDefaultRate
FROM BorrowerLoans
GROUP BY TotalLoans
ORDER BY TotalLoans;


-- ============================================================================
-- SECTION 17: COHORT ANALYSIS BY ORIGINATION YEAR                    ★★★☆
-- ============================================================================
-- Complexity: Single CTE for readability. Simple GROUP BY on extracted year.
--             Foundation for more complex vintage analyses.
-- Purpose   : Groups loans into annual cohorts to detect quality trends.
-- ============================================================================
WITH Cohorts AS (
    SELECT
          YEAR(LoanOriginationDate)  AS CohortYear
        , LoanStatus
        , LP_GrossPrincipalLoss
    FROM dbo.prosperLoanData
)
SELECT
      CohortYear
    , COUNT(*)                                                                     AS TotalLoans
    , SUM(
        CASE
            WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1
            ELSE 0
        END
      )                                                                            AS BadLoans
    , SUM(LP_GrossPrincipalLoss)                                                   AS TotalGrossLoss
FROM Cohorts
GROUP BY CohortYear
ORDER BY CohortYear;


-- ============================================================================
-- SECTION 18: DTI BUCKETS & DELINQUENCY CORRELATION                  ★★★☆
-- ============================================================================
-- Complexity: Single CTE with CASE bucketing + outer GROUP BY on bucket label.
-- Purpose   : Shows how DTI financial stress translates into missed payments.
-- ============================================================================
WITH DTIBuckets AS (
    SELECT
          ListingKey
        , LoanStatus
        , LoanCurrentDaysDelinquent
        , DebtToIncomeRatio
        , CASE
              WHEN DebtToIncomeRatio <= 0.20                               THEN '0–20%  (Low)'
              WHEN DebtToIncomeRatio >  0.20 AND DebtToIncomeRatio <= 0.40 THEN '21–40% (Mid)'
              WHEN DebtToIncomeRatio >  0.40 AND DebtToIncomeRatio <= 0.60 THEN '41–60% (High)'
              ELSE                                                              '60%+   (Critical)'
          END                                                                      AS DTIRange
    FROM dbo.prosperLoanData
    WHERE DebtToIncomeRatio IS NOT NULL
)
SELECT
      DTIRange
    , COUNT(*)                                                                     AS BorrowerCount
    , AVG(LoanCurrentDaysDelinquent)                                               AS AvgDaysDelinquent
    , CAST(
        SUM(CASE WHEN LoanStatus <> 'Current' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*)
      AS DECIMAL(10, 2))                                                           AS DelinquencyRate_Pct
FROM DTIBuckets
GROUP BY DTIRange
ORDER BY DTIRange;


-- ============================================================================
-- SECTION 19: VINTAGE ANALYSIS — COHORT BY QUARTER                   ★★★☆
-- ============================================================================
-- Complexity: GROUP BY on two date extractions (YEAR + QUARTER). FORMAT()
--             function for currency display. Two-column ORDER BY.
-- Purpose   : Tracks quarterly volume, credit quality, and ticket size trends.
-- ============================================================================
SELECT
      YEAR(CAST(LoanOriginationDate AS DATETIME2))                                 AS OriginationYear
    , DATEPART(QUARTER, CAST(LoanOriginationDate AS DATETIME2))                    AS OriginationQuarter
    , COUNT(*)                                                                     AS LoansIssued
    , AVG(ProsperScore)                                                            AS AvgProsperScore
    , FORMAT(SUM(LoanOriginalAmount), 'C', 'en-US')                                AS QuarterlyVolume
    , FORMAT(AVG(LoanOriginalAmount), 'C', 'en-US')                                AS AvgTicketSize
FROM dbo.prosperLoanData
WHERE LoanOriginationDate IS NOT NULL
GROUP BY
      YEAR(CAST(LoanOriginationDate AS DATETIME2))
    , DATEPART(QUARTER, CAST(LoanOriginationDate AS DATETIME2))
ORDER BY OriginationYear DESC, OriginationQuarter DESC;


-- ============================================================================
-- SECTION 20: LOAN TERM COMPARISON (36 vs 60 Months)                 ★★★☆
-- ============================================================================
-- Complexity: CTE pre-aggregates, outer query adds derived ratios
--             (MonthsToPayoff, PaymentToIncomeRatio) via arithmetic on CTEs.
-- Purpose   : Apples-to-apples comparison of term structures.
-- ============================================================================
WITH TermCompare AS (
    SELECT
          Term
        , COUNT(*)                                                                 AS LoanCount
        , SUM(LoanOriginalAmount)                                                  AS TotalVolume
        , AVG(LoanOriginalAmount)                                                  AS AvgLoanAmount
        , AVG(BorrowerRate * 100)                                                  AS AvgInterestRate
        , SUM(CASE WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1 ELSE 0 END) AS DefaultCount
        , AVG(DebtToIncomeRatio)                                                   AS AvgDTI
        , AVG(StatedMonthlyIncome)                                                 AS AvgMonthlyIncome
        , AVG((CreditScoreRangeLower + CreditScoreRangeUpper) / 2.0)               AS AvgCreditScore
        , AVG(MonthlyLoanPayment)                                                  AS AvgMonthlyPayment
    FROM dbo.prosperLoanData
    WHERE Term IN (36, 60)
    GROUP BY Term
)
SELECT
      Term
    , LoanCount
    , TotalVolume
    , ROUND(AvgLoanAmount,    0)                                                   AS AvgLoanAmount
    , ROUND(AvgInterestRate,  2)                                                   AS AvgInterestRate
    , DefaultCount
    , ROUND(DefaultCount * 100.0 / LoanCount, 2)                                   AS DefaultRate_Pct
    , ROUND(AvgDTI,           3)                                                   AS AvgDTI
    , ROUND(AvgMonthlyIncome, 0)                                                   AS AvgMonthlyIncome
    , ROUND(AvgCreditScore,   0)                                                   AS AvgCreditScore
    , ROUND(AvgMonthlyPayment, 2)                                                  AS AvgMonthlyPayment
    , ROUND(AvgLoanAmount / NULLIF(AvgMonthlyPayment, 0), 1)                       AS MonthsToPayoff
    , ROUND(AvgMonthlyPayment * 100.0 / NULLIF(AvgMonthlyIncome, 0), 2)            AS PaymentToIncome_Pct
    , CASE Term
          WHEN 36 THEN 'Medium Term'
          WHEN 60 THEN 'Long Term'
      END                                                                          AS TermLabel
FROM TermCompare
ORDER BY Term;


-- ============================================================================
-- SECTION 21: RISK-ADJUSTED YIELD MATRIX (Lender's Perspective)      ★★★☆
-- ============================================================================
-- Complexity: Arithmetic across three AVG aggregations. FORMAT() for currency.
--             WHERE filters to normalize by term for fair comparison.
-- Purpose   : Net Estimated Yield = Lender Yield - Estimated Loss.
--             Best view of pricing adequacy relative to estimated risk.
-- ============================================================================
SELECT
      ProsperRating_Alpha
    , COUNT(ListingKey)                                                            AS TotalLoans
    , CAST(AVG(BorrowerAPR)   * 100 AS DECIMAL(10, 2))                             AS AvgBorrowerAPR_Pct
    , CAST(AVG(LenderYield)   * 100 AS DECIMAL(10, 2))                             AS AvgLenderYield_Pct
    , CAST(AVG(EstimatedLoss) * 100 AS DECIMAL(10, 2))                             AS AvgEstimatedLoss_Pct
    , CAST((AVG(LenderYield) - AVG(EstimatedLoss)) * 100 AS DECIMAL(10, 2))        AS NetEstimatedReturn_Pct
    , FORMAT(SUM(LoanOriginalAmount), 'C', 'en-US')                                AS TotalVolumeUSD
FROM dbo.prosperLoanData
WHERE ProsperRating_Alpha IS NOT NULL
  AND Term = 36
GROUP BY ProsperRating_Alpha
ORDER BY NetEstimatedReturn_Pct DESC;


-- ============================================================================
-- SECTION 22: RISK ANALYSIS BY CREDIT SCORE & EMPLOYMENT STATUS      ★★★☆
-- ============================================================================
-- Complexity: GROUP BY on two columns. COUNT(DISTINCT CASE WHEN ...) pattern.
--             HAVING filters for statistical significance (50+ loans).
-- Purpose   : Cross-tabulates credit quality and employment for segmentation.
-- ============================================================================
SELECT
      CreditScoreRangeLower                                                        AS CreditScoreFloor
    , EmploymentStatus
    , COUNT(*)                                                                     AS LoanCount
    , CAST(ROUND(
        SUM(CASE WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*)
      , 2) AS DECIMAL(5, 2))                                                       AS DefaultRate_Pct
    , AVG(CAST(BorrowerRate AS DECIMAL(10, 4)))                                    AS AvgInterestRate
    , AVG(LoanOriginalAmount)                                                      AS AvgLoanAmount
    , AVG(CAST(DebtToIncomeRatio AS DECIMAL(10, 2)))                               AS AvgDTI
    , COUNT(
        DISTINCT CASE
            WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN MemberKey
        END
      )                                                                            AS UniqueDefaulters
FROM dbo.prosperLoanData
WHERE CreditScoreRangeLower IS NOT NULL
  AND EmploymentStatus       IS NOT NULL
GROUP BY CreditScoreRangeLower, EmploymentStatus
HAVING COUNT(*) >= 50
ORDER BY CreditScoreRangeLower DESC, DefaultRate_Pct DESC;


-- ============================================================================
-- SECTION 23: REPEAT BORROWER BEHAVIOR & CREDIT HISTORY ANALYSIS     ★★★☆
-- ============================================================================
-- Complexity: Single CTE per borrower. Outer GROUP BY on computed TotalLoans.
--             HAVING caps the range for relevance.
-- Purpose   : Measures how borrowing frequency correlates with default rate.
-- ============================================================================
WITH BorrowerMetrics AS (
    SELECT
          MemberKey
        , COUNT(*)                                                                 AS TotalLoans
        , SUM(LoanOriginalAmount)                                                  AS TotalBorrowed
        , AVG(CAST(BorrowerRate AS DECIMAL(10, 4)))                                AS AvgBorrowRate
        , SUM(
            CASE
                WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1
                ELSE 0
            END
          )                                                                        AS TimesFailed
        , AVG(CreditScoreRangeLower)                                               AS AvgCreditScore
        , AVG(CAST(DebtToIncomeRatio AS DECIMAL(10, 2)))                           AS AvgDTI
    FROM dbo.prosperLoanData
    WHERE MemberKey IS NOT NULL
    GROUP BY MemberKey
)
SELECT
      TotalLoans
    , COUNT(MemberKey)                                                             AS BorrowerCount
    , AVG(TotalBorrowed)                                                           AS AvgTotalBorrowed
    , AVG(AvgBorrowRate)                                                           AS AvgBorrowRate
    , CAST(ROUND(
        SUM(TimesFailed) * 100.0 / SUM(TotalLoans)
      , 2) AS DECIMAL(5, 2))                                                       AS OverallDefaultRate_Pct
    , AVG(AvgCreditScore)                                                          AS AvgCreditScore
    , AVG(AvgDTI)                                                                  AS AvgDTI
FROM BorrowerMetrics
GROUP BY TotalLoans
HAVING TotalLoans <= 10
ORDER BY TotalLoans DESC;


-- ============================================================================
-- SECTION 24: MONTHLY SEASONALITY & TREND ANALYSIS                   ★★★☆
-- ============================================================================
-- Complexity: CTE with CASE-based quarter derivation + GROUP BY on 3 columns.
--             Outer query adds two window functions (AVG OVER PARTITION BY).
-- Purpose   : Detects seasonal patterns and intra-year default trends.
-- ============================================================================
WITH MonthlyCohorts AS (
    SELECT
          YEAR(TRY_CONVERT(DATETIME, LoanOriginationDate))                         AS OriginationYear
        , MONTH(TRY_CONVERT(DATETIME, LoanOriginationDate))                        AS OriginationMonth
        , CASE
              WHEN MONTH(TRY_CONVERT(DATETIME, LoanOriginationDate)) IN (1, 2, 3)  THEN 'Q1'
              WHEN MONTH(TRY_CONVERT(DATETIME, LoanOriginationDate)) IN (4, 5, 6)  THEN 'Q2'
              WHEN MONTH(TRY_CONVERT(DATETIME, LoanOriginationDate)) IN (7, 8, 9)  THEN 'Q3'
              ELSE                                                                      'Q4'
          END                                                                      AS Quarter
        , COUNT(*)                                                                 AS LoansOriginated
        , SUM(LoanOriginalAmount)                                                  AS TotalVolume
        , AVG(CAST(BorrowerRate AS DECIMAL(10, 4)))                                AS AvgBorrowerRate
        , SUM(CASE WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1 ELSE 0 END) AS DefaultCount
        , SUM(CASE WHEN LoanStatus = 'Completed'                  THEN 1 ELSE 0 END) AS CompletedCount
        , SUM(CASE WHEN LoanStatus = 'Current'                    THEN 1 ELSE 0 END) AS CurrentCount
    FROM dbo.prosperLoanData
    WHERE LoanOriginationDate IS NOT NULL
    GROUP BY
          YEAR(TRY_CONVERT(DATETIME, LoanOriginationDate))
        , MONTH(TRY_CONVERT(DATETIME, LoanOriginationDate))
        , CASE
              WHEN MONTH(TRY_CONVERT(DATETIME, LoanOriginationDate)) IN (1, 2, 3)  THEN 'Q1'
              WHEN MONTH(TRY_CONVERT(DATETIME, LoanOriginationDate)) IN (4, 5, 6)  THEN 'Q2'
              WHEN MONTH(TRY_CONVERT(DATETIME, LoanOriginationDate)) IN (7, 8, 9)  THEN 'Q3'
              ELSE                                                                      'Q4'
          END
)
SELECT
      OriginationYear
    , OriginationMonth
    , Quarter
    , LoansOriginated
    , TotalVolume
    , AvgBorrowerRate
    , DefaultCount
    , CAST(ROUND(
        CAST(DefaultCount AS FLOAT) / LoansOriginated * 100
      , 2) AS DECIMAL(5, 2))                                                       AS MonthlyDefaultRate_Pct
    , CompletedCount
    , CurrentCount
    , AVG(LoansOriginated) OVER (PARTITION BY OriginationYear)                     AS YearlyAvgMonthlyLoans
    , AVG(DefaultCount)    OVER (PARTITION BY Quarter)                             AS QuarterlyAvgDefaults
FROM MonthlyCohorts
ORDER BY OriginationYear DESC, OriginationMonth DESC;


-- ============================================================================
-- SECTION 25: INVESTMENT RETURNS & YIELD ANALYSIS BY INVESTOR TIER   ★★★☆
-- ============================================================================
-- Complexity: CTE pre-casts all financial columns to safe decimals.
--             Outer query buckets investors and calculates multi-dimensional
--             return metrics (total, interest, loss, default) per tier.
-- Purpose   : Full investor perspective on returns net of fees and losses.
-- ============================================================================
WITH InvestmentMetrics AS (
    SELECT
          Investors
        , PercentFunded
        , LoanOriginalAmount
        , CAST(BorrowerRate  AS DECIMAL(10, 4))                                    AS BorrowerRate
        , CAST(LenderYield   AS DECIMAL(10, 4))                                    AS LenderYield
        , MonthlyLoanPayment
        , DATEDIFF(
            MONTH
          , TRY_CONVERT(DATETIME, LoanOriginationDate)
          , ISNULL(TRY_CONVERT(DATETIME, ClosedDate), GETDATE())
          )                                                                        AS MonthsActive
        , LoanStatus
        , CAST(LP_CustomerPayments             AS DECIMAL(15, 2))                  AS CustomerPayments
        , CAST(LP_CustomerPrincipalPayments    AS DECIMAL(15, 2))                  AS PrincipalPayments
        , CAST(LP_InterestandFees              AS DECIMAL(15, 2))                  AS InterestAndFees
        , CAST(LP_ServiceFees                  AS DECIMAL(15, 2))                  AS ServiceFees
        , CAST(LP_CollectionFees               AS DECIMAL(15, 2))                  AS CollectionFees
        , CAST(LP_GrossPrincipalLoss           AS DECIMAL(15, 2))                  AS GrossPrincipalLoss
        , CAST(LP_NetPrincipalLoss             AS DECIMAL(15, 2))                  AS NetPrincipalLoss
    FROM dbo.prosperLoanData
    WHERE LoanOriginalAmount IS NOT NULL
      AND Investors          IS NOT NULL
      AND LenderYield        IS NOT NULL
)
SELECT
      CASE
          WHEN Investors >= 500 THEN '500+ Investors'
          WHEN Investors >= 200 THEN '200–499 Investors'
          WHEN Investors >= 100 THEN '100–199 Investors'
          WHEN Investors >= 50  THEN '50–99 Investors'
          ELSE                       '<50 Investors'
      END                                                                          AS InvestorTier
    , COUNT(*)                                                                     AS LoanCount
    , AVG(LoanOriginalAmount)                                                      AS AvgLoanSize
    , AVG(MonthsActive)                                                            AS AvgMonthsActive
    , AVG(BorrowerRate)                                                            AS AvgBorrowerRate
    , AVG(LenderYield)                                                             AS AvgLenderYield
    , CAST(ROUND(AVG(CustomerPayments) * 100.0 / AVG(LoanOriginalAmount), 2)
        AS DECIMAL(5, 2))                                                          AS AvgTotalReturn_Pct
    , CAST(ROUND(AVG(InterestAndFees)  * 100.0 / AVG(LoanOriginalAmount), 2)
        AS DECIMAL(5, 2))                                                          AS AvgInterestReturn_Pct
    , CAST(ROUND(AVG(NetPrincipalLoss) * 100.0 / AVG(LoanOriginalAmount), 2)
        AS DECIMAL(5, 2))                                                          AS AvgLossRate_Pct
    , CAST(ROUND(
        SUM(CASE WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*)
      , 2) AS DECIMAL(5, 2))                                                       AS DefaultRate_Pct
    , CAST(ROUND(
        AVG(CASE WHEN PercentFunded <= 1.0 THEN 1 ELSE 0 END) * 100
      , 2) AS DECIMAL(5, 2))                                                       AS FullyFunded_Pct
FROM InvestmentMetrics
GROUP BY
    CASE
        WHEN Investors >= 500 THEN '500+ Investors'
        WHEN Investors >= 200 THEN '200–499 Investors'
        WHEN Investors >= 100 THEN '100–199 Investors'
        WHEN Investors >= 50  THEN '50–99 Investors'
        ELSE                       '<50 Investors'
    END
ORDER BY LoanCount DESC;


-- ============================================================================
-- SECTION 26: PORTFOLIO GEOGRAPHIC CONCENTRATION (State-Level)       ★★★☆
-- ============================================================================
-- Complexity: CTE with ROW_NUMBER() window function. Outer SELECT adds
--             cumulative SUM OVER window for running total exposure.
-- Purpose   : Geographic concentration risk. Identifies top 10/25 states
--             and cumulative portfolio exposure.
-- ============================================================================
WITH StateConcentration AS (
    SELECT
          BorrowerState
        , COUNT(*)                                                                 AS StateLoans
        , SUM(LoanOriginalAmount)                                                  AS StateLoanVolume
        , CAST(ROUND(
            SUM(LoanOriginalAmount) * 100.0
            / (SELECT SUM(LoanOriginalAmount) FROM dbo.prosperLoanData)
          , 2) AS DECIMAL(5, 2))                                                   AS VolumeShare_Pct
        , AVG(CAST(BorrowerRate AS DECIMAL(10, 4)))                                AS AvgStateRate
        , CAST(ROUND(
            SUM(CASE WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1 ELSE 0 END)
            * 100.0 / COUNT(*)
          , 2) AS DECIMAL(5, 2))                                                   AS StateDefaultRate_Pct
        , ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC)                               AS StateRank
    FROM dbo.prosperLoanData
    WHERE BorrowerState IS NOT NULL
    GROUP BY BorrowerState
)
SELECT
      StateRank
    , BorrowerState
    , StateLoans
    , StateLoanVolume
    , VolumeShare_Pct
    , SUM(VolumeShare_Pct) OVER (ORDER BY StateRank)                               AS CumulativeVolume_Pct
    , AvgStateRate
    , StateDefaultRate_Pct
    , CASE
          WHEN StateRank <= 10 THEN 'Top 10 States'
          WHEN StateRank <= 25 THEN 'Top 25 States'
          ELSE                      'Remainder'
      END                                                                          AS ConcentrationTier
FROM StateConcentration
ORDER BY StateRank;


-- ============================================================================
-- ★★★★  TIER 4 — EXPERT
-- Multiple CTEs (2–4 layers). Self-referencing subqueries. CROSS JOIN.
-- Complex window functions. Multi-dimensional segmentation.
-- UNION ALL scenario modeling.
-- ============================================================================


-- ============================================================================
-- SECTION 27: CREDIT UTILIZATION ANALYSIS                            ★★★★
-- ============================================================================
-- Complexity: CTE with multi-column CASE bucketing. Outer query adds a
--             calculated utilization ratio from CTE-aggregated columns.
--             CASE ORDER BY for logical bucket ordering.
-- Purpose   : Impact of revolving credit utilization on loan outcomes.
-- ============================================================================
WITH CreditUtil AS (
    SELECT
          CASE
              WHEN BankcardUtilization <= 0.10 THEN '0–10%'
              WHEN BankcardUtilization <= 0.30 THEN '11–30%'
              WHEN BankcardUtilization <= 0.50 THEN '31–50%'
              WHEN BankcardUtilization <= 0.70 THEN '51–70%'
              WHEN BankcardUtilization <= 0.90 THEN '71–90%'
              ELSE                                  '91–100%+'
          END                                                                      AS UtilizationBucket
        , COUNT(*)                                                                 AS BorrowerCount
        , AVG(BorrowerRate * 100)                                                  AS AvgInterestRate
        , AVG((CreditScoreRangeLower + CreditScoreRangeUpper) / 2.0)               AS AvgCreditScore
        , SUM(CASE WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1 ELSE 0 END) AS DefaultCount
        , AVG(LoanOriginalAmount)                                                  AS AvgLoanAmount
        , AVG(RevolvingCreditBalance)                                              AS AvgRevolvingBalance
        , AVG(AvailableBankcardCredit)                                             AS AvgAvailableCredit
    FROM dbo.prosperLoanData
    WHERE BankcardUtilization IS NOT NULL
      AND BankcardUtilization BETWEEN 0 AND 1
    GROUP BY
        CASE
            WHEN BankcardUtilization <= 0.10 THEN '0–10%'
            WHEN BankcardUtilization <= 0.30 THEN '11–30%'
            WHEN BankcardUtilization <= 0.50 THEN '31–50%'
            WHEN BankcardUtilization <= 0.70 THEN '51–70%'
            WHEN BankcardUtilization <= 0.90 THEN '71–90%'
            ELSE                                  '91–100%+'
        END
)
SELECT
      UtilizationBucket
    , BorrowerCount
    , ROUND(AvgInterestRate,   2)                                                  AS AvgInterestRate
    , ROUND(AvgCreditScore,    0)                                                  AS AvgCreditScore
    , DefaultCount
    , ROUND(DefaultCount * 100.0 / BorrowerCount, 2)                               AS DefaultRate_Pct
    , ROUND(AvgLoanAmount,     0)                                                  AS AvgLoanAmount
    , ROUND(AvgRevolvingBalance, 0)                                                AS AvgRevolvingBalance
    , ROUND(AvgAvailableCredit, 0)                                                 AS AvgAvailableCredit
    , ROUND(
        AvgRevolvingBalance * 100.0
        / NULLIF(AvgRevolvingBalance + AvgAvailableCredit, 0)
      , 2)                                                                         AS CalculatedUtilization_Pct
FROM CreditUtil
ORDER BY
    CASE UtilizationBucket
        WHEN '0–10%'    THEN 1
        WHEN '11–30%'   THEN 2
        WHEN '31–50%'   THEN 3
        WHEN '51–70%'   THEN 4
        WHEN '71–90%'   THEN 5
        ELSE                 6
    END;


-- ============================================================================
-- SECTION 28: DELINQUENCY HISTORY IMPACT ANALYSIS                    ★★★★
-- ============================================================================
-- Complexity: CTE with two simultaneous CASE bucket dimensions.
--             Outer query uses SUM OVER() for portfolio share calculation.
--             HAVING and ORDER BY on computed expression.
-- Purpose   : Shows how current + historical delinquency predict defaults.
-- ============================================================================
WITH DelinqAnalysis AS (
    SELECT
          CASE
              WHEN CurrentDelinquencies = 0  THEN '0 Delinquencies'
              WHEN CurrentDelinquencies <= 2 THEN '1–2 Delinquencies'
              WHEN CurrentDelinquencies <= 5 THEN '3–5 Delinquencies'
              ELSE                               '6+ Delinquencies'
          END                                                                      AS CurrentDelinqBucket
        , CASE
              WHEN DelinquenciesLast7Years = 0  THEN '0 Past Delinquencies'
              WHEN DelinquenciesLast7Years <= 5  THEN '1–5 Past Delinquencies'
              WHEN DelinquenciesLast7Years <= 10 THEN '6–10 Past Delinquencies'
              ELSE                                    '11+ Past Delinquencies'
          END                                                                      AS HistoricalDelinqBucket
        , COUNT(*)                                                                 AS LoanCount
        , AVG(BorrowerRate * 100)                                                  AS AvgInterestRate
        , SUM(CASE WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1 ELSE 0 END) AS DefaultCount
        , AVG((CreditScoreRangeLower + CreditScoreRangeUpper) / 2.0)               AS AvgCreditScore
        , AVG(LoanOriginalAmount)                                                  AS AvgLoanAmount
    FROM dbo.prosperLoanData
    WHERE CurrentDelinquencies  IS NOT NULL
      AND DelinquenciesLast7Years IS NOT NULL
    GROUP BY
          CASE
              WHEN CurrentDelinquencies = 0  THEN '0 Delinquencies'
              WHEN CurrentDelinquencies <= 2 THEN '1–2 Delinquencies'
              WHEN CurrentDelinquencies <= 5 THEN '3–5 Delinquencies'
              ELSE                               '6+ Delinquencies'
          END
        , CASE
              WHEN DelinquenciesLast7Years = 0  THEN '0 Past Delinquencies'
              WHEN DelinquenciesLast7Years <= 5  THEN '1–5 Past Delinquencies'
              WHEN DelinquenciesLast7Years <= 10 THEN '6–10 Past Delinquencies'
              ELSE                                    '11+ Past Delinquencies'
          END
)
SELECT
      CurrentDelinqBucket
    , HistoricalDelinqBucket
    , LoanCount
    , ROUND(AvgInterestRate,  2)                                                   AS AvgInterestRate
    , DefaultCount
    , ROUND(DefaultCount * 100.0 / LoanCount, 2)                                   AS DefaultRate_Pct
    , ROUND(AvgCreditScore,  0)                                                    AS AvgCreditScore
    , ROUND(AvgLoanAmount,   0)                                                    AS AvgLoanAmount
    , ROUND(LoanCount * 100.0 / SUM(LoanCount) OVER(), 2)                          AS PortfolioShare_Pct
FROM DelinqAnalysis
WHERE LoanCount >= 5
ORDER BY DefaultCount * 100.0 / LoanCount DESC;


-- ============================================================================
-- SECTION 29: INVESTOR PERFORMANCE ANALYSIS                          ★★★★
-- ============================================================================
-- Complexity: CTE with multi-bucket GROUP BY. Outer query computes
--             NetExpectedReturn as arithmetic on two CTE aggregations.
-- Purpose   : Shows how investor participation level impacts expected returns.
-- ============================================================================
WITH InvestorPerf AS (
    SELECT
          CASE
              WHEN Investors <= 10  THEN '1–10 Investors'
              WHEN Investors <= 50  THEN '11–50 Investors'
              WHEN Investors <= 100 THEN '51–100 Investors'
              WHEN Investors <= 200 THEN '101–200 Investors'
              ELSE                       '200+ Investors'
          END                                                                      AS InvestorCategory
        , COUNT(*)                                                                 AS LoanCount
        , AVG(Investors)                                                           AS AvgInvestorsPerLoan
        , AVG(LoanOriginalAmount)                                                  AS AvgLoanAmount
        , AVG(BorrowerRate * 100)                                                  AS AvgInterestRate
        , AVG(LenderYield  * 100)                                                  AS AvgLenderYield
        , SUM(CASE WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1 ELSE 0 END) AS DefaultCount
        , AVG(EstimatedEffectiveYield * 100)                                       AS AvgEstimatedYield
        , AVG(EstimatedLoss          * 100)                                        AS AvgEstimatedLoss
        , AVG(EstimatedReturn        * 100)                                        AS AvgEstimatedReturn
    FROM dbo.prosperLoanData
    WHERE Investors > 0
    GROUP BY
        CASE
            WHEN Investors <= 10  THEN '1–10 Investors'
            WHEN Investors <= 50  THEN '11–50 Investors'
            WHEN Investors <= 100 THEN '51–100 Investors'
            WHEN Investors <= 200 THEN '101–200 Investors'
            ELSE                       '200+ Investors'
        END
)
SELECT
      InvestorCategory
    , LoanCount
    , ROUND(AvgInvestorsPerLoan, 0)                                                AS AvgInvestorsPerLoan
    , ROUND(AvgLoanAmount,       0)                                                AS AvgLoanAmount
    , ROUND(AvgInterestRate,     2)                                                AS AvgInterestRate
    , ROUND(AvgLenderYield,      2)                                                AS AvgLenderYield
    , DefaultCount
    , ROUND(DefaultCount * 100.0 / LoanCount, 2)                                   AS ActualDefaultRate_Pct
    , ROUND(AvgEstimatedYield,   2)                                                AS AvgEstimatedYield
    , ROUND(AvgEstimatedLoss,    2)                                                AS AvgEstimatedLoss
    , ROUND(AvgEstimatedReturn,  2)                                                AS AvgEstimatedReturn
    , ROUND(AvgLenderYield - AvgEstimatedLoss, 2)                                  AS NetExpectedReturn
FROM InvestorPerf
ORDER BY LoanCount DESC;


-- ============================================================================
-- SECTION 30: PORTFOLIO STRESS TEST (Scenario Analysis)              ★★★★
-- ============================================================================
-- Complexity: Single CTE aggregates baseline metrics. Four UNION ALL rows
--             apply multipliers for mild/moderate/severe stress scenarios.
--             Simulates forward-looking capital at risk.
-- Purpose   : Models portfolio losses under adverse economic conditions.
-- ============================================================================
WITH BaseMetrics AS (
    SELECT
          COUNT(*)                                                                 AS TotalLoans
        , SUM(LoanOriginalAmount)                                                  AS TotalVolume
        , AVG(CAST(BorrowerRate AS DECIMAL(10, 4)))                                AS AvgRate
        , CAST(ROUND(
            SUM(CASE WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1 ELSE 0 END)
            * 100.0 / COUNT(*)
          , 2) AS DECIMAL(5, 2))                                                   AS CurrentDefaultRate
        , SUM(
            CASE
                WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN LoanOriginalAmount
                ELSE 0
            END
          )                                                                        AS ActualLosses
        , SUM(
            CASE
                WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 0
                WHEN LoanStatus LIKE 'Past Due%'               THEN MonthlyLoanPayment * 0.5
                ELSE MonthlyLoanPayment
            END
          )                                                                        AS AdjustedMonthlyPayments
    FROM dbo.prosperLoanData
)
SELECT 'Baseline (Actual)'                AS Scenario
     , TotalLoans, TotalVolume, AvgRate
     , CurrentDefaultRate, ActualLosses, AdjustedMonthlyPayments
     , CAST(ROUND(ActualLosses * 100.0 / TotalVolume, 2) AS DECIMAL(5, 2))         AS LossRate_Pct
FROM BaseMetrics
UNION ALL
SELECT 'Mild Stress (+5% Defaults)'
     , TotalLoans, TotalVolume, AvgRate
     , CAST(ROUND(CurrentDefaultRate * 1.05, 2) AS DECIMAL(5, 2))
     , CAST(ROUND(ActualLosses * 1.05, 0) AS DECIMAL(15, 2))
     , AdjustedMonthlyPayments
     , CAST(ROUND((ActualLosses * 1.05) * 100.0 / TotalVolume, 2) AS DECIMAL(5, 2))
FROM BaseMetrics
UNION ALL
SELECT 'Moderate Stress (+15% Defaults)'
     , TotalLoans, TotalVolume, AvgRate
     , CAST(ROUND(CurrentDefaultRate * 1.15, 2) AS DECIMAL(5, 2))
     , CAST(ROUND(ActualLosses * 1.15, 0) AS DECIMAL(15, 2))
     , AdjustedMonthlyPayments
     , CAST(ROUND((ActualLosses * 1.15) * 100.0 / TotalVolume, 2) AS DECIMAL(5, 2))
FROM BaseMetrics
UNION ALL
SELECT 'Severe Stress (+25% Defaults)'
     , TotalLoans, TotalVolume, AvgRate
     , CAST(ROUND(CurrentDefaultRate * 1.25, 2) AS DECIMAL(5, 2))
     , CAST(ROUND(ActualLosses * 1.25, 0) AS DECIMAL(15, 2))
     , AdjustedMonthlyPayments
     , CAST(ROUND((ActualLosses * 1.25) * 100.0 / TotalVolume, 2) AS DECIMAL(5, 2))
FROM BaseMetrics;


-- ============================================================================
-- SECTION 31: GEOGRAPHIC RISK ANALYSIS                               ★★★★
-- ============================================================================
-- Complexity: Two chained CTEs (StateAnalysis → StateRanking). Three
--             simultaneous RANK() window functions on different expressions.
-- Purpose   : State-level risk profiling with multi-dimensional ranking.
-- ============================================================================
WITH StateAnalysis AS (
    SELECT
          BorrowerState
        , COUNT(*)                                                                 AS TotalLoans
        , SUM(LoanOriginalAmount)                                                  AS TotalVolume
        , AVG(BorrowerRate * 100)                                                  AS AvgInterestRate
        , SUM(CASE WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1 ELSE 0 END) AS DefaultCount
        , AVG((CreditScoreRangeLower + CreditScoreRangeUpper) / 2.0)               AS AvgCreditScore
        , AVG(DebtToIncomeRatio)                                                   AS AvgDTI
        , AVG(StatedMonthlyIncome)                                                 AS AvgMonthlyIncome
    FROM dbo.prosperLoanData
    WHERE BorrowerState IS NOT NULL
      AND BorrowerState <> ''
    GROUP BY BorrowerState
),
StateRanking AS (
    SELECT
          BorrowerState
        , TotalLoans
        , TotalVolume
        , ROUND(AvgInterestRate, 2)                                                AS AvgInterestRate
        , DefaultCount
        , DefaultCount * 100.0 / TotalLoans                                        AS DefaultRate
        , ROUND(AvgCreditScore,  0)                                                AS AvgCreditScore
        , ROUND(AvgDTI,          3)                                                AS AvgDTI
        , ROUND(AvgMonthlyIncome, 0)                                               AS AvgMonthlyIncome
        , RANK() OVER (ORDER BY DefaultCount * 100.0 / TotalLoans DESC)            AS DefaultRateRank
        , RANK() OVER (ORDER BY TotalVolume DESC)                                  AS VolumeRank
        , RANK() OVER (ORDER BY AvgInterestRate DESC)                              AS InterestRateRank
    FROM StateAnalysis
    WHERE TotalLoans >= 5
)
SELECT
      BorrowerState
    , TotalLoans
    , TotalVolume
    , AvgInterestRate
    , DefaultCount
    , ROUND(DefaultRate, 2)                                                        AS DefaultRate_Pct
    , AvgCreditScore
    , AvgDTI
    , AvgMonthlyIncome
    , DefaultRateRank
    , VolumeRank
    , InterestRateRank
    , CASE
          WHEN DefaultRateRank <= 5  THEN 'High Risk'
          WHEN DefaultRateRank <= 15 THEN 'Medium Risk'
          ELSE                           'Low Risk'
      END                                                                          AS RiskCategory
FROM StateRanking
ORDER BY DefaultRate DESC;


-- ============================================================================
-- SECTION 32: BORROWER CHARACTERISTICS ANALYSIS                      ★★★★
-- ============================================================================
-- Complexity: CTE with 6-bucket income CASE. GROUP BY on 3 CASE dimensions.
--             Outer query uses SUM OVER() window for portfolio share.
--             Multi-column ORDER BY using CASE expression.
-- Purpose   : Demographic profiling across income, homeownership, employment.
-- ============================================================================
WITH BorrowerAnalysis AS (
    SELECT
          CASE
              WHEN IncomeRange IN ('Not employed', '$0')  THEN 'No Income'
              WHEN IncomeRange = '$1-24,999'               THEN 'Low Income'
              WHEN IncomeRange = '$25,000-49,999'          THEN 'Lower Middle'
              WHEN IncomeRange = '$50,000-74,999'          THEN 'Middle Income'
              WHEN IncomeRange = '$75,000-99,999'          THEN 'Upper Middle'
              WHEN IncomeRange = '$100,000+'               THEN 'High Income'
              ELSE                                             'Not Displayed'
          END                                                                      AS IncomeCategory
        , IsBorrowerHomeowner
        , EmploymentStatus
        , COUNT(*)                                                                 AS BorrowerCount
        , AVG((CreditScoreRangeLower + CreditScoreRangeUpper) / 2.0)               AS AvgCreditScore
        , AVG(DebtToIncomeRatio)                                                   AS AvgDTI
        , AVG(LoanOriginalAmount)                                                  AS AvgLoanSize
        , SUM(CASE WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*)                                                       AS DefaultRate
        , AVG(BorrowerRate * 100)                                                  AS AvgInterestRate
        , AVG(StatedMonthlyIncome)                                                 AS AvgMonthlyIncome
    FROM dbo.prosperLoanData
    WHERE IncomeRange IS NOT NULL
      AND IncomeRange <> 'Not displayed'
    GROUP BY
          CASE
              WHEN IncomeRange IN ('Not employed', '$0')  THEN 'No Income'
              WHEN IncomeRange = '$1-24,999'               THEN 'Low Income'
              WHEN IncomeRange = '$25,000-49,999'          THEN 'Lower Middle'
              WHEN IncomeRange = '$50,000-74,999'          THEN 'Middle Income'
              WHEN IncomeRange = '$75,000-99,999'          THEN 'Upper Middle'
              WHEN IncomeRange = '$100,000+'               THEN 'High Income'
              ELSE                                             'Not Displayed'
          END
        , IsBorrowerHomeowner
        , EmploymentStatus
)
SELECT
      IncomeCategory
    , IsBorrowerHomeowner
    , EmploymentStatus
    , BorrowerCount
    , ROUND(AvgCreditScore,   0)                                                   AS AvgCreditScore
    , ROUND(AvgDTI,           3)                                                   AS AvgDTI
    , ROUND(AvgLoanSize,      0)                                                   AS AvgLoanSize
    , ROUND(DefaultRate,      2)                                                   AS DefaultRate_Pct
    , ROUND(AvgInterestRate,  2)                                                   AS AvgInterestRate
    , ROUND(AvgMonthlyIncome, 0)                                                   AS AvgMonthlyIncome
    , ROUND(BorrowerCount * 100.0 / SUM(BorrowerCount) OVER(), 2)                  AS PortfolioShare_Pct
FROM BorrowerAnalysis
ORDER BY
    CASE IncomeCategory
        WHEN 'High Income'    THEN 1
        WHEN 'Upper Middle'   THEN 2
        WHEN 'Middle Income'  THEN 3
        WHEN 'Lower Middle'   THEN 4
        WHEN 'Low Income'     THEN 5
        WHEN 'No Income'      THEN 6
        ELSE                       7
    END
  , IsBorrowerHomeowner DESC
  , BorrowerCount DESC;


-- ============================================================================
-- SECTION 33: MONTHLY PAYMENT TO INCOME ANALYSIS                     ★★★★
-- ============================================================================
-- Complexity: Two-CTE chain. First CTE computes row-level PTI ratio + bucket.
--             Second CTE aggregates per bucket. Final SELECT adds portfolio
--             share via SUM OVER() and logical CASE ORDER BY.
-- Purpose   : Payment-to-income stress indicator and affordability threshold
--             analysis for underwriting policy optimization.
-- ============================================================================
WITH PaymentRatio AS (
    SELECT
          ListingKey
        , LoanStatus
        , MonthlyLoanPayment
        , StatedMonthlyIncome
        , LoanOriginalAmount
        , BorrowerRate * 100                                                       AS InterestRate
        , Term
        , CASE
              WHEN StatedMonthlyIncome > 0
                   THEN MonthlyLoanPayment * 100.0 / StatedMonthlyIncome
              ELSE NULL
          END                                                                      AS PaymentToIncomeRatio
        , CASE
              WHEN StatedMonthlyIncome > 0
               AND MonthlyLoanPayment * 100.0 / StatedMonthlyIncome <= 15  THEN 'Very Low (≤15%)'
              WHEN StatedMonthlyIncome > 0
               AND MonthlyLoanPayment * 100.0 / StatedMonthlyIncome <= 25  THEN 'Low (16–25%)'
              WHEN StatedMonthlyIncome > 0
               AND MonthlyLoanPayment * 100.0 / StatedMonthlyIncome <= 35  THEN 'Moderate (26–35%)'
              WHEN StatedMonthlyIncome > 0
               AND MonthlyLoanPayment * 100.0 / StatedMonthlyIncome <= 45  THEN 'High (36–45%)'
              WHEN StatedMonthlyIncome > 0                                  THEN 'Very High (>45%)'
              ELSE                                                               'No Income'
          END                                                                      AS PTIBucket
    FROM dbo.prosperLoanData
    WHERE MonthlyLoanPayment  > 0
      AND StatedMonthlyIncome IS NOT NULL
),
PTISummary AS (
    SELECT
          PTIBucket
        , COUNT(*)                                                                 AS LoanCount
        , AVG(PaymentToIncomeRatio)                                                AS AvgPTI
        , AVG(InterestRate)                                                        AS AvgInterestRate
        , AVG(LoanOriginalAmount)                                                  AS AvgLoanAmount
        , AVG(StatedMonthlyIncome)                                                 AS AvgMonthlyIncome
        , SUM(CASE WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1 ELSE 0 END) AS DefaultCount
        , AVG(Term)                                                                AS AvgTermMonths
    FROM PaymentRatio
    WHERE PaymentToIncomeRatio IS NOT NULL
    GROUP BY PTIBucket
)
SELECT
      PTIBucket
    , LoanCount
    , ROUND(AvgPTI,           1)                                                   AS AvgPTI_Pct
    , ROUND(AvgInterestRate,  2)                                                   AS AvgInterestRate
    , ROUND(AvgLoanAmount,    0)                                                   AS AvgLoanAmount
    , ROUND(AvgMonthlyIncome, 0)                                                   AS AvgMonthlyIncome
    , DefaultCount
    , ROUND(DefaultCount * 100.0 / LoanCount, 2)                                   AS DefaultRate_Pct
    , ROUND(AvgTermMonths,    0)                                                   AS AvgTermMonths
    , ROUND(LoanCount * 100.0 / SUM(LoanCount) OVER(), 2)                          AS PortfolioShare_Pct
FROM PTISummary
ORDER BY
    CASE PTIBucket
        WHEN 'Very Low (≤15%)'   THEN 1
        WHEN 'Low (16–25%)'      THEN 2
        WHEN 'Moderate (26–35%)' THEN 3
        WHEN 'High (36–45%)'     THEN 4
        WHEN 'Very High (>45%)'  THEN 5
        ELSE                          6
    END;


-- ============================================================================
-- SECTION 34: OCCUPATIONAL RISK SEGMENTATION WITH INCOME CORRELATION  ★★★★
-- ============================================================================
-- Complexity: CTE aggregates per Occupation × EmploymentStatus. Outer query
--             adds LoanToAnnualIncomeRatio (arithmetic on two CTE averages)
--             and ROW_NUMBER() window function for risk ranking.
-- Purpose   : Job-type risk profiling with affordability stress indicator.
-- ============================================================================
WITH OccupationAnalysis AS (
    SELECT
          Occupation
        , EmploymentStatus
        , COUNT(*)                                                                 AS OccupationLoans
        , COUNT(DISTINCT MemberKey)                                                AS UniqueWorkers
        , AVG(CAST(StatedMonthlyIncome AS DECIMAL(15, 2)))                         AS AvgMonthlyIncome
        , AVG(LoanOriginalAmount)                                                  AS AvgLoanAmount
        , AVG(EmploymentStatusDuration)                                            AS AvgEmploymentMonths
        , AVG(CAST(BorrowerRate AS DECIMAL(10, 4)))                                AS AvgBorrowerRate
        , SUM(CASE WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1 ELSE 0 END) AS DefaultCount
        , SUM(CASE WHEN LoanStatus = 'Completed'                  THEN 1 ELSE 0 END) AS CompletedCount
        , AVG(CAST(DebtToIncomeRatio AS DECIMAL(10, 2)))                           AS AvgDTI
        , AVG(CreditScoreRangeLower)                                               AS AvgCreditScore
    FROM dbo.prosperLoanData
    WHERE Occupation      IS NOT NULL
      AND Occupation       <> 'Other'
      AND EmploymentStatus IS NOT NULL
    GROUP BY Occupation, EmploymentStatus
)
SELECT
      Occupation
    , EmploymentStatus
    , OccupationLoans
    , UniqueWorkers
    , AvgMonthlyIncome
    , ROUND(AvgLoanAmount,       0)                                                AS AvgLoanAmount
    , ROUND(AvgEmploymentMonths, 0)                                                AS AvgEmploymentMonths
    , ROUND(AvgBorrowerRate,     4)                                                AS AvgBorrowerRate
    , DefaultCount
    , CAST(ROUND(
        CAST(DefaultCount AS FLOAT) / OccupationLoans * 100
      , 2) AS DECIMAL(5, 2))                                                       AS DefaultRate_Pct
    , CompletedCount
    , ROUND(AvgDTI,              3)                                                AS AvgDTI
    , ROUND(AvgCreditScore,      0)                                                AS AvgCreditScore
    , CAST(ROUND(
        AvgLoanAmount * 100.0 / NULLIF(AvgMonthlyIncome, 0) / 12
      , 2) AS DECIMAL(5, 2))                                                       AS LoanToAnnualIncomeRatio
    , ROW_NUMBER() OVER (ORDER BY DefaultCount DESC)                               AS RiskRank
FROM OccupationAnalysis
WHERE OccupationLoans >= 100
ORDER BY DefaultCount DESC;


-- ============================================================================
-- SECTION 35: DEFAULT PROPENSITY MODEL (Multi-Factor Segmentation)   ★★★★
-- ============================================================================
-- Complexity: Single CTE with three simultaneous CASE dimensions in both
--             SELECT and GROUP BY. Outer query adds a correlated scalar
--             subquery for portfolio-average variance calculation.
-- Purpose   : 3D segmentation (Credit × DTI × Delinquency). Calculates
--             default probability and variance from portfolio baseline.
-- ============================================================================
WITH DefaultPatterns AS (
    SELECT
          CASE
              WHEN CreditScoreRangeLower >= 720 THEN '720+ (Prime)'
              WHEN CreditScoreRangeLower >= 680 THEN '680–719 (Near-Prime)'
              WHEN CreditScoreRangeLower >= 640 THEN '640–679 (Subprime)'
              ELSE                                   'Below 640 (Deep Sub)'
          END                                                                      AS CreditTier
        , CASE
              WHEN DebtToIncomeRatio < 0.30 THEN 'Low DTI'
              WHEN DebtToIncomeRatio < 0.50 THEN 'Mid DTI'
              ELSE                               'High DTI'
          END                                                                      AS DTITier
        , CASE
              WHEN CurrentDelinquencies = 0 THEN 'Clean'
              ELSE                               'Delinquent'
          END                                                                      AS DelinquencyStatus
        , Term
        , COUNT(*)                                                                 AS SegmentLoans
        , SUM(CASE WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1 ELSE 0 END) AS SegmentDefaults
        , SUM(CASE WHEN LoanStatus = 'Completed'                  THEN 1 ELSE 0 END) AS SegmentCompleted
        , SUM(CASE WHEN LoanStatus = 'Current'                    THEN 1 ELSE 0 END) AS SegmentCurrent
    FROM dbo.prosperLoanData
    WHERE CreditScoreRangeLower IS NOT NULL
      AND DebtToIncomeRatio     IS NOT NULL
      AND CurrentDelinquencies  IS NOT NULL
    GROUP BY
          CASE
              WHEN CreditScoreRangeLower >= 720 THEN '720+ (Prime)'
              WHEN CreditScoreRangeLower >= 680 THEN '680–719 (Near-Prime)'
              WHEN CreditScoreRangeLower >= 640 THEN '640–679 (Subprime)'
              ELSE                                   'Below 640 (Deep Sub)'
          END
        , CASE
              WHEN DebtToIncomeRatio < 0.30 THEN 'Low DTI'
              WHEN DebtToIncomeRatio < 0.50 THEN 'Mid DTI'
              ELSE                               'High DTI'
          END
        , CASE
              WHEN CurrentDelinquencies = 0 THEN 'Clean'
              ELSE                               'Delinquent'
          END
        , Term
)
SELECT
      CreditTier
    , DTITier
    , DelinquencyStatus
    , Term
    , SegmentLoans
    , SegmentDefaults
    , CAST(ROUND(
        CAST(SegmentDefaults AS FLOAT) / SegmentLoans * 100
      , 2) AS DECIMAL(5, 2))                                                       AS DefaultProbability_Pct
    , SegmentCompleted
    , SegmentCurrent
    , CAST(ROUND(
        CAST(SegmentCompleted + SegmentCurrent AS FLOAT) / SegmentLoans * 100
      , 2) AS DECIMAL(5, 2))                                                       AS PerformanceRate_Pct
    , CAST(ROUND(
        CAST(SegmentDefaults AS FLOAT) / SegmentLoans * 100
        - (
            SELECT CAST(ROUND(
                SUM(CASE WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1 ELSE 0 END)
                * 100.0 / COUNT(*), 2) AS DECIMAL(5, 2))
            FROM dbo.prosperLoanData
          )
      , 2) AS DECIMAL(5, 2))                                                       AS VarianceFromPortfolioAvg
FROM DefaultPatterns
ORDER BY DefaultProbability_Pct DESC;


-- ============================================================================
-- SECTION 36: BORROWER MIGRATION & PERFORMANCE PROGRESSION           ★★★★
-- ============================================================================
-- Complexity: CTE aggregates full borrower lifecycle. Outer GROUP BY applies
--             a 5-condition CASE expression across CTE computed columns.
--             Same CASE repeated in GROUP BY (SQL Server requirement).
-- Purpose   : Classifies borrowers into performance tiers and tracks
--             lifecycle patterns across all loans.
-- ============================================================================
WITH BorrowerProgressions AS (
    SELECT
          MemberKey
        , COUNT(DISTINCT LoanKey)                                                  AS TotalLoans
        , SUM(CASE WHEN LoanStatus = 'Current'                          THEN 1 ELSE 0 END) AS CurrentLoans
        , SUM(CASE WHEN LoanStatus = 'Completed'                        THEN 1 ELSE 0 END) AS CompletedLoans
        , SUM(CASE WHEN LoanStatus IN ('Defaulted', 'Chargedoff')        THEN 1 ELSE 0 END) AS DefaultedLoans
        , SUM(CASE WHEN LoanStatus LIKE 'Past Due%'                      THEN 1 ELSE 0 END) AS PastDueLoans
        , CAST(ROUND(
            SUM(CASE WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1 ELSE 0 END)
            * 100.0 / COUNT(*)
          , 2) AS DECIMAL(5, 2))                                                   AS DefaultRate
        , MIN(CreditScoreRangeLower)                                               AS LowestCreditScore
        , MAX(CreditScoreRangeLower)                                               AS HighestCreditScore
        , AVG(CAST(BorrowerRate AS DECIMAL(10, 4)))                                AS AvgBorrowRate
        , AVG(LoanOriginalAmount)                                                  AS AvgLoanSize
    FROM dbo.prosperLoanData
    WHERE MemberKey IS NOT NULL
    GROUP BY MemberKey
)
SELECT
      CASE
          WHEN DefaultRate = 0
               AND CompletedLoans + CurrentLoans = TotalLoans  THEN 'Perfect-Performing'
          WHEN DefaultRate = 0
               AND (CurrentLoans > 0 OR PastDueLoans > 0)      THEN 'Currently-Performing'
          WHEN DefaultRate BETWEEN 0.01 AND 0.25               THEN 'Low-Risk'
          WHEN DefaultRate BETWEEN 0.26 AND 0.50               THEN 'Medium-Risk'
          ELSE                                                      'High-Risk'
      END                                                                          AS PerformanceProfile
    , COUNT(MemberKey)                                                             AS BorrowerCount
    , AVG(TotalLoans)                                                              AS AvgLoansPerBorrower
    , AVG(DefaultRate)                                                             AS AvgDefaultRate
    , AVG(LowestCreditScore)                                                       AS AvgLowestCreditScore
    , AVG(HighestCreditScore)                                                      AS AvgHighestCreditScore
    , AVG(AvgBorrowRate)                                                           AS AvgBorrowRate
    , SUM(TotalLoans)                                                              AS TotalLoansInProfile
    , AVG(AvgLoanSize)                                                             AS AvgLoanSize
FROM BorrowerProgressions
GROUP BY
    CASE
        WHEN DefaultRate = 0
             AND CompletedLoans + CurrentLoans = TotalLoans  THEN 'Perfect-Performing'
        WHEN DefaultRate = 0
             AND (CurrentLoans > 0 OR PastDueLoans > 0)      THEN 'Currently-Performing'
        WHEN DefaultRate BETWEEN 0.01 AND 0.25               THEN 'Low-Risk'
        WHEN DefaultRate BETWEEN 0.26 AND 0.50               THEN 'Medium-Risk'
        ELSE                                                      'High-Risk'
    END
ORDER BY BorrowerCount DESC;


-- ============================================================================
-- SECTION 37: COMPOSITE BORROWER RISK SCORE MODEL                    ★★★★
-- ============================================================================
-- Complexity: Two chained CTEs. First CTE (RiskFactors) scores 5 dimensions.
--             Second CTE (RiskScores) computes composite + category.
--             Final SELECT groups by category with CASE ORDER BY.
-- Purpose   : Multi-factor scoring model (Credit + DTI + Delinquency +
--             Public Records + Employment) validated against actual defaults.
-- ============================================================================
WITH RiskFactors AS (
    SELECT
          MemberKey
        , LoanKey
        , LoanStatus
        , CASE
              WHEN CreditScoreRangeLower >= 760 THEN 0
              WHEN CreditScoreRangeLower >= 720 THEN 1
              WHEN CreditScoreRangeLower >= 680 THEN 2
              WHEN CreditScoreRangeLower >= 640 THEN 3
              ELSE                                   4
          END                                                                      AS CreditScoreFactor
        , CASE
              WHEN DebtToIncomeRatio < 0.20 THEN 0
              WHEN DebtToIncomeRatio < 0.35 THEN 1
              WHEN DebtToIncomeRatio < 0.50 THEN 2
              WHEN DebtToIncomeRatio < 0.70 THEN 3
              ELSE                               4
          END                                                                      AS DTIFactor
        , CASE
              WHEN CurrentDelinquencies = 0  THEN 0
              WHEN CurrentDelinquencies <= 2 THEN 1
              WHEN CurrentDelinquencies <= 5 THEN 2
              ELSE                                3
          END                                                                      AS DelinquencyFactor
        , CASE
              WHEN PublicRecordsLast10Years = 0 THEN 0
              WHEN PublicRecordsLast10Years = 1 THEN 2
              ELSE                                   3
          END                                                                      AS PublicRecordsFactor
        , CASE
              WHEN EmploymentStatus = 'Employed'      THEN 0
              WHEN EmploymentStatus = 'Self-employed'  THEN 1
              WHEN EmploymentStatus = 'Not employed'   THEN 3
              ELSE                                         1
          END                                                                      AS EmploymentFactor
        , CAST(BorrowerRate AS DECIMAL(10, 4))                                     AS BorrowerRate
        , LoanOriginalAmount
    FROM dbo.prosperLoanData
    WHERE CreditScoreRangeLower IS NOT NULL
      AND DebtToIncomeRatio     IS NOT NULL
),
RiskScores AS (
    SELECT
          MemberKey
        , LoanKey
        , LoanStatus
        , (CreditScoreFactor + DTIFactor + DelinquencyFactor
           + PublicRecordsFactor + EmploymentFactor)                               AS CompositeRiskScore
        , CAST(ROUND(
            (CreditScoreFactor + DTIFactor + DelinquencyFactor
             + PublicRecordsFactor + EmploymentFactor) / 20.0 * 100
          , 2) AS DECIMAL(5, 2))                                                   AS RiskScore_Pct
        , CASE
              WHEN (CreditScoreFactor + DTIFactor + DelinquencyFactor
                    + PublicRecordsFactor + EmploymentFactor) <= 3  THEN 'Low Risk'
              WHEN (CreditScoreFactor + DTIFactor + DelinquencyFactor
                    + PublicRecordsFactor + EmploymentFactor) <= 8  THEN 'Medium Risk'
              WHEN (CreditScoreFactor + DTIFactor + DelinquencyFactor
                    + PublicRecordsFactor + EmploymentFactor) <= 13 THEN 'High Risk'
              ELSE                                                       'Very High Risk'
          END                                                                      AS RiskCategory
        , BorrowerRate
        , LoanOriginalAmount
    FROM RiskFactors
)
SELECT
      RiskCategory
    , COUNT(*)                                                                     AS LoanCount
    , AVG(CompositeRiskScore)                                                      AS AvgRiskScore
    , AVG(RiskScore_Pct)                                                           AS AvgRiskScore_Pct
    , CAST(ROUND(
        SUM(CASE WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*)
      , 2) AS DECIMAL(5, 2))                                                       AS ActualDefaultRate_Pct
    , AVG(BorrowerRate)                                                            AS AvgRateCharged
    , AVG(LoanOriginalAmount)                                                      AS AvgLoanAmount
    , COUNT(DISTINCT MemberKey)                                                    AS UniqueBorrowers
FROM RiskScores
GROUP BY RiskCategory
ORDER BY
    CASE RiskCategory
        WHEN 'Low Risk'       THEN 1
        WHEN 'Medium Risk'    THEN 2
        WHEN 'High Risk'      THEN 3
        WHEN 'Very High Risk' THEN 4
    END;


-- ============================================================================
-- SECTION 38: COMPREHENSIVE RISK SCORECARD                           ★★★★
-- ============================================================================
-- Complexity: Two chained CTEs (RiskFactorsComb → RiskScoreCards). First CTE
--             combines 5 CASE dimensions + a 3-condition composite rule.
--             Second CTE aggregates across 6 group-by dimensions. Final SELECT
--             adds RANK() window function and SUM OVER() for portfolio share.
--             Most complex query in the project.
-- Purpose   : Unified scorecard combining all risk dimensions into a single
--             ranked view. Ideal for underwriting policy optimization.
-- ============================================================================
WITH RiskFactorsComb AS (
    SELECT
          ListingKey
        , LoanStatus
        , BorrowerRate * 100                                                       AS InterestRate
        , LoanOriginalAmount
        , CASE
              WHEN (CreditScoreRangeLower + CreditScoreRangeUpper) / 2.0 >= 720  THEN 'Excellent (720+)'
              WHEN (CreditScoreRangeLower + CreditScoreRangeUpper) / 2.0 >= 680  THEN 'Good (680–719)'
              WHEN (CreditScoreRangeLower + CreditScoreRangeUpper) / 2.0 >= 640  THEN 'Fair (640–679)'
              ELSE                                                                    'Poor (<640)'
          END                                                                      AS CreditScoreCategory
        , CASE
              WHEN DebtToIncomeRatio <= 0.20 THEN 'Low DTI (≤20%)'
              WHEN DebtToIncomeRatio <= 0.40 THEN 'Medium DTI (21–40%)'
              ELSE                               'High DTI (>40%)'
          END                                                                      AS DTICategory
        , CASE
              WHEN EmploymentStatusDuration >= 60 THEN 'Very Stable (5+ yrs)'
              WHEN EmploymentStatusDuration >= 24 THEN 'Stable (2–5 yrs)'
              WHEN EmploymentStatusDuration >= 12 THEN 'Some Stability (1–2 yrs)'
              ELSE                                    'Limited (<1 yr)'
          END                                                                      AS EmploymentStability
        , CASE
              WHEN IncomeRange = '$100,000+'                                THEN 'High Income'
              WHEN IncomeRange IN ('$75,000-99,999', '$50,000-74,999')      THEN 'Middle Income'
              WHEN IncomeRange = '$25,000-49,999'                           THEN 'Lower Middle'
              WHEN IncomeRange = '$1-24,999'                                THEN 'Low Income'
              ELSE                                                               'No/Minimal Income'
          END                                                                      AS IncomeCategory
        , CASE
              WHEN IsBorrowerHomeowner = 'True' THEN 'Homeowner'
              ELSE                                   'Renter'
          END                                                                      AS HousingStatus
        -- Composite rule combining 4 dimensions for final risk label
        , CASE
              WHEN (CreditScoreRangeLower + CreditScoreRangeUpper) / 2.0 >= 720
               AND DebtToIncomeRatio          <= 0.30
               AND EmploymentStatusDuration   >= 24
               AND IncomeRange IN ('$50,000-74,999', '$75,000-99,999', '$100,000+') THEN 'Low Risk'
              WHEN (CreditScoreRangeLower + CreditScoreRangeUpper) / 2.0 >= 640
               AND DebtToIncomeRatio          <= 0.50                               THEN 'Medium Risk'
              ELSE                                                                       'High Risk'
          END                                                                      AS RiskCategory
    FROM dbo.prosperLoanData
    WHERE CreditScoreRangeLower  IS NOT NULL
      AND DebtToIncomeRatio       IS NOT NULL
      AND EmploymentStatusDuration IS NOT NULL
      AND IncomeRange              IS NOT NULL
      AND IncomeRange              <> 'Not displayed'
),
RiskScoreCards AS (
    SELECT
          RiskCategory
        , CreditScoreCategory
        , DTICategory
        , EmploymentStability
        , IncomeCategory
        , HousingStatus
        , COUNT(*)                                                                 AS LoanCount
        , AVG(InterestRate)                                                        AS AvgInterestRate
        , AVG(LoanOriginalAmount)                                                  AS AvgLoanAmount
        , SUM(CASE WHEN LoanStatus IN ('Defaulted', 'Chargedoff') THEN 1 ELSE 0 END) AS DefaultCount
    FROM RiskFactorsComb
    GROUP BY
          RiskCategory
        , CreditScoreCategory
        , DTICategory
        , EmploymentStability
        , IncomeCategory
        , HousingStatus
)
SELECT
      RiskCategory
    , CreditScoreCategory
    , DTICategory
    , EmploymentStability
    , IncomeCategory
    , HousingStatus
    , LoanCount
    , ROUND(AvgInterestRate,  2)                                                   AS AvgInterestRate
    , ROUND(AvgLoanAmount,    0)                                                   AS AvgLoanAmount
    , DefaultCount
    , ROUND(DefaultCount * 100.0 / LoanCount, 2)                                   AS DefaultRate_Pct
    , ROUND(LoanCount * 100.0 / SUM(LoanCount) OVER(), 2)                          AS PortfolioShare_Pct
    , RANK() OVER (ORDER BY DefaultCount * 100.0 / LoanCount DESC)                 AS RiskRank
FROM RiskScoreCards
WHERE LoanCount >= 5
ORDER BY RiskCategory, DefaultCount * 100.0 / LoanCount DESC;


-- ============================================================================
-- END OF FILE
-- ============================================================================