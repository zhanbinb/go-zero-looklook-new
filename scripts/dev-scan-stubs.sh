#!/bin/bash
# scripts/dev-scan-stubs.sh
# 扫所有 logic 文件, 找出 goctl 生成后没被实现的空壳 (todo: add your logic here)
# 用法: ./scripts/dev-scan-stubs.sh
#
# 这是 M1 阶段发现的实战教训: .api 定义存在不代表接口能用, 真正的代码在 logic/*.go
# 跑完这个脚本, 可以心里有数哪些接口可以 smoke, 哪些是 schema-only (永远返回空)
set -e
cd "$(dirname "$0")/.."

echo "=== 总 logic 文件 ==="
find app/{usercenter,travel,payment,order,mqueue}/cmd -name "*Logic.go" 2>/dev/null | wc -l | xargs echo "  "

echo ""
echo "=== 空 stub (todo: add your logic here) ==="
matches=$(grep -rl "todo: add your logic here" app/ 2>/dev/null || true)
if [ -z "$matches" ]; then
  echo "  (无 — 所有 logic 都已实现)"
else
  echo "$matches"
fi

echo ""
echo "=== 其他可疑模式 (return &types.X{}, nil) ==="
suspects=$(grep -rEn '^\s*return &types\.\w+Resp\{\}, nil\s*$' app/ 2>/dev/null || true)
if [ -z "$suspects" ]; then
  echo "  (无)"
else
  echo "$suspects"
fi
