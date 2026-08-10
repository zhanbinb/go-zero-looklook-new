#!/bin/bash
# scripts/dev-apisix-upstreams.sh
# 给 APISIX 创建 4 个 Upstream (对应 4 个 go-zero api 服务, 跑在 host)
#
# 用法: ./scripts/dev-apisix-upstreams.sh
# 幂等: 重复执行会用新配置覆盖, 不会报错
#
# upstream id 约定:
#   1 = order      (1001)
#   2 = payment    (1002)
#   3 = travel     (1003)
#   4 = usercenter (1004)

set -e
ADMIN_KEY="edd1c9f034325f303f3f3f3f3f3f3f3f"
BASE="http://127.0.0.1:9180/apisix/admin"

create_upstream() {
  local id="$1" port="$2" name="$3" desc="$4"
  echo "==> upstream $id: $name -> host.docker.internal:$port"
  curl -s -X PUT "$BASE/upstreams/$id" \
    -H "X-API-KEY: $ADMIN_KEY" \
    -d "{\"name\":\"$name\",\"desc\":\"$desc\",\"type\":\"roundrobin\",\"nodes\":{\"host.docker.internal:$port\":1}}"
  echo ""
}

create_upstream 1 1001 "order-api"      "looklook order api (端口1001)"
create_upstream 2 1002 "payment-api"    "looklook payment api (端口1002)"
create_upstream 3 1003 "travel-api"     "looklook travel api (端口1003)"
create_upstream 4 1004 "usercenter-api" "looklook usercenter api (端口1004)"

echo ""
echo "==> 全部完成, 验证:"
curl -s "$BASE/upstreams" -H "X-API-KEY: $ADMIN_KEY" | python3 -m json.tool 2>/dev/null || \
curl -s "$BASE/upstreams" -H "X-API-KEY: $ADMIN_KEY"
