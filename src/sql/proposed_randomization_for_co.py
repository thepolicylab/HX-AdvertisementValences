"""
This code approximately blocks a table by ZIP code

Assumes there is a table called `easy_enrollment` which has a schema ≈ like:

  CREATE TABLE easy_enrollment (
    id                   BIGINT,
    name                 VARCHAR(255),
    household_id         BIGINT,
    address1             VARCHAR(255),
    address2             VARCHAR(255),
    city                 VARCHAR(64),
    state                CHAR(2),
    zipcode              CHAR(5),
    did_check_box        BOOLEAN,
    email                VARCHAR(255),
    may_contact          BOOLEAN,
    has_enrolled         BOOLEAN,
  )
"""
from hashlib import sha256

import pandas as pd


# Name of input file
INPUT_DATA = "RWJF input.csv"

# Format of output filename
OUTPUT_FILE_FORMAT = "RWJF Randomizations - 2022-10-31 - {arm_name}.csv"

NUM_ARMS = 4       # Number of arms in experiment. 0 = Control
MIN_ZIP_SIZE = 10  # Minimum ZIP code size to block on

# Read data; make sure zipcode gets read as string
df = pd.read_csv(
    INPUT_DATA,
    dtype={"zipcode": str}
)

def get_hash_as_hexdigest(col: str, salt: str = "asalt") -> str:
    """ Get a hash of a string column prepended by a salt """
    return sha256(f"{salt}::{col}".encode("utf8")).hexdigest()


# Append a random person id
df["person_id"] = df["id"].apply(get_hash_as_hexdigest)

# Create the universe according to our conditions, including one person per household
universe_df = df[
    df["did_check_box"]       # Signed up for easy enrollment
    & df["email"].notna()     # Has an email address
    & df["address1"].notna()  # Has an address
    & df["may_contact"]       # Has not opted out of comms
    & ~df["has_enrolled"]     # Has not already enrolled
]

# Keep one person per household
universe_df = (universe_df
    .sort_values(by=["household_id", "person_id"])  # Sort for consistency
    .drop_duplicates(subset=["household_id"])
    .copy()
)


# Group small ZIP codes into the largest ZIP code
# Break ties by taking lowest ZIP code
zipcode_sizes = universe_df.groupby("zipcode").size()
largest_zipcode = zipcode_sizes.sort_index().idxmax()
universe_df["is_small_zipcode"] = (universe_df["zipcode"]
    .isin(zipcode_sizes[zipcode_sizes < MIN_ZIP_SIZE].index)
)
universe_df["block_id"] = universe_df["zipcode"].copy()
universe_df.loc[universe_df["is_small_zipcode"], "block_id"] = largest_zipcode

# Create randomizations
random_df = universe_df.copy()
random_df["row_hash"] = random_df["block_id"].apply(get_hash_as_hexdigest)
random_df["arm"] = random_df.groupby("row_hash").cumcount() % NUM_ARMS

# Write the randomizations out
for arm in range(NUM_ARMS):
    this_df = random_df[random_df["arm"] == arm]
    if arm == 0:
        this_df.to_csv(OUTPUT_FILE_FORMAT.format(arm_name="DO NOT SEND"), index=False)
    else:
        this_df.to_csv(OUTPUT_FILE_FORMAT.format(arm_name=f"Card {arm}"), index=False)
