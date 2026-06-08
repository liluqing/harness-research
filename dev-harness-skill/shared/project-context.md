# 项目上下文

> 此文件是 Agent 执行 Harness 开发流程时的「项目记忆」。
> 在本文件填写的约定，Agent 会在 Spec 决策树中自动归类为「分支 A：Agent 自主决策」。
> 
> **维护规则：** 新增约定时追加，不要删除已有约定（除非确实过时）。

---

## 基本信息

- **项目名：** <!-- 填写 -->
- **简述：** <!-- 一句话描述项目做什么 -->
- **语言/运行时：** <!-- 如 Java 17, Python 3.11 -->
- **框架：** <!-- 如 Spring Boot 3.x, FastAPI -->
- **构建工具：** <!-- 如 Maven, Gradle, uv -->
- **数据库：** <!-- 如 MySQL 8.0, PostgreSQL 15 -->
- **ORM：** <!-- 如 JPA/Hibernate, SQLAlchemy -->

---

## 代码组织

```
<!-- 填写项目目录结构 -->

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

**包/模块命名约定：** <!-- 如 com.example.{模块} -->

---

## API 约定

- **路径前缀：** `/api/v1`
- **响应格式：** 
  ```json
  { "code": 0, "data": {}, "message": "success" }
  ```
- **分页格式：** <!-- 如 Page<T> { content, totalPages, totalElements, size, number } -->
- **错误码规范：** <!-- 如 40001=参数错误, 40401=资源不存在, 40901=冲突 -->

---

## 数据库约定

- **表名：** <!-- 单数/复数，如 user 还是 users -->
- **主键策略：** <!-- 自增 / UUID / 雪花ID -->
- **主键列名：** `id`
- **时间字段：** `created_at`, `updated_at`（DATETIME / TIMESTAMP）
- **软删除：** <!-- 是否有 deleted_at 字段 -->
- **字段命名：** <!-- snake_case -->

---

## 代码风格

- **缩进：** <!-- 4 空格 / Tab -->
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

- **测试框架：** <!-- 如 JUnit 5 + Mockito -->
- **测试文件位置：** `src/test/java/`，镜像 main 目录结构
- **测试类命名：** `{ClassName}Test`
- **构建命令：** <!-- 如 mvn test, gradle test -->
- **运行单个测试：** <!-- 如 mvn test -Dtest=UserServiceTest -->

---

## 已有模块

<!-- Agent 在决策时可参考的已有代码列表 -->

| 模块 | Entity | Controller | 说明 |
|------|--------|------------|------|
| <!-- 例：部门管理 --> | `Dept` | `DeptController` | 树形结构，支持增删改查 |
| | | | |

---

## 项目特有约定

<!-- 任何不通用、但项目内一致的约定 -->

- <!-- 例：所有接口需要 @Auth 注解 -->
- <!-- 例：异常统一用 GlobalExceptionHandler 处理 -->
- <!-- 例：日志用 @Slf4j，关键操作记录到操作日志表 -->
