## 一键脚本
```
bash <(curl -fsSL https://raw.githubusercontent.com/passeway/tuic/main/tuic.sh)
```
## 一键卸载
```
systemctl stop tuic && systemctl disable --now tuic.service && rm -rf /opt/tuic
```
## 常用指令
| 命令 | 说明 |
|------|------|
| `systemctl status tuic` | 查看 TUIC 状态 |
| `systemctl start tuic` | 启动 TUIC 服务 |
| `systemctl stop tuic` | 停止 TUIC 服务 |
| `systemctl restart tuic` | 重启 TUIC 服务 |
| `journalctl -u tuic` | 查看 TUIC 日志 |
| `journalctl -u tuic -f` | 跟踪 TUIC 日志 |
| `systemctl enable tuic` | 设置 TUIC 自启 |
| `systemctl disable tuic` | 取消 TUIC 自启 |
| `systemctl daemon-reload` | 刷新 TUIC 后台 |
