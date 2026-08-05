package result

import (
	"context"
	"errors"

	"looklook/pkg/xerr"

	"github.com/zeromicro/go-zero/core/logx"
	"google.golang.org/grpc/status"
)

// job返回
func JobResult(ctx context.Context, resp interface{}, err error) {
	if err == nil {
		// 成功返回 ,只有dev环境下才会打印info，线上不显示
		if resp != nil {
			logx.Infof("resp: %+v", resp)
		}
		return
	} else {
		errCode := xerr.SERVER_COMMON_ERROR
		errMsg := "服务器开小差啦，稍后再来试一试"

		// 错误返回
		var e *xerr.CodeError
		if errors.As(err, &e) { // 自定义错误类型
			// 自定义CodeError
			errCode = e.GetErrCode()
			errMsg = e.GetErrMsg()
		} else {
			if gstatus, ok := status.FromError(err); ok { // grpc err错误
				grpcCode := uint32(gstatus.Code())
				if xerr.IsCodeErr(grpcCode) { // 区分自定义错误跟系统底层、db等错误，底层、db错误不能返回给前端
					errCode = grpcCode
					errMsg = gstatus.Message()
				}
			}
		}

		logx.WithContext(ctx).Errorf("【JOB-ERR】 : %+v ,errCode:%d , errMsg:%s ", err, errCode, errMsg)
		return
	}
}
