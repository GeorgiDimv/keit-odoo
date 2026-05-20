# KEIT Odoo — Accounting Guide

Audience: KEIT's accountant. App: **Accounting**. The Bulgarian chart of
accounts + VAT are already configured via l10n_bg.

## The two sides

- **Customers** (receivables / AR): money owed *to* KEIT — invoices
- **Vendors** (payables / AP): money owed *by* KEIT — bills

## Customer invoices

**From a sales order (normal flow):** SO → Create Invoice → it pulls
delivered quantities → Post.

**Manual invoice:** Accounting → Customers → Invoices → New
1. Customer, invoice date, due date
2. Add product lines (VAT 20% auto-applies from the fiscal position)
3. **Confirm** → assigns the legal number, posts to the ledger
   (DR 411 Receivable / CR 70x Revenue / CR 4532 Output VAT)

## Vendor bills

**From a purchase order:** PO → Create Bill → check it matches the
receipt (3-way match) → Post.

**Manual bill:** Accounting → Vendors → Bills → New → same idea
(DR expense or stock / DR 4531 Input VAT / CR 401 Payable).

## Registering a payment

1. Open a posted invoice/bill
2. Click **Register Payment**
3. Pick the **Bank** journal, amount (defaults to full), date
4. **Create Payment** → the invoice flips to **Paid**, AR/AP clears

## Bank reconciliation

1. Import or enter a bank statement: Accounting → Banking → (your bank
   journal) → **Statements** → upload CAMT file or enter lines manually
2. Click **Reconcile** on the statement
3. The OCA reconciliation widget **auto-suggests** the matching
   invoice/payment for each bank line
4. Confirm matches → bank line tied to the accounting entry

This is how you prove "the money actually arrived", not just "we invoiced".

## VAT reporting (monthly)

1. Accounting → Reporting → **Tax Report**
2. Pick the period (e.g. last month)
3. See Input VAT (4531) vs Output VAT (4532) and the net payable/refundable
4. **Export** (PDF/XLSX) → this is what you submit to NRA
   (current setup generates the file; you upload it via the NRA portal)

## Key reports — answering "what's the state of the business?"

| Question | Report |
|---|---|
| Who owes us, how much, how late? | Reporting → **Aged Receivable** |
| Who do we owe? | Reporting → **Aged Payable** |
| Are we profitable? | Reporting → **Profit and Loss** |
| What's our financial position? | Reporting → **Balance Sheet** |
| Every entry on an account | Reporting → **General Ledger** |
| A specific partner's history | Reporting → **Partner Ledger** |
| Unpaid invoices | Customers → Invoices → filter **Not Paid** |

All export to Excel (OCA `report_xlsx` is installed).

## Month-end checklist

1. Post all draft invoices/bills
2. Register all payments received/made
3. Reconcile the bank statement(s) fully
4. Run the inventory valuation journal (manual periodic — BG default)
5. Run the Tax Report, export, submit to NRA
6. Review Aged Receivable — chase overdue customers
7. Run Profit & Loss + Balance Sheet for management

## Things to never do

- Don't delete posted entries — use a **Credit Note**
  to reverse an invoice
- Don't change the chart of accounts without the adviser role + a reason
- Don't uninstall l10n_bg / l10n_bg_ledger (VAT compliance depends on them)

## Out of scope (separate systems / engagements)

- **Fiscal device (cash register)** — receipts, third-party connector
- **Payroll** — handled in a dedicated Bulgarian payroll system
- **Direct NRA submission** — current setup generates files for manual upload
