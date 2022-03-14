import Foundation
import Combine

final class OrderNotesViewModel: OrderCreationNotesViewModel {
    init(originalNote: String = "", analytics: Analytics = ServiceLocator.analytics) {
        super.init(originalNote: originalNote) {

        }
    }
}
