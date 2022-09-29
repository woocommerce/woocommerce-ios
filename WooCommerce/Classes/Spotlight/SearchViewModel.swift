import Foundation
import CoreSpotlight
import Storage
import SwiftUI
import CoreData

struct SearchResultItem: Identifiable, Equatable {
    let id = UUID()

    let title: String
    let object: NSManagedObject
}

class SearchViewModel: ObservableObject {
    private var searchQuery: CSSearchQuery?
    private var spotlightFoundItems: [CSSearchableItem] = []
    @Published private(set) var results: [SearchResultItem] = []

    func setSearchText(_ term: String) {
        guard !term.isEmpty else {
          searchQuery?.cancel()
            results = []
          return
        }
        searchCoreSpotlight(term)
    }

    private func searchCoreSpotlight(_ term: String) {
        let escapedTerm = term
          .replacingOccurrences(of: "\\", with: "\\\\")
          .replacingOccurrences(of: "\"", with: "\\\"")
        let queryString = "(textContent == \"\(escapedTerm)*\"cd)"

        searchQuery = CSSearchQuery(
          queryString: queryString,
          attributes: ["textContent"])

        searchQuery?.foundItemsHandler = { items in
          DispatchQueue.main.async {
            self.spotlightFoundItems += items
          }
        }

        searchQuery?.completionHandler = { error in
          guard error == nil else {
            print(error?.localizedDescription ?? "oh no!")
            return
          }

          DispatchQueue.main.async {
            self.convertSearchResults(self.spotlightFoundItems)
            self.spotlightFoundItems.removeAll()
          }
        }

        searchQuery?.start()
    }

    private func convertSearchResults(_ items: [CSSearchableItem]) {
        results = items.compactMap { title(from: $0) }.removingDuplicates()
    }

    private func title(from item: CSSearchableItem) -> SearchResultItem? {
        guard let objectURI = URL(string: item.uniqueIdentifier),
              let object = ServiceLocator.storageManager.managedObjectWithURI(objectURI) else {
            return nil
        }



        if let product = object as? Storage.Product {
            return SearchResultItem(title: "Product: \(product.name)", object: object)
        } else if let order = object as? Storage.Order {
            return SearchResultItem(title: "Order #\(order.orderID) \(order.billingFirstName ?? "") \(order.billingLastName ?? "")", object: object)
        } else if let review = object as? ProductReview {
            return SearchResultItem(title: "Review: " + String.localizedStringWithFormat(CoreDataSpotlightDelegate.Localization.reviewDisplayName,
                                                                            review.reviewer ?? ""), object: object)
        }

        return nil
    }
}
