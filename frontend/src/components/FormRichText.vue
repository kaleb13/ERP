<script setup lang="ts">
import { ref, watch, onMounted, computed } from 'vue';
import {
  ChevronDown, AlignLeft, AlignCenter, AlignRight,
  AlignJustify, Bold, Italic, Underline,
  Strikethrough, Code, Table as TableIcon, Link2,
  Image as ImageIcon, Undo2, Redo2
} from 'lucide-vue-next';;

interface Props {
  modelValue?: string;
  label?: string;
  placeholder?: string;
  maxLength?: number;
  showCharCount?: boolean;
  minHeight?: string;
  disabled?: boolean;
  required?: boolean;
  error?: string;
  helpText?: string;
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: '',
  label: '',
  placeholder: 'Type content here...',
  maxLength: 5000,
  showCharCount: true,
  minHeight: '220px',
  disabled: false,
  required: false,
  error: '',
  helpText: ''
});

const emit = defineEmits<{
  (e: 'update:modelValue', value: string): void;
  (e: 'change', value: string): void;
  (e: 'focus'): void;
  (e: 'blur'): void;
}>();

const editorRef = ref<HTMLDivElement | null>(null);
const isFocused = ref(false);

// Dropdown states
const showHeadingDropdown = ref(false);
const showFontDropdown = ref(false);
const showAlignDropdown = ref(false);
const showColorDropdown = ref(false);

const currentHeading = ref('Paragraph');
const currentFont = ref('Font Type');
const currentAlign = ref<'left' | 'center' | 'right' | 'justify'>('left');
const activeColor = ref('#0B529C');

// Active formatting flags
const isBold = ref(false);
const isItalic = ref(false);
const isUnderline = ref(false);
const isStrike = ref(false);
const isCode = ref(false);

const charCount = ref(0);

const colorPalette = [
  { label: 'Primary Brand Blue', value: '#0B529C' },
  { label: 'Dark Text', value: '#262626' },
  { label: 'Secondary Slate', value: '#404040' },
  { label: 'Muted Tertiary', value: '#737373' },
  { label: 'Success Emerald', value: '#009966' },
  { label: 'Warning Amber', value: '#E17100' },
  { label: 'Error Red', value: '#E7000B' },
  { label: 'Purple Accent', value: '#7C3AED' }
];

const closeAllDropdowns = () => {
  showHeadingDropdown.value = false;
  showFontDropdown.value = false;
  showAlignDropdown.value = false;
  showColorDropdown.value = false;
};

// Execute standard formatting commands
const exec = (command: string, value: string | undefined = undefined) => {
  if (props.disabled) return;
  document.execCommand(command, false, value);
  updateActiveFormats();
  handleInput();
};

const updateActiveFormats = () => {
  isBold.value = document.queryCommandState('bold');
  isItalic.value = document.queryCommandState('italic');
  isUnderline.value = document.queryCommandState('underline');
  isStrike.value = document.queryCommandState('strikeThrough');
};

const handleHeadingSelect = (tag: string, label: string) => {
  currentHeading.value = label;
  exec('formatBlock', tag);
  showHeadingDropdown.value = false;
};

const handleFontSelect = (fontFamily: string, label: string) => {
  currentFont.value = label;
  exec('fontName', fontFamily);
  showFontDropdown.value = false;
};

const handleAlignSelect = (align: 'left' | 'center' | 'right' | 'justify') => {
  currentAlign.value = align;
  if (align === 'left') exec('justifyLeft');
  if (align === 'center') exec('justifyCenter');
  if (align === 'right') exec('justifyRight');
  if (align === 'justify') exec('justifyFull');
  showAlignDropdown.value = false;
};

const handleColorSelect = (color: string) => {
  activeColor.value = color;
  exec('foreColor', color);
  showColorDropdown.value = false;
};

