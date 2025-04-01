import Foundation
import protocol Networking.Network
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings
import Storage

public protocol PointOfSaleItemSearchServiceProtocol: PointOfSaleItemServiceProtocol {
    func updateSearchTerm(_ searchTerm: String)
}

public final class PointOfSaleItemSearchService: PointOfSaleItemSearchServiceProtocol {

    private var siteID: Int64
    private let currencyFormatter: CurrencyFormatter
    private let storage: StorageManagerType?

    private var itemService: PointOfSaleItemService

    public init(siteID: Int64,
                currencySettings: CurrencySettings,
                network: Network,
                storage: StorageManagerType? = nil) {
        self.siteID = siteID
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.storage = storage

        self.itemService = PointOfSaleItemService(siteID: siteID,
                                                  currencySettings: currencySettings,
                                                  network: network)
    }

    private var searchTerm: String = ""

    public func updateSearchTerm(_ searchTerm: String) {
        self.searchTerm = searchTerm
    }

    public func providePointOfSaleItems(pageNumber: Int) async throws -> PagedItems<POSItem> {
        try await self.itemService.provideSearchedPointOfSaleItems(query: searchTerm, pageNumber: pageNumber)
    }

    public func providePointOfSaleVariationItems(for parentProduct: POSVariableParentProduct, pageNumber: Int) async throws -> PagedItems<POSItem> {
        try await self.itemService.providePointOfSaleVariationItems(
            for: parentProduct,
            pageNumber: pageNumber)
    }
}
