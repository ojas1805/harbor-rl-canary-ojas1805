
# Payment Transaction Reconciliation

You are working with a Python CLI application that reconciles payment transactions from CSV files.

## Input

The application must accept a CSV file through:

    python /app/reconcile.py --input /path/to/transactions.csv

The CSV contains four columns:

- tx_id
- timestamp
- amount
- status

## Output

The application must print a JSON object containing:

- total_valid_amount
- valid_count
- failed_count

## Business Rules

1. Only transactions with status VALID should contribute to the valid amount and valid count.
2. Transactions with FAILED, PENDING, or any other non-VALID status must contribute to failed_count.
3. Transaction IDs must be unique in the reconciliation result. If multiple rows have the same tx_id, retain only the row with the latest timestamp.
4. Timestamps may contain different UTC offsets. Compare timestamps by their actual chronological instant, not by their string representation.
5. Amounts must be calculated using decimal arithmetic and rounded to two decimal places.
6. The output must contain valid JSON.

## Execution

The application should accept the --input argument and print the reconciliation summary to standard output.
