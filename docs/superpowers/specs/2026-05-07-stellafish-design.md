# StellaFish iOS App — Design Spec

**Date:** 2026-05-07  
**Version:** MVP v1 (P0 + P1)  
**Platform:** iOS 17+, SwiftUI + SwiftData  
**Project location:** `/Users/wawayu/StellaFish`

---

## 1. Product Summary

StellaFish is a personal iOS travel planning app. It is NOT a ticket-scraping or real-time price tool. It is a trip planning, manual ticket logging, checklist, expense tracking (with voice input), hotel candidate tracking, and AI-assisted planning tool. Data is stored locally (SwiftData). CloudKit sync is architecturally reserved for a future version.

---

## 2. Architecture

**Pattern:** MVVM + Repository  
**Data layer:** SwiftData behind Repository protocols — Views never touch `ModelContext` directly; they go through a ViewModel which calls a Repository.  
**Navigation:** `TabView` with 6 tabs (iOS native).  
**AI:** DeepSeek API, key stored in Keychain, entered by user in Settings.  
**Location:** CoreLocation, "when in use" only.  
**Notifications:** Local only, `UserNotifications`.  
**Voice:** Apple `Speech` framework + `AVAudioEngine` + `SFSpeechRecognizer`.

---

## 3. Project File Structure

```
StellaFish/
├── App/
│   ├── StellaFishApp.swift
│   └── ContentView.swift              # TabView root (6 tabs)
│
├── Core/
│   ├── Models/                        # SwiftData @Model classes
│   │   ├── Trip.swift
│   │   ├── TransportTask.swift
│   │   ├── TicketSnapshot.swift
│   │   ├── HotelCandidate.swift
│   │   ├── ChecklistItem.swift
│   │   ├── ExpenseRecord.swift
│   │   └── City.swift                 # Value type, not @Model
│   ├── Repositories/
│   │   ├── Protocols/
│   │   │   ├── TripRepositoryProtocol.swift
│   │   │   └── ExpenseRepositoryProtocol.swift
│   │   └── Local/
│   │       ├── LocalTripRepository.swift
│   │       └── LocalExpenseRepository.swift
│   └── Services/
│       ├── LocationService.swift
│       ├── NotificationService.swift
│       ├── SpeechService.swift
│       ├── ExpenseParser.swift         # Local rule-based voice parsing
│       └── DeepSeekService.swift
│
├── Features/
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   └── DashboardViewModel.swift
│   ├── Trip/
│   │   ├── TripListView.swift
│   │   ├── TripDetailView.swift
│   │   ├── TripEditView.swift
│   │   ├── TripViewModel.swift
│   │   └── CityPickerView.swift
│   ├── Transport/
│   │   ├── TransportTaskListView.swift
│   │   ├── TransportTaskDetailView.swift
│   │   ├── TicketSnapshotFormView.swift
│   │   ├── CostComparisonView.swift
│   │   └── TransportViewModel.swift
│   ├── Hotel/
│   │   ├── HotelListView.swift
│   │   ├── HotelFormView.swift
│   │   └── HotelViewModel.swift
│   ├── Checklist/
│   │   ├── ChecklistView.swift
│   │   ├── ChecklistItemFormView.swift
│   │   └── ChecklistViewModel.swift
│   ├── Expense/
│   │   ├── ExpenseListView.swift
│   │   ├── ExpenseFormView.swift
│   │   ├── VoiceExpenseView.swift
│   │   ├── ExpenseConfirmView.swift
│   │   ├── ExpenseSummaryView.swift
│   │   └── ExpenseViewModel.swift
│   ├── AI/
│   │   ├── AIView.swift
│   │   └── AIViewModel.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── SettingsViewModel.swift
│
├── UI/
│   ├── Components/
│   │   ├── TripCard.swift
│   │   ├── StatCard.swift
│   │   ├── SectionHeader.swift
│   │   └── FloatingVoiceButton.swift
│   ├── Theme/
│   │   ├── AppColors.swift            # Blue-purple gradient, orange accents
│   │   └── AppFonts.swift
│   └── Extensions/
│       ├── Date+Weekday.swift
│       └── Double+Currency.swift
│
└── Resources/
    └── cities.json
```

