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

                let persistedProducts = try PersistedProduct
                    .posProductsRequest(siteID: siteID)
                    .limit(pageSize * currentPage)
                    .fetchAll(database)

                return try persistedProducts.map { persistedProduct in
                    let images = try persistedProduct.request(for: PersistedProduct.images).fetchAll(database)
                    let attributes = try persistedProduct.request(for: PersistedProduct.attributes).fetchAll(database)

                    return persistedProduct.toPOSProduct(
                        images: images.map { $0.toProductImage() },
                        attributes: attributes.map { $0.toProductAttribute(siteID: persistedProduct.siteID) }
                    )
                }
            }

        productObservationCancellable = observation
            .publisher(in: grdbManager.databaseConnection)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        Task { @MainActor in
                            self?.error = error
                            self?.isLoadingProducts = false
                        }
                    }
                },
                receiveValue: { [weak self] observedProducts in
                    guard let self else { return }
                    let posItems = itemMapper.mapProductsToPOSItems(products: observedProducts)
                    Task { @MainActor [weak self] in
                        self?.productItems = posItems
                        self?.error = nil
                        self?.isLoadingProducts = false
                    }
                }
            )
    }

    private func setupVariationObservation(parentProduct: POSVariableParentProduct) {
        variationObservationCancellable?.cancel()

        let currentPage = currentVariationPage
        let observation = ValueObservation
            .tracking { [weak self] database -> [POSProductVariation] in
                guard let self else { return [] }

                let persistedVariations = try PersistedProductVariation
                    .posVariationsRequest(siteID: self.siteID, parentProductID: parentProduct.productID)
                    .limit(self.pageSize * currentPage)
                    .fetchAll(database)

                return try persistedVariations.map { persistedVariation in
                    let attributes = try persistedVariation.request(for: PersistedProductVariation.attributes).fetchAll(database)
                    let image = try persistedVariation.request(for: PersistedProductVariation.image).fetchOne(database)

                    return persistedVariation.toPOSProductVariation(
                        attributes: attributes.map { $0.toProductVariationAttribute() },
                        image: image?.toProductImage()
                    )
                }
            }

        variationObservationCancellable = observation
            .publisher(in: grdbManager.databaseConnection)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        Task { @MainActor in
                            self?.error = error
                            self?.isLoadingVariations = false
                        }
                    }
                },
                receiveValue: { [weak self] observedVariations in
                    guard let self else { return }
                    let posItems = itemMapper.mapVariationsToPOSItems(
                        variations: observedVariations,
                        parentProduct: parentProduct
                    )
                    Task { @MainActor [weak self] in
                        self?.variationItems = posItems
                        self?.error = nil
                        self?.isLoadingVariations = false
                    }
                }
            )
    }

    private func setupStatisticsObservation() {
        let observation = ValueObservation
            .tracking { [weak self] database in
                guard let self else { return (0, 0) }

                let productCount = try PersistedProduct
                    .posProductsRequest(siteID: siteID)
                    .fetchCount(database)

                let variationCount = try PersistedProductVariation
                    .filter(PersistedProductVariation.Columns.siteID == siteID)
                    .fetchCount(database)

                return (productCount, variationCount)
            }

        statisticsObservationCancellable = observation
            .publisher(in: grdbManager.databaseConnection)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        // Silently ignore - statistics are not critical
                    }
                },
                receiveValue: { [weak self] (productCount, variationCount) in
                    Task { @MainActor in
                        self?.totalProductCount = productCount
                        self?.totalVariationCount = variationCount
                    }
                }
            )
    }
}
