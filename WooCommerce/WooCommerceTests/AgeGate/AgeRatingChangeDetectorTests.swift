import XCTest
@testable import WooCommerce

final class AgeRatingChangeDetectorTests: XCTestCase {
    private enum Constants {
        static let userDefaultsDomain = "AgeRatingChangeDetectorTests"
        static let cacheKey = "ageRatingChangeDetector.lastSeenAgeRating"
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

    func test_checkForChange_when_no_cached_value_then_baselines_without_reporting_a_change() async {
        // Given
        provider.code = 1

        // When
        let result = await sut.checkForChange()

        // Then
        XCTAssertNil(result)
        XCTAssertEqual(defaults.integer(forKey: Constants.cacheKey), 1)
    }

    func test_checkForChange_when_same_as_cached_then_returns_nil() async {
        // Given
        defaults.set(2, forKey: Constants.cacheKey)
        provider.code = 2

        // When
        let result = await sut.checkForChange()

        // Then
        XCTAssertNil(result)
        XCTAssertEqual(defaults.integer(forKey: Constants.cacheKey), 2)
    }

    func test_checkForChange_when_different_from_cached_then_reports_change_without_consuming_it() async {
        // Given
        defaults.set(1, forKey: Constants.cacheKey)
        provider.code = 3

        // When
        let firstResult = await sut.checkForChange()
        let secondResult = await sut.checkForChange()

        // Then
        XCTAssertEqual(firstResult, .ageRatingChanged(previous: 1, current: 3))
        // The change must keep being reported until acknowledged, so an unresolved
        // consent (pending/denied) survives relaunches.
        XCTAssertEqual(secondResult, .ageRatingChanged(previous: 1, current: 3))
        XCTAssertEqual(defaults.integer(forKey: Constants.cacheKey), 1)
    }

    func test_acknowledge_when_called_then_subsequent_check_reports_no_change() async {
        // Given
        defaults.set(1, forKey: Constants.cacheKey)
        provider.code = 3

        // When
        sut.acknowledge(ratingCode: 3)
        let result = await sut.checkForChange()

        // Then
        XCTAssertNil(result)
        XCTAssertEqual(defaults.integer(forKey: Constants.cacheKey), 3)
    }
}

private final class MockAgeRatingProvider: AgeRatingProviding {
    var code: Int?
    func currentAgeRating() async -> Int? {
        code
    }
}
