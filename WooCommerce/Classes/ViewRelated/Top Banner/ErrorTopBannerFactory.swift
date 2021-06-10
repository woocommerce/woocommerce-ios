import Yosemite

/// Creates a top banner to be used when there is an error loading data on a screen.
/// The banner has two action buttons: "Troubleshoot" and "Contact Support."
struct ErrorTopBannerFactory {
    static func createTopBanner(isExpanded: Bool,
                                expandedStateChangeHandler: @escaping () -> Void,
                                onTroubleshootButtonPressed: @escaping () -> Void,
                                onContactSupportButtonPressed: @escaping () -> Void) -> TopBannerView {
        let troubleshootAction = TopBannerViewModel.ActionButton(title: Localization.troubleshoot, action: onTroubleshootButtonPressed)
        let contactSupportAction = TopBannerViewModel.ActionButton(title: Localization.contactSupport, action: onContactSupportButtonPressed)
        let actions = [troubleshootAction, contactSupportAction]
        let viewModel = TopBannerViewModel(title: Localization.title,
                                           infoText: Localization.info,
                                           icon: .infoOutlineImage,
                                           isExpanded: isExpanded,
                                           topButton: .chevron(handler: expandedStateChangeHandler),
                                           actionButtons: actions)
        let topBannerView = TopBannerView(viewModel: viewModel)
        topBannerView.translatesAutoresizingMaskIntoConstraints = false

        return topBannerView
    }

    /// Display the error banner in the table view header
    ///
    static func showTopBannerView(banner topBannerView: TopBannerView, in tableView: UITableView) {
        // Configure header container view
        let headerContainer = UIView(frame: CGRect(x: 0, y: 0, width: Int(tableView.frame.width), height: 0))
        headerContainer.addSubview(topBannerView)
        headerContainer.pinSubviewToSafeArea(topBannerView)

        tableView.tableHeaderView = headerContainer
        tableView.updateHeaderHeight()
    }

    /// Hide the error banner from the table view header
    ///
    static func hideTopBannerView(banner topBannerView: TopBannerView, in tableView: UITableView) {
        topBannerView.removeFromSuperview()
        tableView.updateHeaderHeight()
    }
}

private extension ErrorTopBannerFactory {
    enum Localization {
        static let title = NSLocalizedString("We couldn't load your data",
                                             comment: "The title of the Error Loading Data banner")
        static let info = NSLocalizedString("Please try again later or reach out to us and we'll be happy to assist you!",
                                            comment: "The info of the Error Loading Data banner")
        static let troubleshoot = NSLocalizedString("Troubleshoot",
                                                    comment: "The title of the button to get troubleshooting information in the Error Loading Data banner")
        static let contactSupport = NSLocalizedString("Contact Support",
                                                      comment: "The title of the button to contact support in the Error Loading Data banner")
    }
}
