import Alamofire

/// Converter to convert Jetpack tunnel requests into REST API requests if needed
///
struct RequestConverter {
    let credentials: Credentials?

    func convert(_ request: URLRequestConvertible) -> URLRequestConvertible {
        guard let jetpackRequest = request as? JetpackRequest,
              case let .wporg(_, _, siteAddress) = credentials,
              let restRequest = jetpackRequest.asRESTRequest(with: siteAddress) else {
            return request
        }

        return restRequest
    }
}
