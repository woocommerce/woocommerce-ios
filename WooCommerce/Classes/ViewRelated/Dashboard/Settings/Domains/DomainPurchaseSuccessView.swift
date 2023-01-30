import SwiftUI

/// Hosting controller that wraps the `DomainPurchaseSuccessView` view.
final class DomainPurchaseSuccessHostingController: UIHostingController<DomainPurchaseSuccessView> {
    init(viewModel: DomainPurchaseSuccessView.ViewModel, onContinue: @escaping () -> Void) {
        super.init(rootView: DomainPurchaseSuccessView(viewModel: viewModel,
                                                       onContinue: onContinue))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTransparentNavigationBar()
    }
}

/// Shows congratulatory UI after a domain is purchased or redeemed successfully.
struct DomainPurchaseSuccessView: View {
    /// Necessary data to show the success UI.
    struct ViewModel {
        /// Domain name that is purchased.
        let domainName: String
    }

    let viewModel: ViewModel
    /// Called when the user taps to continue.
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            Text(Localization.title)
                .titleStyle()
            // TODO: 8558 - update UI
            Text(viewModel.domainName)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Divider()
                    .dividerStyle()
                Button(Localization.continueButtonTitle) {
                    onContinue()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(Layout.defaultPadding)
            }
            .background(Color(.systemBackground))
        }
        .navigationBarBackButtonHidden()
    }
}

private extension DomainPurchaseSuccessView {
    enum Localization {
        static let title = NSLocalizedString(
            "Congratulations on your purchase",
            comment: "Title of the domain purchase success screen."
        )
        static let subtitle = NSLocalizedString(
            "Your site address is being set up. It may take up 30 minutes for your domain to start working.",
            comment: "Subtitle of the domain purchase success screen."
        )
        static let continueButtonTitle = NSLocalizedString(
            "Done",
            comment: "Title of the button to finish the domain purchase success screen."
        )
    }

    enum Layout {
        static let defaultPadding: EdgeInsets = .init(top: 10, leading: 16, bottom: 10, trailing: 16)
    }
}

struct DomainPurchaseSuccessView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DomainPurchaseSuccessView(viewModel: .init(domainName: "go.trees")) {}
        }
    }
}
