import Foundation

enum POSCashSessionErrorMessage {
    enum Operation: CaseIterable {
        case loadCurrent
        case loadPast
        case loadMorePast
        case loadDetail
        case start
        case recordPayIn
        case recordPayOut
        case close

        fileprivate var fallback: String {
            switch self {
            case .loadCurrent: Localization.loadCurrent
            case .loadPast: Localization.loadPast
            case .loadMorePast: Localization.loadMorePast
            case .loadDetail: Localization.loadDetail
            case .start: Localization.start
            case .recordPayIn: Localization.recordPayIn
            case .recordPayOut: Localization.recordPayOut
            case .close: Localization.close
            }
        }
    }

    static func message(for error: Error, operation: Operation) -> String {
        guard let error = error as? POSCashSessionServiceError else {
            return operation.fallback
        }

        switch error {
        case .sessionChanged:
            return operation == .close ? Localization.sessionChangedAtClose : Localization.sessionChangedDuringUpdate
        case .unsupported, .sessionAlreadyOpen, .drawerAlreadyOpen, .sessionNotOwner, .insufficientCash,
             .noOpenSession, .invalidAmount, .invalidReference, .previewUnavailable,
             .pendingCashMovements, .movementRecordedRefreshFailed:
            return error.errorDescription ?? operation.fallback
        }
    }
}

private extension POSCashSessionErrorMessage {
    enum Localization {
        static let loadCurrent = NSLocalizedString(
            "pos.cashSession.error.loadCurrent",
            value: "Could not load the current cash session. Try again.",
            comment: "Fallback message when loading the current cash session fails."
        )
        static let loadPast = NSLocalizedString(
            "pos.cashSession.error.loadPast",
            value: "Could not load past cash sessions. Try again.",
            comment: "Fallback message when loading past cash sessions fails."
        )
        static let loadMorePast = NSLocalizedString(
            "pos.cashSession.error.loadMorePast",
            value: "Could not load more cash sessions. Try again.",
            comment: "Fallback message when loading another page of cash sessions fails."
        )
        static let loadDetail = NSLocalizedString(
            "pos.cashSession.error.loadDetail",
            value: "Could not load the cash session details. Try again.",
            comment: "Fallback message when loading a cash session's details fails."
        )
        static let start = NSLocalizedString(
            "pos.cashSession.error.start",
            value: "Could not start the cash session. Try again.",
            comment: "Fallback message when starting a cash session fails."
        )
        static let recordPayIn = NSLocalizedString(
            "pos.cashSession.error.recordPayIn",
            value: "Could not record the pay in. Try again.",
            comment: "Fallback message when recording cash paid in fails."
        )
        static let recordPayOut = NSLocalizedString(
            "pos.cashSession.error.recordPayOut",
            value: "Could not record the pay out. Try again.",
            comment: "Fallback message when recording cash paid out fails."
        )
        static let close = NSLocalizedString(
            "pos.cashSession.error.close",
            value: "Could not close the cash session. Try again.",
            comment: "Fallback message when closing a cash session fails."
        )
        static let sessionChangedAtClose = NSLocalizedString(
            "pos.cashSession.error.reviewChangedSession",
            value: "The session changed. Review the latest totals and count the cash again.",
            comment: "Message asking the cashier to review and recount after the cash session changes."
        )
        static let sessionChangedDuringUpdate = NSLocalizedString(
            "pos.cashSession.error.sessionChangedDuringUpdate",
            value: "The cash session changed. Close this form and try again.",
            comment: "Message shown when a cash movement cannot be saved because the session changed."
        )
    }
}
