import zipfile
import os
import xml.sax.saxutils as saxutils

def escape(text):
    return saxutils.escape(text)

def make_cell(text, width=2000, is_header=False, bg_color=None, bold=False, align="left", color="000000"):
    align_xml = ""
    if align == "center":
        align_xml = '<w:jc w:val="center"/>'
    elif align == "right":
        align_xml = '<w:jc w:val="right"/>'

    shd_xml = ""
    if bg_color:
        shd_xml = f'<w:shd w:val="clear" w:color="auto" w:fill="{bg_color}"/>'

    bold_xml = "<w:b/>" if (bold or is_header) else ""
    font_sz = "18" if is_header else "18"  # 9pt
    text_color = "FFFFFF" if is_header else color

    lines = text.split("\n")
    p_xmls = []
    for line in lines:
        p_xmls.append(f"""
        <w:p>
          <w:pPr>
            <w:spacing w:before="60" w:after="60" w:line="240" w:lineRule="auto"/>
            {align_xml}
          </w:pPr>
          <w:r>
            <w:rPr>
              <w:rFonts w:ascii="Segoe UI" w:hAnsi="Segoe UI"/>
              {bold_xml}
              <w:color w:val="{text_color}"/>
              <w:sz w:val="{font_sz}"/>
            </w:rPr>
            <w:t>{escape(line)}</w:t>
          </w:r>
        </w:p>""")

    content = "".join(p_xmls)
    return f"""
      <w:tc>
        <w:tcPr>
          <w:tcW w:w="{width}" w:type="dxa"/>
          {shd_xml}
          <w:tcMar>
            <w:top w:w="120" w:type="dxa"/>
            <w:bottom w:w="120" w:type="dxa"/>
            <w:left w:w="160" w:type="dxa"/>
            <w:right w:w="160" w:type="dxa"/>
          </w:tcMar>
          <w:vAlign w:val="center"/>
        </w:tcPr>
        {content}
      </w:tc>"""

def make_row(cells, is_header=False):
    header_tag = "<w:trPr><w:tblHeader/></w:trPr>" if is_header else ""
    return f"""
    <w:tr>
      {header_tag}
      {"".join(cells)}
    </w:tr>"""

def make_table(headers, rows, col_widths, header_bg="0B529C", alt_row=True):
    header_cells = [
        make_cell(h, width=w, is_header=True, bg_color=header_bg, align="left")
        for h, w in zip(headers, col_widths)
    ]
    row_xmls = [make_row(header_cells, is_header=True)]

    for r_idx, row_data in enumerate(rows):
        bg = "F9FAFB" if (alt_row and r_idx % 2 == 1) else "FFFFFF"
        row_cells = []
        for c_idx, cell_value in enumerate(row_data):
            cell_bold = False
            cell_color = "000000"
            align = "left"
            if cell_value in ("G", "100%", "0"):
                if cell_value == "G":
                    cell_color = "008855"
                    cell_bold = True
                align = "center"
            elif cell_value in ("A", "At risk"):
                cell_color = "D97706"
                cell_bold = True
                align = "center"

            row_cells.append(make_cell(
                cell_value,
                width=col_widths[c_idx],
                is_header=False,
                bg_color=bg,
                bold=cell_bold,
                align=align,
                color=cell_color
            ))
        row_xmls.append(make_row(row_cells, is_header=False))

    total_w = sum(col_widths)
    return f"""
    <w:tbl>
      <w:tblPr>
        <w:tblW w:w="{total_w}" w:type="dxa"/>
        <w:jc w:val="center"/>
        <w:tblBorders>
          <w:top w:val="single" w:sz="6" w:space="0" w:color="D1D5DB"/>
          <w:left w:val="single" w:sz="6" w:space="0" w:color="D1D5DB"/>
          <w:bottom w:val="single" w:sz="6" w:space="0" w:color="D1D5DB"/>
          <w:right w:val="single" w:sz="6" w:space="0" w:color="D1D5DB"/>
          <w:insideH w:val="single" w:sz="4" w:space="0" w:color="E5E7EB"/>
          <w:insideV w:val="single" w:sz="4" w:space="0" w:color="E5E7EB"/>
        </w:tblBorders>
      </w:tblPr>
      {"".join(row_xmls)}
    </w:tbl>
    <w:p><w:pPr><w:spacing w:after="160"/></w:pPr></w:p>"""

