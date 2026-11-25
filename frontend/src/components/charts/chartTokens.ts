/**
 * QMT Team Library Chart Design Tokens & Shared Utilities
 * Source: EVkNwnkJXcHROkdv2QqXoU (Bar chart 5676:722, Line chart 5678:650, Pie chart 5681:481)
 * Adheres strictly to Haleta ERP darkest text rule (#404040 color/text/secondary).
 */

export type ChartPalette = 'brand' | 'categorical';

export const QMT_CHART_TOKENS = {
  surface: '#FFFFFF',
  border: '#E5E5E5',
  grid: '#E5E5E5',
  axis: '#D4D4D4',
  crosshair: '#D4D4D4',
  tickFg: '#737373',
  labelFg: '#404040',
  titleFg: '#404040',
  subtitleFg: '#737373',
  tooltipBg: '#FFFFFF',
  tooltipBorder: '#E5E5E5',
  other: '#737373',
  brand: '#0B529C',
  brandShades: [
    '#0B529C',                // 100%
    'rgba(11, 82, 156, 0.8)', // 80%
    'rgba(11, 82, 156, 0.6)', // 60%
    'rgba(11, 82, 156, 0.45)' // 45%
  ],
  categorical: [
    '#0084D1', // chart/categorical-1 (sky/600)
    '#F54900', // chart/categorical-2 (orange/600)
    '#615FFF', // chart/categorical-3 (indigo/500)
    '#F6339A'  // chart/categorical-4 (pink/500)
  ]
} as const;

export function getChartSeriesColor(
  palette: ChartPalette,
  index: number,
  options?: { isOther?: boolean; customColor?: string }
): string {
  if (options?.customColor) return options.customColor;
  if (options?.isOther) return QMT_CHART_TOKENS.other;
  if (palette === 'categorical') {
    return QMT_CHART_TOKENS.categorical[index % QMT_CHART_TOKENS.categorical.length];
  }
  return QMT_CHART_TOKENS.brandShades[index % QMT_CHART_TOKENS.brandShades.length];
}

/**
 * Computes clean human-friendly axis ticks starting from minVal (default 0) up to a nice ceiling.
 */
export function computeNiceTicks(
  rawMax: number,
  options?: { min?: number; max?: number; tickCount?: number }
): { min: number; max: number; ticks: number[] } {
  const min = options?.min ?? 0;
  const tickCount = Math.max(2, options?.tickCount ?? 4);

  if (options?.max !== undefined && options.max > min) {
    const step = (options.max - min) / (tickCount - 1);
    const ticks = Array.from({ length: tickCount }, (_, i) =>
      Number((min + step * i).toFixed(2))
    );
    return { min, max: options.max, ticks };
  }

  const safeMax = Math.max(rawMax, min + 1);
  const range = safeMax - min;
  const roughStep = range / (tickCount - 1);
  const magnitude = Math.pow(10, Math.floor(Math.log10(roughStep)));
  const normalized = roughStep / magnitude;

  let niceNormalized = 1;
  if (normalized <= 1) niceNormalized = 1;
  else if (normalized <= 2) niceNormalized = 2;
  else if (normalized <= 2.5) niceNormalized = 2.5;
  else if (normalized <= 5) niceNormalized = 5;
  else niceNormalized = 10;

  const step = niceNormalized * magnitude;
  const niceMax = Math.ceil(safeMax / step) * step;
  const ticks: number[] = [];
  for (let v = min; v <= niceMax + step * 0.001; v += step) {
    ticks.push(Number(v.toFixed(2)));
  }
  return { min, max: niceMax, ticks };
}

export function defaultValueFormat(value: number): string {
  if (Number.isInteger(value)) return value.toLocaleString('en-US');
  return value.toLocaleString('en-US', { maximumFractionDigits: 1 });
}
