# Credit & Payment Behaviour — exploratory data analysis

Technical test for a Junior Data Scientist position. The deliverable is a single
executable notebook that takes an undocumented credit portfolio from raw CSV to a set of
findings about what can and cannot be modelled from it.

The dataset arrives **without a data dictionary**, so a large part of the work is
reconstructing what each column means — including two whose names turn out to be
misleading, and one that cannot be used at all.

---

## Layout

```text
PYTHON_ETL/
├── etl_scripts/
│   └── src/
│       ├── development/
│       │   └── eda.ipynb      the analysis, end to end
│       └── config.json        every threshold, rule and semantic decision
├── ResultsReport.pdf          written report of the findings (IEEE format, Spanish)
├── ResultsPresentation.pptx   results deck; the commentary is in the speaker notes
├── dataset.csv                source data — NOT in version control, see below
├── requirements.txt           pinned dependencies
├── setup.sh / setup.ps1       create .venv and install
└── README.md                  this file
```

## Getting the data

`dataset.csv` is excluded by `.gitignore` (`*.csv`) and **nothing in this repository can
regenerate it**. It is the file supplied with the technical test and must be placed at
`PYTHON_ETL/dataset.csv` before anything will run. The expected format is declared in
`config.json` under `read_csv`: semicolon-separated, `utf-8-sig`, comma as the decimal
mark in `puntaje`, day-first dates.

## Running it

```bash
./setup.sh                       # or  .\setup.ps1  on Windows
.venv/bin/python -m jupyter lab etl_scripts/src/development/eda.ipynb
```

Run the notebook top to bottom from a clean kernel. It writes nothing to disk — every
table and figure is an interactive cell output — so re-running a cell out of order is
safe for everything except the ones that say otherwise in a comment.

To execute it headlessly:

```bash
.venv/bin/python -m jupyter nbconvert --to notebook --execute --inplace \
    etl_scripts/src/development/eda.ipynb
```

## What the notebook covers

| Section | Contents |
|---|---|
| 1 | Raw load with every column as text — no implicit coercion, so the file's own null representation stays visible |
| 2 | Variable taxonomy, null standardisation, repair of contaminated values, typing, **unit normalisation**, structural consistency checks, range rules, column removal |
| 3 | Univariate, bivariate and multivariate EDA — distributions, default rates by group, Pearson *and* Spearman correlation, scatter matrices |
| 4 | Feature engineering candidates, ranked against the target |
| 5 | The modelling frame and a data-quality summary |
| 6 | The curated findings — the plots that carry the story |
| 7 | Figure index |

## The two deliverables at the root

`ResultsReport.pdf` is the written report: the leakage finding, the unit error, the
signals that survive and the limitations, with the figures and the external references.
`ResultsPresentation.pptx` presents the same results visually — the slides carry the
figures and the headline numbers, and every explanation lives in the speaker notes rather
than on screen. Both are generated from the analysis in `eda.ipynb`; neither adds a
finding that is not in the notebook.

## `config.json` is the single source of truth

No threshold is hard-coded in the notebook. The file carries:

- **`validation_rules`** — the accepted range for every numeric column, re-checked on load.
- **`unit_scale`** — the bureau balance columns arrive in *thousands* of COP while the loan
  and income columns are in COP. The block records the factor, the affected columns and
  the evidence for the correction.
- **`column_semantics`** — meanings that are not obvious from the names and that change
  how a feature must be built. Notably `total_otros_prestamos`, which is a self-declared
  **monthly payment**, not an outstanding balance.
- **`sentinels`** — numbers that stand for "no information": `puntaje_datacredito == 0`
  means *not scored*, not a score of zero.
- **`leakage_columns`** — see below.
- **`domain_reference`** — the published Colombian market values the rules were checked
  against (bureau score scale, usury caps, minimum wage, debt-service convention).

Changing a threshold means editing this file, not the notebook.

## The one thing to know before reusing this data

**`puntaje` is target leakage and is excluded from modelling.** The highest value among
defaulted loans is 62.67; the lowest among loans paid on time is 63.81. A single threshold
reproduces the label for 100% of the 10,763 rows. 87% of the portfolio sits on one
repeated value and every one of those loans paid on time.

The column is **deliberately kept in the dataset** so that section 3.2.1 can demonstrate
the problem rather than quietly hide it. It is listed in `config.json` under
`leakage_columns`, excluded from every feature ranking, and section 5.1 asserts that it
never reaches the modelling frame.

Leakage also propagates: a data-quality feature counting range-rule violations initially
looked like the strongest signal in the project until it turned out one of the rules
bounds `puntaje`, and every row violating it is a default. Anything derived from a leaking
column has to be audited too.

## Notes for whoever picks this up

- The target is imbalanced at 4.75% positives. Predicting "paid on time" for everyone
  already scores 95.25% accuracy, so use PR-AUC or recall at fixed precision.
- **Split by `fecha_prestamo`, not at random.** Recent cohorts have not had time to
  mature, and a random split leaks future cohorts into training.
- `saldo_total` and `saldo_principal` correlate at ρ = 0.95 and are identical in 84% of
  rows; keep one plus the interest difference.
- Rank-based statistics are used throughout for screening. Pearson is reported alongside
  Spearman rather than instead of it — on several pairs the two disagree completely, and
  the disagreement is itself a finding.

The notebook is committed **with its outputs**: the stored figures and tables are the
deliverable, not a build artefact.
