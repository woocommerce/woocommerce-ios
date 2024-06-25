import Foundation
import SwiftUI

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