def make_heading(title, level=1):
    sz = "32" if level == 1 else ("26" if level == 2 else "22")
    before = "280" if level == 1 else ("200" if level == 2 else "140")
    color = "0B529C" if level == 1 else ("1F2937" if level == 2 else "374151")
    return f"""
    <w:p>
      <w:pPr>
        <w:spacing w:before="{before}" w:after="80"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:rFonts w:ascii="Segoe UI Semibold" w:hAnsi="Segoe UI Semibold"/>
          <w:b/>
          <w:color w:val="{color}"/>
          <w:sz w:val="{sz}"/>
        </w:rPr>
        <w:t>{escape(title)}</w:t>
      </w:r>
    </w:p>"""

def make_note(text):
    return f"""
    <w:p>
      <w:pPr>
        <w:spacing w:before="60" w:after="120"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:rFonts w:ascii="Segoe UI" w:hAnsi="Segoe UI"/>
          <w:i/>
          <w:color w:val="6B7280"/>
          <w:sz w:val="17"/>
        </w:rPr>
        <w:t>{escape(text)}</w:t>
      </w:r>
    </w:p>"""

# BUILD CONTENT
body_parts = []

body_parts.append(make_heading("UI / UX Team — Weekly Report", level=1))
body_parts.append(make_note("Haleta ERP · Procurement Module · Sprint 10 (Part 1)"))

# 1. Portfolio summary
body_parts.append(make_heading("1. Portfolio summary", level=2))
t1_headers = ["Project / Module", "Sprint # / Week (dates)", "Team Lead", "Capacity (person-days or SP)", "Overall RAG (G / A / R)"]
t1_rows = [
    ["Haleta ERP / Procurement", "Sprint 10 (Part 1) / Week 47 (17–20 Nov 2026)", "Muluken Z.", "10 person-days", "G"]
]
t1_widths = [2400, 3100, 1600, 2000, 1500]
body_parts.append(make_table(t1_headers, t1_rows, t1_widths))

# A. Sprint goal
body_parts.append(make_heading("A. Sprint / weekly goal and commitment", level=2))
ta_headers = ["Sprint / weekly goal (one outcome + measure + date)", "Planned (SP / items)", "Done (meets DoD)", "Carried over", "Added mid-sprint", "Completion % (Done / Planned)"]
ta_rows = [
    ["Deliver and get sign-off on the full Section #1: Foundation, Policy and Configuration [PRMS01-01] UI package (40+ screens in Figma, usability-checked, QMT compliant) by 20 Nov", "42 screens", "42 screens", "0", "0", "100%"]
]
ta_widths = [3600, 1400, 1400, 1200, 1400, 1600]
body_parts.append(make_table(ta_headers, ta_rows, ta_widths))

# B. Deliverables
body_parts.append(make_heading("B. Deliverables per designer", level=2))
body_parts.append(make_note("Only items that meet the Definition of Done count as Delivered"))
tb_headers = ["Designer name", "Committed this week (Task IDs + outcome)", "Delivered (meets DoD / accepted)", "Done %", "Status (G / A / R)", "Blocked by"]
tb_rows = [
    [
        "Kaleb T.",
        "DSN-PRMS-01: Section #1 Foundation, Policy & Configuration UI Package\n• Categories (ProcurementCategory)\n• Methods & Thresholds (PurchaseMethod)\n• Units & Members (ProcurementUnit)\n• Committee Mandates (ProcurementCommitteeMandate)\n• Approval Routing (ProcurementApprovalRoute)\n• Assignment Rules (ProcurementAssignmentRule)\n• Receipt & Matching Tolerances\n• Approval Delegations (ApprovalDelegation)",
        "Completed 42 screens in Figma.\nMaster directories, tabular master-child forms, inspection dossiers, quick create modals, bulk bars, column hiders, and lifecycle states meet DoD and adhere strictly to QMT tokens and procurement-v4.sql. Ready for engineering handover.",
        "100%",
        "G",
        "None"
    ],
    [
        "Muluken Z. (Lead)",
        "Sprint 10 coordination, architecture alignment & developer review",
        "Reviewed Section #1 component inventory and design token compliance.",
        "100%",
        "G",
        "-"
    ],
    [
        "Yohannes B.",
        "Field catalog & cross-module integration check",
        "Confirmed spend class lookups and inventory category mapping.",
        "100%",
        "G",
        "-"
    ]
]
tb_widths = [1500, 2900, 3600, 900, 900, 800]
body_parts.append(make_table(tb_headers, tb_rows, tb_widths))

