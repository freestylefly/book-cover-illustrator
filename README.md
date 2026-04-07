# Book Cover Illustrator —— 书籍章节配图生成助手

> 为场景化实操指南类书籍生成风格统一的章节题图，全书一套视觉语言，告别配图风格混乱。

## 这是什么？

`book-cover-illustrator` 是一个 AI Agent Skill，专为书籍写作场景设计。它能根据你提供的章节信息，自动生成**扁平化 2.5D 插画风格**的章节题图，并确保全书所有配图的视觉风格高度统一。

## 核心特性

- 🎨 **风格锁定**：科技蓝（#4A90D9）+ 暖橙（#FF8C42）+ 浅灰背景（#F5F7FA），全书统一
- 📐 **16:9 横版**：标准章节题图比例，适配各类排版需求
- 🤖 **一键生成**：提供章节主题和关键词，自动构建 Prompt 并调用 API 生成
- 📚 **全书规划**：内置 10 章配图元素参考表，每章都有对应的视觉方案
- 🔄 **失败重试**：内置自动重试机制，提升生成成功率

## 视觉风格

| 属性 | 规范 |
|------|------|
| 风格 | 扁平化 2.5D 等距插画 |
| 主色 | 科技蓝 #4A90D9 |
| 强调色 | 暖橙 #FF8C42 |
| 背景色 | 浅灰 #F5F7FA |
| 比例 | 16:9 横版（1920x1080） |
| 限制 | 无真人、无文字、无品牌 Logo |

## 快速开始

### 安装

```bash
git clone https://github.com/freestylefly/book-cover-illustrator.git
```

### 配置 API Key

```bash
export CANGHE_API_KEY="your-api-key-here"
```

### 生成配图

```bash
bash scripts/generate.sh \
  --prompt "Generate a wide 16:9 landscape image (1920x1080 pixels): A flat 2.5D isometric illustration for a book chapter cover about workplace office productivity skills. The scene shows a modern desk setup with a laptop displaying a daily report, surrounded by floating icons: an email envelope, a calendar, a meeting video call window, and a clipboard with checkmarks. Use a vivid tech-blue (#4A90D9) and warm-orange (#FF8C42) color palette on a light gray (#F5F7FA) background. Make the orange color prominent in 2-3 key elements for visual contrast. The style should be clean flat design with subtle 3D depth, no real people, friendly and professional. Centered composition with ample white space on both sides. No text in the image. The image MUST be in 16:9 wide landscape aspect ratio." \
  --output "./ch4_cover.png"
```

### 在 Agent 中使用

如果你使用 Claude Code 等 AI Agent，只需将本项目放入 Skills 目录，然后对 Agent 说：

```
帮我生成第4章的章节题图。
第4章：职场办公与沟通类 Skills 的创建与应用
涉及场景：日报周报、工作总结、高效开会、邮件处理、活动策划
```

Agent 会自动读取 `SKILL.md` 中的视觉规范，构建 Prompt，调用脚本生成图片。

## 文件结构

```
book-cover-illustrator/
├── SKILL.md              # Skill 核心指令（视觉规范 + 使用流程）
├── scripts/
│   └── generate.sh       # 生图脚本（调用 Canghe API）
├── README.md             # 项目说明
└── LICENSE               # MIT 开源协议
```

## 依赖

- `bash`（macOS / Linux 自带）
- `curl`（HTTP 请求）
- `python3`（JSON 处理 & base64 解码）
- Canghe API Key（通过 https://canghe.ai 获取）

## 许可证

MIT License

## 作者

苍何（[@freestylefly](https://github.com/freestylefly)）

---

> **风格统一是书籍配图的第一优先级。宁可单张图不够惊艳，也不要破坏全书的视觉和谐。**
