import Alamofire

/// Converter to convert Jetpack tunnel requests into REST API requests if needed
///
struct RequestConverter {
    let credentials: Credentials?

    func convert(_ request: URLRequestConvertible) -> URLRequestConvertible {
        if request is RESTRequest {
            return request
        }
        let siteAddress: String? = {
            switch credentials {
            case let .wporg(_, _, siteAddress):
                return siteAddress
            case let .applicationPassword(_, _, siteAddress):
                return siteAddress
            case .wpcom:
                return credentials?.appPasswordCompanion?.siteURL // TODO: Here I need to check if the app password is valid for that site id
            default:
                return nil
            }
        }()
        guard let convertibleRequest = request as? RESTRequestConvertible,
              let siteAddress,
              let restRequest = convertibleRequest.asRESTRequest(with: siteAddress) else {
            return request
        }

        return restRequest
    }
}
