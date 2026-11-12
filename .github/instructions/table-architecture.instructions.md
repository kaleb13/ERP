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
  - The detail view provides breadcrumb and back-button navigation (`← Back to [Entities]`) to return to the table.
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

## 7. Strict Anti-Badge Standard (Plain Text Default)
- **Plain Text Default**: Table data cells MUST default to clean, readable plain text in the tertiary color (`#737373`).
- **NEVER wrap ordinary content in badges**:
  - ❌ **Forbidden**: Wrapping unit counts (`16 Units`, `8 Units`) in a badge or colored container.
  - ❌ **Forbidden**: Wrapping entity types (`Department`, `Section`, `Region`) in badge pills.
  - ❌ **Forbidden**: Wrapping boolean visibility or flags (`Visible`, `Hidden`) in badges.
  - ✅ **Mandatory**: Simply write the plain text (`16 Units`, `Department`, `Section`).
- **Badges/Pills are Strictly Reserved for Lifecycle States**:
  - Badges are permitted **only** for actual record lifecycle states (`Active`, `Inactive`, `Draft`, `Pending`), and even then, only when genuinely needed.
  - If information can simply be written as clear text, write it as plain text without badges.

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
