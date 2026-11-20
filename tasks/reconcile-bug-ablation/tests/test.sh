
#!/bin/bash
set -u

mkdir -p /logs/verifier

python3 - <<'PYTHON'
import csv
import json
import os
import random
import subprocess
import tempfile
from decimal import Decimal

APP = "/app/reconcile.py"
rng = random.SystemRandom()
score = 0.0

def random_amount():
    return Decimal(rng.randint(100, 999999)) / Decimal("100")

def write_csv(rows):
    f = tempfile.NamedTemporaryFile(
        mode="w", suffix=".csv", newline="", delete=False
    )
    writer = csv.DictWriter(
        f, fieldnames=["tx_id", "timestamp", "amount", "status"]
    )
    writer.writeheader()
    writer.writerows(rows)
    f.close()
    return f.name

def run_app(path, argument):
    return subprocess.run(
        ["python3", APP, argument, path],
        capture_output=True,
        text=True,
        timeout=10
    )

def run_with_fallback(path):
    result = run_app(path, "--input")
    if result.returncode == 0:
        return result
    return run_app(path, "--file")

def parse_result(result):
    if result.returncode != 0:
        return None
    try:
        return json.loads(result.stdout)
    except (ValueError, TypeError):
        return None

def matches(data, total, valid, failed):
    if not isinstance(data, dict):
        return False
    try:
        return (
            Decimal(str(data["total_valid_amount"])) == total
            and data["valid_count"] == valid
            and data["failed_count"] == failed
        )
    except (KeyError, ValueError, TypeError):
        return False

def check(rows, expected_total, expected_valid, expected_failed,
          argument="--input"):
    path = write_csv(rows)
    try:
        result = parse_result(run_app(path, argument))
        return matches(result, expected_total, expected_valid, expected_failed)
    finally:
        os.unlink(path)

# Check 1: Correct CLI argument (20%)
try:
    amount = random_amount()
    rows = [{
        "tx_id": "CLI-" + str(rng.randrange(1000000)),
        "timestamp": "2026-11-20T10:00:00+05:30",
        "amount": str(amount),
        "status": "VALID"
    }]
    if check(rows, amount, 1, 0):
        score += 0.20
        print("Check 1 passed: CLI")
    else:
        print("Check 1 failed: CLI")
except Exception as e:
    print("Check 1 error:", e)

# Check 2: Status handling (30%)
try:
    valid_amount = random_amount()
    pending_amount = random_amount()
    failed_amount = random_amount()

    rows = [
        {
            "tx_id": "STATUS-1",
            "timestamp": "2026-11-20T10:00:00+05:30",
            "amount": str(valid_amount),
            "status": "VALID"
        },
        {
            "tx_id": "STATUS-2",
            "timestamp": "2026-11-20T10:01:00+05:30",
            "amount": str(pending_amount),
            "status": "PENDING"
        },
        {
            "tx_id": "STATUS-3",
            "timestamp": "2026-11-20T10:02:00+05:30",
            "amount": str(failed_amount),
            "status": "FAILED"
        }
    ]

    if check(rows, valid_amount, 1, 2):
        score += 0.30
        print("Check 2 passed: status handling")
    else:
        # Give independent logic credit if the old CLI still exists.
        if check(rows, valid_amount, 1, 2, "--file"):
            score += 0.30
            print("Check 2 passed: status handling (legacy CLI)")
        else:
            print("Check 2 failed: status handling")
except Exception as e:
    print("Check 2 error:", e)

# Check 3: Duplicate IDs, chronological ordering and timezone comparison (50%)
try:
    old_amount = random_amount()
    latest_amount = random_amount()
    unique_amount = random_amount()

    rows = [
        {
            "tx_id": "DUP-1",
            "timestamp": "2026-11-20T05:00:00+00:00",
            "amount": str(latest_amount),
            "status": "FAILED"
        },
        {
            "tx_id": "DUP-1",
            "timestamp": "2026-11-20T10:00:00+05:30",
            "amount": str(old_amount),
            "status": "VALID"
        },
        {
            "tx_id": "DUP-2",
            "timestamp": "2026-11-20T10:10:00+05:30",
            "amount": str(unique_amount),
            "status": "VALID"
        }
    ]

    if check(rows, unique_amount, 1, 1):
        score += 0.50
        print("Check 3 passed: chronological duplicate and timezone handling")
    elif check(rows, unique_amount, 1, 1, "--file"):
        score += 0.50
        print("Check 3 passed: chronological duplicate handling (legacy CLI)")
    else:
        print("Check 3 failed: chronological duplicate and timezone handling")

except Exception as e:
    print("Check 3 error:", e)

score = round(score, 2)

with open("/logs/verifier/reward.txt", "w") as f:
    f.write(f"{score:.2f}\n")

print(f"Final dense reward: {score:.2f}")
PYTHON
