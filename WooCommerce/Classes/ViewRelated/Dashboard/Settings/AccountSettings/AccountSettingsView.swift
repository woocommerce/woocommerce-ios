import SwiftUI

/// Hosting controller for `AccountSettingsView`
final class AccountSettingsHostingController: UIHostingController<AccountSettingsView> {
    init(viewModel: AccountSettingsViewModel) {
        super.init(rootView: AccountSettingsView(viewModel: viewModel))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// View for Account Settings
struct AccountSettingsView: View {
    private let viewModel: AccountSettingsViewModel

    init(viewModel: AccountSettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text("Hello, World!")
    }
}

struct AccountSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AccountSettingsView(viewModel: .init())
    }
}
