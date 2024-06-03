import Foundation

struct CardPresentPaymentsModalButtonViewModel {
    var title: String
    var actionHandler: () -> Void

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
