import XCTest
@testable import VaporGenerators

class VaporGeneratorsTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(VaporGenerators().text, "Hello, World!")
    }


    static var allTests : [(String, (VaporGeneratorsTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
