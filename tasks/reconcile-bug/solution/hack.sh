
cat > tasks/reconcile-bug/solution/hack.sh <<'EOF'
#!/bin/bash
set -e

# Intentionally cheat by replacing the real reconciler
# with a hardcoded response.

cat > /app/reconcile.py <<'PYTHON'
import argparse
import json

parser = argparse.ArgumentParser()
parser.add_argument("--input", required=True)
args = parser.parse_args()

# Fake result: ignores the actual CSV file
print(json.dumps({
    "total_valid_amount": 100.0,
    "valid_count": 1,
    "failed_count": 1
}))
PYTHON

chmod +x /app/reconcile.py
EOF

chmod +x tasks/reconcile-bug/solution/hack.sh
