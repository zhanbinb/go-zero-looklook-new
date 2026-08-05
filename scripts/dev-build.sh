#!/bin/bash
# scripts/dev-build.sh
# 构建全部 11 个服务 binary 到 ./tmp/  (对标 modd.conf 的 prep)
# 由 .air.toml 的 [build].cmd 调用
set -e
cd "$(dirname "$0")/.."

mkdir -p tmp
echo "==> [dev-build] building 11 services..."

go build -o ./tmp/usercenter-rpc    ./app/usercenter/cmd/rpc
go build -o ./tmp/usercenter-api    ./app/usercenter/cmd/api
go build -o ./tmp/travel-rpc        ./app/travel/cmd/rpc
go build -o ./tmp/travel-api        ./app/travel/cmd/api
go build -o ./tmp/payment-rpc       ./app/payment/cmd/rpc
go build -o ./tmp/payment-api       ./app/payment/cmd/api
go build -o ./tmp/order-rpc         ./app/order/cmd/rpc
go build -o ./tmp/order-api         ./app/order/cmd/api
go build -o ./tmp/order-mq          ./app/order/cmd/mq
go build -o ./tmp/mqueue-scheduler  ./app/mqueue/cmd/scheduler
go build -o ./tmp/mqueue-job        ./app/mqueue/cmd/job

echo "==> [dev-build] done:"
ls -lh ./tmp/* | awk '{print $5"\t"$9}'
