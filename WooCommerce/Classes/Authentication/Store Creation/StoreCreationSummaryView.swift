import SwiftUI

/// Hosting controller that wraps the `StoreCreationSummaryView`.
final class StoreCreationSummaryHostingController: UIHostingController<StoreCreationSummaryView> {
    private let onContinueToPayment: () -> Void

    init(viewModel: StoreCreationSummaryViewModel,
         onContinueToPayment: @escaping () -> Void) {
        self.onContinueToPayment = onContinueToPayment
        super.init(rootView: StoreCreationSummaryView(viewModel: viewModel))

        rootView.onContinueToPayment = { [weak self] in
            self?.onContinueToPayment()
        }
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBarAppearance()
    }

    /// Shows a transparent navigation bar without a bottom border.
    func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .systemBackground

        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
    }
}

/// View model for `StoreCreationSummaryView`.
struct StoreCreationSummaryViewModel {
    /// The name of the store.
    let storeName: String
    /// The URL slug of the store.
    let storeSlug: String
    /// Optional category name from the previous profiler question.
    let categoryName: String?
}

/// Displays a summary of the store creation flow with the store information (e.g. store name, store slug).
struct StoreCreationSummaryView: View {
    /// Set in the hosting controller.
    var onContinueToPayment: (() -> Void) = {}

    private let viewModel: StoreCreationSummaryViewModel

    init(viewModel: StoreCreationSummaryViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Layout.spacingBetweenSubtitleAndStoreInfo) {
                    // Header label.
                    Text(Localization.subtitle)
                        .foregroundColor(Color(.secondaryLabel))
                        .bodyStyle()

                    // Store info.
                    VStack(alignment: .leading, spacing: 0) {
                        // Image.
                        HStack {
                            Spacer()
                            Image(uiImage: .storeSummaryImage)
                            Spacer()
                        }
                        .background(Color(.systemColor(.systemGray6)))

                        VStack {
                            VStack(alignment: .leading, spacing: Layout.spacingBetweenStoreNameAndDomain) {
                                // Store name.
                                Text(viewModel.storeName)
                                    .headlineStyle()
                                // Store URL slug.
                                Text(viewModel.storeSlug)
                                    .foregroundColor(Color(.secondaryLabel))
                                    .bodyStyle()
                                // Store category (optional).
                                if let categoryName = viewModel.categoryName {
                                    Text(categoryName)
                                        .foregroundColor(Color(.label))
                                        .bodyStyle()
                                }
                            }
                        }
                        .padding(Layout.storeInfoPadding)
                    }
                    .cornerRadius(Layout.storeInfoCornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.storeInfoCornerRadius)
                            .stroke(Color(.separator), lineWidth: 0.5)
                    )
                }
                .padding(Layout.defaultPadding)
            }

            // Continue button.
            Group {
                Divider()
                    .frame(height: Layout.dividerHeight)
                    .foregroundColor(Color(.separator))
                Button(Localization.continueButtonTitle) {
                    onContinueToPayment()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(Layout.defaultButtonPadding)
            }
        }
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.large)
    }
}

private extension StoreCreationSummaryView {
    enum Layout {
        static let spacingBetweenSubtitleAndStoreInfo: CGFloat = 40
        static let spacingBetweenStoreNameAndDomain: CGFloat = 4
        static let defaultHorizontalPadding: CGFloat = 16
        static let dividerHeight: CGFloat = 1
        static let defaultPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let defaultButtonPadding: EdgeInsets = .init(top: 10, leading: 16, bottom: 10, trailing: 16)
        static let storeInfoPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let storeInfoCornerRadius: CGFloat = 8
    }

    enum Localization {
        static let title = NSLocalizedString("My store", comment: "Title of the store creation summary screen.")
        static let subtitle = NSLocalizedString(
            "Your store will be created based on the options of your choice!",
            comment: "Subtitle of the store creation summary screen.")
        static let continueButtonTitle = NSLocalizedString(
            "Continue to Payment",
            comment: "Title of the button on the store creation summary view to continue to payment."
        )
    }
}

struct StoreCreationSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        StoreCreationSummaryView(viewModel:
                .init(storeName: "Fruity shop", storeSlug: "fruityshop.com", categoryName: "Arts and Crafts"))
        StoreCreationSummaryView(viewModel:
                .init(storeName: "Fruity shop", storeSlug: "fruityshop.com", categoryName: "Arts and Crafts"))
        .preferredColorScheme(.dark)
    }
}