---

## 4. Data Models

### Trip
```swift
@Model class Trip {
    var id: UUID
    var title: String
    var fromCity: String
    var toCity: String
    var departDate: Date
    var returnDate: Date
    var peopleCount: Int
    var timeValuePerHour: Double       // yuan/hour/person
    var preference: TripPreference     // balanced|money|time|easy
    var note: String
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade) var transportTasks: [TransportTask]
    @Relationship(deleteRule: .cascade) var hotelCandidates: [HotelCandidate]
    @Relationship(deleteRule: .cascade) var checklistItems: [ChecklistItem]
    @Relationship(deleteRule: .cascade) var expenses: [ExpenseRecord]
}
```

### TransportTask
```swift
@Model class TransportTask {
    var id: UUID
    var trip: Trip?
    var title: String
    var fromPlace: String
    var toPlace: String
    var date: Date
    var transportTypes: [TransportType]   // stored as [String]
    var targetPrice: Double?
    var targetSeatStatus: SeatStatus
    var reminderIntervalMinutes: Int
    var nextReminderAt: Date?
    var note: String
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade) var snapshots: [TicketSnapshot]
}
```

### TicketSnapshot
```swift
@Model class TicketSnapshot {
    var id: UUID
    var task: TransportTask?
    var platform: String               // 12306|携程|飞猪|去哪儿|航司|其他
    var transportType: TransportType
    var code: String                   // train/flight number
    var price: Double                  // per person
    var seatStatus: SeatStatus         // 充足|紧张|候补|无票|未查询
    var departTime: Date
    var arriveTime: Date
    var fromStation: String
    var toStation: String
    var transferCost: Double           // 接驳费用
    var transferMinutes: Int           // 接驳耗时
    var extraMinutes: Int              // 额外耗时（安检/候车等）
    var baggageCost: Double
    var riskCost: Double
    var hassleCost: Double
    var note: String
    var createdAt: Date
}
```

**Computed cost** (not stored, computed from trip.peopleCount + trip.timeValuePerHour):
```
totalCost = price × people
           + transferCost
           + baggageCost
           + doorToDoorHours × timeValuePerHour × people
           + riskCost
           + hassleCost

doorToDoorMinutes = (arriveTime - departTime) + transferMinutes + extraMinutes
```

Default extraMinutes / riskCost / hassleCost by transport type (per spec):
- 飞机: extra=120, risk=50, hassle=40
- 高铁/动车: extra=40, risk=10, hassle=10
- 普通火车: extra=40, risk=10, hassle=30
- 汽车/大巴: extra=30, risk=40, hassle=40
- 自驾: extra=0, risk=60, hassle=80

Snapshots with `seatStatus == .noTicket` are sorted last in comparison view.

### HotelCandidate
```swift
@Model class HotelCandidate {
    var id: UUID
    var trip: Trip?
    var name: String
    var brand: String
    var address: String
    var latitude: Double?
    var longitude: Double?
    var checkInDate: Date
    var checkOutDate: Date
    var pricePerNight: Double
    var nights: Int                    // computed from dates
    var distanceNote: String
    var trafficNote: String
    var ratingNote: String
    var bookingStatus: BookingStatus   // 未预订|已预订|已放弃
    var note: String
    var createdAt: Date
    var updatedAt: Date
}
```

### ChecklistItem
```swift
@Model class ChecklistItem {
    var id: UUID
    var trip: Trip?                    // nil = global checklist
    var title: String
    var category: ChecklistCategory    // 证件|衣物|数码|药品|订票|酒店|景点|其他
    var isDone: Bool
    var note: String
    var sortOrder: Int
    var dueDate: Date?
    var createdAt: Date
    var updatedAt: Date
}
```

