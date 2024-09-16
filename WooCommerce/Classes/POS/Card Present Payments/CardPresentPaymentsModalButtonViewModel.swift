import Foundation

struct CardPresentPaymentsModalButtonViewModel: Identifiable {
    let title: String
    let actionHandler: () -> Void
    let id = UUID()

    init(title: String, actionHandler: @escaping (() -> Void)) {
        self.title = title
        self.actionHandler = actionHandler
    }
}

extension CardPresentPaymentsModalButtonViewModel: Hashable {
    static func == (lhs: CardPresentPaymentsModalButtonViewModel, rhs: CardPresentPaymentsModalButtonViewModel) -> Bool {
        return lhs.title == rhs.title &&
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(id)
    }
}
