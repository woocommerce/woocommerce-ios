import SwiftUI

/// Reusable view for when Analytics module is disabled.
///
struct UnavailableAnalyticsView: View {
    @State private var showingSupportForm = false

    private let title: String

    init(title: String) {
        self.title = title
    }

    var body: some View {
        VStack(alignment: .center, spacing: Layout.padding) {
            Image(uiImage: .noStoreImage)
            Text(title)
                .headlineStyle()
            Text(Localization.details)
                .bodyStyle()
            Button(Localization.buttonTitle) {
                showingSupportForm = true
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showingSupportForm) {
            supportForm
        }
    }
}

private extension UnavailableAnalyticsView {
    var supportForm: some View {
        NavigationView {
            SupportForm(isPresented: $showingSupportForm,
                        viewModel: SupportFormViewModel())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.done) {
                        showingSupportForm = false
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

private extension UnavailableAnalyticsView {
    enum Layout {
        static let padding: CGFloat = 16
    }

    enum Localization {
        static let details = NSLocalizedString(
            "unavailableAnalyticsView.details",
            value: "Make sure you are running the latest version of WooCommerce on your site" +
            " and enabling Analytics in WooCommerce Settings.",
            comment: "Text that explains how to get access to the Analytics module"
        )
        static let buttonTitle = NSLocalizedString(
            "unavailableAnalyticsView.buttonTitle",
            value: "Still need help? Contact us",
            comment: "Button title to contact support to get help with unavailable Analytics module"
        )
        static let done = NSLocalizedString(
            "unavailableAnalyticsView.dismissSupport",
            value: "Done",
            comment: "Button to dismiss the support form."
        )
    }
}

#Preview {
    UnavailableAnalyticsView(title: "No analytics available")
}
