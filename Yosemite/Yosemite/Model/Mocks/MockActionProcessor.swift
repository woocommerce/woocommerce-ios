import Foundation

final class MockActionProcessor<ActionType: Action>: ActionsProcessor {
    private var onActionCallback: (ActionType) -> Void

    init(onActionCallback: @escaping (ActionType) -> Void) {
        self.onActionCallback = onActionCallback
    }

    func onAction(_ action: Action) {
        guard let action = action as? ActionType else {
            return
        }
        onActionCallback(action)
    }
}
