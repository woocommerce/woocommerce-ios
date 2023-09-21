import Foundation
import Yosemite

/// View model for `ProductDetailPreviewView`
///
final class ProductDetailPreviewViewModel: ObservableObject {

    @Published private(set) var isGeneratingDetails: Bool = false
    
    private let siteID: Int64
    private let stores: StoresManager
    private let analytics: Analytics

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.stores = stores
        self.analytics = analytics
    }

    func generateProductDetails() {
        isGeneratingDetails = true
        // TODO
    }

    func saveProductAsDraft() {
        // TODO
    }
}
