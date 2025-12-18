<div align="center">
    <img src="imgs/foam2.png" alt="jpg name" width="30%"/>
</div>

# 🚀 部署方式

<div align="center">

[**📖 项目介绍**](./README.md) &nbsp;|&nbsp; [**🚀 部署教程**](./DEPLOY.md) &nbsp;|&nbsp; [**🎨 界面预览**](./PREVIEW.md)

</div>

## 本地运行

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
      # 配置hosts 否则无法访问tmdb接口
      # 18.161.6.73 api.themoviedb.org
      # 18.161.6.73 api.tmdb.org
      # 18.161.6.73 www.themoviedb.org
      # 18.161.6.73 api.thetvdb.com
      # 104.19.223.128 api.nullbr.eu.org
      - /etc/hosts:/etc/hosts
    container_name: foam-api
    restart: always
    environment:
      #db:3306 使用的是容器内部的端口 不是映射完的端口
      - SPRING_DATASOURCE_URL=jdbc:mysql://db:3306/foam-api?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=GMT%2B8&allowPublicKeyRetrieval=true
      - SPRING_DATASOURCE_USERNAME=root
      - SPRING_DATASOURCE_PASSWORD=78FRC#5BqnOk0ppk
#      - EMBY_APIKEY=apikey
#      - EMBY_URL=http://ip:port/emby/
#      - EMBY_COPYFROMUSERID=复制emby用户id # 复制emby用户权限
      # 需要配置tmdb接口hosts
      - TMDB_APITOKEN=tmdb api token
      - TMDB_APIKEY=tmdb api key
      - TMDB_IMAGE_URL=https://image.tmdb.org/t/p/original
      - TZ=Asia/Shanghai
      # 代理地址
      - HTTP_PROXY_ENABLED=true
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

## 🐳 Docker 部署

```shell
docker-compose up -d
```

访问：http://localhost:8081

---

## ⚙️ 配置说明

### 添加Emby入库通知

登录Emby管理后台，点击左侧导航栏的`系统` -> `通知` -> `添加通知` -> `Webhooks`

输入地址http://ip:8080/emby/notifier

勾选application/json 添加媒体库 播放行为 用户验证等

### 添加MoviePilot配置

系统配置 ->moviepilot配置

### 添加企业微信通知（webhook）

企业微信新建企业-> 新建群聊-> 群聊中消息推送添加机器人-> 复制webhook地址

Foam管理后台通知渠道-> 企业微信机器人-> 粘贴webhook地址-> 保存

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

### ✅ **配置汇总**

| 参数名 | 对应后台位置 | 说明 |
| :--- | :--- | :--- |
| `corpId` | 我的企业 -> 企业信息 | 企业唯一ID |
| `agentId` | 应用管理 -> 应用详情 | 机器人的ID |
| `appSecret` | 应用管理 -> 应用详情 | 机器人的密钥 (需扫码查看) |
| `token` | 应用管理 -> 接收消息 -> API接收 | 用于验证回调请求 |
| `encodingAesKey` | 应用管理 -> 接收消息 -> API接收 | 用于加密消息内容 |
