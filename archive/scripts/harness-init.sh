#!/usr/bin/env bash
# ============================================================
# Harness Init — 项目初始化引导脚本 v1.0
# ============================================================
# 一键检测项目环境、引导填写上下文、自动部署 Harness Skill
#
# 用法：
#   ./harness-init.sh                          # 当前目录
#   ./harness-init.sh /path/to/project         # 指定项目目录
#   ./harness-init.sh --non-interactive         # 纯自动检测，不提问
# ============================================================

set -euo pipefail

# ── 颜色 ──────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── 参数解析 ──────────────────────────────────────
NON_INTERACTIVE=false
PROJECT_DIR="$(pwd)"

# 解析参数
for arg in "$@"; do
    case "$arg" in
        --non-interactive)
            NON_INTERACTIVE=true
            ;;
        -*)
            echo "❌ 未知选项: $arg"
            echo "用法: $0 [项目目录] [--non-interactive]"
            exit 1
            ;;
        *)
            PROJECT_DIR="$arg"
            ;;
    esac
done

if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ 目录不存在: $PROJECT_DIR"
    exit 1
fi
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

# ── 找到 Harness 源码位置 ──────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# 脚本放在 harness-research/scripts/ 下
# dev-harness-skill/ 在 harness-research/ 同级子目录
HARNESS_REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"            # harness-research/
HARNESS_SKILL_DIR="$HARNESS_REPO_DIR/dev-harness-skill"     # dev-harness-skill/

if [ ! -f "$HARNESS_SKILL_DIR/skill.md" ]; then
    echo "❌ 找不到 Harness Skill 源码 (skill.md)"
    echo "   请确保本脚本放在 dev-harness-skill/scripts/ 下"
    exit 1
fi

