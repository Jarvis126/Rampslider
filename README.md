# 阶梯式复杂数量滑块

基于 **Vue 3 + PrimeVue 4 + Vite** 实现的分段式非线性进度条/滑块组件。

![macOS](https://img.shields.io/badge/platform-macOS-blue)
![Vue 3](https://img.shields.io/badge/Vue-3.5-42b883)
![PrimeVue](https://img.shields.io/badge/PrimeVue-4.x-26a69a)

---

## 一键启动

在 Finder 中双击项目根目录下的 **`阶梯式复杂数量滑块.command`** 文件即可自动启动。

脚本会依次完成：
1. 自动 `cd` 到项目目录
2. 检测 Node.js 环境
3. 首次运行自动 `npm install`
4. 检测端口冲突并自动顺延到可用端口
5. 启动 Vite 开发服务器
6. 服务就绪后自动打开默认浏览器
7. `Ctrl+C` 优雅退出并清理进程

也可在终端手动执行：

```bash
chmod +x 阶梯式复杂数量滑块.command
./阶梯式复杂数量滑块.command
```

---

## 项目结构

```
├── src/
│   ├── main.js                          # Vue 应用入口
│   ├── App.vue                          # Demo 页面（InputNumber + 滑块）
│   └── components/
│       └── SegmentedSlider.vue          # ⭐ 核心可复用组件
├── index.html                           # HTML 入口
├── package.json                         # 依赖管理
├── vite.config.js                       # Vite 配置
├── 阶梯式复杂数量滑块.command              # 一键启动脚本
└── README.md                            # 本文件
```

---

## 组件 API

### `<SegmentedSlider>`

| Prop | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `modelValue` | `Number` | ✅ | — | 当前数值，支持 `v-model` 双向绑定 |
| `segments` | `Array<Segment>` | ✅ | — | 分段配置数组 |
| `showTooltip` | `Boolean` | — | `true` | 是否显示 Handle 上方的 Tooltip |

#### Segment 结构

```typescript
interface Segment {
  min: number    // 区间起始值
  max: number    // 区间结束值
  label: string  // 区间内显示文字，如 "Give 1%"
  bonus: number  // 奖励百分比
  color: string  // 该区间的填充色（HEX）
}
```

#### 使用示例

```vue
<script setup>
import { ref } from 'vue'
import SegmentedSlider from './components/SegmentedSlider.vue'

const amount = ref(1000)

const segments = [
  { min: 50,   max: 500,  label: 'Give 1%', bonus: 1, color: '#b2dfdb' },
  { min: 500,  max: 1000, label: 'Give 2%', bonus: 2, color: '#80cbc4' },
  { min: 1000, max: 2000, label: 'Give 3%', bonus: 3, color: '#4db6ac' },
  { min: 2000, max: 3000, label: 'Give 4%', bonus: 4, color: '#26a69a' },
  { min: 3000, max: 5000, label: 'Give 5%', bonus: 5, color: '#009688' },
]
</script>

<template>
  <SegmentedSlider v-model="amount" :segments="segments" />
</template>
```

---

## 核心算法：非线性映射

每个区间占据 **相等的视觉宽度**（5 个区间各占 20%），区间内部线性插值。

```
金额范围         视觉位置
50 ~ 500    →    0% ~ 20%
500 ~ 1000  →   20% ~ 40%
1000 ~ 2000 →   40% ~ 60%
2000 ~ 3000 →   60% ~ 80%
3000 ~ 5000 →   80% ~ 100%
```

`mapAmountToPercentage(1122)` → `42.44%`（位于第 3 段 12.2% 处）

---

## 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Vue 3 | 3.5+ | 响应式框架 |
| PrimeVue | 4.x (Aura) | InputNumber 组件 |
| Vite | 6.x | 构建工具 & 开发服务器 |
| Inter Font | — | UI 字体 |

---

## 操作记录

| 日期 | 操作 | 说明 |
|------|------|------|
| 2026-03-30 | 项目初始化 | 创建 Vue 3 + Vite + PrimeVue 项目骨架 |
| 2026-03-30 | 实现分段进度条 | 完成非线性映射、分段渐变填充、Tooltip、拖拽交互 |
| 2026-03-30 | 组件封装 | 将滑块提取为 `SegmentedSlider.vue`，支持 props/emits/v-model |
| 2026-03-30 | 一键启动脚本 | 创建 `阶梯式复杂数量滑块.command`，支持端口检测、自动浏览器 |
| 2026-03-30 | 文档编写 | 生成 README.md，包含组件 API、算法说明、使用方法 |
