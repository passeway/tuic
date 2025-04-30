## 一键脚本
```
bash <(curl -fsSL https://raw.githubusercontent.com/passeway/tuic/main/tuic.sh)
```
## 一键卸载
```
systemctl stop tuic && systemctl disable --now tuic.service && rm -rf /opt/tuic
```
