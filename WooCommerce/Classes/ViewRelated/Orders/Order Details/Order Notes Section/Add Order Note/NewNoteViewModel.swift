import Foundation
import Yosemite

final class NewNoteViewModel {
    let order: Order
    let orderNotes: [OrderNote]
    var onDidFinishEditing: ((OrderNote) -> Void)?
    let analytics: Analytics

    init(order: Order, orderNotes: [OrderNote], analytics: Analytics = ServiceLocator.analytics) {
        self.order = order
        self.orderNotes = orderNotes
        self.analytics = analytics
    }
}
