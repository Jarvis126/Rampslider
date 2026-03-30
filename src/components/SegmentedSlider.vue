<script setup>
/**
 * SegmentedSlider - 阶梯式分段数量滑块
 *
 * 可复用组件：通过 props 配置区间、颜色、奖励，支持 v-model 双向绑定。
 * 非线性映射确保每个区间占据相等的视觉宽度。
 *
 * @example
 * <SegmentedSlider
 *   v-model="amount"
 *   :segments="segments"
 *   :show-tooltip="true"
 * />
 */
import { ref, computed, onBeforeUnmount } from 'vue'

const props = defineProps({
  modelValue: {
    type: Number,
    required: true,
  },
  segments: {
    type: Array,
    required: true,
    validator: (val) =>
      val.length > 0 &&
      val.every((s) => 'min' in s && 'max' in s && 'label' in s && 'bonus' in s && 'color' in s),
  },
  showTooltip: {
    type: Boolean,
    default: true,
  },
})

const emit = defineEmits(['update:modelValue'])

// ─── 派生常量 ───
const breakpoints = computed(() => [
  props.segments[0].min,
  ...props.segments.map((s) => s.max),
])

const minAmount = computed(() => breakpoints.value[0])
const maxAmount = computed(() => breakpoints.value[breakpoints.value.length - 1])

// ─── 响应式状态 ───
const barRef = ref(null)
const isDragging = ref(false)

// ─── 非线性映射：金额 → 百分比 ───
function mapAmountToPercentage(val) {
  const bps = breakpoints.value
  if (val <= bps[0]) return 0
  if (val >= bps[bps.length - 1]) return 100

  const n = bps.length - 1
  const segWidth = 100 / n

  for (let i = 0; i < n; i++) {
    if (val <= bps[i + 1]) {
      const ratio = (val - bps[i]) / (bps[i + 1] - bps[i])
      return segWidth * i + segWidth * ratio
    }
  }
  return 100
}

// ─── 反向映射：百分比 → 金额 ───
function mapPercentageToAmount(pct) {
  const bps = breakpoints.value
  if (pct <= 0) return bps[0]
  if (pct >= 100) return bps[bps.length - 1]

  const n = bps.length - 1
  const segWidth = 100 / n
  const i = Math.min(Math.floor(pct / segWidth), n - 1)
  const ratio = (pct - i * segWidth) / segWidth
  return Math.round(bps[i] + ratio * (bps[i + 1] - bps[i]))
}

// ─── 计算属性 ───
const percentage = computed(() => mapAmountToPercentage(props.modelValue))

const currentSegmentIndex = computed(() => {
  for (let i = 0; i < props.segments.length; i++) {
    if (props.modelValue <= props.segments[i].max) return i
  }
  return props.segments.length - 1
})

const tooltipInfo = computed(() => {
  const idx = currentSegmentIndex.value
  if (idx >= props.segments.length - 1) {
    return { visible: false }
  }
  const next = props.segments[idx + 1]
  const diff = next.min - props.modelValue
  const totalReceive = Math.round(next.min * (1 + next.bonus / 100))
  return {
    visible: true,
    bonusPercent: next.bonus,
    rechargeNeeded: diff,
    receiveAmount: totalReceive,
  }
})

// ─── 区间填充 ───
function getSegmentFillRatio(index) {
  const segWidth = 100 / props.segments.length
  const start = segWidth * index
  const end = segWidth * (index + 1)
  const pct = percentage.value
  if (pct >= end) return 1
  if (pct <= start) return 0
  return (pct - start) / segWidth
}

function getSegmentBackground(index) {
  const fill = getSegmentFillRatio(index)
  const { color } = props.segments[index]
  const gray = '#e8e8e8'
  if (fill >= 1) return color
  if (fill <= 0) return gray
  const p = (fill * 100).toFixed(2)
  return `linear-gradient(to right, ${color} ${p}%, ${gray} ${p}%)`
}

function getSegmentLabelClass(index) {
  const fill = getSegmentFillRatio(index)
  if (fill >= 1) return 'filled'
  if (fill > 0) return 'partial'
  return 'unfilled'
}

// ─── 拖拽交互 ───
let moveHandler = null
let upHandler = null

function setAmount(val) {
  const clamped = Math.max(minAmount.value, Math.min(maxAmount.value, val))
  emit('update:modelValue', clamped)
}

function updateFromClientX(clientX) {
  const bar = barRef.value
  if (!bar) return
  const rect = bar.getBoundingClientRect()
  const x = Math.max(0, Math.min(clientX - rect.left, rect.width))
  setAmount(mapPercentageToAmount((x / rect.width) * 100))
}

function onBarMouseDown(e) {
  e.preventDefault()
  const cx = e.touches ? e.touches[0].clientX : e.clientX
  updateFromClientX(cx)
  beginDrag()
}

function onHandleDown(e) {
  e.preventDefault()
  e.stopPropagation()
  beginDrag()
}

function beginDrag() {
  isDragging.value = true

  moveHandler = (ev) => {
    const cx = ev.touches ? ev.touches[0].clientX : ev.clientX
    updateFromClientX(cx)
  }
  upHandler = () => {
    isDragging.value = false
    removeDragListeners()
  }

  document.addEventListener('mousemove', moveHandler)
  document.addEventListener('mouseup', upHandler)
  document.addEventListener('touchmove', moveHandler, { passive: false })
  document.addEventListener('touchend', upHandler)
}

