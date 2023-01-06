import Alamofire

/// Converter to convert Jetpack tunnel requests into REST API requests if needed
///
struct RequestConverter {
    let credentials: Credentials?

    func convert(_ request: URLRequestConvertible) -> URLRequestConvertible {
        guard let convertibleRequest = request as? RESTRequestConvertible,
              case let .wporg(_, _, siteAddress) = credentials,
              let restRequest = convertibleRequest.asRESTRequest(with: siteAddress) else {
            return request
        }

        return restRequest
    }
}
