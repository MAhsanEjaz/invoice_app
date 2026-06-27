# Features Before Going Live

Based on competitor analysis (Invoice Simple, Zoho, Wave, Bookipi, Joist, Invoice Ninja, FreshBooks, QuickBooks).

---

## HIGH PRIORITY — Users will notice immediately

### ~~1. Convert Quote / Estimate → Invoice~~ ✅ DONE
- One-tap conversion from an existing Quote or Estimate document into a full Invoice
- Fully implemented: provider, confirmation dialog, UI button, all 4 language translations

### 2. Recurring Invoices
- Schedule an invoice to repeat (weekly / monthly / custom interval)
- Auto-create the next invoice when the period ends
- Show a "recurring" badge on those invoices in the list
- **Competitors: Zoho, Wave, Invoice Ninja, Joist, Bookipi, Invoice2go, FreshBooks**
- **Effort: Medium (3–5 days)**

### 3. Per-Line Item Discount
- Currently only a global invoice-level discount exists
- Add an optional discount % or flat amount per line item
- **Competitors: Zoho, Invoice Simple**
- **Effort: Low–Medium (1–2 days)**

### 4. Multiple / Partial Payment Recording
- Let users record multiple payments against one invoice (e.g. 50% upfront, 50% on delivery)
- Show running balance due after each payment
- Currently only a single `receivedAmount` field exists
- **Effort: Medium (2–3 days)**

### 5. Payment Link / UPI / QR on Invoice
- Add a field on the invoice for a payment link (UPI ID, PayPal.me, bank QR, etc.)
- Renders as text or scannable QR code on the PDF
- Critical for South Asian / Middle East market (UPI, bank transfer dominant)
- **Effort: Medium (2–3 days)**

### 6. Client Signature Capture
- Let the client (or user on behalf of client) draw a signature on the invoice
- Signature is embedded in the PDF
- **Competitors: Joist, Bookipi, Invoice Simple**
- **Effort: Medium (2–3 days)**

---

## MEDIUM PRIORITY — Makes the app feel professional

### 7. Saved Items Quick-Add Inside Invoice Screen
- Users retype items every invoice. Saved services exist but the UX is a separate screen.
- Show a bottom sheet with saved items/services while in the invoice editor for fast insertion
- **Effort: Low (1 day)**

### 8. Overdue Invoice Push Notification to User
- Already have due-date local notifications — extend to send a repeat reminder if still unpaid X days after due date
- **Effort: Low (1 day)**

### 9. Better Dashboard Reports
- Monthly revenue bar/line chart (last 6 months)
- Top clients by revenue
- Paid vs Unpaid breakdown chart (pie/donut)
- Outstanding amount ageing (30 / 60 / 90 days overdue buckets)
- **Competitors: Zoho (30+ reports), Wave (P&L dashboard)**
- **Effort: Medium (3–4 days)**

### 10. Expense / Receipt Tracking
- Basic expense log with category, amount, date, optional photo of receipt
- Shows total expenses on dashboard alongside revenue
- **Competitors: Zoho Free, Wave Free both include this**
- **Effort: Medium–High (4–6 days)**

### 11. Email Invoice Directly from App
- Currently share via system share sheet only
- Add an in-app "Send via Email" option with pre-filled subject and body
- **Effort: Medium (2 days)**

---

## LOWER PRIORITY — Nice to have / post-launch

### 12. QR Code on Invoice PDF
- Payment QR (UPI / bank details encoded) printed on the invoice
- Popular in South Asian and European markets (SageOne has ATCUD + QR)
- **Effort: Low (1 day with qr_flutter package)**

### 13. Photo / File Attachment on Invoice
- Attach job photos, contracts, or receipts to an invoice record
- Displayed in app; optionally embedded in PDF
- **Competitors: Joist, Bookipi**
- **Effort: Medium (2–3 days)**

### 14. Per-Invoice PDF Color / Template Override
- Currently template + color is a global setting
- Allow overriding template and accent color per individual invoice
- **Effort: Low–Medium (1–2 days)**

### 15. Client Portal (View / Download Link)
- Generate a shareable web link where the client can view and download their invoice
- **Competitors: Zoho, Invoice2go**
- **Effort: High (requires backend)**

### 16. Invoice "Viewed" Notification
- Know when the client opened/viewed the PDF
- Invoice Simple's #1 differentiating feature
- **Effort: High (requires backend tracking)**

---

## Our Strengths to Keep & Highlight in Play Store

- 6 PDF templates (most competitors offer 1–3)
- Multi-business support at zero cost
- 4 languages with full RTL support (Arabic, Urdu) — almost no competitor does this
- Full offline — no account, no subscription, no internet required
- Portable backup & restore (JSON) — cloud-only competitors can't offer this
- Custom tax label (GST, VAT, etc.) + default tax rate
- Professional invoice numbering (prefix + padding)
- Bank account details on invoice (critical for bank-transfer markets)
- Due date push notifications
