import SwiftUI

/// Hosting controller for `AccountSettingsView`
final class AccountSettingsHostingController: UIHostingController<AccountSettingsView> {
    init(onCloseAccount: @escaping () -> Void) {
        super.init(rootView: AccountSettingsView(onCloseAccount: onCloseAccount))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// View for Account Settings
struct AccountSettingsView: View {
    private let closeAccountHandler: () -> Void

    init(onCloseAccount: @escaping () -> Void) {
        self.closeAccountHandler = onCloseAccount
    }

    var body: some View {
        ScrollView {
            Button(action: closeAccountHandler) {
                Text(Localization.closeAccount)
                    .errorStyle()
                    .padding(.vertical, Layout.buttonHorizontalPadding)
            }
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(Layout.buttonCornerRadius)
            .padding(.horizontal, Layout.contentHorizontalMargin)
            .padding(.top, Layout.contentTopMargin)

            Spacer()
        }
        .background(Color(.listBackground))
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension AccountSettingsView {
    enum Layout {
        static let contentHorizontalMargin: CGFloat = 24
        static let contentTopMargin: CGFloat = 32
        static let buttonHorizontalPadding: CGFloat = 12
        static let buttonCornerRadius: CGFloat = 8
    }

    enum Localization {
        static let closeAccount = NSLocalizedString("Close Account", comment: "This text appears as a button label on the Account Settings screen that allows users to close their account. The button is likely styled as a prominent action button with specific padding and corner radius styling.")
        static let title = NSLocalizedString("Account Settings", comment: "This text appears as the navigation title at the top of the Account Settings screen in the WooCommerce iOS app. It displays in the navigation bar when users access their account configuration options.")
    }
}

struct AccountSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AccountSettingsView {}
    }
}
