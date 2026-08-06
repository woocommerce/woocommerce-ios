import Foundation
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
        addProduct(product: product,
                   password: password,
                   successEventName: successEventName,
                   failureEventName: failureEventName,
                   trackAnalytics: true) { result, _ in
            onCompletion(result)
        }
    }

    /// Duplicates a product remotely, using the core endpoint when available and a compatibility fallback on older stores.
    /// - Parameters:
    ///   - originalProduct: The product to be duplicated remotely.
    ///   - password: Optional password of the duplicated product.
    ///   - onCompletion: Called when the complete duplication flow finishes.
    func duplicateProduct(originalProduct: EditableProductModel,
                          password: String?,
                          onCompletion: @escaping DuplicateProductCompletion) {
        let trackedCompletion: (_ result: Result<ResultData, ProductUpdateError>, _ analyticsError: Error?) -> Void = { result, analyticsError in
            switch result {
            case .success:
                ServiceLocator.analytics.track(.duplicateProductSuccess)
            case .failure(let error):
                ServiceLocator.analytics.track(.duplicateProductFailed, withError: analyticsError ?? error)
            }
            onCompletion(result)
        }

        let action = ProductAction.duplicateProduct(siteID: originalProduct.siteID, productID: originalProduct.productID) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let duplicatedProductID):
                self.retrieveDuplicatedProduct(id: duplicatedProductID,
                                                siteID: originalProduct.siteID,
                                                password: password,
                                                onCompletion: trackedCompletion)
            case .failure(.endpointUnavailable):
                self.duplicateProductUsingLegacyFlow(originalProduct: originalProduct,
                                                     password: password,
                                                     onCompletion: trackedCompletion)
            case .failure(.unknown(let error)):
                trackedCompletion(.failure(.unknown(error: error)), error)
            }
        }
        stores.dispatch(action)
    }

    /// Compatibility fallback for stores where the core duplication endpoint is conclusively unavailable.
    private func duplicateProductUsingLegacyFlow(originalProduct: EditableProductModel,
                                                 password: String?,
                                                 onCompletion: @escaping (_ result: Result<ResultData, ProductUpdateError>,
                                                                          _ analyticsError: Error?) -> Void) {
        let productModelToSave: EditableProductModel = {
            let newName = String(format: Localization.copyProductName, originalProduct.name)
            let copiedProduct = originalProduct.product.copy(
                productID: 0,
                name: newName,
                slug: "", // let the server assign a unique slug for the duplicate instead of reusing the original's
                permalink: "", // derived server-side; cleared for local consistency
                statusKey: ProductStatus.draft.rawValue,
                sku: .some(nil), // just resetting SKU to nil for simplicity
                password: password
            )
            return EditableProductModel(product: copiedProduct)
        }()

        addProduct(product: productModelToSave,
                   password: password,
                   successEventName: .duplicateProductSuccess,
                   failureEventName: .duplicateProductFailed,
                   trackAnalytics: false) { [weak self] result, analyticsError in
            guard let self else { return }
            switch result {
            case .success(let data):
                let originalCustomFields = originalProduct.product.customFields

                // Copy custom fields from the original product to the duplicated product.
                self.copyCustomFields(originalCustomFields,
                                      toProductID: data.product.productID,
                                      siteID: data.product.siteID)

                // Wrap completion to optimistically inject custom fields so the UI shows them immediately.
                let onCompletionWithCustomFields = { (result: Result<ResultData, ProductUpdateError>, analyticsError: Error?) in
                    onCompletion(result.map { data in
                        ResultData(product: EditableProductModel(product: data.product.product.copy(customFields: originalCustomFields)),
                                   password: data.password)
                    }, analyticsError)
                }

                let variableTypes: [ProductType] = [.variable, .variableSubscription]
                guard variableTypes.contains(data.product.productType) else {
                    return onCompletionWithCustomFields(.success(data), nil)
                }
                self.duplicateVariations(originalProduct.product.variations,
                                         from: originalProduct.productID,
                                         to: data.product,
                                         onCompletion: { result in
                    switch result {
                    case .success(let product):
                        onCompletionWithCustomFields(.success(ResultData(product: product, password: data.password)), nil)
                    case .failure(let error):
                        onCompletionWithCustomFields(.failure(error), error)
                    }
                })
            case .failure(let error):
                onCompletion(.failure(error), analyticsError)
            }
        }
    }

    private func addProduct(product: EditableProductModel,
                            password: String?,
                            successEventName: WooAnalyticsStat,
                            failureEventName: WooAnalyticsStat,
                            trackAnalytics: Bool,
                            onCompletion: @escaping (_ result: Result<ResultData, ProductUpdateError>,
                                                     _ analyticsError: Error?) -> Void) {
        let updatedProduct = EditableProductModel(product: product.product.copy(password: password))
        addProductRemotely(product: updatedProduct) { productResult in
            switch productResult {
            case .failure(let error):
                if trackAnalytics {
                    ServiceLocator.analytics.track(failureEventName, withError: error)
                }
                onCompletion(.failure(error), error)
            case .success(let product):
                // `self` is retained because the use case is not usually strongly held.
                self.updatePasswordRemotely(product: product, password: password) { passwordResult in
                    switch passwordResult {
                    case .failure(let error):
                        if trackAnalytics {
                            ServiceLocator.analytics.track(failureEventName, withError: error)
                        }
                        onCompletion(.failure(.passwordCannotBeUpdated), error)
                    case .success(let password):
                        if trackAnalytics {
                            ServiceLocator.analytics.track(successEventName)
                        }
                        onCompletion(.success(ResultData(product: product, password: password)), nil)
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

        let updatedProduct = EditableProductModel(product: product.product.copy(password: password))

        group.enter()
        editProductRemotely(product: updatedProduct, originalProduct: originalProduct) { result in
            productResult = result
            group.leave()
        }

        group.enter()
        updatePasswordRemotely(product: updatedProduct, password: password, originalPassword: originalPassword) { result in
            passwordResult = result
            group.leave()
        }

        group.notify(queue: .main) {
            guard let productResult, let passwordResult else {
                assertionFailure("Unexpected nil result after updating product and password remotely")
                onCompletion(.failure(.unexpected))
                return
            }

            do {
                let password = try passwordResult.get()
                // Update the product with the new password
                var updatedProduct = try productResult.get()
                updatedProduct = EditableProductModel(product: updatedProduct.product.copy(password: password))
                onCompletion(.success(ResultData(product: updatedProduct, password: password)))
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

extension ProductFormRemoteActionUseCase {
    /// Fetches the latest product from the server and updates local storage.
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
}

private extension ProductFormRemoteActionUseCase {
    func retrieveDuplicatedProduct(id: Int64,
                                   siteID: Int64,
                                   password: String?,
                                   onCompletion: @escaping (_ result: Result<ResultData, ProductUpdateError>,
                                                            _ analyticsError: Error?) -> Void) {
        let action = ProductAction.retrieveProduct(siteID: siteID, productID: id) { result in
            switch result {
            case .success(let product):
                onCompletion(.success(ResultData(product: EditableProductModel(product: product), password: password)), nil)
            case .failure(let error):
                onCompletion(.failure(.unknown(error: AnyError(error))), error)
            }
        }
        stores.dispatch(action)
    }

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

        // Update the product password using the `updateSitePostPassword` method only if:
        // 1) A password is provided.
        // 2) The user is not authenticated with WPCom or if the store is not eligible for the new `password` field introduced in WC 8.1.
        // Otherwise, update the password locally in the Product model.
        guard let updatedPassword = password,
              stores.isAuthenticatedWithoutWPCom == false || !ProductPasswordEligibilityUseCase().isEligibleForWooProductPasswordEndpoint() else {
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
        Task {
            // Retrieves and duplicate product variations
            await withTaskGroup(of: Void.self, body: { [weak self] group in
                guard let self else { return }
                for id in variationIDs {
                    group.addTask {
                        guard let variation = await self.retrieveProductVariation(variationID: id, siteID: newProduct.siteID, productID: oldProductID) else {
                            return
                        }
                        let newVariation = CreateProductVariation(regularPrice: variation.regularPrice ?? "",
                                                                  salePrice: variation.salePrice ?? "",
                                                                  attributes: variation.attributes,
                                                                  description: variation.description ?? "",
                                                                  image: variation.image,
                                                                  subscription: variation.subscription)
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
            } catch {
                await MainActor.run {
                    onCompletion(.failure(.unknown(error: AnyError(error))))
                }
            }
        }
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

    func copyCustomFields(_ customFields: [MetaData],
                           toProductID newProductID: Int64,
                           siteID: Int64) {
        if customFields.isEmpty { return }
        let metadata: [RequestParameterDictionary] = customFields.map {
            ["key": .string($0.key), "value": .string($0.value.stringValue)]
        }
        let action = MetaDataAction.updateMetaData(
            siteID: siteID,
            parentItemID: newProductID,
            metaDataType: .product,
            metadata: metadata
        ) { result in
            if case .failure(let error) = result {
                DDLogError("⚠️ Failed to copy custom fields to duplicated product: \(error)")
            }
        }
        stores.dispatch(action)
    }

    func duplicateProductVariation(_ newVariation: CreateProductVariation, parent: EditableProductModel) async {
        await withCheckedContinuation { [weak self] continuation in
            let createAction = ProductVariationAction.createProductVariation(
                siteID: parent.siteID,
                productID: parent.productID,
                newVariation: newVariation) { _ in
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
