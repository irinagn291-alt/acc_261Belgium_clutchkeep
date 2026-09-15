import XCTest
@testable import Clutchkeep

@MainActor
final class RoostWatchTests: XCTestCase {
    func test_seededHomeEnablesCreditAndNamesTheJob() {
        let watch = RoostWatch.previewPopulated()
        XCTAssertTrue(watch.onboardingComplete)
        XCTAssertTrue(watch.creditEnabled)
        XCTAssertTrue(watch.hasFlock)
        XCTAssertTrue(watch.hasCredits)
        XCTAssertEqual(watch.jobTitle, "Credit a hen to log an egg")
        XCTAssertFalse(watch.jobLine.isEmpty)
        XCTAssertGreaterThan(watch.production.qty, 0)
        XCTAssertGreaterThan(watch.production.layMarkCount, 0)
        XCTAssertEqual(NestRoost.laneCount(henCount: 5, wide: false), 3)
        XCTAssertEqual(NestRoost.laneCount(henCount: 5, wide: true), 5)
        XCTAssertEqual(NestRoost.laneCount(henCount: 4, wide: true), 4)
        XCTAssertEqual(NestRoost.rowCount(henCount: 5, wide: false), 2)
        XCTAssertEqual(NestRoost.rowCount(henCount: 5, wide: true), 1)
        XCTAssertGreaterThan(NestRoost.bandHeight(henCount: 5, wide: true), RoostRail.tap)
        XCTAssertGreaterThan(NestRoost.bandHeight(henCount: 5, wide: false), NestRoost.roostFloor(henCount: 5, wide: false))
        let phone = NestRoost.split(henCount: 5, wide: false, in: 480)
        XCTAssertGreaterThanOrEqual(phone.board, NestRoost.boardFloor)
        XCTAssertGreaterThanOrEqual(phone.roost, NestRoost.roostFloor(henCount: 5, wide: false))
        let pad = NestRoost.split(henCount: 5, wide: true, in: 700)
        XCTAssertEqual(pad.roost, NestRoost.bandHeight(henCount: 5, wide: true), accuracy: 0.5)
        XCTAssertGreaterThan(pad.board, phone.board)
    }

    func test_reviewKeysSelectThreeLanes() {
        let today = RoostWatch.previewPopulated()
        today.applyReview(arguments: ["-ReviewScreen", "today"])
        XCTAssertEqual(today.lane, .flock)

        let log = RoostWatch.previewPopulated()
        log.applyReview(arguments: ["-ReviewScreen", "log"])
        XCTAssertEqual(log.lane, .analytics)

        let goals = RoostWatch.previewPopulated()
        goals.applyReview(arguments: ["-ReviewScreen", "goals"])
        XCTAssertEqual(goals.lane, .settings)

        XCTAssertNotEqual(today.lane, log.lane)
        XCTAssertNotEqual(log.lane, goals.lane)
        XCTAssertNotEqual(today.lane, goals.lane)
    }

    func test_reviewDoesNotFireBeforeOnboarding() {
        let watch = RoostWatch.previewEmpty()
        watch.store.install(YardBook.empty)
        watch.applyReview(arguments: ["-ReviewScreen", "log"])
        XCTAssertEqual(watch.lane, .flock)
        XCTAssertFalse(watch.onboardingComplete)
    }

    func test_emptyFlockCopy() {
        let watch = RoostWatch.previewEmpty()
        XCTAssertFalse(watch.hasFlock)
        XCTAssertFalse(watch.creditEnabled)
        XCTAssertEqual(watch.jobTitle, "Add a hen to the roost")
    }
}
