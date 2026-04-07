#!/usr/bin/env bash
#
# book-cover-illustrator 生图脚本
# 调用 Canghe API 生成书籍配图（支持章节题图和场景插图）
#
# 用法:
#   bash generate.sh --prompt "英文Prompt" --output "./ch4_cover.png"
#   bash generate.sh --prompt "英文Prompt" --output "./ch4_cover.png" --ratio "4:3"
#   bash generate.sh --prompt "英文Prompt" --output "./ch4_cover.png" --api-key "sk-xxx"

set -euo pipefail

# 默认值
API_BASE="https://api.canghe.ai/v1/chat/completions"
MODEL="gemini-3.1-flash-image-preview"
OUTPUT="output.png"
PROMPT=""
API_KEY="${CANGHE_API_KEY:-}"
MAX_RETRIES=1
RATIO="16:9"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    echo "用法: bash generate.sh [选项]"
    echo ""
    echo "选项:"
    echo "  --prompt     生图 Prompt（英文，必填）"
    echo "  --output     输出文件路径（默认: output.png）"
    echo "  --ratio      图片比例（默认: 16:9，可选: 4:3）"
    echo "  --api-key    Canghe API Key（可选，也可通过 CANGHE_API_KEY 环境变量设置）"
    echo "  --model      模型名称（默认: gemini-3.1-flash-image-preview）"
    echo "  --help       显示帮助信息"
    exit 0
}

# 解析参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        --prompt)   PROMPT="$2"; shift 2 ;;
        --output)   OUTPUT="$2"; shift 2 ;;
        --ratio)    RATIO="$2"; shift 2 ;;
        --api-key)  API_KEY="$2"; shift 2 ;;
        --model)    MODEL="$2"; shift 2 ;;
        --help)     usage ;;
        *)          echo -e "${RED}未知参数: $1${NC}"; usage ;;
    esac
done

# 参数检查
if [[ -z "$PROMPT" ]]; then
    echo -e "${RED}错误: 必须提供 --prompt 参数${NC}"
    usage
fi

if [[ -z "$API_KEY" ]]; then
    echo -e "${RED}错误: 未设置 API Key。请通过 --api-key 参数或 CANGHE_API_KEY 环境变量提供${NC}"
    exit 1
fi

# 比例校验
if [[ "$RATIO" != "16:9" && "$RATIO" != "4:3" && "$RATIO" != "3:2" ]]; then
    echo -e "${RED}错误: 不支持的比例 $RATIO（支持: 16:9, 4:3, 3:2）${NC}"
    exit 1
fi

# 根据比例确定类型标签
case "$RATIO" in
    "16:9") TYPE_LABEL="章节题图" ;;
    "4:3")  TYPE_LABEL="场景插图" ;;
    "3:2")  TYPE_LABEL="场景插图" ;;
esac

# 确保输出目录存在
OUTPUT_DIR=$(dirname "$OUTPUT")
if [[ "$OUTPUT_DIR" != "." ]]; then
    mkdir -p "$OUTPUT_DIR"
fi

# 构建请求体（转义 Prompt 中的特殊字符）
build_request_body() {
    python3 -c "
import json, sys
prompt = sys.argv[1]
body = {
    'model': sys.argv[2],
    'messages': [{
        'role': 'user',
        'content': prompt
    }],
    'max_tokens': 4096
}
print(json.dumps(body, ensure_ascii=False))
" "$PROMPT" "$MODEL"
}

# 从响应中提取 base64 图片并保存
extract_and_save_image() {
    local response="$1"
    local output_path="$2"

    python3 -c "
import json, base64, re, sys

try:
    data = json.loads(sys.argv[1])
except json.JSONDecodeError as e:
    print(f'JSON 解析失败: {e}', file=sys.stderr)
    sys.exit(1)

# 提取 content
try:
    content = data['choices'][0]['message']['content']
except (KeyError, IndexError) as e:
    print(f'响应结构异常: {e}', file=sys.stderr)
    print(f'响应内容: {json.dumps(data, ensure_ascii=False)[:500]}', file=sys.stderr)
    sys.exit(1)

# 尝试匹配 data URI 格式
match = re.search(r'data:image/(png|jpeg|jpg|webp);base64,([A-Za-z0-9+/=]+)', content)
if match:
    b64 = match.group(2)
    img_bytes = base64.b64decode(b64)
    with open(sys.argv[2], 'wb') as f:
        f.write(img_bytes)
    print(f'OK|{len(img_bytes)}')
    sys.exit(0)

# 尝试匹配纯 base64 块
match2 = re.search(r'[A-Za-z0-9+/]{200,}={0,2}', content)
if match2:
    b64 = match2.group(0)
    try:
        img_bytes = base64.b64decode(b64)
        with open(sys.argv[2], 'wb') as f:
            f.write(img_bytes)
        print(f'OK|{len(img_bytes)}')
        sys.exit(0)
    except Exception:
        pass

print('FAIL|未找到图片数据', file=sys.stderr)
print(f'响应内容前 300 字符: {content[:300]}', file=sys.stderr)
sys.exit(1)
" "$response" "$output_path"
}

# 主流程
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Book Cover Illustrator - ${TYPE_LABEL}生成${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}模型:${NC} $MODEL"
echo -e "${YELLOW}比例:${NC} $RATIO ($TYPE_LABEL)"
echo -e "${YELLOW}输出:${NC} $OUTPUT"
echo -e "${YELLOW}Prompt:${NC} ${PROMPT:0:80}..."
echo ""

REQUEST_BODY=$(build_request_body)

attempt=0
while [[ $attempt -le $MAX_RETRIES ]]; do
    if [[ $attempt -gt 0 ]]; then
        echo -e "${YELLOW}第 $((attempt)) 次重试...${NC}"
    fi

    echo -e "${BLUE}正在调用 Canghe API 生成${TYPE_LABEL}...${NC}"

    RESPONSE=$(curl -s --max-time 120 \
        "$API_BASE" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$REQUEST_BODY" 2>&1)

    CURL_EXIT=$?
    if [[ $CURL_EXIT -ne 0 ]]; then
        echo -e "${RED}网络请求失败 (exit code: $CURL_EXIT)${NC}"
        attempt=$((attempt + 1))
        continue
    fi

    RESULT=$(extract_and_save_image "$RESPONSE" "$OUTPUT" 2>/dev/null) || true

    if [[ "$RESULT" == OK* ]]; then
        SIZE=$(echo "$RESULT" | cut -d'|' -f2)
        echo ""
        echo -e "${GREEN}生成成功！${NC}"
        echo -e "${GREEN}类型: $TYPE_LABEL ($RATIO)${NC}"
        echo -e "${GREEN}文件: $OUTPUT${NC}"
        echo -e "${GREEN}大小: $((SIZE / 1024)) KB${NC}"
        exit 0
    else
        echo -e "${RED}图片提取失败${NC}"
        extract_and_save_image "$RESPONSE" "$OUTPUT" 2>&1 || true
        attempt=$((attempt + 1))
    fi
done

echo -e "${RED}生成失败，已达最大重试次数${NC}"
exit 1
