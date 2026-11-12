/**
 * QMT Design System Theme & Color Tokens
 * Authoritative palette extracted from Figma QMT Team Library (File EVkNwnkJXcHROkdv2QqXoU):
 * - Canvas 3328:2 (Colors)
 * - Canvas 3328:3 (Icons)
 */

export const QmtColors = {
  // Brand Blue
  brandBlue: {
    50: '#F1F7FE',
    100: '#E1EEFD',
    200: '#BDDBFA',
    300: '#83BFF6',
    400: '#419EEF',
    500: '#1982DE',
    600: '#0C65BD',
    700: '#0B529C', // Primary Brand Blue
    800: '#0D457F',
    900: '#113B69',
    950: '#0B2546',
    primary: '#0B529C',
    hover: '#0D457F',
    subtle: '#E1EEFD',
    surface: '#F1F7FE',
  },
  // Neutrals
  neutral: {
    50: '#FAFAFA',
    100: '#F5F5F5',
    200: '#E5E5E5',
    300: '#D4D4D4',
    400: '#A1A1A1',
    500: '#737373',
    600: '#525252',
    700: '#404040',
    800: '#262626',
    900: '#171717',
    950: '#0A0A0A',
    white: '#FFFFFF',
    black: '#000000',
  },
  // Emerald / Success
  success: {
    50: '#ECFDF5',
    100: '#D0FAE5',
    200: '#A4F4CF',
    300: '#5EE9B5',
    400: '#00D492',
    500: '#00BC7D',
    600: '#009966', // Icon & strong bg
    700: '#007A55', // Text & hover
    800: '#006045',
    900: '#004F3B',
    950: '#002C22',
  },
  // Red / Danger / Error
  error: {
    50: '#FEF2F2',
    100: '#FFE2E2',
    200: '#FFC9C9',
    300: '#FFA2A2',
    400: '#FF6467',
    500: '#FB2C36',
    600: '#E7000B', // Icon & strong bg
    700: '#C10007', // Text & hover
    800: '#9F0712',
    900: '#82181A',
    950: '#460809',
  },
  // Amber / Warning
  warning: {
    50: '#FFFBEB',
    100: '#FEF3C6',
    200: '#FEE685',
    300: '#FFD230',
    400: '#FFB900',
    500: '#FE9A00',
    600: '#E17100', // Icon & strong bg
    700: '#BB4D00', // Text & hover
    800: '#973C00',
    900: '#7B3306',
    950: '#461901',
  },
  // Sky / Info
  info: {
    50: '#F0F9FF',
    100: '#DFF2FE',
    200: '#B8E6FE',
    300: '#74D4FF',
    400: '#00BCFF',
    500: '#00A6F4',
    600: '#0084D1', // Icon & strong bg
    700: '#0069A8', // Text & hover
    800: '#00598A',
    900: '#024A70',
    950: '#052F4A',
  },
  // Semantic Icon Colors (Figma 3328:3)
  icon: {
    brand: '#0B529C',
    primary: '#262626',
    secondary: '#404040',
    tertiary: '#737373',
    disabled: '#A1A1A1',
    success: '#009966',
    warning: '#E17100',
    error: '#E7000B',
    info: '#0084D1',
    inverse: '#F5F5F5',
    onBrand: '#FFFFFF',
    onSurface: '#262626',
  },
  // Semantic Text Colors
  text: {
    primary: '#262626',
    secondary: '#404040',
    tertiary: '#737373',
    disabled: '#A1A1A1',
    brand: '#0B529C',
    brandSecondary: '#83BFF6',
    success: '#007A55',
    error: '#C10007',
    warning: '#BB4D00',
    info: '#0069A8',
    inverse: '#F5F5F5',
    onBrand: '#FFFFFF',
  },
  // Surfaces & Backgrounds
  surface: {
    primary: '#FAFAFA',
    subtle: '#F5F5F5',
    elevated: '#FFFFFF',
    inverse: '#171717',
    hover: '#F5F5F5',
    active: '#E5E5E5',
    disabled: '#FAFAFA',
  },
  // Borders
  border: {
    primary: '#D4D4D4',
    subtle: '#E5E5E5',
    inverse: '#404040',
    brand: '#83BFF6',
    success: '#5EE9B5',
    error: '#FFA2A2',
    warning: '#FFD230',
    info: '#74D4FF',
  }
} as const;

export type QmtIconColor = keyof typeof QmtColors.icon;

/**
 * QMT Design System Spacing Tokens (Figma EVkNwnkJXcHROkdv2QqXoU)
 */
export const QmtSpacing = {
  none: '0px',
  xxs: '2px',   // 0.5
  xs: '4px',    // 1
  sm: '6px',    // 1.5
  md: '8px',    // 2
  lg: '12px',   // 3
  xl: '16px',   // 4
  '2xl': '20px', // 5 (Top padding above breadcrumb, major section gap)
  '3xl': '24px', // 6 (Main body container left/right padding)
  '4xl': '32px', // 8
  '5xl': '40px', // 10
  '6xl': '48px', // 12
  '7xl': '64px', // 16
  '8xl': '80px', // 20
  '9xl': '96px', // 24
} as const;

export type QmtSpacingKey = keyof typeof QmtSpacing;

/**
 * QMT Design System Radius Tokens (Figma EVkNwnkJXcHROkdv2QqXoU)
 */
export const QmtRadius = {
  none: '0px',
  xs: '2px',
  sm: '4px',
  md: '6px',
  lg: '8px',
  xl: '12px',
  '2xl': '16px',
  '3xl': '20px',
  '4xl': '24px',
  full: '9999px',
} as const;

export type QmtRadiusKey = keyof typeof QmtRadius;
