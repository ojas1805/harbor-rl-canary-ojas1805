
#!/bin/bash
set -e

cat > /app/reconcile.py <<'PYTHON'
import argparse
import csv
import json
from datetime import datetime, timezone
from decimal import Decimal, ROUND_HALF_UP


def parse_timestamp(value):
    timestamp = datetime.fromisoformat(value.strip().replace("Z", "+00:00"))

    if timestamp.tzinfo is None:
        raise ValueError("Timestamp must include a UTC offset")

    return timestamp.astimezone(timezone.utc)


def reconcile(input_file):
    latest_transactions = {}

    with open(input_file, "r", newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)

        for row in reader:
            tx_id = row["tx_id"].strip()
            timestamp = parse_timestamp(row["timestamp"])

            if tx_id not in latest_transactions:
                latest_transactions[tx_id] = (timestamp, row)
            elif timestamp >= latest_transactions[tx_id][0]:
                latest_transactions[tx_id] = (timestamp, row)

    total_valid_amount = Decimal("0.00")
    valid_count = 0
    failed_count = 0

    for timestamp, row in latest_transactions.values():
        status = row["status"].strip().upper()

        if status == "VALID":
            amount = Decimal(row["amount"].strip())
            total_valid_amount += amount
            valid_count += 1
        else:
            failed_count += 1

    total_valid_amount = total_valid_amount.quantize(
        Decimal("0.01"),
        rounding=ROUND_HALF_UP
    )

    return {
        "total_valid_amount": float(total_valid_amount),
        "valid_count": valid_count,
        "failed_count": failed_count
    }


def main():
    parser = argparse.ArgumentParser(
        description="Payment transaction reconciliation"
    )
    parser.add_argument("--input", required=True)

    args = parser.parse_args()

    result = reconcile(args.input)
    print(json.dumps(result))


if __name__ == "__main__":
    main()
PYTHON

chmod +x /app/reconcile.py
