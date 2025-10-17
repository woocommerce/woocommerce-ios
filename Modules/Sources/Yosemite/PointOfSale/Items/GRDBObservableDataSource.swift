// periphery:ignore:all
import Foundation
import GRDB
import Combine
import Observation
import Storage
import WooFoundation

/// Observable data source for GRDB-based POS items using ValueObservation
/// Provides automatic SwiftUI updates when database changes occur
@Observable
public final class GRDBObservableDataSource: POSObservableDataSourceProtocol {
    // MARK: - Observable Properties

    public private(set) var productItems: [POSItem] = []
    public private(set) var variationItems: [POSItem] = []
    public private(set) var isLoadingProducts: Bool = false
    public private(set) var isLoadingVariations: Bool = false
    public private(set) var error: Error? = nil

    public var hasMoreProducts: Bool {
        productItems.count >= (pageSize * currentProductPage) && totalProductCount > productItems.count
    }

    public var hasMoreVariations: Bool {
        variationItems.count >= (pageSize * currentVariationPage) && totalVariationCount > variationItems.count
    }

    // MARK: - Private Properties

    private let siteID: Int64
    private let grdbManager: GRDBManagerProtocol
    private let itemMapper: PointOfSaleItemMapperProtocol
    private let pageSize: Int

    private var currentProductPage: Int = 1
    private var currentVariationPage: Int = 1
    private var currentParentProduct: POSVariableParentProduct?
    private var totalProductCount: Int = 0
    private var totalVariationCount: Int = 0

    // ValueObservation subscriptions
    private var productObservationCancellable: AnyCancellable?
    private var variationObservationCancellable: AnyCancellable?
    private var statisticsObservationCancellable: AnyCancellable?
    private var variationStatisticsObservationCancellable: AnyCancellable?

    // MARK: - Initialization

    public init(siteID: Int64,
                grdbManager: GRDBManagerProtocol,
                currencySettings: CurrencySettings,
                itemMapper: PointOfSaleItemMapperProtocol? = nil,
                pageSize: Int = 20) {
        self.siteID = siteID
        self.grdbManager = grdbManager
        self.itemMapper = itemMapper ?? PointOfSaleItemMapper(currencySettings: currencySettings)
        self.pageSize = pageSize

        setupStatisticsObservation()
    }

    deinit {
        productObservationCancellable?.cancel()
        variationObservationCancellable?.cancel()
        statisticsObservationCancellable?.cancel()
        variationStatisticsObservationCancellable?.cancel()
    }

    // MARK: - POSObservableDataSourceProtocol

    public func loadProducts() {
        currentProductPage = 1
        isLoadingProducts = true
        setupProductObservation()
    }

    public func loadMoreProducts() {
        guard hasMoreProducts && !isLoadingProducts else { return }

        isLoadingProducts = true
        currentProductPage += 1
        setupProductObservation()
    }

    public func loadVariations(for parentProduct: POSVariableParentProduct) {
        guard currentParentProduct?.productID != parentProduct.productID else {
            return // Same parent - idempotent
        }

        currentParentProduct = parentProduct
        currentVariationPage = 1
        isLoadingVariations = true
        variationItems = []

        setupVariationObservation(parentProduct: parentProduct)
        setupVariationStatisticsObservation(parentProduct: parentProduct)
    }

    public func loadMoreVariations() {
        guard let parentProduct = currentParentProduct,
              hasMoreVariations && !isLoadingVariations else { return }

        isLoadingVariations = true
        currentVariationPage += 1
        setupVariationObservation(parentProduct: parentProduct)
    }

    public func refresh() {
        // No-op: database observation automatically updates when data changes during incremental sync
    }

    // MARK: - ValueObservation Setup