Default template items: 身份证, 手机, 充电器, 充电宝, 耳机, 换洗衣物, 雨伞, 常用药, 纸巾, 酒店确认, 去程票, 返程票.

### ExpenseRecord
```swift
@Model class ExpenseRecord {
    var id: UUID
    var trip: Trip?
    var title: String
    var amount: Double
    var category: ExpenseCategory      // 餐饮|交通|住宿|门票|购物|娱乐|其他
    var paymentMethod: PaymentMethod?  // 现金|微信|支付宝|银行卡|其他
    var note: String
    var latitude: Double?
    var longitude: Double?
    var locationName: String?
    var createdAt: Date
    var updatedAt: Date
    var source: ExpenseSource          // manual|voice|ai
    var rawText: String?               // original speech text
}
```

### City (value type, from JSON)
```swift
struct City: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var province: String
    var pinyin: String
    var firstLetter: String
    var latitude: Double
    var longitude: Double
}
```

---

## 5. Repository Layer

```swift
protocol TripRepositoryProtocol {
    func fetchAll() -> [Trip]
    func save(_ trip: Trip)
    func delete(_ trip: Trip)
}

protocol ExpenseRepositoryProtocol {
    func fetchAll(tripId: UUID?) -> [ExpenseRecord]
    func save(_ expense: ExpenseRecord)
    func delete(_ expense: ExpenseRecord)
    func totalAmount(tripId: UUID?) -> Double
    func summaryByCategory(tripId: UUID?) -> [ExpenseCategory: Double]
}
```

`LocalTripRepository` and `LocalExpenseRepository` hold a `ModelContext` and implement these protocols using SwiftData fetch descriptors.

ViewModels receive repositories via init injection. Future CloudKit versions just swap the concrete type.

---

## 6. Services

### LocationService
- `@Observable` class, `CLLocationManagerDelegate`
- `requestWhenInUseAuthorization()`
- `currentCoordinate: CLLocationCoordinate2D?`
- `currentCityName: String?` — via `CLGeocoder.reverseGeocodeLocation`
- Non-blocking: if location unavailable, returns nil silently

### NotificationService
- `requestAuthorization()`
- `scheduleTicketReminder(task:)` — creates a `UNTimeIntervalNotificationTrigger`
- `cancelReminder(taskId:)`
- Reminder intervals: 15m / 30m / 1h / 3h / daily

### SpeechService
- `@Observable` class
- `startRecording()` / `stopRecording()`
- Publishes `recognizedText: String` in real time via `SFSpeechRecognizer` + `AVAudioEngine`
- Handles microphone + speech recognition permission requests

### ExpenseParser (local rule engine)
Input: raw String  
Output: `[ParsedExpense]` where `ParsedExpense = (title: String, amount: Double)`

Rules:
1. Split on `，,。；;和然后还有`
2. For each segment, extract amount: regex for patterns like `(\d+\.?\d*)[元块](\d)?` → normalize to Double
3. Extract title: everything before the amount keyword (`花了`/`花了约`/bare number at end)
4. If parsing yields no results, return single item with full text as title and amount=0 (user fixes manually)

### DeepSeekService
- Reads API key from Keychain (`"stellafish.deepseek.apikey"`)
- `sendMessage(systemPrompt:userPrompt:) async throws -> String`
- Used for: generate checklist, analyze transport options, generate destination guide, summarize expenses, (optional) re-parse voice text
- All calls are explicit user-triggered actions, never automatic background calls

---

## 7. Navigation & Tab Structure

```
TabView
├── Tab 1: Dashboard      (house.fill)
├── Tab 2: Trip           (map.fill)
├── Tab 3: Checklist      (checklist)
├── Tab 4: Expense        (yensign.circle.fill)
├── Tab 5: AI             (sparkles)
└── Tab 6: Settings       (gearshape.fill)
```

