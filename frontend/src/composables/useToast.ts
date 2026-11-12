import { readonly, ref } from 'vue';
import type { ToastStatus, ToastType } from '../components/BaseToast.vue';

export interface ToastItem {
  id: number;
  title: string;
  description?: string;
  status: ToastStatus;
  type: ToastType;
  duration: number;
  showClose?: boolean;
  actionLabel?: string;
  cancelLabel?: string;
  onAction?: () => void;
  onCancel?: () => void;
}

export type ToastOptions = Partial<Omit<ToastItem, 'id'>> & {
  title: string;
};

const toasts = ref<ToastItem[]>([]);
let nextToastId = 1;
const timers = new Map<number, ReturnType<typeof setTimeout>>();

function dismiss(id: number) {
  const timer = timers.get(id);
  if (timer) {
    clearTimeout(timer);
    timers.delete(id);
  }
  toasts.value = toasts.value.filter((t) => t.id !== id);
}

function show(options: ToastOptions): number {
  const id = nextToastId++;
  const duration = options.duration ?? 4500;
  const item: ToastItem = {
    id,
    title: options.title,
    description: options.description,
    status: options.status ?? 'default',
    type: options.type ?? 'flat',
    duration,
    showClose: options.showClose ?? true,
    actionLabel: options.actionLabel,
    cancelLabel: options.cancelLabel,
    onAction: options.onAction,
    onCancel: options.onCancel
  };

  toasts.value = [...toasts.value, item];

  if (duration > 0) {
    const timer = setTimeout(() => dismiss(id), duration);
    timers.set(id, timer);
  }

  return id;
}

export const toast = {
  show,
  dismiss,
  clear() {
    for (const timer of timers.values()) clearTimeout(timer);
    timers.clear();
    toasts.value = [];
  },
  success(title: string, description?: string, opts: Partial<ToastOptions> = {}) {
    return show({ ...opts, title, description, status: 'success' });
  },
  error(title: string, description?: string, opts: Partial<ToastOptions> = {}) {
    return show({ ...opts, title, description, status: 'error' });
  },
  warning(title: string, description?: string, opts: Partial<ToastOptions> = {}) {
    return show({ ...opts, title, description, status: 'warning' });
  },
  info(title: string, description?: string, opts: Partial<ToastOptions> = {}) {
    return show({ ...opts, title, description, status: 'info' });
  },
  loading(title: string, description?: string, opts: Partial<ToastOptions> = {}) {
    return show({ duration: 0, ...opts, title, description, status: 'loading' });
  }
};

export function useToast() {
  return {
    toasts: readonly(toasts),
    toast,
    showToast: toast.show,
    dismissToast: toast.dismiss
  };
}
