import XCTest
@testable import Clutchkeep

final class RoostLaneTests: XCTestCase {
    func test_readsOnceAfterOnboarding() {
        var hook = RoostHook()
        XCTAssertNil(hook.take(arguments: ["-ReviewScreen", "log"], onboarded: false))
        XCTAssertFalse(hook.consumed)

        let first = hook.take(arguments: ["app", "-ReviewScreen", "log"], onboarded: true)
        XCTAssertEqual(first, .log)
        XCTAssertEqual(first?.lane, .analytics)
        XCTAssertTrue(hook.consumed)
        XCTAssertNil(hook.take(arguments: ["-ReviewScreen", "goals"], onboarded: true))
    }

    func test_unknownKeyIsIgnored() {
        var hook = RoostHook()
        XCTAssertNil(hook.take(arguments: ["-ReviewScreen", "aura"], onboarded: true))
        XCTAssertTrue(hook.consumed)
    }

    func test_todayLogGoalsOpenThreeLanes() {
        var today = RoostHook()
        XCTAssertEqual(today.take(arguments: ["-ReviewScreen", "today"], onboarded: true), .today)
        XCTAssertEqual(ReviewRoost.today.lane, .flock)

        var log = RoostHook()
        XCTAssertEqual(log.take(arguments: ["-ReviewScreen", "log"], onboarded: true), .log)
        XCTAssertEqual(ReviewRoost.log.lane, .analytics)

        var goals = RoostHook()
        XCTAssertEqual(goals.take(arguments: ["-ReviewScreen", "goals"], onboarded: true), .goals)
        XCTAssertEqual(ReviewRoost.goals.lane, .settings)

        XCTAssertNotEqual(ReviewRoost.today, ReviewRoost.log)
        XCTAssertNotEqual(ReviewRoost.log, ReviewRoost.goals)
        XCTAssertNotEqual(ReviewRoost.today, ReviewRoost.goals)
        XCTAssertNotEqual(ReviewRoost.today.lane, ReviewRoost.log.lane)
        XCTAssertNotEqual(ReviewRoost.log.lane, ReviewRoost.goals.lane)
        XCTAssertNotEqual(ReviewRoost.today.lane, ReviewRoost.goals.lane)
    }

    func test_missingValueDoesNotCrash() {
        var hook = RoostHook()
        XCTAssertNil(hook.take(arguments: ["-ReviewScreen"], onboarded: true))
        XCTAssertTrue(hook.consumed)
    }

    func test_defaultArgumentsReadProcessInfoAfterOnboarding() {
        var hook = RoostHook()
        XCTAssertNil(hook.take(onboarded: false))
        XCTAssertFalse(hook.consumed)
        _ = hook.take(arguments: ProcessInfo.processInfo.arguments, onboarded: true)
        XCTAssertTrue(hook.consumed)
    }
}
