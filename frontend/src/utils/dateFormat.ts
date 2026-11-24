const SHORT_MONTHS = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

/**
 * Formats an ISO date (YYYY-MM-DD) or timestamp (YYYY-MM-DD HH:mm) into
 * the Haleta ERP display standard: "MMM D, YYYY" (e.g. "Jul 1, 2026").
 * Parses date parts directly to avoid UTC timezone off-by-one shifts.
 */
export function formatDisplayDate(
  value: string | null | undefined,
  fallback = '—'
): string {
  if (!value) return fallback;
  const trimmed = String(value).trim();
  if (!trimmed) return fallback;

  const match = trimmed.match(/^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}:\d{2}))?/);
  if (!match) return trimmed;

  const year = Number(match[1]);
  const monthIdx = Number(match[2]) - 1;
  const day = Number(match[3]);
  const timePart = match[4];

  if (monthIdx < 0 || monthIdx > 11 || day < 1 || day > 31) return trimmed;

  const formatted = `${SHORT_MONTHS[monthIdx]} ${day}, ${year}`;
  return timePart ? `${formatted} · ${timePart}` : formatted;
}

/**
 * Formats a start/end date range into "MMM D, YYYY → MMM D, YYYY"
 * (or "MMM D, YYYY → Open" when end date is null/empty).
 */
export function formatDisplayDateRange(
  from: string | null | undefined,
  to: string | null | undefined,
  openLabel = 'Open'
): string {
  const start = formatDisplayDate(from);
  const end = to ? formatDisplayDate(to) : openLabel;
  return `${start} → ${end}`;
}
