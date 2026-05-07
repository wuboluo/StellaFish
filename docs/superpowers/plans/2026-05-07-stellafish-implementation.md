# StellaFish iOS — 实现计划

**设计文档:** `docs/superpowers/specs/2026-05-07-stellafish-design.md`  
**项目路径:** `/Users/wawayu/StellaFish/StellaFish/`  
**技术栈:** iOS 17+, SwiftUI, SwiftData, MVVM + Repository

---

## Phase 1 — 项目基础结构

目标：建立文件夹结构、主题、入口点。

### 任务
1. **整理目录结构** — 按设计文档的文件树在 Xcode 中创建分组：App / Core / Features / UI / Resources
2. **删除默认文件** — 删除 `Item.swift`，替换 `ContentView.swift`
3. **AppColors.swift** — 定义 `primary` 渐变(#5B6CF8→#9B59F5)、`accent`(#FF7043)、`background`(#F5F5F7)
4. **AppFonts.swift** — 定义全局字体扩展（不引入第三方）
5. **Date+Weekday.swift / Double+Currency.swift** — 工具扩展
6. **StellaFishApp.swift** — 配置 `ModelContainer`（包含所有 @Model 类型），注入 `modelContext`
7. **ContentView.swift** — 实现 6-tab `TabView`（空占位视图）

**验收：** 项目编译通过，TabView 显示 6 个空标签页。

---

## Phase 2 — 数据模型 & Repository

目标：SwiftData 模型 + Repository 协议 + 本地实现。

### 任务
1. **数据模型**（按顺序，因有关联关系）：
   - `Trip.swift` — 含所有枚举：`TripPreference`
   - `TransportTask.swift` — 含枚举：`TransportType`, `SeatStatus`
   - `TicketSnapshot.swift`
   - `HotelCandidate.swift` — 含枚举：`BookingStatus`
   - `ChecklistItem.swift` — 含枚举：`ChecklistCategory`
   - `ExpenseRecord.swift` — 含枚举：`ExpenseCategory`, `PaymentMethod`, `ExpenseSource`
2. **City.swift** — value type（`Codable, Identifiable, Hashable`）
3. **cities.json** — 打包约 100 个主要中国城市数据到 Resources/
4. **TripRepositoryProtocol.swift / ExpenseRepositoryProtocol.swift**
5. **LocalTripRepository.swift / LocalExpenseRepository.swift** — 使用 SwiftData `FetchDescriptor`

**验收：** 所有模型编译，ModelContainer 初始化无崩溃。

---

## Phase 3 — Services

目标：实现 4 个服务类。

### 任务
1. **LocationService.swift** — `@Observable`，CLLocationManager，当前坐标 + 城市名（反地理编码）
2. **NotificationService.swift** — 请求权限，`scheduleTicketReminder(task:)`，`cancelReminder(taskId:)`
3. **SpeechService.swift** — `@Observable`，AVAudioEngine + SFSpeechRecognizer，实时转文字
4. **ExpenseParser.swift** — 纯本地规则引擎：分句 → 提取金额（正则）→ 提取标题
5. **DeepSeekService.swift** — Keychain 读取 API key，`sendMessage(systemPrompt:userPrompt:) async throws -> String`，HTTP 调用 DeepSeek API

**验收：** 服务类实例化无崩溃，LocationService 在模拟器能请求权限。

---

## Phase 4 — Dashboard Tab

目标：实现首页仪表盘。

### 组件
- `StatCard.swift` — mini 统计卡片（通用）
- `TripCard.swift` — 行程卡片（带渐变背景）
- `SectionHeader.swift` — 通用分组标题
- `FloatingVoiceButton.swift` — 悬浮麦克风按钮
- `DashboardViewModel.swift` — 从 Repository 聚合：当前行程、总花费、待办清单数、下次提醒
- `DashboardView.swift` — Hero 卡片 + 2列 grid + 底部快速操作按钮

**验收：** 创建一个测试行程后，Dashboard 正确显示数据。

---

## Phase 5 — Trip Tab（行程管理）

目标：行程 CRUD。

### 组件
- `TripViewModel.swift`
- `TripListView.swift` — 行程列表
- `TripDetailView.swift` — 行程详情（含子 Tab：交通/酒店/清单/花费）
- `TripEditView.swift` — 新建/编辑行程表单
- `CityPickerView.swift` — 从 cities.json 搜索城市（拼音/首字母/名称）

**验收：** 能创建、编辑、删除行程；城市选择器正常工作。

---

## Phase 6 — Transport & Ticket

目标：交通任务 + 票务快照 + 费用比较。

### 组件
- `TransportViewModel.swift`
- `TransportTaskListView.swift` — 某行程下的交通任务列表
- `TransportTaskDetailView.swift` — 任务详情 + 快照列表
- `TicketSnapshotFormView.swift` — 添加/编辑快照（计算实际费用）
- `CostComparisonView.swift` — 多快照横向对比，按 totalCost 排序（无票排最后）

**关键逻辑：** `totalCost` 计算公式在 TicketSnapshot 扩展中实现（不存储）；各交通类型默认值按设计文档。

**验收：** 添加 3 个快照后，比较视图按费用正确排序。

---

## Phase 7 — Hotel Tab

目标：酒店候选管理。

### 组件
- `HotelViewModel.swift`
- `HotelListView.swift` — 候选酒店列表（按预订状态分组）
- `HotelFormView.swift` — 添加/编辑酒店候选

**验收：** 能添加酒店候选，修改预订状态。

---

## Phase 8 — Checklist Tab

目标：清单管理（全局 + 行程专属）。

### 组件
- `ChecklistViewModel.swift`
- `ChecklistView.swift` — 按 category 分组显示，支持拖拽排序
- `ChecklistItemFormView.swift` — 添加/编辑清单项

**初始化逻辑：** 新建行程时自动插入 12 个默认模板项。

**验收：** 默认项出现，能勾选/取消。

---

## Phase 9 — Expense Tab（含语音记账）

目标：花费记录 + 语音输入。

### 组件
- `ExpenseViewModel.swift`
- `ExpenseListView.swift` — 花费列表，按日期分组
- `ExpenseFormView.swift` — 手动添加花费
- `VoiceExpenseView.swift` — 语音录音界面，实时显示转文字
- `ExpenseConfirmView.swift` — 展示解析结果，用户确认/修改每条记录
- `ExpenseSummaryView.swift` — 分类汇总（文字版，无图表）

**语音流程：** 按设计文档第 9 节（SpeechService → ExpenseParser → ExpenseConfirmView → 持久化）

**验收：** 语音输入"午饭花了35元，打车15块"能解析出两条记录。

---

## Phase 10 — AI Tab

目标：4 个 AI 功能按钮。

### 组件
- `AIViewModel.swift` — 调用 DeepSeekService，持有 `isLoading` / `result: String`
- `AIView.swift` — 4 个按钮 + 结果展示（Markdown 滚动文本）

**4 个功能：**
- 生成行前清单（返回 JSON array → 插入 ChecklistItem）
- 分析交通方案（传入快照摘要 → 返回推荐文字）
- 生成目的地攻略（传入目的地/日期/人数）
- 总结花费（传入花费列表）

**验收：** 配置 API Key 后，"总结花费"功能能返回响应。

---

## Phase 11 — Settings Tab

目标：API Key 管理 + 应用信息。

### 组件
- `SettingsViewModel.swift` — Keychain 读写
- `SettingsView.swift` — API Key 输入框 + 测试连接按钮 + 版本信息 + 预留 CloudKit 开关（灰色）

**验收：** 保存 API Key 后重启 App 仍能读取。

---

## Phase 12 — 权限 & Info.plist & 打磨

目标：完成上线前必要配置。

### 任务
1. **Info.plist** — 添加 3 个权限描述（位置/语音识别/麦克风）
2. **通知权限** — 在 App 首次启动时请求（NotificationService）
3. **错误处理** — 关键路径（DeepSeek 网络失败、语音权限拒绝）显示友好提示
4. **Loading 状态** — AI 调用时显示 ProgressView
5. **空状态视图** — 各列表无数据时显示引导文字
6. **全局测试** — 完整走一遍核心用户旅程（新建行程→添加票→语音记账→AI分析）

**验收：** App 在模拟器和真机均能完整使用核心功能，无崩溃。

---

## 执行顺序

```
Phase 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 11 → 12
```

每个 Phase 独立，完成一个后再开始下一个。Phase 3 的 Services 可以在 Phase 2 完成后并行推进（LocationService + NotificationService 不依赖其他 Service）。

---

## 当前状态

- [x] 设计文档完成
- [x] Xcode 项目创建（含默认模板文件）
- [ ] Phase 1 开始
