import XCTest

@testable import Networking

final class URL_PreviewTests: XCTestCase {

    func testAppendingProductPreviewParamsToAProductURL() {
        let url = URL(string: "https://woostore.com/?post_type=product&p=834")
        guard let urlWithPreviewParams = url?.appendingProductPreviewParameters() else {
            XCTFail("Unable to append product preview params")
            return
        }
        guard let components = URLComponents(url: urlWithPreviewParams, resolvingAgainstBaseURL: false) else {
            XCTFail("Cannot get components from URL: \(urlWithPreviewParams)")
            return
        }
        XCTAssertEqual(components.queryItems?.count, 3)
        XCTAssertTrue(components.queryItems?
            .contains(where: { $0.name == "preview" && $0.value == "true" }) == true)
    }
}
