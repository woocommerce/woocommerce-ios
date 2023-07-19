import Yosemite
import enum Networking.DotcomError

/// Creates a top banner to be used when there is an error loading data on a screen.
/// The banner has two action buttons: "Troubleshoot" and "Contact Support."
struct ErrorTopBannerFactory {
    static func createTopBanner(for error: Error? = nil,
                                expandedStateChangeHandler: @escaping () -> Void,
                                onTroubleshootButtonPressed: @escaping () -> Void,
                                onContactSupportButtonPressed: @escaping () -> Void) -> TopBannerView {
        let errorType: ErrorType = {
            if error is DecodingError {
                return .decodingError
            } else if error as? DotcomError == .jetpackNotConnected {
                return .jetpackConnectionError
            } else {
                return .generalError
            }
        }()
        let troubleshootAction = TopBannerViewModel.ActionButton(title: Localization.troubleshoot, action: { _ in onTroubleshootButtonPressed() })
        let contactSupportAction = TopBannerViewModel.ActionButton(title: Localization.contactSupport, action: { _ in onContactSupportButtonPressed() })
        let actions = [troubleshootAction, contactSupportAction]
        let viewModel = TopBannerViewModel(title: errorType.title,
                                           infoText: errorType.info,
                                           icon: .infoOutlineImage,
                                           isExpanded: true,
                                           shouldResizeInfo: false,
                                           topButton: .chevron(handler: expandedStateChangeHandler),
                                           actionButtons: actions)
        let topBannerView = TopBannerView(viewModel: viewModel)
        topBannerView.translatesAutoresizingMaskIntoConstraints = false

        return topBannerView
    }
}

extension ErrorTopBannerFactory {
    enum ErrorType {
        /// An error decoding the JSON response
        ///
        case decodingError

        /// A broken Jetpack connection error
        ///
        case jetpackConnectionError

        /// Any other error
        ///
        case generalError

        var title: String {
            switch self {
            case .jetpackConnectionError:
                return Localization.jetpackConnectionTitle
            default:
                return Localization.generalTitle
            }
        }

        var info: String {
            switch self {
            case .decodingError:
                return Localization.decodingInfo
            case .jetpackConnectionError:
                return Localization.jetpackConnectionInfo
            case .generalError:
                return Localization.generalInfo
            }
        }
    }

    enum Localization {
        static let generalTitle = NSLocalizedString("We couldn't load your data",
                                                    comment: "The title of the Error Loading Data banner")
        static let jetpackConnectionTitle = NSLocalizedString("We couldn't connect to your store",
                                                              comment: "The title of the Error Loading Data banner when there is a Jetpack connection error")
        static let generalInfo = NSLocalizedString("Please try again later or reach out to us and we'll be happy to assist you!",
                                                   comment: "The info of the Error Loading Data banner")
        static let decodingInfo = NSLocalizedString("This could be related to a conflict with a plugin. " +
                                                    "Please try again later or reach out to us and we'll be happy to assist you!",
                                                    comment: "The info on the Error Loading Data banner when there was a decoding error.")
        static let jetpackConnectionInfo = NSLocalizedString("There is a problem with your store's Jetpack connection. " +
                                                             "Please reconnect Jetpack or reach out to us and we'll be happy to assist you!",
                                                             comment: "The info on the Error Loading Data banner when there was a Jetpack connection error.")
        static let troubleshoot = NSLocalizedString("Troubleshoot",
                                                    comment: "The title of the button to get troubleshooting information in the Error Loading Data banner")
        static let contactSupport = NSLocalizedString("Contact support",
                                                      comment: "The title of the button to contact support in the Error Loading Data banner")
    }
}
