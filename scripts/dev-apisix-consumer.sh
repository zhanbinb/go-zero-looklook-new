#!/bin/bash
# scripts/dev-apisix-consumer.sh
# 给 APISIX 创建 1 个 Consumer (用 jwt-auth 插件做网关层 JWT 鉴权)
#
# 关键点:
#   - Consumer 的 username 跟 jwt-auth.key 保持一致 ("looklook")
#   - jwt-auth.secret 必须 = go-zero 各 service 的 JwtAuth.AccessSecret
#     (app/*/cmd/api/etc/*.yaml 里的 AccessSecret: ae0536f9-...)
#   - algorithm 跟 go-zero 用的 SigningMethodHS256 对应
#   - 所有用户 token 的 payload.key = "looklook", 都能匹配到这个 Consumer
#
# 用法: ./scripts/dev-apisix-consumer.sh
# 幂等: 重复执行会覆盖

set -e
ADMIN_KEY="edd1c9f034325f303f3f3f3f3f3f3f3f"
BASE="http://127.0.0.1:9180/apisix/admin"
SECRET="ae0536f9-6450-4606-8e13-5a19ed505da0"

echo "==> consumer: looklook (jwt-auth)"
curl -s -X PUT "$BASE/consumers" \
  -H "X-API-KEY: $ADMIN_KEY" \
  -d "{
    \"username\":\"looklook\",
    \"desc\":\"looklook 项目的 JWT 签发方\",
    \"plugins\":{
      \"jwt-auth\":{
        \"key\":\"looklook\",
        \"secret\":\"$SECRET\",
        \"algorithm\":\"HS256\"
      }
    }
  }"
echo ""

echo ""
echo "==> 验证:"
curl -s "$BASE/consumers/looklook" -H "X-API-KEY: $ADMIN_KEY" | python3 -m json.tool 2>/dev/null || \
curl -s "$BASE/consumers/looklook" -H "X-API-KEY: $ADMIN_KEY"
