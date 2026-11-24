# 本地 Jenkins 更新中心

此目录保存华为云更新中心地址和其第三方签名证书，可纳入 Git 管理。证书是公开证书，不包含私钥。安装后，Jenkins 将信任该第三方签发的更新数据；镜像中的部分插件下载地址使用 HTTP。

停止 Jenkins 后，在仓库根目录的 Git Bash 或其他 POSIX Shell 中运行：

```sh
sh ./dev-config/jenkins-update-center/initialize-jenkins-mirror.sh
```

默认使用 `war/work` 作为 `JENKINS_HOME`，也可使用 `--jenkins-home <目录>` 指定其他目录（Git Bash 中使用 `/h/...` 格式）。脚本仅在目标文件不存在时安装；如需用仓库中的配置替换已有文件，显式传入 `--force`。启动 Jenkins 后，在插件管理页面刷新更新中心数据。

Jenkins 数据目录、插件、缓存、用户数据和密码继续保存在 Git 忽略的 `JENKINS_HOME` 中，不要提交这些运行数据。
