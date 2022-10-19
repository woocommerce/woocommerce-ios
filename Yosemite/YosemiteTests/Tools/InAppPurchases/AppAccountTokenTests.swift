import XCTest
@testable import Yosemite

final class AppAccountTokenTests: XCTestCase {
    private let sampleSiteId: Int64 = 1234

    func test_AppAccountToken_encodes_site_id() throws {
        let token = AppAccountToken.tokenWithSiteId(sampleSiteId)
        let tokenString = try XCTUnwrap(token?.uuidString)
        // 0x4D2 is 1234 in hex
        XCTAssertTrue(tokenString.hasSuffix("-0000000004D2"))
    }

    func test_AppAccountToken_decodes_site_id() throws {
        // Random UUID, ensuring last component represents sampleSiteID
        // 0x4D2 is 1234 in hex
        let token = UUID(uuidString: "2BE1D4A7-0126-438A-A525-0000000004D2")!
        let siteID = try XCTUnwrap(AppAccountToken.siteIDFromToken(token))
        XCTAssertEqual(siteID, sampleSiteId)
    }

}
