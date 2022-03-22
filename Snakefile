rule all:
    input:
        "data/phase2/merged/data_by_zipcode.parquet",
        "data/phase2/demographics_by_zipcode.csv.gz",
        "data/phase2/zip_code_with_two_party_vote_share_crude.csv"


rule convert_data:
    input:
        "data/hud/COUNTY_ZIP_092021.xlsx",
        "data/hud/ZIP_COUNTY_092021.xlsx",
        "data/hud/TRACT_ZIP_092021.xlsx",
        "data/hud/ZIP_TRACT_092021.xlsx"
    output:
        "data/hud/COUNTY_ZIP_092021.parquet",
        "data/hud/ZIP_COUNTY_092021.parquet",
        "data/hud/TRACT_ZIP_092021.parquet",
        "data/hud/ZIP_TRACT_092021.parquet"
    shell:
        "mkdir -p build && poetry run papermill src/notebooks/000_Data_to_Parquet.ipynb build/000_Data_to_Parquet.ipynb"

rule parse_data:
    input:
        "data/phase2/original/DePaul Campaign Data - Demographics.xlsx",
        "data/phase2/original/DePaul Campaign Data - State.xlsx",
        "data/phase2/original/Depaul Campaign Data - Zip Codes.xlsx",
        "data/phase2/original/DePaul Campaign Data - Campaign & Ad Performance.xlsx"
    output:
        "data/phase2/merged/data_by_zipcode.parquet",
        "data/phase2/merged/data_by_demographics.parquet",
        "data/phase2/merged/data_by_state.parquet",
        "data/phase2/merged/data_by_zipcode_merged_census.parquet",
        "data/phase2/exploded/exploded_data_by_zipcode.parquet",
        "data/phase2/exploded/exploded_data_by_demographics.parquet",
        "data/phase2/exploded/exploded_data_by_state.parquet",
        "data/phase2/exploded/exploded_data_by_zipcode_merged_census.parquet",
        "data/phase2/exploded/exploded_data_by_zipcode.csv.gz",
        "data/phase2/exploded/exploded_data_by_demographics.csv.gz",
        "data/phase2/exploded/exploded_data_by_state.csv.gz",
        "data/phase2/exploded/exploded_data_by_zipcode_merged_census.csv.gz"
    shell:
        "mkdir -p build && poetry run papermill src/notebooks/010_Parse_Data.ipynb build/010_Parse_Data.ipynb"

rule political_data:
    input:
        "data/medsl/countypres_2000-2020.csv.xz",
        "data/hud/COUNTY_ZIP_092021.parquet",
        "data/hud/ZIP_COUNTY_092021.parquet"
    output:
        "data/phase2/zip_code_with_two_party_vote_share_crude.parquet",
        "data/phase2/zip_code_with_two_party_vote_share_crude.csv"
    shell:
        "mkdir -p build && poetry run papermill src/notebooks/020_Political_Data.ipynb build/020_Political_Data.ipynb"

rule census_data:
    input:
        "data/hud/TRACT_ZIP_092021.parquet",
        "data/hud/ZIP_TRACT_092021.parquet"
    output:
        "data/phase2/demographics_by_zipcode.csv.gz"
    shell:
        "mkdir -p build && poetry run papermill src/notebooks/030_Census_Data.ipynb build/030_Census_Data.ipynb"
