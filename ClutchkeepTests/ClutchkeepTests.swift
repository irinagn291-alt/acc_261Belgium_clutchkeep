import XCTest
@testable import Clutchkeep

final class ClutchkeepTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: ClutchkeepApp.self), "ClutchkeepApp")
        XCTAssertEqual(RoostInk.background, "#F5FAFA")
        XCTAssertEqual(RoostLink.contact.absoluteString, "https://clutchkeep-roost.pro/contact-us")
    }
}
