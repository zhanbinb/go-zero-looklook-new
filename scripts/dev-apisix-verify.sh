#!/bin/bash
# scripts/dev-apisix-verify.sh
# A4 验证: 6 条关键路径, 全部走 APISIX 9080 入口
#
# 前置: ./scripts/dev-up.sh 已跑, APISIX 已配 routes+consumer
# 用法: ./scripts/dev-apisix-verify.sh

set -e
BASE="http://127.0.0.1:9080"
USER="18721432599"
PASS="test123456"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

show() {
  local n="$1" name="$2" want="$3" got="$4" body="$5"
  echo "[$n/6] $name  want=$want got=$got"
  echo "  body: $(echo "$body" | head -c 250)"
  echo ""
}

echo "===================================================="
echo "  A4 验证: 6 条路径走 APISIX (9080)"
echo "===================================================="

# ---- 1) /travel/ 公开 ----
echo "[1/6] /travel/v1/homestay/homestayList (公开, 不带 token)"
BODY=$(curl -s -X POST "$BASE/travel/v1/homestay/homestayList" \
  -H "Content-Type: application/json" -d '{"lastId":0,"pageSize":5}')
HTTP=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BASE/travel/v1/homestay/homestayList" \
  -H "Content-Type: application/json" -d '{"lastId":0,"pageSize":5}')
if [ "$HTTP" -ge 200 ] && [ "$HTTP" -lt 300 ]; then
  echo -e "  ${GREEN}✅ PASS${NC} (公开路径 2xx)"
else
  echo -e "  ${YELLOW}⚠️  http=$HTTP (非 2xx, 业务问题)${NC}"
fi
echo "  body: $(echo "$BODY" | head -c 250)"
echo ""

# ---- 2) /order/ 受保护, 不带 token 应 401 ----
echo "[2/6] /order/v1/homestayOrder/createHomestayOrder (受保护, 不带 token 应 401)"
HTTP=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BASE/order/v1/homestayOrder/createHomestayOrder" \
  -H "Content-Type: application/json" \
  -d '{"homestayId":1,"isFood":false,"liveStartDate":"2026-08-17","liveEndDate":"2026-08-19","livePeopleNum":3,"remark":"v"}')
BODY=$(curl -s -X POST "$BASE/order/v1/homestayOrder/createHomestayOrder" \
  -H "Content-Type: application/json" \
  -d '{"homestayId":1,"isFood":false,"liveStartDate":"2026-08-17","liveEndDate":"2026-08-19","livePeopleNum":3,"remark":"v"}')
if [ "$HTTP" = "401" ]; then
  echo -e "  ${GREEN}✅ PASS${NC} (jwt-auth 拦截成功)"
else
  echo -e "  ${RED}❌ FAIL${NC} (期望 401, 实际 $HTTP)"
fi
echo "  body: $(echo "$BODY" | head -c 250)"
echo ""

# ---- 3) /usercenter/login 公开, 拿 token ----
echo "[3/6] /usercenter/v1/user/login (公开, 拿 token)"
LOGIN_RESP=$(curl -s -X POST "$BASE/usercenter/v1/user/login" \
  -H "Content-Type: application/json" \
  -d "{\"mobile\":\"$USER\",\"password\":\"$PASS\"}")
LOGIN_HTTP=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BASE/usercenter/v1/user/login" \
  -H "Content-Type: application/json" \
  -d "{\"mobile\":\"$USER\",\"password\":\"$PASS\"}")
if [ "$LOGIN_HTTP" -ge 200 ] && [ "$LOGIN_HTTP" -lt 300 ]; then
  echo -e "  ${GREEN}✅ PASS${NC} (公开登录成功)"
else
  echo -e "  ${RED}❌ FAIL${NC} (登录 http=$LOGIN_HTTP)"
