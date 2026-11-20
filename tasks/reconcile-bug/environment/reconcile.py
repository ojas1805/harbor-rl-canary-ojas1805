
import argparse
import csv
import json
import sys
from datetime import datetime


def reconcile(input_file):
    transactions = []

    with open(input_file, "r", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            transactions.append(row)

    total_valid_amount = 0.0
    valid_count = 0
    failed_count = 0

    seen = {}

    for row in transactions:
        tx_id = row["tx_id"]
        status = row["status"].strip().upper()

        # BUG 3: Duplicate transaction IDs are not resolved.
        # The latest timestamp should win.

        # BUG 2: PENDING transactions are incorrectly accepted.
        if status in ("VALID", "PENDING"):
            try:
                amount = float(row["amount"])
            except (ValueError, TypeError):
                amount = 0.0

            total_valid_amount += amount
            valid_count += 1
        else:
            failed_count += 1

    return {
        "total_valid_amount": round(total_valid_amount, 2),
        "valid_count": valid_count,
        "failed_count": failed_count
    }


def main():
    parser = argparse.ArgumentParser(
        description="Payment transaction reconciliation"
    )

    # BUG 1: The required --input argument is named --file.
    parser.add_argument("--file", required=True)

    args = parser.parse_args()

    try:
        result = reconcile(args.file)
        print(json.dumps(result, indent=2))
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
