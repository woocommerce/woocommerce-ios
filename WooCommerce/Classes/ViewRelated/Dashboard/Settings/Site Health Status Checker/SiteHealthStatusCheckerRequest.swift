import Foundation

struct SiteHealthStatusCheckerRequest {

    /// Name of the endpoint. Eg. `Orders`
    ///
    var endpointName: String?

    /// Name of the action. Eg. `Orders retrieve`
    ///
    var actionName: String?

    /// Result of the response
    ///
    var success: Bool?

    /// The error, if available
    ///
    var error: Error?

    /// The time took for the request
    ///
    var time: TimeInterval?
}
