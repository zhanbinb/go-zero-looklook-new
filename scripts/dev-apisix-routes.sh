#!/bin/bash
# scripts/dev-apisix-routes.sh
# 给 APISIX 创建 7 条 Route (路径 → upstream + 是否鉴权)
#
# 用法: ./scripts/dev-apisix-routes.sh
# 幂等: 重复执行会覆盖
#
# Route 设计:
#   精确匹配 (4 条: login/register/wxMiniAuth/detail)
#     + catch-all (3 条: travel/* order/* payment callback)
#   公开路由 (5): login/register/wxMiniAuth/travel/callback
#   受保护路由 (2): user/detail + order/*   <- 挂 jwt-auth 插件
#
# 优先级: 精确路径 route id 1-4, 10-30 是 catch-all
#         APISIX 默认按最长前缀匹配, 精确路径不会被 catch-all 截胡

set -e
ADMIN_KEY="edd1c9f034325f303f3f3f3f3f3f3f3f"
BASE="http://127.0.0.1:9180/apisix/admin"

# --------- 公开路由 (5 条) ---------
echo "==> route 1: usercenter/login (公开)"
curl -s -X PUT "$BASE/routes/1" -H "X-API-KEY: $ADMIN_KEY" -d '{
  "uri":"/usercenter/v1/user/login",
  "name":"login-public",
  "desc":"登录拿 token",
  "upstream_id":"4"
}'
echo ""

echo "==> route 2: usercenter/register (公开)"
curl -s -X PUT "$BASE/routes/2" -H "X-API-KEY: $ADMIN_KEY" -d '{
  "uri":"/usercenter/v1/user/register",
  "name":"register-public",
  "desc":"注册",
  "upstream_id":"4"
}'
echo ""

echo "==> route 3: usercenter/wxMiniAuth (公开)"
curl -s -X PUT "$BASE/routes/3" -H "X-API-KEY: $ADMIN_KEY" -d '{
  "uri":"/usercenter/v1/user/wxMiniAuth",
  "name":"wxMiniAuth-public",
  "desc":"微信小程序授权",
  "upstream_id":"4"
}'
echo ""

echo "==> route 10: travel/* (公开 catch-all)"
curl -s -X PUT "$BASE/routes/10" -H "X-API-KEY: $ADMIN_KEY" -d '{
  "uri":"/travel/*",
  "name":"travel-catchall",
  "desc":"旅游业务(浏览为主)",
  "upstream_id":"3"
}'
echo ""

echo "==> route 20: payment/callback (公开)"
curl -s -X PUT "$BASE/routes/20" -H "X-API-KEY: $ADMIN_KEY" -d '{
  "uri":"/payment/v1/payment/callback",
  "name":"payment-callback-public",
  "desc":"微信支付回调(必须公开)",
  "upstream_id":"2"
}'
echo ""

# --------- 受保护路由 (2 条) ---------
echo "==> route 4: usercenter/detail (jwt-auth)"
curl -s -X PUT "$BASE/routes/4" -H "X-API-KEY: $ADMIN_KEY" -d '{
  "uri":"/usercenter/v1/user/detail",
  "name":"user-detail-protected",
  "desc":"我的资料(需 token)",
  "upstream_id":"4",
  "plugins":{
    "jwt-auth":{}
  }
}'
echo ""

echo "==> route 30: order/* (jwt-auth catch-all)"
curl -s -X PUT "$BASE/routes/30" -H "X-API-KEY: $ADMIN_KEY" -d '{
  "uri":"/order/*",
  "name":"order-catchall-protected",
  "desc":"订单(需 token)",
  "upstream_id":"1",
  "plugins":{
    "jwt-auth":{}
  }
}'
echo ""

echo ""
echo "==> 全部完成, 验证:"
curl -s "$BASE/routes" -H "X-API-KEY: $ADMIN_KEY" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(f'共 {d[\"total\"]} 条 route:')
for r in d['list']:
    v = r['value']
    plugins = list(v.get('plugins',{}).keys())
    print(f'  id={v[\"id\"]:>3}  uri={v[\"uri\"]:<35} upstream={v.get(\"upstream_id\",\"-\"):<2} plugins={plugins}')
"
