package xerr

import (
	"fmt"
)

// CodeError 是业务错误类型, 带错误码 + 消息
// 保留类型, 让 errors.As(err, &codeErr) 能识别
type CodeError struct {
	errCode uint32
	errMsg  string
}

//返回给前端的错误码
func (e *CodeError) GetErrCode() uint32 {
	return e.errCode
}

//返回给前端显示端错误信息
func (e *CodeError) GetErrMsg() string {
	return e.errMsg
}

func (e *CodeError) Error() string {
	return fmt.Sprintf("ErrCode:%d，ErrMsg:%s", e.errCode, e.errMsg)
}

func NewErrCodeMsg(errCode uint32, errMsg string) *CodeError {
	return &CodeError{errCode: errCode, errMsg: errMsg}
}

func NewErrCode(errCode uint32) *CodeError {
	return &CodeError{errCode: errCode, errMsg: MapErrMsg(errCode)}
}

func NewErrMsg(errMsg string) *CodeError {
	return &CodeError{errCode: SERVER_COMMON_ERROR, errMsg: errMsg}
}

// wrappedCodeError 保留 CodeError 类型 + 链真实 cause
type wrappedCodeError struct {
	*CodeError
	cause error
}

func (e *wrappedCodeError) Error() string {
	return e.CodeError.Error() + ": " + e.cause.Error()
}

// Unwrap 让 errors.Is/As 能递归匹配
func (e *wrappedCodeError) Unwrap() error {
	return e.cause
}

// Wrapf 完全模仿 pkg/errors.Wrapf 签名 (调用方 0 改动, 只需换 import + 函数名前缀)
//
// 用法 (跟 pkg/errors.Wrapf 一模一样):
//   xerr.Wrapf(xerr.NewErrCode(xerr.DB_ERROR), "Register db user Insert err:%v,user:%+v", err, user)
//   xerr.Wrapf(ErrUserNoExistsError, "id:%d", in.Id)
//
// 区别:
//   1. 用 std errors 链 (fmt.Errorf %w), 不用 pkg/errors
//   2. 不带 stack trace (go-zero 1.10+ 内部也不带 stack, 一致)
//   3. 保留 CodeError 类型 (errors.As 能找到), 真实 err 通过 Unwrap 链 (errors.Is 找得到)
func Wrapf(err error, format string, args ...any) error {
	codeErr, ok := err.(*CodeError)
	if !ok {
		// 降级: 不是 CodeError 时用普通 fmt.Errorf
		return fmt.Errorf(format+": %w", append(args, err)...)
	}
	return &wrappedCodeError{
		CodeError: codeErr,
		cause:     fmt.Errorf(format+": %w", append(args, err)...),
	}
}

// Wrap 模仿 pkg/errors.Wrap, 用 CodeError 包装一个 err
func Wrap(err error, msg string) error {
	codeErr, ok := err.(*CodeError)
	if !ok {
		return fmt.Errorf("%s: %w", msg, err)
	}
	return &wrappedCodeError{
		CodeError: codeErr,
		cause:     fmt.Errorf("%s: %w", msg, err),
	}
}