function removeDragListeners() {
  if (moveHandler) {
    document.removeEventListener('mousemove', moveHandler)
    document.removeEventListener('touchmove', moveHandler)
  }
  if (upHandler) {
    document.removeEventListener('mouseup', upHandler)
    document.removeEventListener('touchend', upHandler)
  }
  moveHandler = null
  upHandler = null
}

onBeforeUnmount(removeDragListeners)
</script>

<template>
  <div class="seg-slider">
    <!-- Tooltip -->
    <div
      v-if="showTooltip && tooltipInfo.visible"
      class="tooltip-wrapper"
      :style="{ left: percentage + '%' }"
    >
      <div class="tooltip-box">
        <div class="tooltip-title">Extra {{ tooltipInfo.bonusPercent }}% bonus</div>
        <div class="tooltip-desc">
          Recharge ${{ tooltipInfo.rechargeNeeded.toLocaleString() }}
          to receive ${{ tooltipInfo.receiveAmount.toLocaleString() }}
        </div>
      </div>
      <div class="tooltip-arrow" />
    </div>

    <!-- Bar Track -->
    <div
      ref="barRef"
      class="bar-track-wrapper"
      @mousedown="onBarMouseDown"
      @touchstart.prevent="onBarMouseDown"
    >
      <div class="bar-track">
        <div
          v-for="(seg, i) in segments"
          :key="i"
          class="segment"
          :style="{
            width: 100 / segments.length + '%',
            background: getSegmentBackground(i),
          }"
        >
          <span class="seg-label" :class="getSegmentLabelClass(i)">
            {{ seg.label }}
          </span>
        </div>
      </div>

      <!-- Handle -->
      <div
        class="handle"
        :class="{ dragging: isDragging }"
        :style="{ left: percentage + '%' }"
        @mousedown="onHandleDown"
        @touchstart.prevent="onHandleDown"
      />
    </div>

    <!-- Breakpoint Labels -->
    <div class="bp-row">
      <span
        v-for="(bp, i) in breakpoints"
        :key="i"
        class="bp-label"
        :style="{ left: mapAmountToPercentage(bp) + '%' }"
      >
        {{ bp.toLocaleString() }}
      </span>
    </div>
  </div>
</template>

<style scoped>
.seg-slider {
  position: relative;
  padding-top: 66px;
  font-family: 'Inter', 'Manrope', -apple-system, sans-serif;
}

/* ═══ Tooltip ═══ */
.tooltip-wrapper {
  position: absolute;
  top: 0;
  transform: translateX(-50%);
  z-index: 10;
  pointer-events: none;
}

.tooltip-box {
  background: #fff;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  padding: 10px 16px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
  white-space: nowrap;
  text-align: center;
}

.tooltip-title {
  font-size: 13px;
  font-weight: 600;
  color: #26a69a;
  margin-bottom: 3px;
}

.tooltip-desc {
  font-size: 11.5px;
  color: #666;
  line-height: 1.4;
}

.tooltip-arrow {
  width: 0;
  height: 0;
  border-left: 8px solid transparent;
  border-right: 8px solid transparent;
  border-top: 8px solid #fff;
  margin: -1px auto 0;
  filter: drop-shadow(0 1px 1px rgba(0, 0, 0, 0.06));
}

/* ═══ Bar Track ═══ */
.bar-track-wrapper {
  position: relative;
  cursor: pointer;
  user-select: none;
}

.bar-track {
  display: flex;
  height: 38px;
  border-radius: 6px;
  overflow: hidden;
}

.segment {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  transition: background 0.15s ease;
}

.seg-label {
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.3px;
  transition: color 0.2s ease;
  pointer-events: none;
  white-space: nowrap;
}

.seg-label.filled {
  color: #fff;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.12);
}

.seg-label.partial {
  color: rgba(255, 255, 255, 0.85);
  text-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);
}

.seg-label.unfilled {
  color: #b8b8b8;
}

/* ═══ Handle ═══ */
.handle {
  position: absolute;
  top: 50%;
  width: 8px;
  height: 30px;
  background: #fff;
  border: 2px solid #26a69a;
  border-radius: 4px;
  transform: translate(-50%, -50%);
  cursor: grab;
  z-index: 5;
  box-shadow: 0 1px 6px rgba(0, 0, 0, 0.18);
  transition: box-shadow 0.15s, transform 0.1s;
}

.handle:hover {
  box-shadow: 0 2px 10px rgba(38, 166, 154, 0.35);
}

.handle.dragging,
.handle:active {
  cursor: grabbing;
  transform: translate(-50%, -50%) scaleY(1.08);
  box-shadow: 0 2px 12px rgba(38, 166, 154, 0.45);
}

/* ═══ Breakpoint Labels ═══ */
.bp-row {
  position: relative;
  height: 28px;
  margin-top: 10px;
}

.bp-label {
  position: absolute;
  transform: translateX(-50%);
  font-size: 12px;
  color: #999;
  font-weight: 400;
}

.bp-label:first-child {
  transform: translateX(0);
}

.bp-label:last-child {
  transform: translateX(-100%);
}
</style>
