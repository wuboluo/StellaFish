import XCTest
@testable import StellaFish

final class ExpenseParserTests: XCTestCase {
    var parser: ExpenseParser!

    override func setUp() {
        super.setUp()
        parser = ExpenseParser()
    }

    func testSingleItemWithYuan() {
        let result = parser.parse("打车花了32元")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].title, "打车")
        XCTAssertEqual(result[0].amount, 32.0)
    }

    func testSingleItemWithKuai() {
        let result = parser.parse("买烧饼花了1块")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].title, "买烧饼")
        XCTAssertEqual(result[0].amount, 1.0)
    }

    func testDecimalAmount() {
        let result = parser.parse("买水果花了5块5")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].amount, 5.5, accuracy: 0.001)
    }

    func testDecimalWithDot() {
        let result = parser.parse("晚饭两个人花了86.5")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].amount, 86.5, accuracy: 0.001)
    }

    func testMultipleItemsComma() {
        let result = parser.parse("买烧饼花了1块，买水果花了5块5")
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].amount, 1.0)
        XCTAssertEqual(result[1].amount, 5.5, accuracy: 0.001)
    }

    func testMultipleItemsThree() {
        let result = parser.parse("买烧饼花了1块，买水果花了5块5，地铁7块")
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[2].title, "地铁")
        XCTAssertEqual(result[2].amount, 7.0)
    }

    func testBareNumber() {
        let result = parser.parse("咖啡18")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].title, "咖啡")
        XCTAssertEqual(result[0].amount, 18.0)
    }

    func testTicketPrice() {
        let result = parser.parse("门票120")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].amount, 120.0)
    }
}
