"""Order-insensitive, type-tolerant result-set comparison.

Deliberately NOT exact-string-match (IMPLEMENTATION_GUIDE.md Phase 6.4 calls this
out explicitly — SQL can be phrased differently and still be correct). Rows are
compared as multisets; within each row, values are compared as a sorted tuple of
normalized strings so column order/aliasing differences between the gold and
generated query don't cause false negatives. This is a pragmatic heuristic, not a
rigorous relational-equality check — the known gap is that it can't tell apart
two different columns that happen to hold the same value within a row.
"""

from collections import Counter
from decimal import Decimal


def _normalize_value(v) -> str:
    if v is None:
        return "\x00NULL\x00"
    if isinstance(v, Decimal):
        v = float(v)
    if isinstance(v, float):
        return f"{v:.6f}".rstrip("0").rstrip(".")
    return str(v).strip()


def _normalize_row(row: list) -> tuple:
    return tuple(sorted(_normalize_value(v) for v in row))


def result_sets_match(rows_a: list[list], rows_b: list[list]) -> bool:
    counter_a = Counter(_normalize_row(r) for r in rows_a)
    counter_b = Counter(_normalize_row(r) for r in rows_b)
    return counter_a == counter_b