    private func setupProductObservation() {
        let currentPage = currentProductPage
        let observation = ValueObservation
            .tracking { [weak self] database -> [POSProduct] in
                guard let self else { return [] }

                struct ProductWithRelations: Decodable, FetchableRecord {
                    let product: PersistedProduct
                    let images: [PersistedImage]?
                    let attributes: [PersistedProductAttribute]?
                }

                let productsWithRelations = try PersistedProduct
                    .posProductsRequest(siteID: siteID)
                    .limit(pageSize * currentPage)
                    .including(all: PersistedProduct.images)
                    .including(all: PersistedProduct.attributes)
                    .asRequest(of: ProductWithRelations.self)
                    .fetchAll(database)

                return productsWithRelations.map { record in
                    record.product.toPOSProduct(
                        images: (record.images ?? []).map { $0.toProductImage() },
                        attributes: (record.attributes ?? []).map { $0.toProductAttribute(siteID: record.product.siteID) }
                    )
                }
            }

        productObservationCancellable = observation
            .publisher(in: grdbManager.databaseConnection)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = error
                        self?.isLoadingProducts = false
                    }
                },
                receiveValue: { [weak self] observedProducts in
                    guard let self else { return }
                    let posItems = itemMapper.mapProductsToPOSItems(products: observedProducts)
                    productItems = posItems
                    error = nil
                    isLoadingProducts = false
                }
            )
    }

    private func setupVariationObservation(parentProduct: POSVariableParentProduct) {
        let currentPage = currentVariationPage
        let observation = ValueObservation
            .tracking { [weak self] database -> [POSProductVariation] in
                guard let self else { return [] }

                struct VariationWithRelations: Decodable, FetchableRecord {
                    let persistedProductVariation: PersistedProductVariation
                    let attributes: [PersistedProductVariationAttribute]?
                    let image: PersistedImage?
                }

                let variationsWithRelations = try PersistedProductVariation
                    .posVariationsRequest(siteID: self.siteID, parentProductID: parentProduct.productID)
                    .limit(self.pageSize * currentPage)
                    .including(all: PersistedProductVariation.attributes)
                    .including(optional: PersistedProductVariation.image)
                    .asRequest(of: VariationWithRelations.self)
                    .fetchAll(database)

                return variationsWithRelations.map { record in
                    record.persistedProductVariation.toPOSProductVariation(
                        attributes: (record.attributes ?? []).map { $0.toProductVariationAttribute() },
                        image: record.image?.toProductImage()
                    )
                }
            }

        variationObservationCancellable = observation
            .publisher(in: grdbManager.databaseConnection)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = error
                        self?.isLoadingVariations = false
                    }
                },
                receiveValue: { [weak self] observedVariations in
                    guard let self else { return }
                    let posItems = itemMapper.mapVariationsToPOSItems(
                        variations: observedVariations,
                        parentProduct: parentProduct
                    )
                    variationItems = posItems
                    error = nil
                    isLoadingVariations = false
                }
            )
    }

    private func setupStatisticsObservation() {
        let observation = ValueObservation
            .tracking { [weak self] database in
                guard let self else { return 0 }

                let productCount = try PersistedProduct
                    .posProductsRequest(siteID: siteID)
                    .fetchCount(database)

                return productCount
            }

        statisticsObservationCancellable = observation
            .publisher(in: grdbManager.databaseConnection)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        // Silently ignore - statistics are not critical
                    }
                },
                receiveValue: { [weak self] productCount in
                    self?.totalProductCount = productCount
                }
            )
    }

    private func setupVariationStatisticsObservation(parentProduct: POSVariableParentProduct) {
        let observation = ValueObservation
            .tracking { [weak self] database in
                guard let self else { return 0 }

                return try PersistedProductVariation
                    .posVariationsRequest(siteID: siteID, parentProductID: parentProduct.productID)
                    .fetchCount(database)
            }

        variationStatisticsObservationCancellable = observation
            .publisher(in: grdbManager.databaseConnection)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        // Silently ignore - statistics are not critical
                    }
                },
                receiveValue: { [weak self] variationCount in
                    self?.totalVariationCount = variationCount
                }
            )
    }
}
