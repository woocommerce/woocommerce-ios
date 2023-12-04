import Foundation
import Yosemite
import Networking

/// Provides the selected store tax rate information. If the stored information is not valid remotely anymore it clears the cache
///
struct SelectedStoredTaxRateFetcher {
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    func fetchSelectedStoredTaxRate(siteID: Int64) async -> TaxRate? {
        guard let storedTaxRateID = await loadSelectedTaxRateID(siteID: siteID) else {
            return nil
        }

        var taxRate: TaxRate?

        do {
            taxRate = try await retrieveTaxRate(siteID: siteID, taxRateID: storedTaxRateID)
        } catch {
            DDLogError("⛔️ Error when fetching Tax Rate with ID: \(storedTaxRateID).")
            return nil
        }

        return taxRate
    }
}

private extension SelectedStoredTaxRateFetcher {
    func loadSelectedTaxRateID(siteID: Int64) async -> Int64? {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                stores.dispatch(AppSettingsAction.loadSelectedTaxRateID(siteID: siteID) { taxRateID in
                    continuation.resume(returning: taxRateID)
                })
            }
        }
    }

    func retrieveTaxRate(siteID: Int64, taxRateID: Int64) async throws -> TaxRate {
        try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                stores.dispatch(TaxAction.retrieveTaxRate(siteID: siteID, taxRateID: taxRateID) { result in
                    continuation.resume(with: result)
                })
            }
        }
    }
}
