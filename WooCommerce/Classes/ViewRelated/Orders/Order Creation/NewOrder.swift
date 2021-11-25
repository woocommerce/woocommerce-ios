import SwiftUI
import Combine

/// Hosting controller that wraps an `NewOrder` view.
///
final class NewOrderHostingController: UIHostingController<NewOrder> {
    private let noticePresenter: NoticePresenter

    /// References to keep the Combine subscriptions alive within the lifecycle of the object.
    ///
    private var subscriptions: Set<AnyCancellable> = []

    init(viewModel: NewOrderViewModel, noticePresenter: NoticePresenter = ServiceLocator.noticePresenter) {
        self.noticePresenter = noticePresenter
        super.init(rootView: NewOrder(viewModel: viewModel))

        observeNoticeIntent()
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Observe the present notice intent and set it back after presented.
    ///
    private func observeNoticeIntent() {
        rootView.viewModel.$presentNotice
            .compactMap { $0 }
            .sink { [weak self] notice in
                switch notice {
                case .error:
                    self?.noticePresenter.enqueue(notice: .init(title: NewOrder.Localization.errorMessage, feedbackType: .error))
                }

                // Nullify the presentation intent.
                self?.rootView.viewModel.presentNotice = nil
            }
            .store(in: &subscriptions)
    }
}

/// View to create a new manual order
///
struct NewOrder: View {
    @ObservedObject var viewModel: NewOrderViewModel

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: Layout.noSpacing) {
                    Spacer(minLength: Layout.sectionSpacing)

                    ProductsSection(geometry: geometry)
                }
            }
            .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
        }
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                switch viewModel.navigationTrailingItem {
                case .none:
                    EmptyView()
                case .create:
                    Button(Localization.createButton) {
                        viewModel.createOrder()
                    }
                case .loading:
                    ProgressView()
                }
            }
        }
        .wooNavigationBarStyle()
    }
}

// MARK: Order Sections
/// Represents the Products section
///
private struct ProductsSection: View {
    let geometry: GeometryProxy

    var body: some View {
        Group {
            Divider()

            VStack(alignment: .leading, spacing: NewOrder.Layout.verticalSpacing) {
                Text(NewOrder.Localization.products)
                    .headlineStyle()

                // TODO: Add a product row for each product added to the order
                ProductRow()

                AddButton(title: NewOrder.Localization.addProduct) {
                    // TODO: Open Add Product modal view
                }
            }
            .padding(.horizontal, insets: geometry.safeAreaInsets)
            .padding()
            .background(Color(.listForeground))

            Divider()
        }
    }

    /// Represent a single product row in the Product section
    ///
    struct ProductRow: View {
        var body: some View {
            AdaptiveStack(horizontalAlignment: .leading) {
                HStack(alignment: .top) {
                    // Product image
                    // TODO: Display actual product image when available
                    Image(uiImage: .productPlaceholderImage)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: NewOrder.Layout.productImageSize, height: NewOrder.Layout.productImageSize)
                        .foregroundColor(Color(UIColor.listSmallIcon))

                    // Product details
                    VStack(alignment: .leading) {
                        Text("Love Ficus") // Fake data - product name
                        Text("7 in stock • $20.00") // Fake data - stock / price
                            .subheadlineStyle()
                        Text("SKU: 123456") // Fake data - SKU
                            .subheadlineStyle()
                    }
                }

                Spacer()

                ProductStepper()
            }

            Divider()
        }
    }

    /// Represents a custom stepper.
    /// Used to change the product quantity in the order.
    ///
    struct ProductStepper: View {
        @State var textSize: CGSize = .zero

        var body: some View {
            HStack(spacing: textSize.height) {
                Button {
                    // TODO: Decrement the product quantity
                } label: {
                    Image(uiImage: .minusImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: textSize.height)
                }
                Text("1") // Fake data - quantity
                    .background(ViewGeometry())
                    .onPreferenceChange(ViewSizeKey.self) {
                        textSize = $0
                    }
                Button {
                    // TODO: Increment the product quantity
                } label: {
                    Image(uiImage: .plusImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: textSize.height)
                }
            }
            .padding(textSize.height/2)
            .overlay(
                RoundedRectangle(cornerRadius: NewOrder.Layout.stepperBorderRadius)
                    .stroke(Color(UIColor.separator), lineWidth: NewOrder.Layout.stepperBorderWidth)
            )
        }

        /// Custom preference key to get the size of a view
        ///
        struct ViewSizeKey: PreferenceKey {
            static var defaultValue: CGSize = .zero

            static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
                value = nextValue()
            }
        }

        /// View that calculates its size and sets ViewSizeKey
        ///
        /// Used to ensure that stepper button height matches text height, and overlay border is set correctly at larger text sizes.
        ///
        struct ViewGeometry: View {
            var body: some View {
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: ViewSizeKey.self, value: geometry.size)
                }
            }
        }
    }
}

// MARK: Custom Views
/// Represents a button with a plus icon.
/// Used for any button that adds details to the order.
///
private struct AddButton: View {
    let title: String
    let onButtonTapped: () -> Void

    var body: some View {
        Button(action: { onButtonTapped() }) {
            Label {
                Text(title)
            } icon: {
                Image(uiImage: .plusImage)
            }
            Spacer()
        }
    }
}

// MARK: Constants
private extension NewOrder {
    enum Layout {
        static let sectionSpacing: CGFloat = 16.0
        static let verticalSpacing: CGFloat = 22.0
        static let noSpacing: CGFloat = 0.0
        static let productImageSize: CGFloat = 44.0
        static let stepperBorderWidth: CGFloat = 1.0
        static let stepperBorderRadius: CGFloat = 4.0
    }

    enum Localization {
        static let title = NSLocalizedString("New Order", comment: "Title for the order creation screen")
        static let createButton = NSLocalizedString("Create", comment: "Button to create an order on the New Order screen")
        static let errorMessage = NSLocalizedString("Unable to create new order", comment: "Notice displayed when order creation fails")
        static let products = NSLocalizedString("Products", comment: "Title text of the section that shows the Products when creating a new order")
        static let addProduct = NSLocalizedString("Add product", comment: "Title text of the button that adds a product when creating a new order")
    }
}

struct NewOrder_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = NewOrderViewModel(siteID: 123)

        NavigationView {
            NewOrder(viewModel: viewModel)
        }

        NavigationView {
            NewOrder(viewModel: viewModel)
        }
        .environment(\.sizeCategory, .accessibilityExtraExtraLarge)
        .previewDisplayName("Accessibility")

        NavigationView {
            NewOrder(viewModel: viewModel)
        }
        .environment(\.colorScheme, .dark)
        .previewDisplayName("Dark")

        NavigationView {
            NewOrder(viewModel: viewModel)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .previewDisplayName("Right to left")
    }
}
