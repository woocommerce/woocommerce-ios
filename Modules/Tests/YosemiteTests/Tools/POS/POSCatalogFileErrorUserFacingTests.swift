import Foundation
import Testing
import enum NetworkingCore.POSCatalogFileError
@testable import Yosemite

/// Classification of low-level catalog file response facts into the host-blocked condition.
struct POSCatalogFileErrorUserFacingTests {
    private let parseError = NSError(domain: "Test", code: 0)

    @Test func downloadFailed_with_403_is_blocked() {
        #expect(POSCatalogFileError.downloadFailed(statusCode: 403, contentType: nil).isPOSCatalogFileBlockedError)
        #expect(POSCatalogFileError.downloadFailed(statusCode: 403, contentType: "text/html; charset=UTF-8").isPOSCatalogFileBlockedError)
    }

    @Test func downloadFailed_with_html_content_type_is_blocked() {
        #expect(POSCatalogFileError.downloadFailed(statusCode: 503, contentType: "text/html").isPOSCatalogFileBlockedError)
        #expect(POSCatalogFileError.downloadFailed(statusCode: 503, contentType: "TEXT/HTML; charset=UTF-8").isPOSCatalogFileBlockedError)
    }

    @Test func downloadFailed_without_blocked_facts_is_not_blocked() {
        #expect(!POSCatalogFileError.downloadFailed(statusCode: 404, contentType: nil).isPOSCatalogFileBlockedError)
        #expect(!POSCatalogFileError.downloadFailed(statusCode: 500, contentType: "application/json").isPOSCatalogFileBlockedError)
    }

    @Test func invalidResponse_with_html_body_is_blocked() {
        // The background-download parse path has no response metadata — the body fact alone decides.
        let error = POSCatalogFileError.invalidResponse(statusCode: nil, contentType: nil, hasHTMLBody: true, underlyingError: parseError)
        #expect(error.isPOSCatalogFileBlockedError)
    }

    @Test func invalidResponse_with_html_content_type_is_blocked() {
        let error = POSCatalogFileError.invalidResponse(statusCode: 200, contentType: "text/html", hasHTMLBody: false, underlyingError: parseError)
        #expect(error.isPOSCatalogFileBlockedError)
    }

    @Test func invalidResponse_without_blocked_facts_is_not_blocked() {
        let error = POSCatalogFileError.invalidResponse(statusCode: 200, contentType: "application/json", hasHTMLBody: false, underlyingError: parseError)
        #expect(!error.isPOSCatalogFileBlockedError)
    }

    @Test func non_catalog_file_errors_are_not_blocked() {
        #expect(!NSError(domain: "Test", code: 403).isPOSCatalogFileBlockedError)
        #expect(!URLError(.notConnectedToInternet).isPOSCatalogFileBlockedError)
    }
}