const insertTable = () => {
  const tableHtml = `
    <table style="width: 100%; border-collapse: collapse; margin: 12px 0; border: 1px solid #e5e5e5;">
      <thead>
        <tr style="background-color: #f5f5f5;">
          <th style="border: 1px solid #e5e5e5; padding: 8px 12px; font-weight: 600; text-align: left;">Header 1</th>
          <th style="border: 1px solid #e5e5e5; padding: 8px 12px; font-weight: 600; text-align: left;">Header 2</th>
          <th style="border: 1px solid #e5e5e5; padding: 8px 12px; font-weight: 600; text-align: left;">Header 3</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td style="border: 1px solid #e5e5e5; padding: 8px 12px;">Data Cell</td>
          <td style="border: 1px solid #e5e5e5; padding: 8px 12px;">Data Cell</td>
          <td style="border: 1px solid #e5e5e5; padding: 8px 12px;">Data Cell</td>
        </tr>
      </tbody>
    </table><p></p>
  `;
  exec('insertHTML', tableHtml);
};

const insertLink = () => {
  const url = prompt('Enter link URL (e.g. https://haleta.com):', 'https://');
  if (url && url.trim() !== '') {
    exec('createLink', url.trim());
  }
};

const insertImage = () => {
  const url = prompt('Enter image URL:', 'https://');
  if (url && url.trim() !== '') {
    exec('insertImage', url.trim());
  }
};

const handleInput = () => {
  if (!editorRef.value) return;
  const html = editorRef.value.innerHTML;
  const text = editorRef.value.innerText || '';
  charCount.value = text.trim().length;

  emit('update:modelValue', html);
  emit('change', html);
};

const handleFocus = () => {
  isFocused.value = true;
  emit('focus');
};

const handleBlur = () => {
  isFocused.value = false;
  emit('blur');
};

// Sync incoming modelValue
watch(
  () => props.modelValue,
  (newVal) => {
    if (editorRef.value && editorRef.value.innerHTML !== newVal) {
      editorRef.value.innerHTML = newVal || '';
      const text = editorRef.value.innerText || '';
      charCount.value = text.trim().length;
    }
  }
);

onMounted(() => {
  if (editorRef.value && props.modelValue) {
    editorRef.value.innerHTML = props.modelValue;
    const text = editorRef.value.innerText || '';
    charCount.value = text.trim().length;
  }
  window.addEventListener('click', closeAllDropdowns);
});
</script>

