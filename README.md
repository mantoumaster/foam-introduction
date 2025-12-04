<div align="center">
    <img src="imgs/foam2.png" alt="jpg name" width="30%"/>
</div>

# 🫧 Foam — Emby 管理系统

## 📌 版本信息（Version）

- 当前版本：**latest**
- 更新日志详见：[`版本更新`](./CHANGELOG.md)

---

## ✨ 功能亮点

- 🔥 全套 Emby 用户管理能力
- 🪄 精致 UI（玻璃拟态 + 高斯模糊）
- 📊 播放统计可视化
- 📬 多渠道通知（Tg、钉钉、企业微信）
- 🎫 卡密系统（支持自定义天数卡密） + 用户续费
- 🎬 影片请求中心
- 📱 完美适配移动端
- 🛥 支持多Emby服切换
- 🎯 求片自动关联MoviePilot订阅
- 🎯 支持自定义入库图片
- 🎯 支持自定义emby封面生成
- 🎯 求片支持审核操作

## [🚀 点击前往 Foam 群组聊天](https://t.me/FoamHub)

## 🚀 部署方式

### 本地运行

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
      - SPRING_DATASOURCE_PASSWORD=password
      # 需要配置tmdb接口hosts
      - TMDB_APITOKEN=tmdb api token
      - TMDB_APIKEY=tmdb api key
      - TMDB_IMAGE_URL=https://image.tmdb.org/t/p/original
      - TZ=Asia/Shanghai
      # 代理地址
      - HTTP_PROXY_ENABLED=true
      - HTTP_PROXY=http://ip:port
      - HTTPS_PROXY=http://ip:port
      - NO_PROXY=172.17.0.1,127.0.0.1,localhost,foam-api-search
      # lisence配置文件
      - LICENSE_FILE=/data/license.dat
      # 搜索接口地址 pansou地址
      - EMBY_HUB_SEARCH_URL=
      #上传头像访问地址 也就是8080端口 需要外网能访问的ip
      - AVATARS_BASE_URL=http://localhost:8080
    networks:
      - foam-network
    links:
      - db
    depends_on:
      - db

  db:
    image: mysql:8.4.6
    container_name: mysql_container
    environment:
      MYSQL_ROOT_PASSWORD: password
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

networks:
  foam-network:
```

### 🐳 Docker 部署

```shell
docker-compose up -d
```

### 添加Emby入库通知

登录Emby管理后台，点击左侧导航栏的`系统` -> `通知` -> `添加通知` -> `Webhooks`

输入地址http://ip:8080/emby/notifier

勾选application/json 添加媒体库 播放行为 用户验证等

### 添加MoviePilot配置

系统配置 ->moviepilot配置

访问：http://localhost:8081

### 添加企业微信通知

企业微信新建企业->新建群聊->群聊中消息推送添加机器人->复制webhook地址

Foam管理后台通知渠道->企业微信机器人->粘贴webhook地址->保存

## 🎨 系统界面展示

### 🖼️ 系统公告

![](imgs/系统公告.png)

### 🖼️ 主题中心

![](imgs/主题中心.png)

### 🖼️ 求片管理

![](imgs/求片管理.png)

![求片管理入库.png](imgs/%E6%B1%82%E7%89%87%E7%AE%A1%E7%90%86%E5%85%A5%E5%BA%93.png)

### 🖼️ 播放统计

![](imgs/播放统计.png)

### 🖼️ 系统配置

![](imgs/系统配置.png)

### 🖼️ 卡密管理

![](imgs/卡密管理.png)

### 🖼️ 播放汇总

![](imgs/播放汇总.png)

### 🖼️ 媒体库

![](imgs/媒体库.png)

### 🖼️ 求片中心

![](imgs/求片中心.png)

### 🖼️ 用户管理

![](imgs/用户管理.png)

### 🖼️ 仪表盘

![](imgs/仪表盘.png)

![](imgs/仪表盘2.png)

### 🖼️ 今日排行

![](imgs/今日排行.jpg)

### 🖼️ 开始播放

![](imgs/开始播放.png)

### 🖼️ 停止播放

![](imgs/停止播放.png)

### 🖼️ 入库通知

![](imgs/入库通知.png)

### 🖼️ 求片自动关联MoviePilot订阅

![求片订阅.png](imgs/求片订阅.png)

## 🧩 系统功能说明

### 👥 用户管理

- 查看用户列表
- 编辑用户资料
- 删除 / 禁用账号
- 同步 Emby 用户

### 🔑 用户续费

- 查看到期用户
- 延长有效期
- 批量续期

### 💳 卡密管理

- 批量生成卡密
- 卡密使用状态
- 卡密兑换续期

### 📈 播放统计

- 播放次数排行榜
- 用户观看排行
- 记录明细

### 🎬 请求中心

- 用户提交内容请求
- 管理员审核处理
- 请求状态跟踪

### 🔔 通知渠道

- 钉钉机器人
- Tg机器人
- 多渠道组合推送

### 📝 公告管理

- 发布系统公告
- 置顶 / 排序
- 多端展示

### 🛺 Emby多服务器支持

- 支持添加多个Emby服务器 无缝切换 数据隔离

### 🛺 支持自定义入库图片

![自定义横版.jpg](imgs/%E8%87%AA%E5%AE%9A%E4%B9%89%E6%A8%AA%E7%89%88.jpg)

![自定义竖版.jpg](imgs/%E8%87%AA%E5%AE%9A%E4%B9%89%E7%AB%96%E7%89%88.jpg)