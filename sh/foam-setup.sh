#!/usr/bin/env bash
set -euo pipefail

# ---------------- defaults (先定义默认值，彻底避免 unbound) ----------------
DEFAULT_API_PORT="8080"
DEFAULT_WEB_PORT="8081"
DEFAULT_MYSQL_PORT="3306"

DEFAULT_FOAM_DATA_DIR="./data"
DEFAULT_MYSQL_DATA_DIR="./mysql-data"

DEFAULT_MOUNT_HOSTS="true"
DEFAULT_HOSTS_PATH="/etc/hosts"

DEFAULT_MYSQL_DB="foam-api"
DEFAULT_MYSQL_ROOT_PASSWORD="78FRC#5BqnOk0ppk"

DEFAULT_TMDB_APITOKEN="tmdb api token"
DEFAULT_TMDB_APIKEY="tmdb api key"
DEFAULT_TMDB_IMAGE_URL="https://image.tmdb.org/t/p/original"

DEFAULT_TZ="Asia/Shanghai"

DEFAULT_HTTP_PROXY_ENABLED="false"
DEFAULT_HTTP_PROXY="http://ip:port"
DEFAULT_HTTPS_PROXY="http://ip:port"
DEFAULT_NO_PROXY="172.17.0.1,127.0.0.1,localhost,foam-api-search,selenium-chrome"

DEFAULT_SELENIUM_PLATFORM="linux/amd64"
DEFAULT_SELENIUM_MAX_SESSIONS="4"
DEFAULT_SHM_SIZE="2gb"

LICENSE_FILE_IN_CONTAINER="/data/license.dat"

# ---------------- 关键修复：兼容 curl | bash 的交互读取 ----------------
PROMPT_FD=""
if [[ -r /dev/tty ]]; then
  exec 3</dev/tty
  PROMPT_FD="3"
elif [[ -t 0 ]]; then
  PROMPT_FD="0"
else
  PROMPT_FD="" # 无 tty：走默认值（非交互）
fi

# ---------------- helpers ----------------
prompt() {
  local label="$1"
  local def="${2-}"
  local v=""

  if [[ -z "${PROMPT_FD}" ]]; then
    printf '%s\n' "${def}"
    return 0
  fi

  if [[ -n "$def" ]]; then
    read -r -u "${PROMPT_FD}" -p "$label (default: $def): " v || v=""
    printf '%s\n' "${v:-$def}"
  else
    read -r -u "${PROMPT_FD}" -p "$label: " v || v=""
    printf '%s\n' "$v"
  fi
}

prompt_bool() {
  local label="$1"
  local def="${2:-true}"
  local v
  v="$(prompt "$label [true/false]" "$def")"
  v="$(printf '%s' "$v" | tr '[:upper:]' '[:lower:]')"
  case "$v" in
    true|t|yes|y|1) echo "true" ;;
    false|f|no|n|0) echo "false" ;;
    *) echo "$def" ;;
  esac
}

yaml_escape() {
  local s="${1-}"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  echo "$s"
}

ensure_number() {
  local v="${1-}"
  local def="$2"
  if [[ "$v" =~ ^[0-9]+$ ]]; then
    echo "$v"
  else
    echo "$def"
  fi
}

# ---------------- 先初始化变量（杜绝 set -u unbound） ----------------
API_PORT="$DEFAULT_API_PORT"
WEB_PORT="$DEFAULT_WEB_PORT"
MYSQL_PORT="$DEFAULT_MYSQL_PORT"

FOAM_DATA_DIR="$DEFAULT_FOAM_DATA_DIR"
MYSQL_DATA_DIR="$DEFAULT_MYSQL_DATA_DIR"

MOUNT_HOSTS="$DEFAULT_MOUNT_HOSTS"
HOSTS_PATH="$DEFAULT_HOSTS_PATH"

MYSQL_DB="$DEFAULT_MYSQL_DB"
MYSQL_ROOT_PASSWORD="$DEFAULT_MYSQL_ROOT_PASSWORD"

TMDB_APITOKEN="$DEFAULT_TMDB_APITOKEN"
TMDB_APIKEY="$DEFAULT_TMDB_APIKEY"
TMDB_IMAGE_URL="$DEFAULT_TMDB_IMAGE_URL"

TZ="$DEFAULT_TZ"
AVATARS_BASE_URL_DEFAULT=""
AVATARS_BASE_URL=""
EMBY_HUB_SEARCH_URL=""

HTTP_PROXY_ENABLED="$DEFAULT_HTTP_PROXY_ENABLED"
HTTP_PROXY=""
HTTPS_PROXY=""
NO_PROXY="$DEFAULT_NO_PROXY"

SELENIUM_PLATFORM="$DEFAULT_SELENIUM_PLATFORM"
SELENIUM_MAX_SESSIONS="$DEFAULT_SELENIUM_MAX_SESSIONS"
SHM_SIZE="$DEFAULT_SHM_SIZE"

# ---------------- interactive inputs ----------------
echo "== Foam docker-compose 交互生成器 =="
echo