# ═══════════════════════════════════════════════════
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  Harness Init — 项目初始化${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  项目目录: ${BLUE}$PROJECT_DIR${NC}"
echo -e "  项目名:   ${BLUE}$PROJECT_NAME${NC}"
echo ""

# ═══════════════════════════════════════════════════
# STEP 1: 检测技术栈
# ═══════════════════════════════════════════════════
echo -e "${BOLD}🔍 STEP 1: 检测技术栈${NC}"

detect_tech_stack() {
    local dir="$1"
    local lang="" framework="" build_tool="" db="" orm="" runtime=""

    if [ -f "$dir/pom.xml" ]; then
        lang="Java"
        build_tool="Maven"
        # 检测 Spring Boot
        if grep -q 'spring-boot' "$dir/pom.xml" 2>/dev/null; then
            framework="Spring Boot"
            # 尝试提取版本
            local sb_version=$(grep -oP 'spring-boot-starter-parent.*?<version>\K[^<]+' "$dir/pom.xml" 2>/dev/null | head -1)
            framework="${framework} ${sb_version:-3.x}"
        fi
        # 检测 Java 版本
        local java_ver=$(grep -oP '<java.version>\K[^<]+' "$dir/pom.xml" 2>/dev/null | head -1)
        runtime="Java ${java_ver:-17}"
        # 检测数据库
        if grep -q 'mysql\|mysql-connector' "$dir/pom.xml" 2>/dev/null; then
            db="MySQL"
            if grep -q 'postgresql' "$dir/pom.xml" 2>/dev/null; then
                db="PostgreSQL"
            fi
        elif grep -q 'postgresql' "$dir/pom.xml" 2>/dev/null; then
            db="PostgreSQL"
        elif grep -q 'h2' "$dir/pom.xml" 2>/dev/null; then
            db="H2 (开发)"
        else
            db="MySQL 8.0"
        fi
        if grep -q 'spring-boot-starter-data-jpa\|hibernate' "$dir/pom.xml" 2>/dev/null; then
            orm="JPA / Hibernate"
        elif grep -q 'mybatis' "$dir/pom.xml" 2>/dev/null; then
            orm="MyBatis"
        fi

    elif [ -f "$dir/build.gradle" ] || [ -f "$dir/build.gradle.kts" ]; then
        lang="Java"
        build_tool="Gradle"
        framework="Spring Boot 3.x"
        runtime="Java 17"
        db="MySQL 8.0"
        orm="JPA / Hibernate"

    elif [ -f "$dir/package.json" ]; then
        lang="Node.js"
        if [ -f "$dir/package-lock.json" ]; then
            build_tool="npm"
        elif [ -f "$dir/yarn.lock" ]; then
            build_tool="yarn"
        elif [ -f "$dir/pnpm-lock.yaml" ]; then
            build_tool="pnpm"
        else
            build_tool="npm"
        fi
        # 检测框架
        if grep -q '"express"' "$dir/package.json" 2>/dev/null; then
            framework="Express"
        elif grep -q '"fastify"' "$dir/package.json" 2>/dev/null; then
            framework="Fastify"
        elif grep -q '"next"' "$dir/package.json" 2>/dev/null; then
            framework="Next.js"
        elif grep -q '"react"' "$dir/package.json" 2>/dev/null; then
            framework="React"
        elif grep -q '"vue"' "$dir/package.json" 2>/dev/null; then
            framework="Vue"
        fi
        # 检测 Node 版本
        local node_ver=$(grep -oP '"node"\s*:\s*"[~^>=]*\K[^"]+' "$dir/package.json" 2>/dev/null | head -1)
        runtime="Node.js ${node_ver:-20}"
        db="PostgreSQL 15"

    elif [ -f "$dir/requirements.txt" ] || [ -f "$dir/pyproject.toml" ]; then
        lang="Python"
        framework="FastAPI"
        if [ -f "$dir/pyproject.toml" ] && grep -q 'django' "$dir/pyproject.toml" 2>/dev/null; then
            framework="Django"
        fi
        runtime="Python 3.12"
        db="PostgreSQL 15"
        orm="SQLAlchemy"
        if [ -f "$dir/pyproject.toml" ]; then
            build_tool="uv / pip"
        else
            build_tool="pip"
        fi

    elif [ -f "$dir/go.mod" ]; then
        lang="Go"
        build_tool="go"
        framework="标准库 / Gin"
        runtime="Go 1.22"
        db="PostgreSQL 15"

    elif ls "$dir"/*.csproj 2>/dev/null | head -1 > /dev/null; then
        lang=".NET"
        build_tool="dotnet"
        framework="ASP.NET Core"
        runtime=".NET 8"
        db="SQL Server"
        orm="Entity Framework Core"
    fi

    echo "$lang|$framework|$build_tool|$db|$orm|$runtime"
}

DETECTED=$(detect_tech_stack "$PROJECT_DIR")
IFS='|' read -r D_LANG D_FRAMEWORK D_BUILD D_DB D_ORM D_RUNTIME <<< "$DETECTED"

if [ -n "$D_LANG" ]; then
    echo -e "  ✅ 检测到: ${GREEN}${D_LANG}${NC} + ${D_FRAMEWORK}"
    echo -e "           构建: ${D_BUILD}  数据库: ${D_DB}  ORM: ${D_ORM}"
    echo ""
else
    echo -e "  ${YELLOW}⚠️  未检测到已知技术栈，将使用通用模板${NC}"
    echo ""
fi

# ═══════════════════════════════════════════════════
# STEP 2: 引导填写项目信息
# ═══════════════════════════════════════════════════
echo -e "${BOLD}📝 STEP 2: 项目信息${NC}"

if [ "$NON_INTERACTIVE" = false ]; then
    # 项目名
    echo ""
    echo -ne "  项目名 [${BLUE}$PROJECT_NAME${NC}]: "
    read -r INPUT_NAME
    PROJECT_NAME="${INPUT_NAME:-$PROJECT_NAME}"

    # 简述
    echo -ne "  简述（一句话描述）: "
    read -r INPUT_DESC

    # 语言确认
    if [ -n "$D_LANG" ]; then
        echo -ne "  语言/运行时 [${BLUE}${D_RUNTIME}${NC}]: "
    else
        echo -ne "  语言/运行时（如 Java 17, Python 3.12）: "
    fi
    read -r INPUT_LANG
    D_RUNTIME="${INPUT_LANG:-$D_RUNTIME}"

    # 框架确认
    if [ -n "$D_FRAMEWORK" ]; then
        echo -ne "  框架 [${BLUE}${D_FRAMEWORK}${NC}]: "
    else
        echo -ne "  框架（如 Spring Boot 3.x, FastAPI）: "
    fi
    read -r INPUT_FW
    D_FRAMEWORK="${INPUT_FW:-$D_FRAMEWORK}"

    # 构建工具确认
    if [ -n "$D_BUILD" ]; then
        echo -ne "  构建工具 [${BLUE}${D_BUILD}${NC}]: "
    else
        echo -ne "  构建工具（如 Maven, Gradle, npm）: "
    fi
    read -r INPUT_BUILD
    D_BUILD="${INPUT_BUILD:-$D_BUILD}"

    # 数据库确认
    if [ -n "$D_DB" ]; then
        echo -ne "  数据库 [${BLUE}${D_DB}${NC}]: "
    else
        echo -ne "  数据库（如 MySQL 8.0, PostgreSQL 15）: "
    fi
    read -r INPUT_DB
    D_DB="${INPUT_DB:-$D_DB}"

    # ORM 确认
    if [ -n "$D_ORM" ]; then
        echo -ne "  ORM [${BLUE}${D_ORM}${NC}]: "
    else
        echo -ne "  ORM（如 JPA/Hibernate, MyBatis, SQLAlchemy）: "
    fi
    read -r INPUT_ORM
    D_ORM="${INPUT_ORM:-$D_ORM}"
else
    INPUT_DESC=""
fi

echo ""

# ═══════════════════════════════════════════════════
# STEP 3: 生成 project-context.md
# ═══════════════════════════════════════════════════
echo -e "${BOLD}📄 STEP 3: 生成 project-context.md${NC}"

PROJECT_MD="$PROJECT_DIR/project.md"

cat > "$PROJECT_MD" << 'TEMPLATE_HEADER'
# 项目上下文

> 此文件是 Agent 执行 Harness 开发流程时的「项目记忆」。
> 在本文件填写的约定，Agent 会在 Spec 决策树中自动归类为「分支 A：Agent 自主决策」。
> 
> **维护规则：** 新增约定时追加，不要删除已有约定（除非确实过时）。

---

## 基本信息

TEMPLATE_HEADER

cat >> "$PROJECT_MD" << EOF
- **项目名：** $PROJECT_NAME
- **简述：** ${INPUT_DESC:-（待填写）}
- **语言/运行时：** ${D_RUNTIME:-（待填写）}
- **框架：** ${D_FRAMEWORK:-（待填写）}
- **构建工具：** ${D_BUILD:-（待填写）}
- **数据库：** ${D_DB:-（待填写）}
- **ORM：** ${D_ORM:-（待填写）}

EOF

# 根据语言生成对应的代码组织模板
if [ "$D_LANG" = "Java" ]; then
    cat >> "$PROJECT_MD" << 'JAVA_TEMPLATE'
---

## 代码组织

```
src/
├── main/java/com/example/
│   ├── controller/     # REST 控制器
│   ├── service/        # 业务逻辑
│   ├── repository/     # 数据访问
│   ├── entity/         # 实体类
│   ├── dto/            # 数据传输对象
│   └── config/         # 配置类
└── test/java/com/example/
    └── ...
```

**包/模块命名约定：** com.example.{模块}

---

## API 约定

- **路径前缀：** `/api/v1`
- **响应格式：** 
  ```json
  { "code": 0, "data": {}, "message": "success" }
  ```
- **分页格式：** `Page<T> { content, totalPages, totalElements, size, number }`
- **错误码规范：** 40001=参数错误, 40401=资源不存在, 40901=冲突

---

## 数据库约定

- **表名：** 复数（users, orders）
- **主键策略：** 自增
- **主键列名：** `id`
- **时间字段：** `created_at`, `updated_at`（DATETIME）
- **软删除：** 有 `deleted_at` 字段
- **字段命名：** snake_case

---

## 代码风格

- **缩进：** 4 空格
- **命名：** 
  - 类名：PascalCase
  - 方法/变量：camelCase
  - 常量：UPPER_SNAKE_CASE
- **Entity 命名：** `User`, `Order`（单数）
- **Repository 命名：** `UserRepository`
- **Service 命名：** `UserService`
- **Controller 命名：** `UserController`
- **DTO 命名：** `UserCreateRequest`, `UserResponse`, `UserUpdateRequest`

---

## 测试

- **测试框架：** JUnit 5 + Mockito
- **测试文件位置：** `src/test/java/`，镜像 main 目录结构
- **测试类命名：** `{ClassName}Test`
- **构建命令：** `mvn test`
- **运行单个测试：** `mvn test -Dtest=UserServiceTest`

---

## 已有模块

<!-- Agent 在决策时可参考的已有代码列表 -->

| 模块 | Entity | Controller | 说明 |
|------|--------|------------|------|
| | | | |

---

## 项目特有约定

<!-- 任何不通用、但项目内一致的约定 -->

- 
JAVA_TEMPLATE

elif [ "$D_LANG" = "Node.js" ]; then
    cat >> "$PROJECT_MD" << 'NODE_TEMPLATE'

---

## 代码组织

```
src/
├── routes/           # 路由定义
├── controllers/      # 请求处理
├── services/         # 业务逻辑
├── models/           # 数据模型
├── middleware/        # 中间件
├── utils/            # 工具函数
└── config/           # 配置文件
tests/
└── ...
```

---

## API 约定

- **路径前缀：** `/api/v1`
- **响应格式：**
  ```json
  { "code": 0, "data": {}, "message": "success" }
  ```
- **错误处理：** 统一错误中间件

---

## 数据库约定

- **ORM：** 按项目选择（Prisma / TypeORM / Sequelize）
- **表名：** 复数
- **主键：** UUID 或自增
- **时间字段：** `createdAt`, `updatedAt`

---

## 代码风格

- **缩进：** 2 空格
- **命名：** camelCase
- **文件命名：** kebab-case
- **ESLint + Prettier**

---

## 测试

- **测试框架：** Jest / Vitest
- **构建命令：** `npm test`

---

## 已有模块

| 模块 | Model | Router | 说明 |
|------|-------|--------|------|
| | | | |

---

## 项目特有约定

- 
NODE_TEMPLATE

elif [ "$D_LANG" = "Python" ]; then
    cat >> "$PROJECT_MD" << 'PYTHON_TEMPLATE'

---

## 代码组织

```
app/
├── api/              # API 路由
├── core/             # 核心配置
├── models/           # 数据模型
├── schemas/          # Pydantic 模式
├── services/         # 业务逻辑
└── utils/            # 工具函数
tests/
└── ...
```

---

## API 约定

- **路径前缀：** `/api/v1`
- **响应格式：**
  ```json
  { "code": 0, "data": {}, "message": "success" }
  ```

---

## 数据库约定

- **ORM：** SQLAlchemy
- **表名：** 复数
- **主键：** UUID
- **时间字段：** `created_at`, `updated_at`
- **迁移工具：** Alembic

---

## 代码风格

- **缩进：** 4 空格
- **命名：** snake_case
- **类型提示：** 强制使用
- **Lint：** ruff / black

---

## 测试

- **测试框架：** pytest
- **构建命令：** `pytest`

---

## 已有模块

| 模块 | Model | Router | 说明 |
|------|-------|--------|------|
| | | | |

---

## 项目特有约定

- 
PYTHON_TEMPLATE

else
    cat >> "$PROJECT_MD" << 'GENERIC_TEMPLATE'

---

## 代码组织

```
src/
├── ...（待填写）
└── test/
    └── ...
```

---

## API 约定

- **路径前缀：** `/api/v1`
- **响应格式：**
  ```json
  { "code": 0, "data": {}, "message": "success" }

---

## 数据库约定

- **表名：** （待填写）
- **主键策略：** （待填写）

---

## 代码风格

- **缩进：** （待填写）

---

## 测试

- **测试框架：** （待填写）

---

## 已有模块

| 模块 | Entity | Controller | 说明 |
|------|--------|------------|------|
| | | | |

---

## 项目特有约定

- 
GENERIC_TEMPLATE
fi

echo -e "  ✅ ${GREEN}$PROJECT_MD${NC} 已生成"

# ═══════════════════════════════════════════════════
# STEP 4: 部署 Skill symlink
# ═══════════════════════════════════════════════════
echo -e "${BOLD}🔗 STEP 4: 部署 Harness Skill${NC}"

SKILL_LINK="$HOME/.hermes/skills/harness-dev-flow/SKILL.md"
SKILL_TARGET="$HARNESS_SKILL_DIR/skill.md"
SKILL_DIR="$(dirname "$SKILL_LINK")"

mkdir -p "$SKILL_DIR"

if [ -L "$SKILL_LINK" ]; then
    CURRENT_TARGET="$(readlink -f "$SKILL_LINK")"
    if [ "$CURRENT_TARGET" = "$SKILL_TARGET" ]; then
        echo -e "  ✅ Skill 已部署（指向正确）"
    else
        rm "$SKILL_LINK"
        ln -s "$SKILL_TARGET" "$SKILL_LINK"
        echo -e "  ✅ Skill 已重新部署"
    fi
else
    ln -s "$SKILL_TARGET" "$SKILL_LINK"
    echo -e "  ✅ ${GREEN}$SKILL_LINK${NC} → skill.md"
fi

# ═══════════════════════════════════════════════════
# STEP 5: 创建项目目录结构
# ═══════════════════════════════════════════════════
echo -e "${BOLD}📁 STEP 5: 创建目录结构${NC}"

mkdir -p "$PROJECT_DIR/docs/architecture"
mkdir -p "$PROJECT_DIR/docs/technical"
mkdir -p "$PROJECT_DIR/docs/spec"
mkdir -p "$PROJECT_DIR/docs/integration-test"
mkdir -p "$PROJECT_DIR/prd"

echo -e "  ✅ docs/ 目录结构已创建"
echo -e "     ├── docs/architecture/"
echo -e "     ├── docs/technical/"
echo -e "     ├── docs/spec/"
echo -e "     ├── docs/integration-test/"
echo -e "     └── prd/"

# ═══════════════════════════════════════════════════
# 完成报告
# ═══════════════════════════════════════════════════
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}  ✅ Harness 初始化完成！${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  📄 项目上下文: ${GREEN}$PROJECT_MD${NC}"
echo -e "  🔗 Skill 入口:  ${GREEN}$SKILL_LINK${NC}"
echo ""
echo -e "  ${BOLD}下一步：${NC}"
echo -e "  在飞书/终端对 Agent 说："
echo -e "  ${YELLOW}「我想做一个 XX 功能」${NC}  → 进入 Phase 1 产品分析"
echo -e "  ${YELLOW}「开发 XX 功能」${NC}        → 进入 Phase 3 开发（需先有 PRD）"
echo ""
