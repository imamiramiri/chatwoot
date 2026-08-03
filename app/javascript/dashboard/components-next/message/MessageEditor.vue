<script setup>
import { ref, onMounted, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  content: { type: String, default: '' },
  isSaving: { type: Boolean, default: false },
});

const emit = defineEmits(['save', 'cancel']);

const { t } = useI18n();

const draft = ref(props.content ?? '');
const textareaRef = ref(null);

const resize = () => {
  const el = textareaRef.value;
  if (!el) return;
  el.style.height = 'auto';
  el.style.height = `${el.scrollHeight}px`;
};

const onSave = () => {
  const value = draft.value.trim();
  if (!value || value === (props.content ?? '').trim()) {
    emit('cancel');
    return;
  }
  emit('save', value);
};

const onCancel = () => emit('cancel');

onMounted(async () => {
  await nextTick();
  resize();
  const el = textareaRef.value;
  if (el) {
    el.focus();
    el.setSelectionRange(el.value.length, el.value.length);
  }
});
</script>

<template>
  <div
    class="flex flex-col w-full max-w-2xl gap-2 p-3 rounded-xl bg-n-solid-2 border border-n-strong"
  >
    <textarea
      ref="textareaRef"
      v-model="draft"
      rows="1"
      class="w-full p-2 text-sm bg-n-background border border-n-weak rounded-md resize-none outline-none text-n-slate-12 min-h-[2.5rem] max-h-64"
      :disabled="isSaving"
      @input="resize"
      @keydown.esc.prevent="onCancel"
      @keydown.meta.enter.prevent="onSave"
      @keydown.ctrl.enter.prevent="onSave"
    />
    <div class="flex items-center justify-between gap-2">
      <span class="text-xs text-n-slate-11">
        {{ t('CONVERSATION.EDIT_MESSAGE.HELP') }}
      </span>
      <div class="flex items-center gap-2">
        <NextButton
          sm
          faded
          slate
          :label="t('CONVERSATION.EDIT_MESSAGE.CANCEL')"
          :disabled="isSaving"
          @click="onCancel"
        />
        <NextButton
          sm
          solid
          blue
          :label="t('CONVERSATION.EDIT_MESSAGE.SAVE')"
          :is-loading="isSaving"
          :disabled="isSaving"
          @click="onSave"
        />
      </div>
    </div>
  </div>
</template>
