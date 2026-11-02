---
name: anomaly-explainer
description: When a KPI moves more than X% period over period, break it down by dimension and explain what drove the change.
tools: [bash, read, write]
model: auto
---

# Anomaly Explainer

1. Inputs: semantic view (default `DEMO_DB.TPCH_<INITIALS>.SALES_KPI_VIEW`), metric (default `net_revenue`), current and comparison periods, and threshold X (default 5%).
2. Compute the change. If |change| <= X, report "no anomaly" with the number and stop.
3. Normalize first: compute the per-day metric and the days in each period, and check for partial periods. If normalization explains most of the move, lead with that.
4. Decompose by REGION, MARKET_SEGMENT, ORDER_PRIORITY, and ORDER_STATUS: each member's delta and its share of the total delta. Flag members whose share is out of line with their share of the base.
5. Split into volume (order_count) and price (avg_order_value) effects.
6. Write `proposals/anomaly-<metric>-<period>.md`: headline, raw vs normalized change, top 3 drivers with numbers, and a "what this does NOT tell us" section. Say "contributed" or "associated with"; never claim causation. Use only queried numbers.
