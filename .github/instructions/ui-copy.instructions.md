---
description: "Use when writing or editing user-facing ERP text, labels, descriptions, table content, or seed data. Covers English-only UI copy."
---

# Global Rule: Strictly English UI & No Amharic Text

Across the entire Haleta ERP application (all views, components, models, schemas, and dummy seed data):

## 1. Strictly English Interface & Seed Data
- **NEVER** include Amharic text, Ethiopic script (e.g. 'የዲሲፕሊን ሰሚ ኮሚቴ', 'የቅሬታ ሰሚ ኮሚቴ', 'አበበ ከበደ'), or bilingual translations in UI labels, subtitles, table columns, badges, or mock data.
- All UI text, headers, table headers, labels, descriptions, and mock data MUST be purely in clean, professional English.

## 2. No Localized Amharic Properties in Models
- **NEVER** expose `name_am`, `title_am`, or similar Amharic fields in interfaces, templates, or displays unless specifically asked by backend localization pipelines. In the UI presentation layer, display only clean English strings.

## 3. Form Selection Placeholder Standard: `Select [Core Noun]`
- **Concise, Action-Led Format**: All dropdown selectors and combobox placeholders inside form inputs and creation modals MUST use the concise action pattern: **`Select [Core Noun]`**.
- **Never Repeat Long Labels**: Do not repeat the full multi-word label or use wordy sentences in placeholders:
  - Label: `Statutory Purchase Method` $\rightarrow$ Placeholder: **`Select Method`**
  - Label: `Category Scope` $\rightarrow$ Placeholder: **`Select Scope`**
  - Label: `Buying Desk Scope` $\rightarrow$ Placeholder: **`Select Scope`**
  - Label: `Procurement Unit` $\rightarrow$ Placeholder: **`Select Unit`**
  - Label: `Employee` $\rightarrow$ Placeholder: **`Select Employee`**
  - Label: `Department` $\rightarrow$ Placeholder: **`Select Department`**
  - Label: `Work Calendar` $\rightarrow$ Placeholder: **`Select Calendar`**
  - Label: `Receipt Mode` $\rightarrow$ Placeholder: **`Select Mode`**
  - Label: `Spend Class` $\rightarrow$ Placeholder: **`Select Class`**
- **Form Placeholders vs. Filter Prompts**:
  - `All ...` phrases (e.g. `All Categories`, `All Buying Desks`, `All States`) are **strictly reserved for table filter dropdowns** to indicate clearing or unfiltering.
  - In form inputs and modals, NEVER use `All Categories (Global Scope)` as a placeholder; use `Select Scope`.

## 4. Top-Level Directory Breadcrumbs Standard
- On top-level directory/listing pages (e.g. `Spend Threshold Bands`, `Procurement Units`, `Procurement Categories`, `Leave Policies`), the breadcrumb MUST contain **strictly the exact page name** (`[{ label: 'Exact Page Name' }]`).
- NEVER prefix directory breadcrumbs with the parent module name (`Procurement`) or sibling page links.
- Detail / inspection drill-downs expand to: `[{ label: 'Page Name', to: '...', onClick: ... }, { label: 'Item Name' }]`.
