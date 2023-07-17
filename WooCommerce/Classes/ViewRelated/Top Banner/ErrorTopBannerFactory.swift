import Yosemite

/// Creates a top banner to be used when there is an error loading data on a screen.
/// The banner has two action buttons: "Troubleshoot" and "Contact Support."
struct ErrorTopBannerFactory {
    static func createTopBanner(for error: Error? = nil,
                                expandedStateChangeHandler: @escaping () -> Void,
                                onTroubleshootButtonPressed: @escaping () -> Void,
                                onContactSupportButtonPressed: @escaping () -> Void) -> TopBannerView {
        let errorType: ErrorType = error is DecodingError ? .decodingError : .generalError
        let troubleshootAction = TopBannerViewModel.ActionButton(title: Localization.troubleshoot, action: { _ in onTroubleshootButtonPressed() })
        let contactSupportAction = TopBannerViewModel.ActionButton(title: Localization.contactSupport, action: { _ in onContactSupportButtonPressed() })
        let actions = [troubleshootAction, contactSupportAction]
        let viewModel = TopBannerViewModel(title: Localization.title,
                                           infoText: errorType.info,
                                           icon: .infoOutlineImage,
                                           isExpanded: true,
                                           topButton: .chevron(handler: expandedStateChangeHandler),
                                           actionButtons: actions)
        let topBannerView = TopBannerView(viewModel: viewModel)
        topBannerView.translatesAutoresizingMaskIntoConstraints = false

        return topBannerView
    }
}

extension ErrorTopBannerFactory {
    enum ErrorType {
        case decodingError
        case generalError

        var info: String {
            switch self {
            case .decodingError:
                return Localization.decodingInfo
            case .generalError:
                return Localization.generalInfo
            }
        }
    }

    enum Localization {
        static let title = NSLocalizedString("We couldn't load your data",
                                             comment: "The title of the Error Loading Data banner")
        static let generalInfo = NSLocalizedString("Please try again later or reach out to us and we'll be happy to assist you!",
                                                   comment: "The info of the Error Loading Data banner")
        static let decodingInfo = NSLocalizedString("This could be related to a conflict with a plugin. " +
                                                    "Please try again later or reach out to us and we'll be happy to assist you!",
                                                    comment: "The info on the Error Loading Data banner when there was a decoding error.")
        static let troubleshoot = NSLocalizedString("Troubleshoot",
                                                    comment: "The title of the button to get troubleshooting information in the Error Loading Data banner")
        static let contactSupport = NSLocalizedString("Contact support",
                                                      comment: "The title of the button to contact support in the Error Loading Data banner")
    }
}
