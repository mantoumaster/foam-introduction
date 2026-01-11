<div align="center">
    <img src="imgs/foam2.png" alt="jpg name" width="30%"/>
</div>

# 🚀 部署方式

<div align="center">

[![项目介绍](https://img.shields.io/badge/📖_项目介绍-grey?style=for-the-badge&logoColor=white)](./README.md) [![部署教程](https://img.shields.io/badge/🚀_部署教程-FC5531?style=for-the-badge&logoColor=white)](./DEPLOY.md) [![界面预览](https://img.shields.io/badge/🎨_界面预览-grey?style=for-the-badge&logoColor=white)](./PREVIEW.md)

</div>

## 部署方式一

🎯 一键部署脚本（推荐）

使用交互式脚本快速生成 `docker-compose.yml` 配置文件，无需手动编辑配置。

### 使用方法

**方式一：直接运行远程脚本**

```bash
# 创建部署目录并进入
mkdir -p foam && cd foam

# 下载并运行脚本
curl -fsSL https://raw.githubusercontent.com/ciweigg2/foam-introduction/main/sh/foam-setup.sh | bash
```

**方式二：下载后运行**

```bash
# 创建部署目录并进入
mkdir -p foam && cd foam

# 下载脚本
curl -fsSL -o foam-setup.sh https://raw.githubusercontent.com/ciweigg2/foam-introduction/main/sh/foam-setup.sh

# 添加执行权限
chmod +x foam-setup.sh

# 运行脚本
./foam-setup.sh
```

### 运行完成后

脚本会自动在当前目录生成 `docker-compose.yml` 文件，并创建所需的数据目录。

```bash
# 启动服务
docker compose up -d

# 查看日志
docker compose logs -f --tail=200

# 停止服务
docker compose stop

# 重启服务
docker compose restart

# 删除服务（保留数据）
docker compose down
```

访问地址：`http://localhost:8081`（或你配置的 Web 端口）

---

## 部署方式二

🎯 手动部署（不建议没基础的用户使用）

docker-compose 本地运行

```shell
version: '3'
services:
  foam-api:
    image: ciwei123321/foam-api:latest
    privileged: true
    ports:
      - "8080:8080"
    volumes:
      - ./data:/data
      - /etc/hosts:/etc/hosts
    container_name: foam-api
    restart: always
    environment:
      #db:3306 使用的是容器内部的端口 不是映射完的端口
      - SPRING_DATASOURCE_URL=jdbc:mysql://db:3306/foam-api?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=GMT%2B8&allowPublicKeyRetrieval=true
      - SPRING_DATASOURCE_USERNAME=root
      - SPRING_DATASOURCE_PASSWORD=78FRC#5BqnOk0ppk
      # 需要配置tmdb接口hosts
      - TMDB_APITOKEN=tmdb api token
      - TMDB_APIKEY=tmdb api key
      - TMDB_IMAGE_URL=https://image.tmdb.org/t/p/original
      - TZ=Asia/Shanghai
      # 代理地址
      - HTTP_PROXY_ENABLED=false
      - HTTP_PROXY=http://ip:port
      - HTTPS_PROXY=http://ip:port
      - NO_PROXY=172.17.0.1,127.0.0.1,localhost,foam-api-search,selenium-chrome
      # lisence配置文件
      - LICENSE_FILE=/data/license.dat
      # 搜索接口地址 pansou地址
      - EMBY_HUB_SEARCH_URL=
      #上传头像访问地址 也就是8080端口 需要外网能访问的ip
      - AVATARS_BASE_URL=http://localhost:8080
      - SELENIUM_REMOTE_URL=http://selenium-chrome:4444/wd/hub
    networks:
      - foam-network
    links:
      - db
      - selenium-chrome
    depends_on:
      - db
      - selenium-chrome

  db:
    image: mysql:8.4.6
    container_name: mysql_container
    environment:
      MYSQL_ROOT_PASSWORD: 78FRC#5BqnOk0ppk
      MYSQL_DATABASE: foam-api
      TZ: "Asia/Shanghai"
      LANG: en_US.UTF-8
    command:
      - mysqld
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_unicode_ci
      - --group_concat_max_len=102400
    ports:
      - "3306:3306"
    volumes:
      - ./mysql-data:/var/lib/mysql
    restart: always
    networks:
      - foam-network

  foam:
    image: ciwei123321/foam:latest
    container_name: foam
    restart: always
    ports:
      - "8081:80"
    environment:
      API_BASE_URL: "http://foam-api:8080"
      TZ: Asia/Shanghai
      IMAGE_URL: https://image.tmdb.org/t/p/
    networks:
      - foam-network
    links:
      - foam-api
    depends_on:
      - foam-api
        
  selenium-chrome:
    image: selenium/standalone-chrome:latest
    platform: linux/amd64
    ports:
      - "4444:4444"
      - "7900:7900"
    shm_size: "2gb"
    environment:
      - SE_NODE_MAX_SESSIONS=4
    networks:
      - foam-network

networks:
  foam-network:
```

### 🐳 Docker 部署

```shell
docker-compose up -d
```

访问：http://localhost:8081

---

# ⚙️ 配置说明

## 添加Emby入库通知

登录Emby管理后台，点击左侧导航栏的`系统` -> `通知` -> `添加通知` -> `Webhooks`

输入地址http://ip:8080/emby/notifier

勾选application/json 添加媒体库 播放行为 用户验证等

## 添加MoviePilot配置

系统配置 ->moviepilot配置

## 添加企业微信通知（webhook）

企业微信新建企业-> 新建群聊-> 群聊中消息推送添加机器人-> 复制webhook地址

Foam管理后台通知渠道-> 企业微信机器人-> 粘贴webhook地址-> 保存

## 添加企业微信应用通知（企业微信应用）

### 🛠️ **如何获取企业微信参数** (企业微信应用)

### 🏢 **1. 企业 ID (`corpId`)**
> 🔑 这是你整个企业微信组织的唯一标识。

*   **路径**：登录企业微信管理后台 -> **我的企业** -> **企业信息** -> 最下方的 **企业ID**
*   **示例**：`w123...`

### 🤖 **2. 应用 ID (`agentId`) & 应用密钥 (`appSecret`)**
> 📱 这是你创建的"自建应用"（机器人）的身份证明。

1.  **路径**：登录后台 -> **应用管理** -> 在"自建"栏下点击（或创建）你的应用。
2.  **AgentId**：在应用详情页上方可以看到 `AgentId`（数字，如 `123`）。
3.  **Secret**：点击 `Secret` 旁的 **查看** 链接 -> 手机企业微信扫码 -> 获得一串长字符串（如 `J123...`）。

### 🔐 **3. Token & EncodingAESKey**
> 📡 这是用于接收消息和加密通讯的配置。

1.  **路径**：在同一个应用的详情页 -> 向下滚动找到 **接收消息** -> 点击 **设置 API 接收**。
2.  **Token**：点击 **随机获取** 按钮，或者自己填写（如 `W123...`）。
3.  **EncodingAESKey**：点击 **随机获取** 按钮（如 `X123...`）。
4.  **注意**：在这个页面你还需要填写 **URL**（回调地址 机器人/应用回调地址指向 `https://<your-domain>/wechat/bot`），确保你的服务已经启动并能被外网访问，点击"保存"时企业微信会发送请求验证这个 Token 和 Key。

## 积分系统

添加通知渠道->积分机器人->新建机器人（自行百度）->进入群聊成为管理员->使用命令操作机器人就行

**积分可以配置对应奖品 兑换服务器 续费服务器等 这个完全是管理员控制的 推荐公益服使用**

> 部分命令参考

```shell
基础命令
/checkin - 每日签到
/points - 查询积分
/leaderboard - 积分排行榜
/transfer - 积分互转 (用法: /transfer @用户 积分)

抽奖与娱乐
/lottery - 抽奖 (支持 publish 发布, join 参与, status 查看状态)
/blackjack - 🃏 21点游戏 (别名: /bj)
/dice - 🎲 骰子比大小
/slots - 🎰 老虎机

兑换与服务
/exchange - 查看可兑换项目 (列出所有可兑换的 Emby 账号/时长等)
/prizes - 积分奖品列表 (列出实物或虚拟奖品)
/redeem - 积分兑换账号 (用法: /redeem 配置编号 Emby用户名)
/renew - 积分续期账号 (用法: /renew Emby用户名|天数，通常需管理员权限或特殊配置)
```

## 播放统计

### 基于算法

系统播放统计是根据算法统计的（不基于Playback Reporting插件）

### 基于Playback Reporting插件（如果获取不到数据 安装插件就行）

部分功能可以基于Playback Reporting插件实现的