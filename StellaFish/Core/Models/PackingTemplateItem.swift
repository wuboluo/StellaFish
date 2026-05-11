import Foundation
import SwiftData

@Model
final class PackingTemplateItem {
    var id: UUID
    var title: String
    var category: String
    var colorTag: String   // blue / green / red / gray
    var isRequired: Bool
    var sortOrder: Int
    var note: String
    var createdAt: Date
    var updatedAt: Date

    init(title: String, category: String, colorTag: String = "blue",
         isRequired: Bool = true, sortOrder: Int = 0, note: String = "") {
        self.id = UUID()
        self.title = title
        self.category = category
        self.colorTag = colorTag
        self.isRequired = isRequired
        self.sortOrder = sortOrder
        self.note = note
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

extension PackingTemplateItem {
    static let categoryOrder = ["证件与重要物品","衣物类","洗漱与护肤","数码与拍照","药品与应急"]

    static let defaultItems: [(title: String, category: String, colorTag: String)] = [
        ("身份证 / 护照",           "证件与重要物品", "blue"),
        ("车票 / 机票 / 订单信息",   "证件与重要物品", "blue"),
        ("驾驶证（如有自驾计划）",   "证件与重要物品", "blue"),
        ("银行卡、少量现金",         "证件与重要物品", "blue"),
        ("手机及充电器",            "证件与重要物品", "blue"),
        ("充电宝",                 "证件与重要物品", "blue"),
        ("酒店预订信息截图",         "证件与重要物品", "blue"),
        ("紧急联系人信息",          "证件与重要物品", "blue"),

        ("日常换洗衣物",     "衣物类", "blue"),
        ("内衣、袜子",       "衣物类", "blue"),
        ("睡衣",            "衣物类", "blue"),
        ("外套 / 防风衣",    "衣物类", "blue"),
        ("舒适的运动鞋",     "衣物类", "blue"),
        ("拖鞋",            "衣物类", "blue"),
        ("帽子、墨镜",       "衣物类", "blue"),
        ("雨伞 / 雨衣",      "衣物类", "blue"),

        ("牙刷、牙膏",                    "洗漱与护肤", "blue"),
        ("洗面奶",                        "洗漱与护肤", "blue"),
        ("毛巾 / 一次性洗脸巾",            "洗漱与护肤", "blue"),
        ("洗发水、护发素、沐浴露（旅行装）", "洗漱与护肤", "blue"),
        ("护肤品",                        "洗漱与护肤", "blue"),
        ("防晒霜",                        "洗漱与护肤", "blue"),
        ("润唇膏",                        "洗漱与护肤", "blue"),
        ("梳子",                          "洗漱与护肤", "blue"),
        ("女生卸妆用品",                   "洗漱与护肤", "gray"),
        ("男生日常剃须用品",               "洗漱与护肤", "gray"),

        ("相机 / 运动相机",            "数码与拍照", "blue"),
        ("相机电池、充电器",            "数码与拍照", "blue"),
        ("存储卡",                     "数码与拍照", "blue"),
        ("自拍杆 / 三脚架",             "数码与拍照", "gray"),
        ("耳机",                       "数码与拍照", "blue"),
        ("数据线（Type-C / Lightning）","数码与拍照", "blue"),
        ("插线板 / 转换插头",           "数码与拍照", "gray"),

        ("感冒药",           "药品与应急", "blue"),
        ("肠胃药",           "药品与应急", "blue"),
        ("晕车药 / 晕船药",  "药品与应急", "blue"),
        ("创可贴",           "药品与应急", "blue"),
        ("消毒湿巾",         "药品与应急", "blue"),
        ("纸巾 / 湿巾",      "药品与应急", "blue"),
        ("驱蚊液 / 止痒用品","药品与应急", "gray"),
        ("口罩",             "药品与应急", "blue"),
        ("女生生理用品",     "药品与应急", "gray"),
    ]
}
