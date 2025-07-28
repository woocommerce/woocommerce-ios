import Foundation

protocol RESTRequestConvertible {
    /// Returns a `RESTRequest`
    ///
    /// - Parameter siteURL: url of the site to which the REST API request will be sent to
    ///
    /// - Returns: optional `RESTRequest` to send to the REST API
    func asRESTRequest(with siteURL: String) -> RESTRequest?
}
