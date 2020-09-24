import Yosemite

/// Makes network requests for each product form remote action that includes adding/editing a product and password.
///
final class ProductFormRemoteActionUseCase {
    /// A wrapper of product password in add/edit remote action's result.
    struct ResultData: Equatable {
        let product: EditableProductModel
        let password: String?
    }
    typealias AddProductCompletion = (_ result: Result<ResultData, ProductUpdateError>) -> Void
    typealias EditProductCompletion = (_ productResult: Result<ResultData, ProductUpdateError>) -> Void

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
                onCompletion(.failure(error))
            case .success(let product):
                // `self` is retained because the use case is not usually strongly held.
                self.updatePasswordRemotely(product: product, password: password) { passwordResult in
                    switch passwordResult {
                    case .failure:
                        // TODO-2766: M4 analytics
                        onCompletion(.failure(.passwordCannotBeUpdated))
                    case .success(let password):
                        // TODO-2766: M4 analytics
                        onCompletion(.success(ResultData(product: product, password: password)))
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
                onCompletion(.failure(.unexpected))
                return
            }

            do {
                let product = try productResult.get()
                let password = try passwordResult.get()
                onCompletion(.success(ResultData(product: product, password: password)))
            } catch {
                if let productError = productResult.failure {
                    onCompletion(.failure(productError))
                    return
                }
                if passwordResult.isFailure {
                    onCompletion(.failure(.passwordCannotBeUpdated))
                    return
                }
                assertionFailure("""
                    Unexpected error with product result: \(productResult)\npassword result: \(passwordResult)
                    """)
                onCompletion(.failure(.unexpected))
            }
        }
    }

    /// Delete a product remotely.
    /// - Parameters:
    ///   - product: The product to be deleted remotely.
    ///   - onCompletion: Called when the remote process finishes.
    func deleteProduct(product: EditableProductModel, onCompletion: @escaping EditProductCompletion) {
        deleteProductRemotely(product: product) { productResult in
            switch productResult {
            case .failure(let error):
                // TODO: M5 analytics
                onCompletion(.failure(error))
            case .success(let product):
                // TODO: M5 analytics
                onCompletion(.success(ResultData(product: product, password: nil)))
            }
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
        // Only update product if different.
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

    func deleteProductRemotely(product: EditableProductModel,
                               onCompletion: @escaping (Result<EditableProductModel, ProductUpdateError>) -> Void) {
        let deleteProductAction = ProductAction.deleteProduct(siteID: product.siteID, productID: product.productID) { result in
            switch result {
            case .failure(let error):
                onCompletion(.failure(error))
            case .success(let product):
                let model = EditableProductModel(product: product)
                onCompletion(.success(model))
            }
        }
        stores.dispatch(deleteProductAction)
    }

    func updatePasswordRemotely(product: EditableProductModel,
                                password: String?,
                                originalPassword: String?,
                                onCompletion: @escaping (Result<String?, Error>) -> Void) {
        // Only update product password if different.
        guard password != originalPassword else {
            onCompletion(.success(password))
            return
        }
        updatePasswordRemotely(product: product, password: password, onCompletion: onCompletion)
    }

    func updatePasswordRemotely(product: EditableProductModel,
                                password: String?,
                                onCompletion: @escaping (Result<String?, Error>) -> Void) {
        // Only update product password if available.
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
