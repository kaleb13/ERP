# Global Rule: Strictly English UI & No Amharic Text

Across the entire Haleta ERP application (all views, components, models, schemas, and dummy seed data):

## 1. Strictly English Interface & Seed Data
- **NEVER** include Amharic text, Ethiopic script (e.g. 'የዲሲፕሊን ሰሚ ኮሚቴ', 'የቅሬታ ሰሚ ኮሚቴ', 'አበበ ከበደ'), or bilingual translations in UI labels, subtitles, table columns, badges, or mock data.
- All UI text, headers, table headers, labels, descriptions, and mock data MUST be purely in clean, professional English.

## 2. No Localized Amharic Properties in Models
- **NEVER** expose `name_am`, `title_am`, or similar Amharic fields in interfaces, templates, or displays unless specifically asked by backend localization pipelines. In the UI presentation layer, display only clean English strings.
