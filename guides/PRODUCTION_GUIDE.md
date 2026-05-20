# KEIT Odoo — Production / Manufacturing Guide

Audience: production planners + shop floor. App: **Manufacturing**.

## Core concepts

- **BoM (Bill of Materials)** = the recipe. What components + quantities
  make one finished product.
- **Manufacturing Order (MO)** = one production run. Consumes components,
  produces finished goods.
- **Routes** decide *when* an MO is created:
  - **Manufacture** — this product is built, not bought
  - **Replenish on Order (MTO)** — an MO is created automatically when a
    customer orders it (make-to-order)
  - Without MTO — you create MOs manually based on forecast (make-to-stock)

## Creating a Bill of Materials

1. Manufacturing → Products → **Bills of Materials** → New
2. **Product**: the finished good (e.g. Control Panel CP-700)
3. **Quantity**: 1 (the BoM is "to make 1 of these")
4. **Components tab**: add each material + quantity
   - Example CP-700: 1 Metal Enclosure, 1 PCB Board, 3 Contactors,
     1 Wiring Harness, 8 Steel Bolts
5. Save

Multi-level BoMs: a component can itself have a BoM (sub-assembly). Odoo
handles the nesting.

## Make-to-Order setup (auto MO from sales)

On the finished product (Inventory tab → Routes):
- Tick **Manufacture** + **Replenish on Order (MTO)**
- Now: customer SO confirmed → MO created automatically → smart button on the SO

## Running a Manufacturing Order

**Manual (make-to-stock):**
1. Manufacturing → Operations → Manufacturing Orders → New
2. Product + quantity → Odoo pulls the BoM
3. **Confirm** → MO reserves components

**From a sales order (make-to-order):** the MO already exists — open it
from the SO's Manufacturing smart button.

**To produce:**
1. Check **Component Status** is "Available" (green). If "Not Available",
   you're short a material — receive/buy it first, then **Check Availability**
2. For lot-tracked finished goods: set the production **Lot/Serial Number**
3. Click **Produce All** → fills consumption quantities
4. Click **Mark as Done** → components consumed, finished goods in stock

## Traceability (what KEIT cares about most)

Every MO links its consumed component lots to the produced lot. To trace:
- Manufacturing → open a done MO → see exactly which component lots went in
- Or Inventory → Lots/Serial Numbers → open the finished lot →
  **Traceability** button → full genealogy tree

This answers "which material batch is in this exact finished unit?" —
critical for quality recalls and warranty.

## If an MO is cancelled mid-run

Cancelling does **not** automatically return already-consumed components.
If you cancel after consuming materials, do a Physical Inventory
adjustment to put unused components back. (Better: don't consume until
you're sure you'll finish.)

## Component shortage → auto-purchase

If a finished product is MTO and its components have **Buy** + **Reorder
rules**, confirming the MO can trigger purchase orders for missing
components automatically. Talk to the admin to wire up reorder rules per
component.

## Daily checklist for production

- Check **Manufacturing Orders → To Do** for today's runs
- Confirm component availability before starting
- Always set lot numbers on lot-tracked output
- Mark MOs Done promptly so stock + accounting stay accurate
