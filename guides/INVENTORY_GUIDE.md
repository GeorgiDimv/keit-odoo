# KEIT Odoo — Inventory / Warehouse Guide

Audience: warehouse + receiving staff. App: **Inventory**.

## The big picture

Everything that moves stock is a **Transfer** (picking):
- **Receipts** (IN) — goods arriving from vendors
- **Deliveries** (OUT) — goods shipping to customers
- **Internal** — moving between locations
- **Manufacturing** consumes/produces stock automatically

## Receiving goods from a vendor

1. Inventory → Operations → **Transfers** → filter **To Receive** (or open from the PO's Receipt smart button)
2. Open the receipt (WH/IN/xxxxx)
3. Set the received **quantity** per line (defaults to ordered qty)
4. For **lot-tracked** items: type the lot/batch number in the line
   (e.g. supplier's batch number) — this is what makes traceability work
5. Click **Validate** → stock is now on hand

## Lots & Serial Numbers (traceability)

KEIT's materials are lot-tracked. This is how you trace a finished panel
back to its materials.

- **View all lots:** Inventory → Products → Lots/Serial Numbers
- **Trace a lot:** open a lot → **Traceability** smart button → shows the
  full tree: where it came from, what it was used in, where it went
- Example: open lot `CP700-BATCH-2026-001` → see it was made from
  `MK-300-LOT-2026-A`, `PCB-100-LOT-2026-A`, etc., and shipped to Festo

## Checking stock on hand

- **Current:** Inventory → Products → open a product → "On Hand" smart button
- **By location:** Inventory → Reporting → **Locations**
- **At a past date (stock card):** Inventory → Reporting → **Inventory at Date**
  → pick any date → see what was in stock then

## Inventory valuation

- Inventory → Reporting → **Valuation** — current stock value
- Under the BG default (manual periodic), value updates at month-end via
  an inventory journal entry, not on every move

## Physical inventory count

1. Inventory → Operations → **Physical Inventory**
2. Filter to the location/products you're counting
3. Enter **Counted Quantity** per line
4. **Apply** → Odoo creates the adjustment move and updates stock

## Internal transfers (between locations)

1. Inventory → Operations → Transfers → New
2. Operation Type: Internal Transfer
3. Set source + destination location, products, quantities
4. Validate

## Delivering to a customer

Usually starts from a confirmed Sales Order (its Delivery smart button),
but you can see all pending deliveries:
1. Inventory → Operations → Transfers → filter **To Deliver**
2. Open, confirm quantities (and pick the lot to ship for lot-tracked goods)
3. **Validate** → goods leave the warehouse

## Daily checklist for warehouse staff

- Morning: check **To Receive** and **To Deliver** counts on the Inventory dashboard
- Receive incoming goods, always entering lot numbers
- Validate deliveries as they ship
- Report any quantity mismatches to the manager (don't silently adjust)
