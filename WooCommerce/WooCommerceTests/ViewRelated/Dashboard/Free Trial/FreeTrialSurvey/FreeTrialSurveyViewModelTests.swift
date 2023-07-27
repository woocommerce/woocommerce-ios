import XCTest
@testable import WooCommerce

final class FreeTrialSurveyViewModelTests: XCTestCase {
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()

        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil

        super.tearDown()
    }

    func test_answers_has_correct_values() {
        // Given
        let viewModel = FreeTrialSurveyViewModel(source: .freeTrialSurvey24hAfterFreeTrialSubscribed,
                                                 onClose: {},
                                                 onSubmit: {},
                                                 analytics: analytics)

        // Then
        XCTAssertEqual(viewModel.answers, FreeTrialSurveyViewModel.SurveyAnswer.allCases)
    }
}
