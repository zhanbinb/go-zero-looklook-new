#!/bin/bash
# scripts/dev-status.sh
# 查看 dev 服务状态: api/rpc 端口 + ./tmp 进程
cd "$(dirname "$0")/.."

echo "=== api/rpc 端口监听 (1001-1004, 2001-2004) ==="
lsof -nP -iTCP:1001 -iTCP:1002 -iTCP:1003 -iTCP:1004 \
     -iTCP:2001 -iTCP:2002 -iTCP:2003 -iTCP:2004 \
     -sTCP:LISTEN 2>/dev/null || echo "(没有监听的端口)"

echo ""
echo "=== ./tmp 下的 dev 进程 ==="
ps aux | grep '[.]/tmp/' | grep -v grep || echo "(没有 dev 进程)"
