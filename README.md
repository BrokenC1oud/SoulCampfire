# Soul Campfire

一个群聊修仙小游戏

## 部署

> [!WARNING]
> 本项目仍在开发中，且不提供数据迁移方法

### Onebot实现

首先你需要一个Onebot实现，推荐使用[SnowLuma](https://snowluma.github.io/)

``` sh
wget https://github.com/SnowLuma/SnowLuma/releases/download/v1.14.15/SnowLuma-v1.14.15-linux-x64.tar.gz
tar xzvf SnowLuma-v1.14.15-linux-x64.tar.gz
chmod +x ./launcher.sh
sudo ./launcher.sh
```

然后根据指引进入SnowLuma仪表盘，绑定账号

添加HTTP API：

|主机|端口|路径|
|---|---|---|
|127.0.0.1|3000|/|

复制出TOKEN填入.env ONEBOT_TOKEN

添加HTTP客户端：

|目标URL|
|---|
|<http://127.0.0.1:5700>|

### 本体

请使用 zig 0.16编译本项目

``` sh
git clone https://github.com/BrokenC1oud/SoulCampfire.git
cd SoulCampfire
zig build run
```
