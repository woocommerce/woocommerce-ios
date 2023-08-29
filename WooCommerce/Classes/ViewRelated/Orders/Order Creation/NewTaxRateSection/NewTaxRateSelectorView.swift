import SwiftUI
import WooFoundation

struct NewTaxRateSelectorView: View {
    @Environment(\.dismiss) var dismiss

    let taxEducationalDialogViewModel: TaxEducationalDialogViewModel

    /// Indicates if the tax educational dialog should be shown or not.
    ///
    @State private var shouldShowTaxEducationalDialog: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                Text("NewTaxRateView")
            }
            .navigationTitle(Localization.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button(action: {
                dismiss()
            }) {
                Text(Localization.cancelButton)
            }, trailing: Button(action: {
                shouldShowTaxEducationalDialog = true
            }) {
                Image(systemName: "questionmark.circle")
            })
            .fullScreenCover(isPresented: $shouldShowTaxEducationalDialog) {
                TaxEducationalDialogView(viewModel: taxEducationalDialogViewModel,
                                         onDismissWpAdminWebView: {})
                    .background(FullScreenCoverClearBackgroundView())
                }
        }
        .wooNavigationBarStyle()
    }
}

extension NewTaxRateSelectorView {
    enum Localization {
        static let navigationTitle = NSLocalizedString("Set Tax Rate", comment: "Navigation title for the tax rate selector")
        static let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title for the tax rate selector")
    }
}
