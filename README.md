# Sales Tracker — Flipkart & Amazon Seller App

A cross-platform (Android + iOS) Flutter app to track your **Flipkart** and
**Amazon** seller sales: revenue, marketplace fees, **GST tax**, inventory,
returns, and **net profit** — all in one place, working fully offline.

## Features

- **Dashboard** — gross revenue, net profit, GST collected, marketplace fees,
  units sold, returns; monthly revenue trend and a Flipkart-vs-Amazon split.
- **Orders** — add/edit sales by hand or import them; search and filter by
  marketplace, status and date range.
- **Net Payout view** — the headline number: how much money actually reached
  your bank each month (settlement value, after all fees + GST), split by
  Flipkart vs Amazon, grouped by settlement date.
- **Flipkart settlement import** — load the **Settled Transactions `.xlsx`**
  directly (multi-sheet workbook, headers on row 2). The importer reads the
  "Orders" sheet and uses the real **Bank Settlement Value** per order.
  Re-importing the same period safely replaces it.
- **CSV import** — load the order/sales reports you download from Flipkart
  Seller Hub and Amazon Seller Central. Columns are matched by name, with a
  preview before importing.
- **Inventory** — SKUs with cost price, stock, HSN code and low-stock alerts.
  Stock auto-decrements as sales are recorded, and SKUs autofill sale lines.
- **GST tax reporting** — GST backed out of inclusive prices, split into
  CGST/SGST (intra-state) or IGST (inter-state), summarised by rate for GSTR
  filing prep.
- **Settings** — business profile (name, GSTIN, home state, default GST rate).
  The home state auto-decides CGST/SGST vs IGST for each sale based on the
  buyer's state.
- **Profit & Loss** — taxable revenue minus product cost and marketplace fees.
- **Export** — share a full sales CSV or a GST summary CSV.
- **API-ready** — a `MarketplaceApi` interface with Amazon SP-API and Flipkart
  API stubs is in place so live auto-sync can be added later without touching
  the storage or UI layers.

## Getting started

This repo contains the Dart source (`lib/`), tests, and project config. Generate
the platform scaffolding (Android/iOS) once, then run:

```bash
# 1. Generate platform folders (keeps pubspec.yaml and lib/ intact)
flutter create . --platforms=android,ios,web --project-name sales_tracker

# 2. Install dependencies
flutter pub get

# 3. (Web only, one time) copy the sqlite3 WASM worker into web/
dart run sqflite_common_ffi_web:setup

# 4. Run
flutter run                 # pick a device, or:
flutter run -d edge         # Chrome/Edge for a quick preview
flutter run -d <android-id> # full features incl. native share

# Build release artifacts
flutter build apk        # Android
flutter build ios        # iOS (needs macOS + Xcode)
flutter build web        # Web
```

The app runs on Android, iOS, web (Chrome/Edge) and desktop. The database
backend is selected per platform automatically (`lib/db/db_init*.dart`): the
sqflite plugin on mobile, FFI on desktop, and WASM sqlite on web. CSV export
opens the share sheet on native and downloads the file on web.

Requires Flutter 3.x (Dart 3). Run the tests with `flutter test`.

## How the numbers work

- `unitPrice` is the **GST-inclusive** selling price per unit.
- Taxable value = gross ÷ (1 + GST%); GST = gross − taxable value.
- Net profit = taxable value − product cost − marketplace fees. GST collected is
  treated as a pass-through liability, not profit.
- Returned / cancelled / refunded orders are excluded from revenue and profit
  but tracked separately.

## Project structure

```
lib/
  models/        Sale, Product, SalesSummary, enums
  db/            SQLite schema + connection
  repositories/  Data access for sales and products
  providers/     State management (provider package)
  services/      CSV import/export, future marketplace API layer
  screens/       Dashboard, Orders, Inventory, Reports, Settings, Import, Add/Edit
  widgets/       Summary cards, charts, chips, date-range bar
  utils/         Formatters and theme
test/            GST and summary calculation tests
```

## Adding live API sync later

Implement `MarketplaceApi` (`lib/services/api/`) for Amazon SP-API and Flipkart,
return `Sale` objects from `fetchOrders`, and pass them to
`SalesProvider.importSales` — the same path CSV import uses. Credential storage
and a sync trigger are the only additions needed.
