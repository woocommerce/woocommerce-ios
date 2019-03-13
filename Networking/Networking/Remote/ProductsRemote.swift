import Foundation
import Alamofire


/// Product: Remote Endpoints
///
public class ProductsRemote: Remote {
    public func loadAllProducts(for siteID: Int, completion: @escaping ([Product]?, Error?) -> Void) {
        let path = Constants.productsPath
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = ProductListMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants
//
public extension ProductsRemote {
    private enum Constants {
        static let productsPath = "products"
    }
}