# C. Numbers
body_parts.append(make_heading("C. Numbers (2 only)", level=2))
body_parts.append(make_note("Count first, then divide"))
tc_headers = ["Metric", "How to measure", "Target", "Actual", "Status (G / A / R)"]
tc_rows = [
    ["Open critical design issues", "Count of critical usability / design issues still open at week end", "0", "0", "G"],
    ["Finished on time", "Designs delivered by due date / designs planned", ">= 80%", "100%", "G"]
]
tc_widths = [2600, 4200, 1200, 1200, 1400]
body_parts.append(make_table(tc_headers, tc_rows, tc_widths))

# D. Blockers
body_parts.append(make_heading("D. Blockers, risks and decisions needed", level=2))
td_headers = ["Type (Blocker / Risk / Decision)", "Description", "Impact (H / M / L)", "Action or help needed", "Owner", "Due date"]
td_rows = [
    ["None", "No active blockers or dependencies. All 11 domain entity schemas and business rules verified against authoritative procurement-v4.sql.", "L", "Proceed directly to frontend engineering handover", "Kaleb T.", "Closed"]
]
td_widths = [1800, 3800, 1200, 2200, 1100, 900]
body_parts.append(make_table(td_headers, td_rows, td_widths))

# E. Next week
body_parts.append(make_heading("E. Next week's commitments", level=2))
body_parts.append(make_note("Each one is a deliverable, not an activity"))
te_headers = ["#", "Next-week outcome (one deliverable, not an activity)", "Done when (measurable, testable check)", "Owner", "Due date"]
te_rows = [
    ["1", "Section #2: Procurement Planning & Requisition [PRMS01-02] UI Design", "Annual Plan cockpit, Requisition form, item catalog lookups, and PR approval ladder screens completed in Figma", "Kaleb T.", "27 Nov"],
    ["2", "Section #1 Frontend Developer Walkthrough & Token Handover", "Walkthrough session with frontend engineers; Vue components and Figma token mappings signed off", "Kaleb T. / Muluken Z.", "24 Nov"]
]
te_widths = [500, 3600, 4200, 1400, 900]
body_parts.append(make_table(te_headers, te_rows, te_widths))

# F. Team lead
body_parts.append(make_heading("F. Team lead's conclusion", level=2))
tf_headers = ["Lead's conclusion (circle one)", "Note"]
tf_rows = [
    ["[ On track ]  |  At risk  |  Escalate now", "Section #1 (Foundation, Policy and Configuration) was delivered ahead of schedule with 40+ comprehensive screens covering all 11 tables. Designs strictly follow the QMT component-first system and database schema with zero open design blockers. Ready for development sprint planning."]
]
tf_widths = [3600, 7000]
body_parts.append(make_table(tf_headers, tf_rows, tf_widths))

# Footnote
body_parts.append(make_note("Green = on track · Amber = at risk, needs attention · Red = late or blocked: escalate the same day, do not wait for this sheet"))

# XML DOCUMENT ASSEMBLY
document_xml = f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body>
    {"".join(body_parts)}
    <w:sectPr>
      <w:pgSz w:w="12240" w:h="15840" w:orient="portrait"/>
      <w:pgMar w:top="1080" w:right="1080" w:bottom="1080" w:left="1080" w:header="720" w:footer="720"/>
    </w:sectPr>
  </w:body>
</w:document>"""

content_types_xml = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>"""

rels_xml = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>"""

output_path = r"c:\Users\kaleb\Documents\ERP\docs\reports\UI-UX-Weekly-Report-Sprint10-Week47.docx"
os.makedirs(os.path.dirname(output_path), exist_ok=True)

with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as docx:
    docx.writestr('[Content_Types].xml', content_types_xml)
    docx.writestr('_rels/.rels', rels_xml)
    docx.writestr('word/document.xml', document_xml)

print(f"Successfully generated DOCX: {output_path} ({os.path.getsize(output_path)} bytes)")

