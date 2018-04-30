import Foundation
import Alamofire


///
///
public class Remote {

    ///
    ///
    let credentials: Credentials

    ///
    ///
    public init(credentials: Credentials) {
        self.credentials = credentials
    }

    ///
    ///
    func request<T>(endpoint: URLConvertible, method: HTTPMethod = .get, completion: @escaping (T) -> Void) {
        Alamofire.request(endpoint, method: method)
            .validate()
            .responseJSON { response in
                guard let payload = response.result.value as? T else {
                    return
                }

                completion(payload)
        }
    }
}
