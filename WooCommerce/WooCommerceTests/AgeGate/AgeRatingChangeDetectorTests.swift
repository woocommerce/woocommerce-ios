import XCTest
@testable import WooCommerce

final class AgeRatingChangeDetectorTests: XCTestCase {
    private enum Constants {
        static let userDefaultsDomain = "AgeRatingChangeDetectorTests"
    }

    private var defaults: UserDefaults!
    private var provider: MockAgeRatingProvider!
    private var sut: AgeRatingChangeDetector!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: Constants.userDefaultsDomain)
        provider = MockAgeRatingProvider()
        sut = AgeRatingChangeDetector(defaults: defaults, provider: provider)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: Constants.userDefaultsDomain)
        defaults = nil
        provider = nil
        sut = nil
        super.tearDown()
    }

    func test_checkForChange_whenNoCachedValue_returnsEventAndCaches() async {
        provider.code = 1

        let result = await sut.checkForChange()

        XCTAssertNotNil(result)
        if case let .ageRatingChanged(previous, current) = result! {
            XCTAssertNil(previous)
            XCTAssertEqual(current, 1)
        } else {
            XCTFail("Unexpected result \(String(describing: result))")
        }
        XCTAssertEqual(defaults.integer(forKey: "ageRatingChangeDetector.lastSeenAgeRating"), 1)
    }

    func test_checkForChange_whenSameAsCached_returnsNil() async {
        defaults.set(2, forKey: "ageRatingChangeDetector.lastSeenAgeRating")
        provider.code = 2

        let result = await sut.checkForChange()

        XCTAssertNil(result)
        XCTAssertEqual(defaults.integer(forKey: "ageRatingChangeDetector.lastSeenAgeRating"), 2)
    }

    func test_checkForChange_whenDifferentFromCached_returnsEventWithPrevious() async {
        defaults.set(1, forKey: "ageRatingChangeDetector.lastSeenAgeRating")
        provider.code = 3

        let result = await sut.checkForChange()

        XCTAssertNotNil(result)
        if case let .ageRatingChanged(previous, current) = result! {
            XCTAssertEqual(previous, 1)
            XCTAssertEqual(current, 3)
        } else {
            XCTFail("Unexpected result \(String(describing: result))")
        }
        XCTAssertEqual(defaults.integer(forKey: "ageRatingChangeDetector.lastSeenAgeRating"), 3)
    }
}

private final class MockAgeRatingProvider: AgeRatingProviding {
    var code: Int?
    func currentAgeRating() async -> Int? {
        code
    }
}
