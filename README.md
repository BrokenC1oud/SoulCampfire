# Soul Campfire

一个群聊修仙小游戏

## Docker

准备运行配置和数据库目录：

```sh
cp .env.example .env
mkdir -p data
```

编辑 `.env` 填入 `ONEBOT_TOKEN`，然后启动：

```sh
docker compose up -d
```

容器会将 `.env` 以只读方式挂载到 `/app/.env`，SQLite 数据库及其 WAL/SHM 文件保存在宿主机的 `./data` 目录。

GitHub Actions 会在 `main`/`master` 分支和 `v*` 标签推送到 GitHub Container Registry。部署时将 Compose 文件中的镜像替换为仓库地址，或设置 `GITHUB_REPOSITORY` 环境变量：

```sh
GITHUB_REPOSITORY=owner/repository docker compose pull
GITHUB_REPOSITORY=owner/repository docker compose up -d
```