Each tab wraps its root in `NavigationStack`. Deep links push onto the stack (e.g., Dashboard card → Trip detail).

---

## 8. UI Theme

**Colors:**
- Primary gradient: `#5B6CF8` → `#9B59F5` (blue-purple)
- Accent / expense: `#FF7043` (orange)
- Background: `#F5F5F7` (near-white)
- Card: `.white` + `shadow(radius: 4, y: 2)`

**Style rules:**
- Corner radius: 16pt for cards, 12pt for buttons
- All cards use `RoundedRectangle(cornerRadius: 16)`
- SF Symbols throughout, no third-party icon libs
- `Material` backgrounds for overlays
- `LazyVStack` for long lists

**Dashboard layout:**
- Top: large hero card (current trip, gradient background, key stats)
- Below: 2-column grid of stat mini-cards (total spent, pending checklist, next reminder)
- Bottom: horizontal quick-action buttons (new trip / voice expense / add ticket / ask AI)

---

## 9. Voice Expense Flow

1. User taps voice button (FAB on Expense tab, or shortcut on Dashboard / Trip detail)
2. `SpeechService.startRecording()` → real-time transcript shown on screen
3. User taps stop
4. `ExpenseParser.parse(text)` → `[ParsedExpense]`
5. `LocationService` fetches coordinate in parallel (non-blocking)
6. Navigate to `ExpenseConfirmView` with parsed items
7. User reviews / edits each item (title, amount, category)
8. Tap save → all items persisted as `ExpenseRecord` with `source: .voice`

If user taps "AI 重新解析": DeepSeekService called with structured prompt, result replaces parsed items in confirm view.

---

## 10. AI Features (P1)

Fixed action buttons in AI tab, scoped to current active trip:

| Button | System prompt summary |
|--------|----------------------|
| 生成行前清单 | Given trip details, return a JSON array of checklist items |
| 分析交通方案 | Given ticket snapshots + preferences, recommend best option with reasoning |
| 生成目的地攻略 | Given destination + dates + people count, return a structured guide |
| 总结花费 | Given expense list, return natural language summary |

Responses displayed as styled markdown text in a scrollable sheet. User can copy or save to notes.

---

## 11. Settings

- DeepSeek API Key input → saved to Keychain, never logged
- "Test connection" button → sends a trivial ping message, shows success/error
- App info (version, build)
- (Reserved) CloudKit sync toggle (disabled, grayed out)

---

## 12. Permissions & Info.plist Keys

| Key | Purpose |
|-----|---------|
| `NSLocationWhenInUseUsageDescription` | 用于在记账时自动记录当前地点，方便回顾旅行花费。 |
| `NSSpeechRecognitionUsageDescription` | 用于将你的语音转换为文字并生成记账记录。 |
| `NSMicrophoneUsageDescription` | 用于通过语音快速记录旅行花费。 |

---

## 13. Compliance

- No web scraping of 12306, Ctrip, Fliggy, Huazhu, or any third-party platform
- All ticket prices, availability, and hotel prices are manually entered by the user
- DeepSeek API key is user-supplied and stored in Keychain only
- App description for App Store (future): "旅行计划、记账与提醒工具"

---

## 14. Out of Scope (v1)

- CloudKit sync/sharing
- Real-time ticket price APIs
- Auto ticket grabbing
- Amap (高德) integration
- App Store submission
- Charts/graphs (text stats only)
- Chinese number parsing in voice ("十块", "二十")

---

## 15. Open Questions / Decisions Made

| Question | Decision |
|----------|----------|
| App name | StellaFish |
| Navigation | TabView, 6 tabs, iOS native |
| Project path | /Users/wawayu/StellaFish |
| Scope | P0 + P1 |
| DeepSeek key | User-supplied at runtime, Keychain storage |
| City database | Bundled JSON, ~100 major Chinese cities |
| CloudKit | Not in v1, Repository protocol reserved |
