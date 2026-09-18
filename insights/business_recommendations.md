# Business recommendations

## How to read this page

These recommendations are hypotheses drawn from the historical public Olist dataset. They demonstrate a marketplace business-analysis approach; they are not claims about JD or instructions based on current Olist operations.

## 1. Turn high-value first-time buyers into second purchases

**Evidence**

- Only **3.00%** of unique customers placed at least two delivered orders.
- The **24,935 high-value one-time buyers** generated **BRL 8.14M**, or about **61.5%** of delivered item revenue.

**Interpretation**

The biggest revenue cohort is valuable but largely one-off. That makes reactivation a more targeted opportunity than treating every new buyer identically.

**Suggested operating test**

Build a post-delivery journey for high-value first purchasers: category-relevant replenishment or complementary-item recommendations, followed by a time-bound second-purchase incentive. Compare a holdout group on second-order rate and incremental contribution margin before scaling.

## 2. Protect the categories that anchor revenue, then use bundles in low-price, high-volume categories

**Evidence**

- `health_beauty` was the largest category at **BRL 1.23M (9.33%)** of delivered item revenue.
- The five highest-revenue categories represented **39.83%** of delivered item revenue.
- The quartile screen highlighted `telephony`, `electronics`, and `fashion_bags_accessories` as high-volume, lower-price categories.

**Interpretation**

High-revenue categories deserve availability and quality protection. Separately, high-volume/low-price categories may have room to improve basket value rather than merely chase more units.

**Suggested operating test**

For top-revenue categories, monitor in-stock rate, seller fulfilment quality, cancellation rate, and review score. For the low-price, high-volume group, test accessory bundles or cross-sell placements and measure incremental item revenue per order, not just click-through rate.

## 3. Diagnose sellers whose order growth does not convert into item-revenue growth

**Evidence**

The query flags 30 qualified seller-months where completed orders increased but item revenue fell or stayed flat. The highest-priority example grew from 8 to 24 orders in 2018-04 while item revenue fell from BRL 5,013.00 to BRL 3,245.40.

**Interpretation**

This is a diagnostic signal, not proof of poor performance. It can arise from lower-priced product mix, price cuts, promotion-funded orders, or a shift toward lower-intent traffic.

**Suggested operating test**

Open a seller scorecard with product-level mix, price, discount, cancellation, delivery, and traffic-quality data. Classify the reason before acting: preserve a healthy volume strategy if margins hold, or improve assortment and traffic targeting if basket value is eroding.

## 4. Improve delivery reliability through segmented merchant operations

**Evidence**

Among delivered orders with both dates available, **8.11%** arrived after the promised estimated delivery date.

**Interpretation**

The aggregate rate tells us delivery experience is material, but it does not reveal a root cause. A platform team should avoid penalizing merchants uniformly before separating seller, route, product-type, and regional effects.

**Suggested operating test**

Create a weekly exception list of seller × customer state × category combinations with a sufficient order base. Review handover timeliness, carrier routing, and estimated-date accuracy. Set a service-level target only after confirming which component drives the delay.

## 5. Balance strategic-seller support with scalable long-tail playbooks

**Evidence**

The top 10 sellers contributed **13.27%** of delivered item revenue, leaving **86.73%** outside that group. The largest individual seller represented **1.72%**.

**Interpretation**

Revenue is not dominated by a handful of merchants in this source. Focusing exclusively on key accounts would leave most marketplace revenue outside the operating model.

**Suggested operating test**

Use two tracks: account plans for strategic sellers and standardised onboarding, assortment, fulfilment, and diagnostic playbooks for the broader seller base. Compare improvement in seller activation, revenue per active seller, and delivery quality by track.

## Measurement principles

- Keep the denominator explicit: customers, delivered orders, items, or sellers.
- Use completed-order data for commercial outcomes; keep cancelled and unavailable orders for funnel and service diagnostics.
- Treat each recommendation as a testable hypothesis. Add margin, promotion, inventory, and traffic data before assessing profitability or causality.

