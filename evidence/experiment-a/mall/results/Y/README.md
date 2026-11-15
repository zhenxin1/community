# 运行说明

需要 Node 24.22.2 与 npm 11.19.1。在本目录运行 `npm ci`、`npm run typecheck`、`npm run build`，`npm run dev` 后访问 http://127.0.0.1:5173/，Ctrl+C 停止。服务重启会生成新的运行身份。这里仅为候选材料；当前未实现本任务。

固定只读数据通过服务提供：环境变量 `FIXTURE_SCENARIO` 可设 `ready`（默认）、`empty`、`quote-error`，重启服务后生效。GET `/api/session` 返回运行身份，GET `/api/products`、`/api/cart`、`/api/quote` 返回固定响应；quote-error 场景的报价返回 503。数据只用于读取，不实现购物车操作或报价计算。
