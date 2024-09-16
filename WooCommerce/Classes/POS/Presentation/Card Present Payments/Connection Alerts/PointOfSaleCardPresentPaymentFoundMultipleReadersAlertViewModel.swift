import Foundation

struct PointOfSaleCardPresentPaymentFoundMultipleReadersAlertViewModel: Identifiable {
    let readerIDs: [String]
    let connect: (String) -> Void
    let cancelSearch: () -> Void
    // An unchanging, psuedo-random ID helps us correctly compare two copies which may have different closures.
    // This relies on the closures being immutable
    let id = UUID()

    init(readerIDs: [String], selectionHandler: @escaping (String?) -> Void) {
        self.readerIDs = readerIDs
        self.connect = { readerID in
            selectionHandler(readerID)
        }
        self.cancelSearch = {
            selectionHandler(nil)
        }
    }
}

extension PointOfSaleCardPresentPaymentFoundMultipleReadersAlertViewModel: Hashable {
    static func == (lhs: PointOfSaleCardPresentPaymentFoundMultipleReadersAlertViewModel,
                    rhs: PointOfSaleCardPresentPaymentFoundMultipleReadersAlertViewModel) -> Bool {
        return lhs.readerIDs == rhs.readerIDs &&
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(readerIDs)
        hasher.combine(id)
    }
}
