<template>
  <div class="app-wrapper">
    <h2 class="page-title">Recharge Bonus</h2>

    <div class="input-row">
      <span class="custom-label">Custom</span>
      <InputNumber
        v-model="amount"
        :min="50"
        :max="5000"
        prefix="$"
        :useGrouping="true"
        showButtons
        buttonLayout="horizontal"
        :step="1"
        incrementButtonIcon="pi pi-plus"
        decrementButtonIcon="pi pi-minus"
        class="amount-input"
      />
    </div>

    <SegmentedSlider v-model="amount" :segments="segments" />
  </div>
</template>

<script setup>
import { ref } from 'vue'
import InputNumber from 'primevue/inputnumber'
import SegmentedSlider from './components/SegmentedSlider.vue'

const amount = ref(1122)

const segments = [
  { min: 50,   max: 500,  label: 'Give 1%', bonus: 1, color: '#b2dfdb' },
  { min: 500,  max: 1000, label: 'Give 2%', bonus: 2, color: '#80cbc4' },
  { min: 1000, max: 2000, label: 'Give 3%', bonus: 3, color: '#4db6ac' },
  { min: 2000, max: 3000, label: 'Give 4%', bonus: 4, color: '#26a69a' },
  { min: 3000, max: 5000, label: 'Give 5%', bonus: 5, color: '#009688' },
]
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Inter', 'Manrope', -apple-system, sans-serif;
  background: #f4f5f7;
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
}

.app-wrapper {
  background: #fff;
  border-radius: 12px;
  padding: 40px 36px;
  box-shadow: 0 2px 16px rgba(0, 0, 0, 0.07);
  width: 700px;
  max-width: 95vw;
}

.page-title {
  font-size: 18px;
  font-weight: 600;
  color: #333;
  margin-bottom: 24px;
}

.input-row {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 12px;
}

.custom-label {
  font-size: 15px;
  font-weight: 500;
  color: #333;
}

.amount-input :deep(.p-inputnumber-input) {
  width: 110px;
  text-align: center;
  font-weight: 600;
  font-size: 15px;
  font-family: 'Inter', sans-serif;
}

.amount-input :deep(.p-inputnumber-button) {
  background: #f8f9fa;
  border-color: #dee2e6;
  color: #495057;
  width: 36px;
}

.amount-input :deep(.p-inputnumber-button:hover) {
  background: #e9ecef;
}
</style>
