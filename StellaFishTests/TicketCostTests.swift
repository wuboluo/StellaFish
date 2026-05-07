import XCTest
@testable import StellaFish

final class TicketCostTests: XCTestCase {
    func testHighSpeedTrainCost() {
        let depart = Date()
        let arrive = Calendar.current.date(byAdding: .hour, value: 2, to: depart)!
        let snapshot = TicketSnapshot(
            transportType: .highSpeedTrain,
            price: 300,
            seatStatus: .available,
            departTime: depart,
            arriveTime: arrive,
            transferCost: 30,
            transferMinutes: 20,
            extraMinutes: 40,
            baggageCost: 0,
            riskCost: 10,
            hassleCost: 10
        )
        // doorToDoor = 120 + 20 + 40 = 180 min = 3h
        // cost = 300*2 + 30 + 0 + 3*50*2 + 10 + 10 = 600+30+300+20 = 950
        let cost = snapshot.totalCost(people: 2, timeValuePerHour: 50)
        XCTAssertEqual(cost, 950.0, accuracy: 0.01)
    }

    func testNoTicketReturnsInfinity() {
        let now = Date()
        let snapshot = TicketSnapshot(
            transportType: .highSpeedTrain,
            price: 300,
            seatStatus: .noTicket,
            departTime: now,
            arriveTime: now
        )
        let cost = snapshot.totalCost(people: 1, timeValuePerHour: 50)
        XCTAssertEqual(cost, Double.infinity)
    }

    func testDoorToDoorMinutes() {
        let depart = Date()
        let arrive = Calendar.current.date(byAdding: .hour, value: 1, to: depart)!
        let snapshot = TicketSnapshot(
            departTime: depart,
            arriveTime: arrive,
            transferMinutes: 30,
            extraMinutes: 40
        )
        XCTAssertEqual(snapshot.doorToDoorMinutes, 130)
    }
}