<template>
  <div class="qmt-rich-text-wrapper" :class="{ 'is-disabled': disabled, 'has-error': !!error }">
    <!-- Component Label -->
    <label v-if="label" class="qmt-rich-text-label">
      {{ label }}
      <span v-if="required" class="required-star">*</span>
    </label>

    <!-- Main Rich Text Editor Container (Figma Node 8779:68714) -->
    <div 
      class="qmt-rich-text-container" 
      :class="{ 'is-focused': isFocused }"
      @click.stop
    >
      <!-- Top Action Toolbar -->
      <div class="qmt-rich-text-toolbar" @click.stop>
        <div class="toolbar-left">
          <!-- Text Style / Paragraph Dropdown -->
          <div class="dropdown-wrapper">
            <button 
              type="button" 
              class="toolbar-dropdown-btn" 
              :disabled="disabled"
              @click.stop="showHeadingDropdown = !showHeadingDropdown; showFontDropdown = false; showAlignDropdown = false; showColorDropdown = false;"
            >
              <span>{{ currentHeading }}</span>
              <ChevronDown :size="13" class="dropdown-chevron" />
            </button>

            <div v-if="showHeadingDropdown" class="dropdown-menu">
              <button type="button" class="dropdown-item" @click="handleHeadingSelect('p', 'Paragraph')">
                <span class="text-sm font-normal">Paragraph</span>
              </button>
              <button type="button" class="dropdown-item" @click="handleHeadingSelect('h1', 'Heading 1')">
                <span class="text-base font-bold">Heading 1</span>
              </button>
              <button type="button" class="dropdown-item" @click="handleHeadingSelect('h2', 'Heading 2')">
                <span class="text-sm font-semibold">Heading 2</span>
              </button>
              <button type="button" class="dropdown-item" @click="handleHeadingSelect('h3', 'Heading 3')">
                <span class="text-xs font-semibold">Heading 3</span>
              </button>
              <button type="button" class="dropdown-item" @click="handleHeadingSelect('blockquote', 'Quote')">
                <span class="text-xs italic text-gray-500">Quote Block</span>
              </button>
            </div>
          </div>

          <!-- Font Type Dropdown -->
          <div class="dropdown-wrapper">
            <button 
              type="button" 
              class="toolbar-dropdown-btn" 
              :disabled="disabled"
              @click.stop="showFontDropdown = !showFontDropdown; showHeadingDropdown = false; showAlignDropdown = false; showColorDropdown = false;"
            >
              <span>{{ currentFont }}</span>
              <ChevronDown :size="13" class="dropdown-chevron" />
            </button>

            <div v-if="showFontDropdown" class="dropdown-menu">
              <button type="button" class="dropdown-item font-sans" @click="handleFontSelect('Inter, sans-serif', 'Sans-Serif')">
                Inter (Default)
              </button>
              <button type="button" class="dropdown-item font-serif" @click="handleFontSelect('Georgia, serif', 'Serif')">
                Georgia (Serif)
              </button>
              <button type="button" class="dropdown-item font-mono" @click="handleFontSelect('monospace', 'Monospace')">
                Monospace
              </button>
            </div>
          </div>

          <!-- Separator -->
          <div class="toolbar-divider"></div>

          <!-- Alignment Dropdown -->
          <div class="dropdown-wrapper">
            <button 
              type="button" 
              class="toolbar-dropdown-btn icon-only" 
              :disabled="disabled"
              title="Text Alignment"
              @click.stop="showAlignDropdown = !showAlignDropdown; showHeadingDropdown = false; showFontDropdown = false; showColorDropdown = false;"
            >
              <AlignLeft v-if="currentAlign === 'left'" :size="15" />
              <AlignCenter v-else-if="currentAlign === 'center'" :size="15" />
              <AlignRight v-else-if="currentAlign === 'right'" :size="15" />
              <AlignJustify v-else :size="15" />
              <ChevronDown :size="12" class="dropdown-chevron" />
            </button>

            <div v-if="showAlignDropdown" class="dropdown-menu narrow">
              <button type="button" class="dropdown-item" @click="handleAlignSelect('left')">
                <AlignLeft :size="14" /> <span>Align Left</span>
              </button>
              <button type="button" class="dropdown-item" @click="handleAlignSelect('center')">
                <AlignCenter :size="14" /> <span>Align Center</span>
              </button>
              <button type="button" class="dropdown-item" @click="handleAlignSelect('right')">
                <AlignRight :size="14" /> <span>Align Right</span>
              </button>
              <button type="button" class="dropdown-item" @click="handleAlignSelect('justify')">
                <AlignJustify :size="14" /> <span>Justify</span>
              </button>
            </div>
          </div>

          <!-- Formatting Buttons (B, I, U, S, Code, Table) -->
          <div class="format-group">
            <button 
              type="button" 
              class="toolbar-icon-btn" 
              :class="{ 'is-active': isBold }"
              title="Bold (Ctrl+B)"
              :disabled="disabled"
              @click="exec('bold')"
            >
              <span class="font-bold text-[13px]">B</span>
            </button>

            <button 
              type="button" 
              class="toolbar-icon-btn" 
              :class="{ 'is-active': isItalic }"
              title="Italic (Ctrl+I)"
              :disabled="disabled"
              @click="exec('italic')"
            >
              <span class="italic text-[13px] font-serif">I</span>
            </button>

            <button 
              type="button" 
              class="toolbar-icon-btn" 
              :class="{ 'is-active': isUnderline }"
              title="Underline (Ctrl+U)"
              :disabled="disabled"
              @click="exec('underline')"
            >
              <span class="underline text-[13px]">U</span>
            </button>

            <button 
              type="button" 
              class="toolbar-icon-btn" 
              :class="{ 'is-active': isStrike }"
              title="Strikethrough"
              :disabled="disabled"
              @click="exec('strikeThrough')"
            >
              <span class="line-through text-[13px]">S</span>
            </button>

            <button 
              type="button" 
              class="toolbar-icon-btn" 
              title="Inline Code / Preformatted"
              :disabled="disabled"
              @click="exec('formatBlock', 'pre')"
            >
              <Code :size="15" />
            </button>

            <button 
              type="button" 
              class="toolbar-icon-btn" 
              title="Insert Table"
              :disabled="disabled"
              @click="insertTable"
            >
              <TableIcon :size="15" />
            </button>
          </div>

          <!-- Separator -->
          <div class="toolbar-divider"></div>

          <!-- Text Color Picker -->
          <div class="dropdown-wrapper">
            <button 
              type="button" 
              class="toolbar-dropdown-btn color-btn" 
              :disabled="disabled"
              title="Text Color"
              @click.stop="showColorDropdown = !showColorDropdown; showHeadingDropdown = false; showFontDropdown = false; showAlignDropdown = false;"
            >
              <div class="color-indicator-icon">
                <span class="font-bold text-[13px]">A</span>
                <span class="color-underline-bar" :style="{ backgroundColor: activeColor }"></span>
              </div>
              <ChevronDown :size="12" class="dropdown-chevron" />
            </button>

            <div v-if="showColorDropdown" class="dropdown-menu color-grid-menu">
              <button 
                v-for="color in colorPalette" 
                :key="color.value"
                type="button" 
                class="color-swatch-item"
                :title="color.label"
                :style="{ backgroundColor: color.value }"
                @click="handleColorSelect(color.value)"
              ></button>
            </div>
          </div>

          <!-- Separator -->
          <div class="toolbar-divider"></div>

          <!-- Media Group (Link, Image) -->
          <div class="format-group">
            <button 
              type="button" 
              class="toolbar-icon-btn" 
              title="Insert Link"
              :disabled="disabled"
              @click="insertLink"
            >
              <Link2 :size="15" />
            </button>

            <button 
              type="button" 
              class="toolbar-icon-btn" 
              title="Insert Image"
              :disabled="disabled"
              @click="insertImage"
            >
              <ImageIcon :size="15" />
            </button>
          </div>
        </div>

        <!-- History Group (Undo, Redo) -->
        <div class="toolbar-right">
          <button 
            type="button" 
            class="toolbar-icon-btn" 
            title="Undo (Ctrl+Z)"
            :disabled="disabled"
            @click="exec('undo')"
          >
            <Undo2 :size="15" />
          </button>

          <button 
            type="button" 
            class="toolbar-icon-btn" 
            title="Redo (Ctrl+Y)"
            :disabled="disabled"
            @click="exec('redo')"
          >
            <Redo2 :size="15" />
          </button>
        </div>
      </div>

      <!-- Text Input Area (Uses primary background color per Figma node 5104:71401 / 8779:68714) -->
      <div class="qmt-rich-text-input-area">
        <!-- Editable Rich Text Canvas -->
        <div
          ref="editorRef"
          contenteditable="true"
          class="qmt-rich-text-content"
          :style="{ minHeight: minHeight }"
          :data-placeholder="placeholder"
          @input="handleInput"
          @focus="handleFocus"
          @blur="handleBlur"
          @keyup="updateActiveFormats"
          @mouseup="updateActiveFormats"
        ></div>

        <!-- Bottom Status Bar (Characters Count Pill + Resize Handle) -->
        <div class="qmt-rich-text-footer">
          <div v-if="showCharCount" class="qmt-char-count-pill">
            <span>{{ charCount.toLocaleString() }} / {{ maxLength.toLocaleString() }} Characters</span>
          </div>

          <!-- Resize Grip -->
          <div class="resize-grip" title="Resize">
            <svg width="12" height="12" viewBox="0 0 12 12" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M10 2L2 10M10 6L6 10M10 10H10.01" stroke="#A1A1A1" stroke-width="1.5" stroke-linecap="round" />
            </svg>
          </div>
        </div>
      </div>
    </div>

    <!-- Optional Help Text or Error Message -->
    <p v-if="error" class="qmt-field-error-text">{{ error }}</p>
    <p v-else-if="helpText" class="qmt-field-help-text">{{ helpText }}</p>
  </div>
