---
description: "Use when creating or editing ERP directory/listing views or data tables. Covers atomic columns, visibility defaults, table components, identity hierarchy, and status display."
---

# Haleta ERP — Table Column Architecture & Single-Information Standard

This rule governs how all data tables must structure columns, display information, and implement the column hider feature across Haleta ERP.

## Standard Directory Table Composition (QMT)

Use the linked QMT components for both Figma and the ERP implementation. The canonical Figma examples are the [table composition](https://www.figma.com/design/Zo2sdiJUDpOdTRMjnswMXw/Haleta-ERP---HR-Module?node-id=8948-56167), [Table Top Filter Section](https://www.figma.com/design/Zo2sdiJUDpOdTRMjnswMXw/Haleta-ERP---HR-Module?node-id=8957-94541), [Pagination](https://www.figma.com/design/Zo2sdiJUDpOdTRMjnswMXw/Haleta-ERP---HR-Module?node-id=8948-56247), and [Lead checkbox table cell](https://www.figma.com/design/Zo2sdiJUDpOdTRMjnswMXw/Haleta-ERP---HR-Module?node-id=8948-56215).

- **Title block:** Use `20px` top/bottom and `24px` left/right padding for the title and description.
- **Toolbar:** Place the linked QMT **Table Top Filter Section** directly below the title block. Preserve its layout, filters, column controls, and fullscreen action; change only the search prompt and primary action label needed by the page.
- **Table body:** Stretch the table to the card’s left and right edges with no horizontal wrapper padding. Do not add spacer columns or inset the table.
- **Selection:** Do not create a checkbox-only column. The first header cell combines its label and select-all checkbox (`Text=True`, `Checkbox=True`); each body row uses the QMT `Lead checkbox` table-cell variant. In Vue, render the shared `<FormCheckbox />` inside the first identity cell and give it an accessible label. Keep that identity column visible so row selection remains available.
- **Footer:** Use the linked QMT **Pagination** component in Figma (the desktop square card button-group variant) and the existing `<BasePagination />` through `<AppDataTable />`/`<BaseTable />` in Vue. Do not replace pagination with a hand-built footer or plain “Showing entries” text.
- **Component integrity:** Figma controls must remain linked instances of their source components. Build only the row/column structure around those instances; do not detach or redraw shared controls.
- **Sort & Filter Buttons Standard (Secondary Button with Icon Bold):** The Sort button in the Table Top Filter Section MUST ALWAYS be styled as our **Secondary Button** (`secondary-gray`: white background `#ffffff`, subtle border `#e5e5e5`, secondary text `#404040`), exactly matching the Filter button in visual hierarchy. It MUST NEVER be rendered as a colored/brand-blue button. Both Filter (`Filter`) and Sort (`ArrowUpDown`) button icons MUST have the property of `icon bold` (`stroke-width="2.5"` / `class="icon-bold"`).
- **Mandatory Table Header Standard (`Table header gray`):**
  - Table headers across all ERP tables in both Vue and Figma MUST use the gray header background (`#FAFAFA` / `var(--color-background-primary)`).
  - In Figma, always use the linked **`Table header gray`** component; **NEVER** use `Table header white`.
  - The first header cell uses `Table header gray` with `Checkbox=True, Text=True`.
- **Authoritative Geometry & Dimensional Specifications (Figma `5520:79458` & `8957:94541`):**
  - **Outer Card Container**: Full-bleed 100% width, `bg-white`, border `1px solid #E5E5E5` / `#E9EAEB`, `rounded-[12px]`, shadow `0px 1px 3px rgba(10,13,18,0.1)`.
  - **Title Block**: `px-24px py-16px` (Title 20px semi-bold `#404040`, Subtitle 14px regular `#737373`).
  - **Table Top Filter Section**: Height `74px`, `pt-20px pb-19px px-24px`.
    - **Search Input**: Width **400px**, height **44px**, border `1px solid #D5D7DA`, `rounded-8px`, icon `20px`.
    - **Filter Button**: Height **44px**, `px-18px py-10px`, `rounded-8px`, `secondary-gray` (`#FFFFFF`, border `#D9D9D9`), bold icon (`stroke-width="2.5"`).
    - **Sort Button**: Height **44px**, `px-12px py-10px`, `rounded-8px`, `secondary-gray` (`#FFFFFF`, border `#D9D9D9`), bold icon (`stroke-width="2.5"`).
    - **Column Solid Toggle**: Height **44px**, width **44px** (`p-10px`), `rounded-8px`, border `1px solid #D5D7DA`, icon `<IconColumnSolid>` `20px`.
    - **Maximize Button**: Height **44px**, width **44px** (`p-10px`), `rounded-8px`, border `1px solid #D5D7DA`, icon `maximize` `20px`.
    - **Primary CTA**: Height **44px**, `px-16px py-10px`, `rounded-8px`, `bg-[#0B529C]`, semi-bold white text (14px), Plus icon `20px`.
  - **Table Header Cells**: Height **44px**, `bg-[#FAFAFA]`, border-b `1px solid #E9EAEB`, `px-24px py-12px`, text 12px Medium (`#737373`).
  - **Table Body Cells**: Height **72px**, border-b `1px solid #E9EAEB`, `px-24px py-16px`.
    - **Lead Identity Column**: Width **300px–340px** (`331px` in canonical Figma frame `5520:79458`), housing row checkbox (`20px`) + primary title (14px Medium, `#404040`) + code subtext (12px Regular, `#737373`).
    - **Data Columns**: `flex: 1 0 0` (proportional distribution, min-width 120px–200px).
    - **Actions Column**: `Table cell / Action 3-dots` (`MoreVertical`), width **60px–80px**.
  - **Pagination Footer**: Height **68px**, `px-24px py-16px`, border-t `1px solid #E9EAEB`, `bg-white`. Page buttons: **40px × 40px** square buttons (active `bg-[#0B529C]`).
- **Mandatory Table Cell Component Taxonomy (1:1 Design System Mapping):**
  - Every table column must map directly to its corresponding canonical **`Table cell / [Variant]`** from the QMT Team Library:
    1. **`Table cell / Lead checkbox`**: First identity column combining row-selection `<FormCheckbox />`, primary title (`#404040`), and optional code subtext (`#737373`).
    2. **`Table cell / Single badge`**: For Status, State, and salient policy/mode lookups using `<BaseBadge :color="...">`.
    3. **`Table cell / Multiple badge`**: For multi-value tag arrays or collections of pills.
    4. **`Table cell / Text`**: Standard data cells using `#404040` (secondary) for primary identifiers, or `#737373` (tertiary) for descriptions, dates, and foreign keys.
    5. **`Table cell / Currency` / `Amount`**: Formatted monetary values with currency code (e.g., `12,500.00 ETB`).
    6. **`Table cell / Toggle`**: For inline boolean active/inactive switches (`<FormToggle />` / `<AppSwitch />`).
    7. **`Table cell / Progress bar`**: For visual quota consumption, allocation percentages, or completion rates.
    8. **`Table cell / Trending positive` & `Trending negative`**: For metric deltas and percentage variances.
    9. **`Table cell / Leader avatar` & `Avatar group`**: For profile photo identity (entity's own directory) or team/committee rosters.
    10. **`Table cell / Action 3-dots`**: Standard 3-dot kebab menu button (`<MoreVertical />`) triggering the standardized action popover. Never use loose inline action buttons.

---

## Mandatory Column-First Table Construction in Figma (Zero Row-Based Assembly)

In Figma, tables MUST ALWAYS be constructed vertically by **Columns**, NEVER horizontally by **Rows**. The authoritative canonical standard is demonstrated in [Figma `10015:10134`](https://www.figma.com/design/05qJWp6THRmHsOuLX8oc5U/Haleta-ERP---Procurement-Module?node-id=10015-10134) and [Figma `5520:79511`](https://www.figma.com/design/Zo2sdiJUDpOdTRMjnswMXw/Haleta-ERP---HR-Module?node-id=5520-79511).

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Table Content Frame (Horizontal Auto-Layout, layoutMode: 'HORIZONTAL', itemSpacing: 0, padding: 0)         │
├─────────────────┬─────────────────┬─────────────────┬─────────────────┬─────────────────┬───────────────────┤
│ Column 1        │ Column 2        │ Column 3        │ Column 4        │ Column 5        │ Column 6 (Actions)│
│ (Vertical Frame)│ (Vertical Frame)│ (Vertical Frame)│ (Vertical Frame)│ (Vertical Frame)│ (Vertical Frame)  │
│ w: 300–340px    │ w: 190px        │ w: 122px        │ w: 176px        │ w: 127px        │ w: 109px          │
│ itemSpacing: 0  │ itemSpacing: 0  │ itemSpacing: 0  │ itemSpacing: 0  │ itemSpacing: 0  │ itemSpacing: 0    │
├─────────────────┼─────────────────┼─────────────────┼─────────────────┼─────────────────┼───────────────────┤
│ Header Cell 44px│ Header Cell 44px│ Header Cell 44px│ Header Cell 44px│ Header Cell 44px│ Header Cell 44px  │
│ (Table header)  │ (Table header)  │ (Table header)  │ (Table header)  │ (Table header)  │ (Table header)    │
│ width: FILL     │ width: FILL     │ width: FILL     │ width: FILL     │ width: FILL     │ width: FILL       │
├─────────────────┼─────────────────┼─────────────────┼─────────────────┼─────────────────┼───────────────────┤
│ Row 1 Cell 72px │ Row 1 Cell 72px │ Row 1 Cell 72px │ Row 1 Cell 72px │ Row 1 Cell 72px │ Row 1 Cell 72px   │
│ (Lead checkbox) │ (Text)          │ (Text)          │ (Text)          │ (Single badge)  │ (Action 3-dots)   │
│ width: FILL     │ width: FILL     │ width: FILL     │ width: FILL     │ width: FILL     │ width: FILL       │
├─────────────────┼─────────────────┼─────────────────┼─────────────────┼─────────────────┼───────────────────┤
│ Row 2 Cell 72px │ Row 2 Cell 72px │ Row 2 Cell 72px │ Row 2 Cell 72px │ Row 2 Cell 72px │ Row 2 Cell 72px   │
│ (Lead checkbox) │ (Text)          │ (Text)          │ (Text)          │ (Single badge)  │ (Action 3-dots)   │
│ width: FILL     │ width: FILL     │ width: FILL     │ width: FILL     │ width: FILL     │ width: FILL       │
├─────────────────┼─────────────────┼─────────────────┼─────────────────┼─────────────────┼───────────────────┤
│ Row 3 Cell 72px │ Row 3 Cell 72px │ Row 3 Cell 72px │ Row 3 Cell 72px │ Row 3 Cell 72px │ Row 3 Cell 72px   │
│ (Lead checkbox) │ (Text)          │ (Text)          │ (Text)          │ (Single badge)  │ (Action 3-dots)   │
│ width: FILL     │ width: FILL     │ width: FILL     │ width: FILL     │ width: FILL     │ width: FILL       │
└─────────────────┴─────────────────┴─────────────────┴─────────────────┴─────────────────┴───────────────────┘
```

### 1. Structural Auto-Layout Specification:
- **Table Body Container (`Content` / `Card Content`)**:
  - `layoutMode: 'HORIZONTAL'`
  - `itemSpacing: 0` (zero gap between column frames)
  - `padding: 0` (cells extend edge-to-edge)
  - `layoutAlign: 'STRETCH'` / `width: 'FILL'` (full bleed to card borders)
- **Column Container (`Column`)**:
  - `layoutMode: 'VERTICAL'`
  - `itemSpacing: 0` (zero gap between header cell and data cells)
  - `padding: 0`
  - Sizing: Either fixed width (e.g. `w-[190px]`, `w-[122px]`, `w-[176px]`, `w-[109px]`) or `layoutGrow: 1` (`flex: 1 0 0`).
- **Cells Inside Each Column Frame**:
  - **Child 0 (Header)**: Linked instance of **`Table header gray`** (`bg-[#FAFAFA]`, height `44px`, `width: FILL` / `layoutAlign: 'STRETCH'`).
  - **Child 1..N (Body)**: Linked instances of **`Table cell / [Variant]`** (height `72px`, `width: FILL` / `layoutAlign: 'STRETCH'`).

### 2. Why Row-Based Assembly is Forbidden:
- ❌ **NEVER create horizontal Row frames** (`Row 1`, `Row 2`, `Row 3`...):
  - In a row-based layout, adding a new column requires opening every row frame individually and manually inserting and resizing a cell across all rows.
  - Reordering columns requires moving individual cells in every row frame.
  - Deleting or hiding a column requires touching every single row.
- ✅ **Column-First Benefits**:
  - **Instant Column Addition**: Duplicate or insert ONE `Column` vertical frame.
  - **Drag-and-Drop Reordering**: Drag a `Column` frame left or right in Figma; all cells for that column move together.
  - **One-Click Column Resizing**: Resizing the parent `Column` frame automatically resizes the header and all body cells because children are set to `width: FILL`.
  - **Direct Column Hider Synchronization**: Hiding or showing a column in Figma simply toggles the `visible` property of that single `Column` frame, matching the ERP Column Hider mechanism 1:1.

### 3. Column Width Guidelines:
- **Lead Identity Column**: `300px–340px` (or `flex: 1 0 0` / `width: FILL`), housing the checkbox, entity name, and code subtext.
- **Categorical & Scope Columns**: `160px–220px` (e.g. Organization Unit `190px`, Reports To `176px`).
- **Numeric & Monetary Columns**: `130px–160px` (e.g. Guarantee `137px`, Spend Band `140px`).
- **Codes & Pay Grades**: `110px–130px` (e.g. Pay Grade `122px`, Unit Code `110px`).
- **State & Status Badges**: `120px–140px` (e.g. State `127px`, Status `130px`).
- **Actions Column**: `100px–110px` (`109px` in canonical frame), centering the 3-dot kebab menu button (`Table cell / Action 3-dots`).

---

## 1. Atomic Data Columns (One Column = One Information)
- **Strict Atomicity**: Every table column MUST represent a single, specific data field or attribute.
- **NEVER merge different or unrelated data attributes into one cell**:
  - ❌ **Forbidden**: A "Demographics" column combining Gender, Blood Group, and Marital Status.
  - ❌ **Forbidden**: A "Nationality & Status" column combining Nationality Type and Country Code.
  - ❌ **Forbidden**: A "Place of Birth" column combining Place of Birth and Date of Birth (DOB).
  - ✅ **Mandatory**: Each attribute has its own independent column (`Gender`, `Blood Group`, `Marital Status`, `Nationality Type`, `Country`, `Date of Birth`, `Place of Birth`).
- **Exception for Multi-Value Collections**:
  - A single cell may contain multiple items **if and only if** that specific field itself is a collection/list of items of the exact same data type (e.g., an array of multiple phone numbers, role pills, or assigned skills).

---

## 2. Minimalist Default View & Column Hider Standard
- **Clean Initial Table**:
  - Do not overwhelm the user with 10+ columns simultaneously.
  - Tables MUST default to 4–6 essential columns required for immediate identification and daily operations (e.g., `Identity`, `Gender`/`Type`, `Primary Identifier/Contact`, `State`, `Actions`).
- **Column Hider Integration & Exact Figma Icon**:
  - All non-essential, secondary, or detailed columns MUST still be configured in the column definitions with `visible: false` by default.
  - Users can enable or disable any column using the built-in Column Hider dropdown menu.
  - **Figma Column Icon (`<IconColumnSolid :size="16" />`)**: The column hide/show trigger button MUST use the exact 3-column solid SVG icon from Figma (`6095:96606` / `column-solid`), never generic Lucide `<Columns />`.
  - **Product Checkbox Component**: The column hide/show checklist (as well as all table row and select-all checkboxes) MUST use the authoritative product checkbox component (`<FormCheckbox />`) from QMT (`3345:24771` / `FormCheckbox.vue`). Never use raw `<input type="checkbox">`.
  - **Integrated Selection Column**: Do not add a separate checkbox-only column. Combine the select-all checkbox and identity header label in the first header cell, and use the `Lead checkbox` cell variant for each identity row. Keep that identity column visible when it contains row-selection controls.

---

## 3. Mandatory Component Architecture: `<AppDataTable />`
- Always use `<AppDataTable />` (`frontend/src/components/AppDataTable.vue`) or `<BaseTable />` (`frontend/src/components/BaseTable.vue`).
- Define the column configuration using `ColumnDef[]`:

```typescript
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';

const tableColumns = ref<ColumnDef[]>([
  // Essential columns visible by default
  { key: 'party_identity', label: 'Party Identity', visible: true },
  { key: 'gender', label: 'Gender', visible: true },
  { key: 'phone', label: 'Phone', visible: true },
  { key: 'fayda_id', label: 'Fayda ID', visible: true },
  { key: 'state', label: 'State', visible: true },

  // Secondary columns hidden by default, accessible in Column Hider menu
  { key: 'email', label: 'Email', visible: false },
  { key: 'marital_status', label: 'Marital Status', visible: false },
  { key: 'blood_group', label: 'Blood Group', visible: false },
  { key: 'nationality_type', label: 'Nationality Type', visible: false },
  { key: 'country', label: 'Country', visible: false },
  { key: 'birth_date', label: 'Date of Birth', visible: false },
  { key: 'birth_place', label: 'Place of Birth', visible: false },
  { key: 'residence', label: 'Primary Residence', visible: false },
]);

const handleToggleColumn = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  if (col) {
    col.visible = col.visible === false ? true : false;
  }
};

const isColVisible = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  return col ? col.visible !== false : true;
};
```

---

## 4. Template Integration Pattern
```vue
<AppDataTable
  v-model:searchQuery="searchQuery"
  :showFilter="true"
  :filterCount="activeFilterCount"
  :showColumns="true"
  :columns="tableColumns"
  @toggleColumn="handleToggleColumn"
  :showFullscreen="true"
  :totalEntries="filteredItems.length"
  v-model:currentPage="currentPage"
  v-model:perPage="perPage"
  :showPagination="true"
>
  <template #filter-panel>
    <!-- Filter fields in responsive grid -->
  </template>

  <table class="erp-table">
    <thead>
      <tr>
        <th v-if="isColVisible('party_identity')">
          <div class="th-name-content">
            <FormCheckbox
              :model-value="isAllSelected"
              :indeterminate="isPartiallySelected"
              size="md"
              @update:model-value="toggleSelectAll"
            >
              <span class="sr-only">Select all rows on this page</span>
            </FormCheckbox>
            <span>Party Identity</span>
          </div>
        </th>
        <th v-if="isColVisible('gender')">Gender</th>
        <!-- other atomic headers with v-if="isColVisible('...')" -->
        <th style="width: 80px; text-align: center;">Actions</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="item in paginatedItems" :key="item.id">
        <td v-if="isColVisible('party_identity')" class="td-name">
          <div class="name-cell-content">
            <FormCheckbox
              :model-value="selectedRowIds.includes(item.id)"
              size="md"
              @click.stop
              @update:model-value="() => toggleSelectRow(item.id)"
            >
              <span class="sr-only">Select {{ item.name }}</span>
            </FormCheckbox>
            <div class="name-cell-stack">
              <span class="table-name-primary">{{ item.name }}</span>
              <span class="table-code-subtext">{{ item.code }}</span>
            </div>
          </div>
        </td>
        <td v-if="isColVisible('gender')">...</td>
        <!-- other atomic cells with v-if="isColVisible('...')" -->
        <td class="action-cell">...</td>
      </tr>
    </tbody>
  </table>
</AppDataTable>
```

---

## 5. Entity Directory Page & Master-Detail Standard
- **No Outer Headers / Metrics on Directory Pages**:
  - Directory pages are composed directly as: `AppBreadcrumb` -> `<AppDataTable />`.
  - The entity title (`title="..."`) and rich multi-line description (`subtitle="..."`) sit inside the card header block.
  - The primary creation button (`+ Create [Entity]`) sits in the table toolbar's `#actions` slot.
  - Do not add unrequested KPI/Metric cards above standard directory tables. Operational/workflow directories are the documented exception and follow `status-metrics.instructions.md`; governance/reference directories do not show metrics.
- **Master-to-Detail Navigation & Strict Data Isolation**:
  - **Never use `<BaseTabs />`** as a top-level switcher between a Directory list table and a Detail profile view.
  - Directory table is always the root view.
  - Clicking a record row or selecting "View Details" from the action menu transitions to the detail view (`viewMode = 'detail'`).
  - **Zero Back Buttons (Strict Breadcrumb-Only Navigation)**: Detail views and sub-pages MUST navigate strictly via the clickable breadcrumb (`AppBreadcrumb`). **NEVER** create a "Back" button, back arrow, or `← Back to [Entities]` button.
  - **Strict Data Isolation**: Detail pages MUST be dedicated exclusively to the selected record. **NEVER** display other entities as selector tabs or pill bars inside a detail page.

---

## 6. Zero Standalone "Code" Column & Column Color Hierarchy Standard
- **No Standalone "Code" Column**:
  - `Code` MUST NEVER have its own standalone column in tables.
  - The first column MUST always be the **Name / identity** column. Put select-all and row-selection checkboxes inside that column; never add a separate checkbox-only column.
  - If the code is important enough to display, write the Name on top and Code at the bottom as sub-text:
    ```html
    <td class="col-name">
      <div class="name-cell-stack">
        <span class="table-name-primary">{{ item.name }}</span>
        <span class="table-code-subtext font-mono">{{ item.code }}</span>
      </div>
    </td>
    ```
  - If not that important, omit code entirely.
- **Column Text Color Hierarchy (Secondary for Name, Tertiary for Right Columns)**:
  - The first data column (the Name column) MUST be styled in the **Secondary Color** (`#404040` / `--alias-color-text-secondary`, font-weight `500` or `600`).
  - This establishes clear typographic scan hierarchy where the primary entity identity stands out, and all auxiliary column details recede harmoniously into clean tertiary tones.

---

## 7. Table Data Representation: Status, State, and Dual-Lookup Standard (Badges vs. Plain Text)
- **Status and State are Always Represented with Badges**:
  - In all sections and tables across the system, **Status** (`status_lookup_value_id`, approval status, lifecycle status) and **State** (`active` / `inactive`) MUST ALWAYS be represented with badges (`BaseBadge` / status pills).
- **Dual Representation for Schema Lookup Values**:
  - Schema lookup values (e.g. `mode_lookup_value_id`, `class_lookup_value_id`, `receipt_mode_lookup_value_id`, `unit_type_id`, `method_type_id`) have two valid representations:
    1. **Plain Tertiary Text** (`#737373` / `.tertiary-plain-text`): Clean typography for quiet, secondary, or high-density columns.
    2. **Badges** (`BaseBadge`): Visually anchored badges for high-impact operational distinctions.
- **Agent/Designer Decision Responsibility**:
  - It is for the agent/designer to carefully evaluate each table and decide whether a lookup value is best represented in text or in a badge:
    - **Avoid Badge Clutter**: We do not want too many badges across the table rows. An excess of badges across multiple columns creates visual noise, eye fatigue, and reduces table scanability.
    - **Prevent Hidden Information**: We do not want critical operational information to be obscured or overlooked by flattening everything into plain text. When a lookup represents a vital operational distinction or mode that users must quickly distinguish at a glance, a badge provides optimal hierarchy.
    - **Evaluation Rule**: Inspect the table as a whole. Consider total column count, existing badge density (since Status and State are already badged), and the business criticality of the lookup. If a lookup represents a key operational mode (e.g. `Centralized` vs `Decentralized` in Procurement Units), a badge is effective. If the table is wide or the lookup is secondary/taxonomic, use plain tertiary text.
- **No Inactive Gray for Active Lookups**:
  - `color="gray"` is **strictly reserved for Inactive / Dormant states** (`state === 'inactive'`).
  - **NEVER** use `gray` for active functional lookup values, policy modes, or options (such as `Permissive` in policy enforcement, secondary operational modes, etc.).
  - Using inactive gray for operational options makes active configurations appear dead, disabled, or dormant, and conflicts with the State column.
  - Active lookups that warrant a badge MUST use dedicated QMT Library semantic colors from Figma node `3345:21147`:
    - Policy Enforcement: `Mandatory` ➔ `indigo` (`#432DD7` / `#EEF2FF`), `Permissive` ➔ `blue` (`#0069A8` / `#F0F9FF`).
    - Governance Status: `acceptForAll` ➔ `success`, `acceptForThis` ➔ `primary`, `pending` ➔ `warning`, `reject` ➔ `error`.
    - Custom classifications: `purple` (`#8200DB` / `#FAF5FF`), `orange` (`#CA3500` / `#FFF7ED`).
- **Strict Anti-Badge Rule for Non-Lookup Raw Data**:
  - Raw numbers, scalar attributes, counts, and dates MUST NEVER be wrapped in badges:
    - ❌ **Forbidden**: Wrapping unit or item counts (`16 Units`, `8 Items`) in badge pills.
    - ❌ **Forbidden**: Wrapping simple boolean flags (`Yes`, `No`, `Visible`, `Hidden`) in badges.
    - ❌ **Forbidden**: Wrapping dates or timestamps in badge pills.
    - ✅ **Mandatory**: Render raw scalar data as clean, readable plain text.

---

## 8. Zero Extraneous Decorative Icons in Table Cells
- **No Decorative Icons**: Table data cells MUST NOT contain decorative or redundant icons:
  - ❌ **Forbidden**: Placing `<Building2 />` before an owning entity name.
  - ❌ **Forbidden**: Placing `<Layers />` before a unit count.
  - ❌ **Forbidden**: Placing `<FolderTree />` before a unit type.
  - ❌ **Forbidden**: Placing `<Calendar />` or `<ArrowRight />` inside effective timeline date cells.
- **Icons Permitted Only for Functional Actions**:
  - Icons are allowed in tables ONLY when strictly functional (e.g., sort indicators in headers, 3-dots action menu dropdown buttons, row selection checkboxes, or expandable row chevrons).

---

## 9. Cross-Entity Reference Standard (Zero Foreign Avatars in Middle Columns)
- **Middle Columns Must Never Contain Avatars**:
  - When a table row references an external or linked entity (e.g. `Current Manager` / `Unit Head`, `Owning Company`, `Supervisor`, `Approver`):
    - ❌ **Forbidden**: Rendering profile avatars, thumbnails, employee IDs (`EMP-00142`), or compound profile identity cards inside middle columns of a table.
    - Doing so severely degrades UX: it disrupts visual scanning across rows, creates jarring visual noise, and unnecessarily inflates row heights.
    - Avatars belong **exclusively** on the far-left primary identity column of that entity's *own* primary directory table (e.g., `EmployeesView.vue`).
    - ✅ **Mandatory**: Render ONLY the clean plain text name of the person or entity (e.g. `Dawit Tadesse`, `Raleh Girma`, `Solomon Mengistu`) in the tertiary color (`#737373`).
    - The user can click into the record's detail view to inspect full profile photos, IDs, titles, and appointment history.

---

## 10. Strict Separation of "State" vs "Status" & Absolute Prohibition of Active/Inactive on Status Columns
- **"Active" and "Inactive" Belong Exclusively to "State"**:
  - The words **`Active`** and **`Inactive`** are strictly and exclusively reserved for the **State** column (`state`), which represents the mechanical system record lifecycle (active vs soft-deleted/dormant).
- **Zero "Active" / "Inactive" on Status Columns**:
  - A **Status** column (`status_lookup_value_id`, `employment_status_lookup_value_id`, `approval_status`, etc.) MUST NEVER display "Active" or "Inactive" badges.
- **Translating Schema Status Lookups**:
  - When the underlying database schema defines an enum or lookup value named `active` for an entity's status column:
    - ❌ **Forbidden**: Rendering an `Active` badge in the Status column (causes confusing collision with the State column).
    - ✅ **Mandatory**: The UI must synthesize an appropriate business domain term:
      - **Employees (`EMPLOYMENT_STATUS`)**: `active` ➔ **`In Service`** (e.g. `In Service`, `Probation`, `Suspended`, `On Leave`, `Separated`).
      - **Governance Catalogues (`status_lookup_value_id`)**: `acceptForAll` ➔ **`Approved for All Entities`**, `acceptForThis` ➔ **`Approved for This Entity Only`**, `pending` ➔ **`Pending Approval`**.
      - **Versioned Blueprints (`structure_state_lookup_value_id`)**: `active` ➔ **`Current / In Effect`**, `draft` ➔ **`Draft`**, `superseded` ➔ **`Superseded`**.

---

## 11. Mandatory 3-Dot Actions Column Standard (MoreVertical / Zero Loose Inline Action Buttons)
- **Strict Prohibition of Loose Inline Buttons**:
  - The Actions column in tables MUST NEVER render loose, bare, or inline action buttons side-by-side in the table cell (e.g. `Eye`, `Edit2`, and `Trash2` sitting bare next to each other).
  - Inline action buttons create visual clutter, break row rhythm, cause unpredictable column widths, and violate QMT design system standards.
- **Mandatory 3-Dot Kebab Menu (`MoreVertical`)**:
  - The Actions cell MUST ALWAYS contain a single 3-dot kebab menu button (`.btn-action-dots` with `<MoreVertical :size="15" />`).
- **Standardized Action Popover Menu (`.action-menu-popup`)**:
  - Clicking the 3-dot trigger button toggles a floating menu containing contextual actions for that record:
    1. **Inspect / View Details**: `<Eye :size="14" />` with `Inspect [Noun]` or `View Details`.
    2. **Edit Record**: `<Edit2 :size="14" />` with `Edit [Noun]`.
    3. **Lifecycle State Toggle**: `<Check :size="14" />` with `Activate [Noun]` or `Deactivate [Noun]`.
    4. **Divider**: `<div class="menu-divider"></div>` separating non-destructive from destructive operations.
    5. **Delete Record**: `<Trash2 :size="14" />` with danger styling (`.menu-item.danger` with `#E7000B`).
- **Standard Implementation Pattern (Vue)**:
  ```html
  <td v-if="isColVisible('actions')" class="col-actions">
    <div class="action-dropdown-wrapper">
      <button
        type="button"
        class="btn-action-dots"
        title="More actions"
        @click="toggleActionMenu(row.id, $event)"
      >
        <MoreVertical :size="15" />
      </button>

      <div
        v-if="activeActionMenuId === row.id"
        class="action-menu-popup"
        @click.stop
      >
        <button type="button" class="menu-item" @click="() => { closeActionMenu(); openInspectDrawer(row); }">
          <Eye :size="14" />
          <span>Inspect Details</span>
        </button>
        <button type="button" class="menu-item" @click="() => { closeActionMenu(); openEditModal(row); }">
          <Edit2 :size="14" />
          <span>Edit Record</span>
        </button>
        <button type="button" class="menu-item" @click="() => { closeActionMenu(); handleToggleState(row); }">
          <Check :size="14" />
          <span>{{ row.state === 'active' ? 'Deactivate' : 'Activate' }}</span>
        </button>
        <div class="menu-divider"></div>
        <button type="button" class="menu-item danger" @click="() => { closeActionMenu(); handleDelete(row); }">
          <Trash2 :size="14" />
          <span>Delete</span>
        </button>
      </div>
    </div>
  </td>
  ```
- **Outside-Click & Cleanup**:
  - Register a document/window click handler to automatically close the action popover when the user clicks elsewhere.
  - Always clean up the event listener in `onUnmounted`.

---

## 12. Zero Scrollable Tables (Full-Bleed 100% Fit Standard)
- **Strict Prohibition of Horizontal Scrollbars**:
  - Tables across all standard ERP directory and listing views MUST fit 100% of the container width naturally without horizontal scrollbars (`overflow-x: auto;` or horizontal overflow wrappers).
  - Never set artificial horizontal scroll containers on standard directory tables.
- **Compact & High-Signal Column Architectures**:
  - Maintain 5 to 8 high-signal scanning columns by default. Non-essential, detailed, or secondary columns should be toggleable via the Column Hider (`visible: false` by default).
  - Never dump every database column into the default directory table view, which forces table containers to overflow and scroll.

---

## 13. Mandatory Action Column Header Label
- **Explicit Column Title**:
  - The Actions column header MUST ALWAYS display an explicit column title (`Action` or `Actions`), matching Figma specifications.
  - **NEVER** leave the Action column header empty (`label: ''` or empty `<th>`), which causes confusing blank gaps in the table header row.

---

## 14. Zero Focus Outline on Action Buttons (`MoreVertical` / `.btn-action-dots`)
- **No Browser Focus Halos**:
  - Clicking the 3-dot kebab action menu button must NEVER display a browser focus outline, halo ring, or black/blue focus border.
  - All `.btn-action-dots` styles MUST strictly specify:
    ```css
    .btn-action-dots,
    .btn-action-dots:focus,
    .btn-action-dots:focus-visible,
    .btn-action-dots:active {
      outline: none !important;
      box-shadow: none !important;
      -webkit-tap-highlight-color: transparent !important;
    }
    ```

