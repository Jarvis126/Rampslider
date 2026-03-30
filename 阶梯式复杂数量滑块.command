#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║          阶梯式复杂数量滑块 · 一键启动脚本                      ║
# ╚══════════════════════════════════════════════════════════════╝
#
# 使用方法:
#   方式一: 在 Finder 中双击本文件即可自动启动项目
#   方式二: 在终端中执行:
#           chmod +x 阶梯式复杂数量滑块.command
#           ./阶梯式复杂数量滑块.command
#
# 功能清单:
#   ✅ 自动 cd 到项目根目录（无需手动切换）
#   ✅ 自动检测 Node.js 环境
#   ✅ 首次运行自动安装依赖
#   ✅ 自动检测端口占用并顺延到可用端口
#   ✅ 同时管理前端 & 后端进程（当前项目仅含前端）
#   ✅ 服务就绪后自动打开默认浏览器
#   ✅ Ctrl+C 优雅退出，自动清理子进程
#
# 系统要求:
#   - macOS（使用 open 命令打开浏览器、lsof 检测端口）
#   - Node.js >= 16
#   - npm
#
# ═══════════════════════════════════════════════════════════════

# ── 颜色 ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── 自动 cd 到脚本所在目录（= 项目根目录）──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── 子进程 PID 收集 ──
PIDS=()

# ── 优雅退出 ──
cleanup() {
  echo ""
  echo -e "${YELLOW}🛑 正在停止所有服务...${NC}"
  for pid in "${PIDS[@]}"; do
    kill "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
  done
  echo -e "${GREEN}✅ 所有服务已停止，再见！${NC}"
  exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# ── Banner ──
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   ${BOLD}阶梯式复杂数量滑块${NC}${CYAN}  ·  一键启动               ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${GREEN}📂 项目目录:${NC} $SCRIPT_DIR"
echo ""

# ═══════════════════════════════════════
# 1. 环境检查
# ═══════════════════════════════════════
echo -e "${BOLD}[1/5] 检查运行环境${NC}"

if ! command -v node &>/dev/null; then
  echo -e "  ${RED}✖ 未检测到 Node.js${NC}"
  echo -e "  ${RED}  请先安装: https://nodejs.org${NC}"
  echo ""
  read -rp "按回车键退出..."
  exit 1
fi
echo -e "  ${GREEN}✔ Node.js $(node -v)${NC}"

if ! command -v npm &>/dev/null; then
  echo -e "  ${RED}✖ 未检测到 npm${NC}"
  echo ""
  read -rp "按回车键退出..."
  exit 1
fi
echo -e "  ${GREEN}✔ npm $(npm -v)${NC}"

# ═══════════════════════════════════════
# 2. 安装依赖
# ═══════════════════════════════════════
echo ""
echo -e "${BOLD}[2/5] 检查项目依赖${NC}"

if [ ! -d "node_modules" ]; then
  echo -e "  ${YELLOW}📦 首次运行，正在安装依赖...${NC}"
  npm install --loglevel=error
  if [ $? -ne 0 ]; then
    echo -e "  ${RED}✖ 依赖安装失败${NC}"
    read -rp "按回车键退出..."
    exit 1
  fi
  echo -e "  ${GREEN}✔ 依赖安装完成${NC}"
else
  echo -e "  ${GREEN}✔ node_modules 已存在${NC}"
fi

# ═══════════════════════════════════════
# 3. 端口检测
# ═══════════════════════════════════════
echo ""
echo -e "${BOLD}[3/5] 检测可用端口${NC}"

DEFAULT_FRONTEND_PORT=5173
DEFAULT_BACKEND_PORT=3000

find_free_port() {
  local port=$1
  local label=$2
  while lsof -i :"$port" -t >/dev/null 2>&1; do
    echo -e "  ${YELLOW}⚠  ${label}端口 $port 已被占用，尝试 $((port + 1))...${NC}" >&2
    port=$((port + 1))
  done
  echo "$port"
}

FRONTEND_PORT=$(find_free_port $DEFAULT_FRONTEND_PORT "前端")
echo -e "  ${GREEN}✔ 前端端口: ${FRONTEND_PORT}${NC}"

BACKEND_PORT=$(find_free_port $DEFAULT_BACKEND_PORT "后端")
echo -e "  ${GREEN}✔ 后端端口: ${BACKEND_PORT} (预留)${NC}"

# ═══════════════════════════════════════
# 4. 启动服务
# ═══════════════════════════════════════
echo ""
echo -e "${BOLD}[4/5] 启动服务${NC}"

# ── 后端（当前项目无后端，此处为扩展预留）──
# 如需启动后端，取消下方注释并修改命令:
# echo -e "  ${CYAN}🔧 启动后端服务 (端口 $BACKEND_PORT)...${NC}"
# node server.js --port $BACKEND_PORT &
# BACKEND_PID=$!
# PIDS+=($BACKEND_PID)
# echo -e "  ${GREEN}✔ 后端已启动 (PID: $BACKEND_PID)${NC}"

# ── 前端 ──
echo -e "  ${CYAN}🚀 启动前端开发服务器 (端口 $FRONTEND_PORT)...${NC}"
npx vite --port "$FRONTEND_PORT" &
FRONTEND_PID=$!
PIDS+=($FRONTEND_PID)

# ═══════════════════════════════════════
# 5. 等待就绪 & 打开浏览器
# ═══════════════════════════════════════
echo ""
echo -e "${BOLD}[5/5] 等待服务就绪${NC}"

READY=false
for i in $(seq 1 30); do
  if ! kill -0 "$FRONTEND_PID" 2>/dev/null; then
    echo -e "  ${RED}✖ 前端服务启动失败${NC}"
    read -rp "按回车键退出..."
    exit 1
  fi

  if nc -z localhost "$FRONTEND_PORT" 2>/dev/null; then
    READY=true
    break
  fi
  printf "  ⏳ 等待中 (%d/30)\r" "$i"
  sleep 1
done

if [ "$READY" = true ]; then
  echo -e "  ${GREEN}✔ 服务已就绪！${NC}                "
  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║                                                  ║${NC}"
  echo -e "${CYAN}║  ${BOLD}🌐 前端: http://localhost:$FRONTEND_PORT${NC}${CYAN}                  ║${NC}"
  echo -e "${CYAN}║  ${BOLD}🛑 按 Ctrl+C 停止所有服务${NC}${CYAN}                     ║${NC}"
  echo -e "${CYAN}║                                                  ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
  echo ""

  # 自动打开默认浏览器
  open "http://localhost:$FRONTEND_PORT"
else
  echo -e "  ${RED}✖ 服务启动超时 (30秒)${NC}"
  echo -e "  ${YELLOW}尝试手动访问: http://localhost:$FRONTEND_PORT${NC}"
fi

# ── 保持脚本运行，等待前端进程 ──
wait "$FRONTEND_PID"
