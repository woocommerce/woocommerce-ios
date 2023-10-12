import XCTest
@testable import WooCommerce

final class AboutTapToPayContactlessLimitViewModelTests: XCTestCase {

    func test_for_gb_configuration_a_formatted_limit_paragraph_is_provided() {
        let sut = AboutTapToPayContactlessLimitViewModel(configuration: .init(country: .GB))
        assertEqual("In the United Kingdom, cards may only be used with Tap to Pay for transactions up to £100.", sut.contactlessLimitDetails)
    }

    func test_for_us_configuration_a_fallback_paragraph_is_provided_because_the_view_is_not_shown() {
        let sut = AboutTapToPayContactlessLimitViewModel(configuration: .init(country: .US))
        assertEqual("In United States, cards may only be used with Tap to Pay for transactions up to the contactless limit.", sut.contactlessLimitDetails)
    }

}
