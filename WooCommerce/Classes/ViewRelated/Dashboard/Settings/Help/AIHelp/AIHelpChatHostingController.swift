import UIKit
import SwiftUI

/// Wraps `AIHelpChatView` for presentation from UIKit navigation.
///
final class AIHelpChatHostingController: UIHostingController<AIHelpChatView> {

    init(siteID: Int64, siteName: String, siteURL: String) {
        let viewModel = AIHelpChatViewModel(siteID: siteID, siteName: siteName, siteURL: siteURL)
        super.init(rootView: AIHelpChatView(viewModel: viewModel))

        viewModel.onFileZendeskTicket = { [weak self] in
            self?.presentSupportForm()
        }

        viewModel.onOpenNotificationSettings = {
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(settingsURL)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func presentSupportForm() {
        let supportFormController = SupportFormHostingController(viewModel: .init(sourceTag: "ai-help-troubleshooting"))
        supportFormController.show(from: self)
    }
}
