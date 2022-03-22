# Health Exchange Advertisement Valences

This repository reproduces the analyses described in our paper "Can Moral Framing Drive
Insurance Enrollment in the US?" In this analysis, we looked at whether “green halo” and
“noble edge” effects demonstrated in other markets would carry over to the health
insurance marketplace.

Using an online advertising platform (Google), we purchased 5.6 million advertising
impressions in English and Spanish, targeting higher-income Americans nationwide during
the 2021 open-enrollment period. Consumers saw advertisements from a control group
(representing status quo ads highlighting economic self-interest, collected from the
field) versus three experimental groups (helping others, helping community, or personal
responsibility). We measured whether consumers clicked to “shop now” on the
[healthcare.gov](https://www.healthcare.gov/) website (1.01% in English and 1.38% in
Spanish at baseline).

This repository represents the code for our analysis of this experiment.

## Requirements

### Software

To run the code in this repository, you will need Python 3.8+ and Stata 16 pre-installed.

In Python, we use [`poetry`](https://python-poetry.org/) to manage our dependencies. To
install this dependency manager, you can run (assumes Mac or Linux; see tool's
documentation for other operating systems):

```bash
curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3 -
```
Once this is installed, you can install all dependencies with

```bash
poetry install
```

### Census API

In order to run some of this code, you will also need a [Census API Key](https://api.census.gov/data/key_signup.html). Once you have the key, copy the `.env.sample` file to `.env` and fill in your API key in the specified location.

### Running the analysis

Once the dependencies are setup, then you should be able to run the command:

```bash
poetry run snakemake -c 1 all
```

This will produce output in the `build` folder. Note that this does _not_ reproduce
the regressions that are performed in Stata. For those, you will need to open Stata,
point it at the file called `data/phase2/exploded_data_by_demographics.csv.gz`,
and run the do file `src/stata/040_ads_analysis.do`.

### HUD Data

Crosswalks between ZIP codes and Census tracts are made available by the US Department
of Housing and Urban Development [here](https://www.huduser.gov/portal/datasets/usps_crosswalk.html).
We have utilized the third quarter 2021 files, which crosswalk to the 2010 Census
boundaries. For convenience, these files are reproduced in the `data/hud` folder of this
repository.

Din, Alexander and Wilson, Ron, 2020. "Crosswalking ZIP Codes to Census Geographies: Geoprocessing the U.S. Department of Housing & Urban Development’s ZIP Code Crosswalk Files," Cityscape: A Journal of Policy Development and Research, Volume 22, Number 1, https://www.huduser.gov/portal/periodicals/cityscpe/vol22num1/ch12.pdf

### Elections data

Election data is available from MEDSL at their [GitHub repo](https://github.com/MEDSL/2020-elections-official) and the [dataverse](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/VOQCHQ). For convenience, these data have been reproduced in the `data/medsl` folder of this repository.

MIT Election Data and Science Lab, 2018, "County Presidential Election Returns 2000-2020", https://doi.org/10.7910/DVN/VOQCHQ, Harvard Dataverse, V9, UNF:6:qSwUYo7FKxI6vd/3Xev2Ng==


## Code layout

All of our code lives in the `src` directory. It contains three folders described below:

### `hxpr`: Python utilities

These are a few python utilities that are useful throughout the project. No analysis
occurs in these folders.

### `notebooks`: Data wrangling in Python

This folder contains all of the python notebooks used for data wrangling. Each notebook
handles a different type of data we interacted with.

### `stata`: Analyses in Stata

Our principal statistical analyses were performed in Stata. These may be found in this
folder.