# ---- ports ----
API_PORT="$(ensure_number "$(prompt "Foam API 外部端口(映射到容器8080)" "$DEFAULT_API_PORT")" "$DEFAULT_API_PORT")"
WEB_PORT="$(ensure_number "$(prompt "Foam Web 外部端口(映射到容器80)" "$DEFAULT_WEB_PORT")" "$DEFAULT_WEB_PORT")"
MYSQL_PORT="$(ensure_number "$(prompt "MySQL 外部端口(映射到容器3306)" "$DEFAULT_MYSQL_PORT")" "$DEFAULT_MYSQL_PORT")"
echo

# ---- mounts ----
FOAM_DATA_DIR="$(prompt "Foam API 数据目录(宿主机挂载到容器 /data)" "$DEFAULT_FOAM_DATA_DIR")"
MYSQL_DATA_DIR="$(prompt "MySQL 数据目录(宿主机挂载到容器 /var/lib/mysql)" "$DEFAULT_MYSQL_DATA_DIR")"
: "${FOAM_DATA_DIR:=$DEFAULT_FOAM_DATA_DIR}"
: "${MYSQL_DATA_DIR:=$DEFAULT_MYSQL_DATA_DIR}"

MOUNT_HOSTS="$(prompt_bool "是否挂载 /etc/hosts 到容器(解决TMDB DNS问题)" "$DEFAULT_MOUNT_HOSTS")"
HOSTS_PATH="$DEFAULT_HOSTS_PATH"
if [[ "$MOUNT_HOSTS" == "true" ]]; then
  HOSTS_PATH="$(prompt "宿主机 hosts 路径" "$DEFAULT_HOSTS_PATH")"
  : "${HOSTS_PATH:=$DEFAULT_HOSTS_PATH}"
fi
echo

# ---- mysql ----
MYSQL_DB="$(prompt "MySQL 数据库名" "$DEFAULT_MYSQL_DB")"
MYSQL_ROOT_PASSWORD="$(prompt "MySQL root 密码(注意：会写入compose文件)" "$DEFAULT_MYSQL_ROOT_PASSWORD")"
: "${MYSQL_DB:=$DEFAULT_MYSQL_DB}"
: "${MYSQL_ROOT_PASSWORD:=$DEFAULT_MYSQL_ROOT_PASSWORD}"
echo

# ---- tmdb ----
TMDB_APITOKEN="$(prompt "TMDB_APITOKEN" "$DEFAULT_TMDB_APITOKEN")"
TMDB_APIKEY="$(prompt "TMDB_APIKEY" "$DEFAULT_TMDB_APIKEY")"
TMDB_IMAGE_URL="$(prompt "TMDB_IMAGE_URL" "$DEFAULT_TMDB_IMAGE_URL")"
: "${TMDB_APITOKEN:=$DEFAULT_TMDB_APITOKEN}"
: "${TMDB_APIKEY:=$DEFAULT_TMDB_APIKEY}"
: "${TMDB_IMAGE_URL:=$DEFAULT_TMDB_IMAGE_URL}"
echo

# ---- misc ----
TZ="$(prompt "时区 TZ" "$DEFAULT_TZ")"
: "${TZ:=$DEFAULT_TZ}"

: "${AVATARS_BASE_URL_DEFAULT:=http://localhost:${API_PORT}}"
AVATARS_BASE_URL="$(prompt "AVATARS_BASE_URL(外网可访问的地址，给头像用)" "$AVATARS_BASE_URL_DEFAULT")"
EMBY_HUB_SEARCH_URL="$(prompt "EMBY_HUB_SEARCH_URL(可留空)" "")"
: "${AVATARS_BASE_URL:=$AVATARS_BASE_URL_DEFAULT}"
: "${EMBY_HUB_SEARCH_URL:=}"
echo

# ---- proxy ----
HTTP_PROXY_ENABLED="$(prompt_bool "是否启用代理 HTTP_PROXY_ENABLED" "$DEFAULT_HTTP_PROXY_ENABLED")"
: "${HTTP_PROXY_ENABLED:=$DEFAULT_HTTP_PROXY_ENABLED}"

if [[ "$HTTP_PROXY_ENABLED" == "true" ]]; then
  HTTP_PROXY="$(prompt "HTTP_PROXY" "$DEFAULT_HTTP_PROXY")"
  HTTPS_PROXY="$(prompt "HTTPS_PROXY" "$DEFAULT_HTTPS_PROXY")"
  NO_PROXY="$(prompt "NO_PROXY" "$DEFAULT_NO_PROXY")"
else
  HTTP_PROXY=""
  HTTPS_PROXY=""
  NO_PROXY="$(prompt "NO_PROXY(建议保留内网/本地)" "$DEFAULT_NO_PROXY")"
fi
: "${HTTP_PROXY:=}"
: "${HTTPS_PROXY:=}"
: "${NO_PROXY:=$DEFAULT_NO_PROXY}"
echo

