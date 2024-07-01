import SwiftUI

final class TotalsViewModel: ObservableObject {

    @Published private(set) var isSyncingOrder: Bool = false

    func startSyncOrder() {
        isSyncingOrder = true
    }

    func stopSyncOrder() {
        isSyncingOrder = false
    }

}
