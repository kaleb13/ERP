---
name: figma-component-first
description: "Use for creating or editing Figma screens, frames, forms, sidebars, or components. Requires verified reuse of existing Figma components and a user decision before any substitute."
---

# Figma Component-First Workflow

Use this workflow for every Figma design edit in the Haleta ERP file.

## 1. Inspect before editing

1. Confirm the target Figma file, page, and frame. Do not edit a nearby reference frame.
2. Inspect the target screenshot and layer/component metadata.
3. Inspect approved nearby screens and search the file's subscribed libraries for matching components.
4. Record the source component and variant for each shared control: buttons, inputs, selects, checkboxes, badges, sidebar/navigation, and icons.

## 2. Use real component instances

- Insert an instance linked to the source component; visual similarity alone is not component reuse.
- Preserve the component link and use supported text/variant overrides. Do not detach, redraw, or replace a missing asset with ordinary shapes or text.
- Keep task-specific labels and values while using the closest semantically correct component variant.
- If a component's dimensions do not fit, do not silently distort it or alter the page. Ask whether to reflow/expand the frame, use a supplied component, or approve a reusable component.

## 3. Stop when a component is unavailable

If no suitable component is found, or the library component cannot be imported:

1. Stop before building that control.
2. Tell the user what component names/variants and libraries were searched, and what prevented reuse.
3. Ask the user to provide a component link, approve a reusable auto-layout component, or choose an existing alternative.
4. Continue only after the user chooses. Do not treat an unsuccessful search or import as permission to approximate.

## 4. Verify the result

Before reporting completion:

- Check each shared control's node type and source component/variant metadata; verify it is an instance linked to the intended component.
- Capture and inspect the complete target frame at its final size. Check clipping, wrapping, alignment, spacing, and visible states.
- Confirm the reference frame is unchanged and no unapproved substitute remains.
- Report the target frame link, component sources/variants used, any unresolved control, and any layout decision made by the user.

## Figma MCP notes

- Load the official Figma-use and Figma-generate-design guidance before mutating a file, and include both skill names on mutating Figma calls.
- Design-system search results are candidates, not proof of reuse. Verify that the component can be imported and that the final node links to its source.
- `$fig` handles are plan nodes until `await $fig.done()` materializes them. Do not read `.node` or pass a plan node to raw Plugin API methods before materialization.
