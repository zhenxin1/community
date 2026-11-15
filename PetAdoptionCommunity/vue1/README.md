# 寻爪前端
前端使用Vue3.5.45、Vue Router4.6.4、Pinia3.0.4和Vite8.3.8，依赖由package-lock.json锁定。

## 开发
后端在127.0.0.1:8080启动后，在本目录执行`npm.cmd ci`和`npm.cmd run dev`，访问http://127.0.0.1:5173/。Vite代理/api与/media至后端。当前脚本以package.json为准，开发命令是dev。

## 构建与运行
`npm.cmd run build`输出dist。仓库根scripts/build.ps1会构建前端、复制静态资源并打包后端；生产只需一个Spring Boot进程，在8080访问页面。构建前停止本项目开发进程以释放Windows原生依赖锁。

## 目录与约定
src/pages为页面，components为复用展示与状态组件，router.js维护hash路由，core.js维护HTTP、会话和提示，style.css定义统一暖白森林绿布局。Bearer仅内存保存，刷新需要重登；显示金额单位换算为元，实际计算以服务端整数分报价为准。界面隐藏不能替代接口鉴权。
完整运行与课程资料见仓库根README及docs/submission-index.md。
