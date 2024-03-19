import XCTest
@testable import WooCommerce

final class PluginDetailsViewModelTests: XCTestCase {
    func test_when_no_plugin_details_title_then_title_is_not_formatted_with_plugin_name() {
        let sut = PluginDetailsViewModel(siteID: 0, pluginName: "")

        XCTAssertTrue(sut.title == "")
    }

    func test_when_plugin_details_title_then_title_is_formatted_with_plugin_name() {
        let sut = PluginDetailsViewModel(siteID: 0, pluginName: "WooCommerce")

        XCTAssertTrue(sut.title == "WooCommerce" )
    }
}