# ---- selenium ----
SELENIUM_PLATFORM="$(prompt "selenium-chrome platform(Apple Silicon 常用 linux/amd64)" "$DEFAULT_SELENIUM_PLATFORM")"
SELENIUM_MAX_SESSIONS="$(prompt "SE_NODE_MAX_SESSIONS" "$DEFAULT_SELENIUM_MAX_SESSIONS")"
SHM_SIZE="$(prompt "shm_size(避免Chrome崩)" "$DEFAULT_SHM_SIZE")"
: "${SELENIUM_PLATFORM:=$DEFAULT_SELENIUM_PLATFORM}"
: "${SELENIUM_MAX_SESSIONS:=$DEFAULT_SELENIUM_MAX_SESSIONS}"
: "${SHM_SIZE:=$DEFAULT_SHM_SIZE}"
echo

# ---------------- prepare dirs ----------------
mkdir -p "$FOAM_DATA_DIR" "$MYSQL_DATA_DIR"

# ---------------- write docker-compose.yml ----------------
HOSTS_VOLUME_LINE=""
if [[ "$MOUNT_HOSTS" == "true" ]]; then
  HOSTS_VOLUME_LINE="      - $(yaml_escape "$HOSTS_PATH"):/etc/hosts"
fi

cat > docker-compose.yml <<EOF
version: "3"

services:
  foam-api:
    image: ciwei123321/foam-api:latest
    container_name: foam-api
    privileged: true
    restart: always
    ports:
      - "${API_PORT}:8080"
    volumes:
      - $(yaml_escape "$FOAM_DATA_DIR"):/data
${HOSTS_VOLUME_LINE}
    environment:
      SPRING_DATASOURCE_URL: "jdbc:mysql://db:3306/${MYSQL_DB}?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=GMT%2B8&allowPublicKeyRetrieval=true"
      SPRING_DATASOURCE_USERNAME: "root"
      SPRING_DATASOURCE_PASSWORD: "$(yaml_escape "$MYSQL_ROOT_PASSWORD")"

      TMDB_APITOKEN: "$(yaml_escape "$TMDB_APITOKEN")"
      TMDB_APIKEY: "$(yaml_escape "$TMDB_APIKEY")"
      TMDB_IMAGE_URL: "$(yaml_escape "$TMDB_IMAGE_URL")"
      TZ: "$(yaml_escape "$TZ")"

      HTTP_PROXY_ENABLED: "$(yaml_escape "$HTTP_PROXY_ENABLED")"
      HTTP_PROXY: "$(yaml_escape "$HTTP_PROXY")"
      HTTPS_PROXY: "$(yaml_escape "$HTTPS_PROXY")"
      NO_PROXY: "$(yaml_escape "$NO_PROXY")"

      LICENSE_FILE: "$(yaml_escape "$LICENSE_FILE_IN_CONTAINER")"
      EMBY_HUB_SEARCH_URL: "$(yaml_escape "$EMBY_HUB_SEARCH_URL")"
      AVATARS_BASE_URL: "$(yaml_escape "$AVATARS_BASE_URL")"
      SELENIUM_REMOTE_URL: "http://selenium-chrome:4444/wd/hub"

    networks:
      - foam-network
    depends_on:
      - db
      - selenium-chrome

  db:
    image: mysql:8.4.6
    container_name: mysql_container
    restart: always
    ports:
      - "${MYSQL_PORT}:3306"
    volumes:
      - $(yaml_escape "$MYSQL_DATA_DIR"):/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: "$(yaml_escape "$MYSQL_ROOT_PASSWORD")"
      MYSQL_DATABASE: "$(yaml_escape "$MYSQL_DB")"
      TZ: "$(yaml_escape "$TZ")"
      LANG: "en_US.UTF-8"
    command:
      - mysqld
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_unicode_ci
      - --group_concat_max_len=102400
    networks:
      - foam-network

  foam:
    image: ciwei123321/foam:latest
    container_name: foam
    restart: always
    ports:
      - "${WEB_PORT}:80"
    environment:
      API_BASE_URL: "http://foam-api:8080"
      TZ: "$(yaml_escape "$TZ")"
      IMAGE_URL: "https://image.tmdb.org/t/p/"
    networks:
      - foam-network
    depends_on:
      - foam-api

  selenium-chrome:
    image: selenium/standalone-chrome:latest
    container_name: selenium-chrome
    platform: "${SELENIUM_PLATFORM}"
    restart: always
    shm_size: "${SHM_SIZE}"
    environment:
      SE_NODE_MAX_SESSIONS: "$(yaml_escape "$SELENIUM_MAX_SESSIONS")"
    networks:
      - foam-network

networks:
  foam-network:
EOF

echo "✅ 已生成：docker-compose.yml"
echo "✅ 已确保数据目录存在："
echo "   - Foam 数据目录: $FOAM_DATA_DIR"
echo "   - MySQL 数据目录: $MYSQL_DATA_DIR"
echo "   - License 固定路径(容器内): $LICENSE_FILE_IN_CONTAINER"
echo

echo "== 常用命令 =="
echo "启动:   docker compose up -d"
echo "日志:   docker compose logs -f --tail=200"
echo "停止:   docker compose stop"
echo "启动(已停止的): docker compose start"
echo "重启:   docker compose restart"
echo "删除(含网络，不删数据目录): docker compose down"