fi
echo "  body: $(echo "$LOGIN_RESP" | head -c 300)"
TOKEN=$(echo "$LOGIN_RESP" | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    print(d.get('data',{}).get('accessToken') or d.get('data',{}).get('access_token') or '')
except: pass
")
echo "  → token 长度: ${#TOKEN}"
# 把 token payload 解出来看
if [ -n "$TOKEN" ]; then
  PAYLOAD=$(echo "$TOKEN" | cut -d. -f2)
  # pad base64
  case $((${#PAYLOAD} % 4)) in 2) PAYLOAD="${PAYLOAD}==";; 3) PAYLOAD="${PAYLOAD}=";; esac
  echo "  → payload: $(echo "$PAYLOAD" | base64 -d 2>/dev/null)"
fi
echo ""

# ---- 4) /usercenter/detail 受保护, 带 token 应 200 ----
echo "[4/6] /usercenter/v1/user/detail (受保护, 带 token 应 200)"
HTTP=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BASE/usercenter/v1/user/detail" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" -d '{}')
BODY=$(curl -s -X POST "$BASE/usercenter/v1/user/detail" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" -d '{}')
if [ "$HTTP" -ge 200 ] && [ "$HTTP" -lt 300 ]; then
  echo -e "  ${GREEN}✅ PASS${NC} (双层鉴权都通过, 拿到用户信息)"
else
  echo -e "  ${RED}❌ FAIL${NC} (期望 2xx, 实际 $HTTP)"
fi
echo "  body: $(echo "$BODY" | head -c 250)"
echo ""

# ---- 5) /order/ 受保护, 带 token (不是 401 就算过) ----
echo "[5/6] /order/v1/homestayOrder/createHomestayOrder (受保护, 带 token)"
HTTP=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BASE/order/v1/homestayOrder/createHomestayOrder" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"homestayId":1,"isFood":false,"liveStartDate":"2026-08-17","liveEndDate":"2026-08-19","livePeopleNum":3,"remark":"v"}')
BODY=$(curl -s -X POST "$BASE/order/v1/homestayOrder/createHomestayOrder" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"homestayId":1,"isFood":false,"liveStartDate":"2026-08-17","liveEndDate":"2026-08-19","livePeopleNum":3,"remark":"v"}')
if [ "$HTTP" = "401" ]; then
  echo -e "  ${RED}❌ FAIL${NC} (jwt-auth 居然拦了带 token 的请求)"
elif [ "$HTTP" -ge 200 ] && [ "$HTTP" -lt 300 ]; then
  echo -e "  ${GREEN}✅ PASS${NC} (鉴权通过, 业务成功)"
elif [ "$HTTP" -ge 400 ] && [ "$HTTP" -lt 500 ]; then
  echo -e "  ${YELLOW}⚠️  PASS鉴权 + 业务错${NC} (鉴权层过了, 业务层校验 http=$HTTP, 正常)"
else
  echo -e "  ${YELLOW}⚠️  http=$HTTP${NC}"
fi
echo "  body: $(echo "$BODY" | head -c 250)"
echo ""

# ---- 6) /payment/...callback 公开 ----
echo "[6/6] /payment/v1/thirdPayment/thirdPaymentWxPayCallback (公开, 模拟支付回调)"
HTTP=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BASE/payment/v1/thirdPayment/thirdPaymentWxPayCallback" \
  -H "Content-Type: application/json" \
  -d '{"orderSn":"HSO-VERIFY-NOT-EXIST","status":1}')
BODY=$(curl -s -X POST "$BASE/payment/v1/thirdPayment/thirdPaymentWxPayCallback" \
  -H "Content-Type: application/json" \
  -d '{"orderSn":"HSO-VERIFY-NOT-EXIST","status":1}')
if [ "$HTTP" -ge 200 ] && [ "$HTTP" -lt 300 ]; then
  echo -e "  ${GREEN}✅ PASS${NC} (公开回调成功)"
elif [ "$HTTP" = "401" ]; then
  echo -e "  ${RED}❌ FAIL${NC} (公开回调被 jwt-auth 拦了)"
else
  echo -e "  ${YELLOW}⚠️  http=$HTTP${NC} (业务层错误, 但鉴权层过了)"
fi
echo "  body: $(echo "$BODY" | head -c 250)"
echo ""

echo "===================================================="
echo "  A4 验证完成"
echo "===================================================="
