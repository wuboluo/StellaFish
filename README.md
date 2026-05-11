# StellaFish

一款面向中文用户的 iOS 旅行管理应用，帮助你全程追踪出行计划、交通、住宿、花费和行李。

## 功能

- **行程管理** — 创建多个旅程，记录出发/返回日期、城市、人数等信息
- **交通追踪** — 管理火车票、机票、地铁记录，支持票务快照和费用对比
- **记账** — 手动或语音输入花费，按天/旅程汇总，支持分类统计
- **酒店候选** — 记录多个备选住宿，方便对比决策
- **行李清单** — 内置模板 + 自定义，追踪打包进度
- **出行提醒** — 为交通和行程节点设置本地通知
- **地点收藏** — 保存目的地 POI，支持高德/Apple 地图导航
- **AI 助手** — 接入 DeepSeek，生成准备清单、分析路线、生成旅行攻略

## 技术栈

- **语言**: Swift 5.9 / SwiftUI
- **数据层**: SwiftData
- **架构**: MVVM
- **最低系统**: iOS 17.0+
- **第三方接口**:
  - [DeepSeek API](https://platform.deepseek.com/) — AI 功能
  - [高德开放平台](https://lbs.amap.com/) — POI 搜索与地图

## 配置

应用内所有 API Key 均通过 Keychain 存储，不随代码分发。首次运行需在「设置」页面填入：

| Key | 用途 | 获取地址 |
|-----|------|----------|
| DeepSeek API Key | AI 功能 | https://platform.deepseek.com/ |
| 高德 Web API Key | POI 搜索 | https://lbs.amap.com/ |

## 项目结构

```
StellaFish/
├── App/              # 入口与全局状态
├── Core/
│   ├── Models/       # SwiftData 数据模型
│   └── Services/     # 网络、语音、OCR、通知等服务
├── Features/         # 功能模块（Dashboard、Trip、Expense 等）
├── UI/               # 共享组件与主题
└── Resources/        # 静态资源（图标、城市/车站数据）
```

## 开发

```bash
# 克隆仓库
git clone https://github.com/wuboluo/StellaFish.git

# 用 Xcode 打开
open StellaFish.xcodeproj
```

Xcode 15+ 即可构建，无需额外依赖。