</template>

<style scoped>
.qmt-rich-text-wrapper {
  display: flex;
  flex-direction: column;
  gap: 6px;
  width: 100%;
  font-family: var(--qmt-font-family-sans, 'Inter', sans-serif);
  box-sizing: border-box;
}

.qmt-rich-text-label {
  font-size: 13px;
  font-weight: 500;
  line-height: 18px;
  color: var(--alias-color-text-secondary, #404040);
  user-select: none;
}

.required-star {
  color: var(--primitive-color-red-600, #e7000b);
  margin-left: 2px;
}

/* Main Box (Figma Node 8779:68714: rounded 16px, subtle border #e5e5e5) */
.qmt-rich-text-container {
  background-color: var(--alias-color-generic-white, #ffffff);
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: var(--alias-radius-2xl, 16px);
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
  position: relative;
}

.qmt-rich-text-container.is-focused {
  border-color: var(--primitive-color-brand-blue-700, #0b529c);
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.1);
}

.qmt-rich-text-wrapper.has-error .qmt-rich-text-container {
  border-color: var(--primitive-color-red-600, #e7000b);
}

.qmt-rich-text-wrapper.is-disabled .qmt-rich-text-container {
  background-color: var(--alias-color-background-primary, #fafafa);
  cursor: not-allowed;
  opacity: 0.7;
}

/* Toolbar */
.qmt-rich-text-toolbar {
  background-color: var(--alias-color-generic-white, #ffffff);
  border-bottom: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  padding: 8px 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  user-select: none;
  flex-wrap: wrap;
}

.toolbar-left {
  display: flex;
  align-items: center;
  gap: 4px;
  flex-wrap: wrap;
}

.toolbar-right {
  display: flex;
  align-items: center;
  gap: 4px;
}

/* Dropdown trigger button */
.dropdown-wrapper {
  position: relative;
  display: inline-block;
}

.toolbar-dropdown-btn {
  height: 28px;
  padding: 0 8px;
  border-radius: var(--alias-radius-sm, 4px);
  background: transparent;
  border: none;
  font-size: 12.5px;
  font-weight: 500;
  color: var(--alias-color-text-secondary, #404040);
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  transition: background-color 0.15s ease, color 0.15s ease;
}

.toolbar-dropdown-btn:hover:not(:disabled) {
  background-color: var(--alias-color-background-secondary, #f5f5f5);
  color: var(--alias-color-text-primary, #262626);
}

.toolbar-dropdown-btn.icon-only {
  padding: 0 6px;
}

.dropdown-chevron {
  color: var(--alias-color-icon-tertiary, #737373);
}

/* Dropdown Floating Menus */
.dropdown-menu {
  position: absolute;
  top: calc(100% + 4px);
  left: 0;
  background-color: var(--alias-color-generic-white, #ffffff);
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: var(--alias-radius-lg, 8px);
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -4px rgba(0, 0, 0, 0.1);
  padding: 4px;
  z-index: 100;
  min-width: 140px;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.dropdown-menu.narrow {
  min-width: 130px;
}

.dropdown-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 10px;
  border-radius: var(--alias-radius-sm, 4px);
  background: transparent;
  border: none;
  font-size: 12.5px;
  color: var(--alias-color-text-secondary, #404040);
  cursor: pointer;
  width: 100%;
  text-align: left;
  transition: background-color 0.15s ease;
}

.dropdown-item:hover {
  background-color: var(--alias-color-background-secondary, #f5f5f5);
  color: #262626;
}

/* Separator Line */
.toolbar-divider {
  width: 1px;
  height: 18px;
  background-color: var(--alias-color-border-subtle, #e5e5e5);
  margin: 0 4px;
  flex-shrink: 0;
}

/* Format Buttons */
.format-group {
  display: flex;
  align-items: center;
  gap: 2px;
}

.toolbar-icon-btn {
  width: 28px;
  height: 28px;
  border-radius: var(--alias-radius-sm, 4px);
  background: transparent;
  border: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: var(--alias-color-icon-secondary, #404040);
  cursor: pointer;
  transition: background-color 0.15s ease, color 0.15s ease;
}

.toolbar-icon-btn:hover:not(:disabled) {
  background-color: var(--alias-color-background-secondary, #f5f5f5);
  color: var(--alias-color-text-primary, #262626);
}

.toolbar-icon-btn.is-active {
  background-color: var(--alias-color-brand-blue-primary-subtle, #e1eefd);
  color: var(--alias-color-brand-blue-primary, #0b529c);
}

.toolbar-icon-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

/* Color Indicator Icon */
.color-indicator-icon {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  line-height: 1;
}

.color-underline-bar {
  display: block;
  width: 12px;
  height: 2.5px;
  border-radius: 1px;
  margin-top: 1px;
}

.color-grid-menu {
  display: grid;
  grid-template-columns: repeat(4, 24px);
  gap: 6px;
  padding: 8px;
  min-width: auto;
}

.color-swatch-item {
  width: 24px;
  height: 24px;
  border-radius: 4px;
  border: 1px solid rgba(0, 0, 0, 0.1);
  cursor: pointer;
  transition: transform 0.1s ease;
}

.color-swatch-item:hover {
  transform: scale(1.15);
}

/* Content Editing Area */
.qmt-rich-text-input-area {
  background-color: var(--alias-color-background-primary, #fafafa);
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
  border-bottom-left-radius: var(--alias-radius-2xl, 16px);
  border-bottom-right-radius: var(--alias-radius-2xl, 16px);
}

.qmt-rich-text-content {
  padding: 16px 20px;
  outline: none;
  font-size: 14px;
  line-height: 24px;
  color: var(--alias-color-text-primary, #262626);
  background-color: var(--alias-color-background-primary, #fafafa);
  overflow-y: auto;
  flex: 1;
}

.qmt-rich-text-content:empty:before {
  content: attr(data-placeholder);
  color: var(--alias-color-text-disabled, #a1a1a1);
  pointer-events: none;
  display: block;
}

/* Footer / Bottom Status Bar */
.qmt-rich-text-footer {
  padding: 10px 16px 12px 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  background-color: var(--alias-color-background-primary, #fafafa);
  user-select: none;
  border-bottom-left-radius: var(--alias-radius-2xl, 16px);
  border-bottom-right-radius: var(--alias-radius-2xl, 16px);
}

.qmt-char-count-pill {
  background-color: var(--alias-color-generic-white, #ffffff);
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: var(--alias-radius-full, 9999px);
  padding: 4px 14px;
  font-size: 12px;
  line-height: 18px;
  color: var(--alias-color-text-secondary, #404040);
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.03);
}

.resize-grip {
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: se-resize;
  opacity: 0.6;
}

.resize-grip:hover {
  opacity: 1;
}

.qmt-field-error-text {
  font-size: 12px;
  color: var(--primitive-color-red-600, #e7000b);
  margin-top: 4px;
}

.qmt-field-help-text {
  font-size: 12px;
  color: var(--alias-color-text-tertiary, #737373);
  margin-top: 4px;
}
</style>
