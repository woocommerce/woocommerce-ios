import Foundation

struct CardPresentPaymentsModalButtonViewModel: Identifiable {
    let title: String
    let actionHandler: () -> Void
    let id = UUID()

    init(title: String, actionHandler: @escaping (() -> Void)) {
        self.title = title
        self.actionHandler = actionHandler
    }

    init?(title: String?, actionHandler: @escaping (() -> Void)) {
        guard let title else {
            return nil
        }
        self.init(title: title, actionHandler: actionHandler)
    }
}
