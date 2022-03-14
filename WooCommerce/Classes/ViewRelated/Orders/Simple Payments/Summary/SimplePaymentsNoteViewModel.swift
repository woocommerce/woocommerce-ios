import Foundation
import Combine

class SimplePaymentsNoteViewModel: OrderCreationNotesViewModel {
    init(originalNote: String = "", analytics: Analytics = ServiceLocator.analytics) {
        super.init(originalNote: originalNote) {
            analytics.track(event: WooAnalyticsEvent.SimplePayments.simplePaymentsFlowNoteAdded())
        }
    }
}
