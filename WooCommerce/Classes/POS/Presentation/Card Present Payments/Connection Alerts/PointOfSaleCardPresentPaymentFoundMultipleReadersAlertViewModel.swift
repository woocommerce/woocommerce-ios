import Foundation

struct PointOfSaleCardPresentPaymentFoundMultipleReadersAlertViewModel {
    let readerIDs: [String]
    let connect: (String) -> Void
    let cancelSearch: () -> Void

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
        return lhs.readerIDs == rhs.readerIDs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(readerIDs)
    }
}
