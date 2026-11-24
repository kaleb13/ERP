<script setup lang="ts">
import { ref, watch } from 'vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import StarRating from '../../components/StarRating.vue';
import { useToast } from '../../composables/useToast';
import { type SupplierRecord, getGradeLabel } from './supplierData';

interface Props {
  modelValue: boolean;
  supplier: SupplierRecord | null;
  initialStars?: number;
}

const props = withDefaults(defineProps<Props>(), {
  initialStars: 4
});

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void;
  (e: 'saved', supplier: SupplierRecord): void;
}>();

const { toast } = useToast();

const selectedStars = ref(4);
const scoreInput = ref('80');
const reason = ref('');

const resolveGrade = (score: number) => {
  if (score >= 85) return 'excellent' as const;
  if (score >= 70) return 'satisfactory' as const;
  if (score >= 50) return 'needs_improvement' as const;
  return 'unsatisfactory' as const;
};

const roundToHalfStar = (score: number): number => {
  if (score <= 0) return 0;
  return Math.max(0.5, Math.min(5, Math.round((score / 20) * 2) / 2));
};

watch(
  () => [props.modelValue, props.supplier?.id, props.initialStars] as const,
  ([open]) => {
    if (!open || !props.supplier) return;
    const stars = Math.max(0.5, Math.min(5, props.initialStars || 4));
    selectedStars.value = stars;
    scoreInput.value = String(Math.round(stars * 20));
    reason.value = '';
  },
  { immediate: true }
);

const handlePickStar = (val: number) => {
  selectedStars.value = val;
  scoreInput.value = String(Math.round(val * 20));
};

const handleScoreChange = (val: string | number) => {
  scoreInput.value = String(val);
  const num = Number(val);
  if (!Number.isNaN(num)) {
    const clamped = Math.max(0, Math.min(100, num));
    selectedStars.value = roundToHalfStar(clamped);
  }
};

const handleSave = () => {
  const s = props.supplier;
  if (!s) return;
  const raw = Number(scoreInput.value);
  if (scoreInput.value.trim() === '' || Number.isNaN(raw)) {
    toast.error('Please enter a valid rating score between 0 and 100.');
    return;
  }
  const finalScore = Number(Math.max(0, Math.min(100, raw)).toFixed(1));
  const grade = resolveGrade(finalScore);

  if (!s.scorecard) {
    s.scorecard = {
      scorecard_number: `SSC-2026-Q4-${s.id}`,
      period_label: 'Q4 2026 (Oct 1 – Dec 31)',
      overall_score: finalScore,
      grade,
      status: 'reviewed',
      lines: [
        { code: 'OTD', name: 'On-Time Delivery', weight: 35, score: finalScore },
        { code: 'QUALITY', name: 'Quality Acceptance', weight: 35, score: finalScore },
        { code: 'PRICE', name: 'Price Variance', weight: 20, score: finalScore },
        { code: 'COMMS', name: 'Responsiveness', weight: 10, score: finalScore }
      ]
    };
  } else {
    s.scorecard.overall_score = finalScore;
    s.scorecard.grade = grade;
    const commsLine = s.scorecard.lines.find((l) => l.code === 'COMMS');
    if (commsLine) commsLine.score = finalScore;
  }

  emit('saved', s);
  emit('update:modelValue', false);
  toast.success(`${s.legal_name} rated ${finalScore} / 100 (${getGradeLabel(grade)}).`);
};
</script>

<template>
  <QuickCreateModal
    :model-value="modelValue"
    title="Rate Supplier"
    :show-expand-button="false"
    save-label="Save"
    width="sm"
    @update:model-value="emit('update:modelValue', $event)"
    @save="handleSave"
  >
    <div v-if="supplier" class="rating-modal-body">
      <div class="rating-supplier-ref">
        <span class="rating-supplier-name">{{ supplier.legal_name }}</span>
        <span class="rating-supplier-code">{{ supplier.code }}</span>
      </div>

      <div class="rating-stars-field">
        <span class="rating-field-label">Star Rating</span>
        <div class="modal-star-row">
          <StarRating
            :model-value="selectedStars"
            :size="24"
            :interactive="true"
            :allow-half="true"
            @select="handlePickStar"
          />
          <span class="modal-star-count">{{ selectedStars }} / 5</span>
        </div>
      </div>

      <FormInput
        :model-value="scoreInput"
        label="Rating Score (0 – 100)"
        type="number"
        placeholder=""
        required
        @update:model-value="handleScoreChange"
      />

      <FormTextarea
        v-model="reason"
        label="Reason"
        placeholder=""
        :rows="3"
      />
    </div>
  </QuickCreateModal>
</template>

<style scoped>
.rating-modal-body {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.rating-supplier-ref {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 14px;
  background-color: #fafafa;
  border: 1px solid #e5e5e5;
  border-radius: 10px;
}

.rating-supplier-name {
  font-size: 13.5px;
  font-weight: 500;
  color: #404040;
}

.rating-supplier-code {
  font-size: 12.5px;
  color: #737373;
}

.rating-stars-field {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.rating-field-label {
  font-size: 13px;
  font-weight: 500;
  color: #404040;
}

.modal-star-row {
  display: inline-flex;
  align-items: center;
  gap: 10px;
}

.modal-star-count {
  font-size: 13px;
  color: #737373;
}
</style>
