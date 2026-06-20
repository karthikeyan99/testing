# Sales Tracker — Flipkart & Amazon Seller App

A cross-platform (Android + iOS) Flutter app to track your **Flipkart** and
**Amazon** seller sales: revenue, marketplace fees, **GST tax**, inventory,
returns, and **net profit** — all in one place, working fully offline.

## Features

- **Dashboard** — gross revenue, net profit, GST collected, marketplace fees,
  units sold, returns; monthly revenue trend and a Flipkart-vs-Amazon split.
- **Orders** — add/edit sales by hand or import them; search and filter by
  marketplace, status and date range.
- **CSV import** — load the order/sales reports you download from Flipkart
  Seller Hub and Amazon Seller Central. Columns are matched by name, with a
  preview before importing. Re-imports are de-duplicated by order ID + SKU.
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
# 1. Generate android/ and ios/ folders (keeps pubspec.yaml and lib/ intact)
flutter create . --platforms=android,ios --project-name sales_tracker

# 2. Install dependencies
flutter pub get

# 3. Run on a connected device or emulator
flutter run

# Build release artifacts
flutter build apk        # Android
flutter build ios        # iOS (needs macOS + Xcode)
```

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
