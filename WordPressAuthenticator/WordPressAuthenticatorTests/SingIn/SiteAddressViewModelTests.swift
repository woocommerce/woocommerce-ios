import XCTest
@testable import WordPressAuthenticator

final class SiteAddressViewModelTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()

        WordPressAuthenticator.initializeForTesting()
    }

    func testGuessXMLRPCURLSuccess() {
        let mockFacade = MockWordPressXMLRPCAPIFacade()
        mockFacade.success = true
        let viewModel = SiteAddressViewModel(isSiteDiscovery: false, xmlrpcFacade: mockFacade, authenticationDelegate: WordPressAuthenticatorDelegateSpy(), loginFields: LoginFields())
        viewModel.guessXMLRPCURL(for: "testsite.com") { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
            default:
                XCTFail("Unexpected result")
            }
        }
    }

    func testGuessXMLRPCURLError() {
        let mockFacade = MockWordPressXMLRPCAPIFacade()
        mockFacade.success = false
        mockFacade.error = NSError(domain: "Test", code: 999, userInfo: nil)
        let viewModel = SiteAddressViewModel(isSiteDiscovery: false, xmlrpcFacade: mockFacade, authenticationDelegate: WordPressAuthenticatorDelegateSpy(), loginFields: LoginFields())
        viewModel.guessXMLRPCURL(for: "testsite.com") { result in
            switch result {
            case .error(let error, _):
                XCTAssertEqual(error.code, 999)
            default:
                XCTFail("Unexpected result")
            }
        }
    }

    func testGuessXMLRPCURLErrorHandledByDelegate() {
        let mockFacade = MockWordPressXMLRPCAPIFacade()
        mockFacade.success = false
        mockFacade.error = NSError(domain: "Test", code: 999, userInfo: nil)
        let mockDelegate = WordPressAuthenticatorDelegateSpy()
        mockDelegate.shouldHandleError = true
        let viewModel = SiteAddressViewModel(isSiteDiscovery: false, xmlrpcFacade: mockFacade, authenticationDelegate: mockDelegate, loginFields: LoginFields())
        viewModel.guessXMLRPCURL(for: "testsite.com") { result in
            switch result {
            case .customUI:
                XCTAssertTrue(true)
            default:
                XCTFail("Unexpected result")
            }
        }
    }
}


private class MockWordPressXMLRPCAPIFacade: WordPressXMLRPCAPIFacade {
    var success: Bool = false
    var error: NSError?

    override func guessXMLRPCURL(forSite siteAddress: String, success: @escaping (URL?) -> (), failure: @escaping (Error?) -> ()) {
        if self.success {
            success(URL(string: "https://successful.site"))
        } else {
            failure(self.error)
        }
    }
}
