import Foundation
import Testing
@testable import ParcelFittingCheck

@Suite("UnitLength.fromStoreUnit")
struct UnitLengthFromStoreUnitTests {

    struct UnitCase: CustomTestStringConvertible {
        let input: String
        let expected: UnitLength
        var testDescription: String { "\(input) → \(expected.symbol)" }
    }

    static let cases: [UnitCase] = [
        UnitCase(input: "in", expected: .inches),
        UnitCase(input: "cm", expected: .centimeters),
        UnitCase(input: "m", expected: .meters),
        UnitCase(input: "mm", expected: .millimeters),
        UnitCase(input: "yd", expected: .yards),
    ]

    @Test(arguments: cases)
    func test_fromStoreUnit(_ testCase: UnitCase) {
        #expect(UnitLength.fromStoreUnit(testCase.input) == testCase.expected)
    }

    @Test func test_fromStoreUnit_when_unknown_then_defaults_to_centimeters() {
        #expect(UnitLength.fromStoreUnit("ft") == .centimeters)
    }

    @Test func test_fromStoreUnit_when_uppercase_then_still_matches() {
        #expect(UnitLength.fromStoreUnit("IN") == .inches)
    }
}

extension UnitLengthFromStoreUnitTests.UnitCase: Sendable {}
