import Yosemite

/// Makes network requests for each product form remote action that includes adding/editing a product and password.
///
final class ProductFormRemoteActionUseCase {
    typealias AddProductCompletion = (_ productResult: Result<EditableProductModel, ProductUpdateError>, _ passwordResult: Result<String?, Error>?) -> Void
    typealias EditProductCompletion = (_ productResult: Result<EditableProductModel, ProductUpdateError>, _ passwordResult: Result<String?, Error>) -> Void

    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    /// Adds a product and sets its password remotely.
    /// - Parameters:
    ///   - product: The product to be added remotely.
    ///   - password: Optional password of the product.
    ///   - onCompletion: Called when the remote process finishes.
    func addProduct(product: EditableProductModel,
                    password: String?,
                    onCompletion: @escaping AddProductCompletion) {
        addProductRemotely(product: product) { productResult in
            switch productResult {
            case .failure(let error):
                // TODO-2766: M4 analytics
                onCompletion(.failure(error), nil)
            case .success(let product):
                // `self` is retained because the use case is not usually strongly held.
                self.updatePasswordRemotely(product: product, password: password) { passwordResult in
                    switch passwordResult {
                    case .failure(let error):
                        // TODO-2766: M4 analytics
                        onCompletion(.success(product), .failure(error))
                    case .success(let password):
                        // TODO-2766: M4 analytics
                        onCompletion(.success(product), .success(password))
                    }
                }
            }
        }
    }

    /// Edits a product and its password remotely.
    /// - Parameters:
    ///   - product: The product to be updated remotely.
    ///   - originalProduct: The original product before any edits.
    ///   - password: Optional password of the product.
    ///   - originalPassword: Optional password of the original product.
    ///   - onCompletion: Called when the remote process finishes.
    func editProduct(product: EditableProductModel,
                     originalProduct: EditableProductModel,
                     password: String?,
                     originalPassword: String?,
                     onCompletion: @escaping EditProductCompletion) {
        let group = DispatchGroup()

        var productResult: Result<EditableProductModel, ProductUpdateError>?
        var passwordResult: Result<String?, Error>?

        group.enter()
        editProductRemotely(product: product, originalProduct: originalProduct) { result in
            productResult = result
            group.leave()
        }

        group.enter()
        updatePasswordRemotely(product: product, password: password, originalPassword: originalPassword) { result in
            passwordResult = result
            group.leave()
        }

        group.notify(queue: .main) {
            guard let productResult = productResult, let passwordResult = passwordResult else {
                assertionFailure("Unexpected nil result after updating product and password remotely")
                return
            }
            onCompletion(productResult, passwordResult)
        }
    }
}

private extension ProductFormRemoteActionUseCase {
    func addProductRemotely(product: EditableProductModel, onCompletion: @escaping (Result<EditableProductModel, ProductUpdateError>) -> Void) {
        let updateProductAction = ProductAction.addProduct(product: product.product) { result in
            switch result {
            case .failure(let error):
                onCompletion(.failure(error))
            case .success(let product):
                let model = EditableProductModel(product: product)
                onCompletion(.success(model))
            }
        }
        stores.dispatch(updateProductAction)
    }

    func editProductRemotely(product: EditableProductModel,
                               originalProduct: EditableProductModel,
                               onCompletion: @escaping (Result<EditableProductModel, ProductUpdateError>) -> Void) {
        // Update product password if available
        guard product != originalProduct else {
            onCompletion(.success(product))
            return
        }

        let updateProductAction = ProductAction.updateProduct(product: product.product) { result in
            switch result {
            case .failure(let error):
                ServiceLocator.analytics.track(.productDetailUpdateError, withError: error)
                onCompletion(.failure(error))
            case .success(let product):
                ServiceLocator.analytics.track(.productDetailUpdateSuccess)
                let model = EditableProductModel(product: product)
                onCompletion(.success(model))
            }
        }
        stores.dispatch(updateProductAction)
    }

    func updatePasswordRemotely(product: EditableProductModel,
                                password: String?,
                                originalPassword: String?,
                                onCompletion: @escaping (Result<String?, Error>) -> Void) {
        // Update product password if available
        guard password != originalPassword else {
            onCompletion(.success(password))
            return
        }
        updatePasswordRemotely(product: product, password: password, onCompletion: onCompletion)
    }

    func updatePasswordRemotely(product: EditableProductModel,
                                password: String?,
                                onCompletion: @escaping (Result<String?, Error>) -> Void) {
        guard let updatedPassword = password else {
            onCompletion(.success(password))
            return
        }
        let passwordUpdateAction = SitePostAction.updateSitePostPassword(siteID: product.siteID,
                                                                         postID: product.productID,
                                                                         password: updatedPassword) { result in
                                                                            switch result {
                                                                            case .failure(let error):
                                                                                DDLogError("⛔️ Error updating product password: \(error)")
                                                                                onCompletion(.failure(error))
                                                                            case .success(let password):
                                                                                onCompletion(.success(password))
                                                                            }
        }
        stores.dispatch(passwordUpdateAction)
    }
}
