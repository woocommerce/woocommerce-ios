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
    typealias DuplicateProductCompletion = (_ result: Result<ResultData, ProductUpdateError>) -> Void

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
                    successEventName: WooAnalyticsStat = .addProductSuccess,
                    failureEventName: WooAnalyticsStat = .addProductFailed,
                    onCompletion: @escaping AddProductCompletion) {
        addProductRemotely(product: product) { productResult in
            switch productResult {
            case .failure(let error):
                ServiceLocator.analytics.track(failureEventName, withError: error)
                onCompletion(.failure(error))
            case .success(let product):
                // `self` is retained because the use case is not usually strongly held.
                self.updatePasswordRemotely(product: product, password: password) { passwordResult in
                    switch passwordResult {
                    case .failure(let error):
                        ServiceLocator.analytics.track(failureEventName, withError: error)
                        onCompletion(.failure(.passwordCannotBeUpdated))
                    case .success(let password):
                        ServiceLocator.analytics.track(successEventName)
                        onCompletion(.success(ResultData(product: product, password: password)))
                    }
                }
            }
        }
    }

    /// Adds a copy of the input product remotely. The new product will have an updated name, no SKU and its status will be Draft.
    /// - Parameters:
    ///   - originalProduct: The product to be duplicated remotely.
    ///   - onCompletion: Called when the remote process finishes.
    func duplicateProduct(originalProduct: EditableProductModel,
                          password: String?,
                          onCompletion: @escaping DuplicateProductCompletion) {
        let productModelToSave: EditableProductModel = {
            let newName = String(format: Localization.copyProductName, originalProduct.name)
            let copiedProduct = originalProduct.product.copy(
                productID: 0,
                name: newName,
                statusKey: ProductStatus.draft.rawValue,
                sku: .some(nil) // just resetting SKU to nil for simplicity
            )
            return EditableProductModel(product: copiedProduct)
        }()

        let successEventName: WooAnalyticsStat = .duplicateProductSuccess
        let failureEventName: WooAnalyticsStat = .duplicateProductFailed

        addProduct(product: productModelToSave,
                   password: password,
                   successEventName: successEventName,
                   failureEventName: failureEventName) { result in
            switch result {
            case .success(let data):
                guard data.product.productType == .variable else {
                    return onCompletion(.success(data))
                }
                // `self` is retained because the use case is not usually strongly held.
                self.duplicateVariations(originalProduct.product.variations,
                                         from: originalProduct.productID,
                                         to: data.product,
                                         onCompletion: { result in
                    switch result {
                    case .success(let product):
                        ServiceLocator.analytics.track(successEventName)
                        onCompletion(.success(ResultData(product: product, password: data.password)))
                    case .failure(let error):
                        ServiceLocator.analytics.track(failureEventName, withError: error)
                        onCompletion(.failure(error))
                    }
                })
            case .failure(let error):
                onCompletion(.failure(error))
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
        // Only update product password if available and user is authenticated with WPCom.
        guard let updatedPassword = password,
              stores.isAuthenticatedWithoutWPCom == false else {
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

    func duplicateVariations(_ variationIDs: [Int64],
                             from oldProductID: Int64,
                             to newProduct: EditableProductModel,
                             onCompletion: @escaping (Result<EditableProductModel, ProductUpdateError>) -> Void) {
        Task { [weak self] in
            guard let self = self else { return }
            // Retrieves and duplicate product variations
            await withTaskGroup(of: Void.self, body: { group in
                for id in variationIDs {
                    group.addTask {
                        guard let variation = await self.retrieveProductVariation(variationID: id, siteID: newProduct.siteID, productID: oldProductID) else {
                            return
                        }
                        let newVariation = CreateProductVariation(regularPrice: variation.regularPrice ?? "",
                                                                  salePrice: variation.salePrice ?? "",
                                                                  attributes: variation.attributes,
                                                                  description: variation.description ?? "",
                                                                  image: variation.image)
                        await self.duplicateProductVariation(newVariation, parent: newProduct)
                    }
                }
            })

            // Fetches the updated product and return
            do {
                let productModel = try await retrieveProduct(id: newProduct.productID, siteID: newProduct.siteID)
                await MainActor.run {
                    let updatedProduct = EditableProductModel(product: productModel)
                    onCompletion(.success(updatedProduct))
                }
            } catch let error {
                await MainActor.run {
                    onCompletion(.failure(.unknown(error: AnyError(error))))
                }
            }
        }
    }

    func retrieveProduct(id: Int64, siteID: Int64) async throws -> Product {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            let action = ProductAction.retrieveProduct(siteID: siteID, productID: id) { result in
                switch result {
                case .success(let product):
                    continuation.resume(returning: product)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            DispatchQueue.main.async { [weak self] in
                self?.stores.dispatch(action)
            }
        } as Product
    }

    func retrieveProductVariation(variationID: Int64, siteID: Int64, productID: Int64) async -> ProductVariation? {
        await withCheckedContinuation { [weak self] continuation in
            let action = ProductVariationAction.retrieveProductVariation(siteID: siteID,
                                                                         productID: productID,
                                                                         variationID: variationID,
                                                                         onCompletion: { result in
                switch result {
                case .success(let variation):
                    continuation.resume(returning: variation)
                case .failure:
                    continuation.resume(returning: nil)
                }
            })
            DispatchQueue.main.async { [weak self] in
                self?.stores.dispatch(action)
            }
        } as ProductVariation?
    }

    func duplicateProductVariation(_ newVariation: CreateProductVariation, parent: EditableProductModel) async {
        await withCheckedContinuation { [weak self] continuation in
            let createAction = ProductVariationAction.createProductVariation(
                siteID: parent.siteID,
                productID: parent.productID,
                newVariation: newVariation) { result in
                continuation.resume(returning: ())
            }
            DispatchQueue.main.async { [weak self] in
                self?.stores.dispatch(createAction)
            }
        } as Void
    }
}

private extension ProductFormRemoteActionUseCase {
    enum Localization {
        static let copyProductName = NSLocalizedString(
            "%1$@ Copy",
            comment: "The default name for a duplicated product, with %1$@ being the original name. Reads like: Ramen Copy"
        )
    }
}
