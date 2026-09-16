import Alamofire

/// Converter to convert Jetpack tunnel requests into REST API requests if needed
///
struct RequestConverter {
    let siteAddress: String?

    func convert(_ request: URLRequestConvertible) -> URLRequestConvertible {
        if request is RESTRequest {
            return request
        }
        guard let convertibleRequest = request as? RESTRequestConvertible,
              let siteAddress,
              let restRequest = convertibleRequest.asRESTRequest(with: siteAddress) else {
            return request
        }

        return restRequest
    }

    /// Whether `convert` would turn `request` into a direct `RESTRequest`, leaving the Jetpack tunnel.
    ///
    func convertsToDirectRequest(_ request: URLRequestConvertible) -> Bool {
        !(request is RESTRequest) && convert(request) is RESTRequest
    }
}
