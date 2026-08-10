package handler

import (
	"fmt"
	"net/http"
	"strings"

	"looklook/app/usercenter/cmd/api/internal/svc"

	"github.com/golang-jwt/jwt/v4"
	"github.com/zeromicro/go-zero/rest/token"
)

// AuthCheckHandler nginx auth_request 子请求的端点
//
// 工作流:
//   1. nginx 收到受保护请求 (e.g. POST /order/...)
//   2. nginx 调 auth_request /auth_check (子请求, internal, 同 method/header)
//   3. 本 handler 读 Authorization, 验签 + 验 exp
//   4. 把 userId (jwtUserId claim) 写到 X-User-Id response header
//   5. 200 OK = 通过; 401 = 拒绝
//
// 关键: 本端点**自己**不验 jwt 中间件 (不能自己验自己), 应该是 no-JWT route group 的一员
func AuthCheckHandler(ctx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// 1. 拿 Authorization: Bearer xxx
		auth := r.Header.Get("Authorization")
		if !strings.HasPrefix(auth, "Bearer ") {
			http.Error(w, "missing or invalid Authorization header", http.StatusUnauthorized)
			return
		}
		// 2. 用同把 secret 验签 + 验 exp
		//    (token.ParseToken 内部会从 r.Header 抽 "Bearer xxx" 里的 xxx, 不用我们抽)
		//    (跟 step-11 的 rest.WithJwt 内部逻辑一致, 但本端点不走 jwt 中间件)
		parser := token.NewTokenParser()
		tok, err := parser.ParseToken(r, ctx.Config.JwtAuth.AccessSecret, "")
		if err != nil {
			http.Error(w, fmt.Sprintf("parse token: %v", err), http.StatusUnauthorized)
			return
		}
		if !tok.Valid {
			http.Error(w, "invalid token", http.StatusUnauthorized)
			return
		}

		// 3. 拿 claims
		claims, ok := tok.Claims.(jwt.MapClaims)
		if !ok {
			http.Error(w, "invalid claims type", http.StatusUnauthorized)
			return
		}

		// 4. ★ 把 userId 写到 response header (nginx 用 auth_request_set 读)
		//    jwtUserId 是生成时 claims 里设的 key (跟 ctxdata.CtxKeyJwtUserId = "jwtUserId" 一致)
		if uid, ok := claims["jwtUserId"]; ok {
			w.Header().Set("X-User-Id", fmt.Sprintf("%v", uid))
		} else {
			// token 没有 jwtUserId claim, 算无效
			http.Error(w, "missing jwtUserId claim", http.StatusUnauthorized)
			return
		}
		// (可选) 透传更多 claim 给 backend
		if tid, ok := claims["tenantId"]; ok {
			w.Header().Set("X-Tenant-Id", fmt.Sprintf("%v", tid))
		}

		// 5. 200 OK = 通过 (nginx 看到 200 就放行, 同时 X-User-Id header 被提取)
		w.WriteHeader(http.StatusOK)
	}
}
