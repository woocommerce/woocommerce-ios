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
                    OrderStatusSection(geometry: geometry, dateCreated: Date(), orderStatus: viewModel.orderStatus)

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

                Button(NewOrder.Localization.addProduct) {
                    // TODO: Open Add Product modal view
                }
                .buttonStyle(PlusButtonStyle())
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

        // Tracks the scale of the view due to accessibility changes
        @ScaledMetric private var scale: CGFloat = 1

        var body: some View {
            AdaptiveStack(horizontalAlignment: .leading) {
                HStack(alignment: .top) {
                    // Product image
                    // TODO: Display actual product image when available
                    Image(uiImage: .productPlaceholderImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: NewOrder.Layout.productImageSize * scale, height: NewOrder.Layout.productImageSize * scale)
                        .foregroundColor(Color(UIColor.listSmallIcon))
                        .accessibilityHidden(true)

                    // Product details
                    VStack(alignment: .leading) {
                        Text("Love Ficus") // Fake data - product name
                        Text("7 in stock • $20.00") // Fake data - stock / price
                            .subheadlineStyle()
                        Text("SKU: 123456") // Fake data - SKU
                            .subheadlineStyle()
                    }
                    .accessibilityElement(children: .combine)
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

        // Tracks the scale of the view due to accessibility changes
        @ScaledMetric private var scale: CGFloat = 1

        var body: some View {
            HStack(spacing: NewOrder.Layout.stepperSpacing * scale) {
                Button {
                    // TODO: Decrement the product quantity
                } label: {
                    Image(uiImage: .minusSmallImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: NewOrder.Layout.stepperButtonSize * scale)
                }

                Text("1") // Fake data - quantity

                Button {
                    // TODO: Increment the product quantity
                } label: {
                    Image(uiImage: .plusSmallImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: NewOrder.Layout.stepperButtonSize * scale)
                }
            }
            .padding(NewOrder.Layout.stepperSpacing/2 * scale)
            .overlay(
                RoundedRectangle(cornerRadius: NewOrder.Layout.stepperBorderRadius)
                    .stroke(Color(UIColor.separator), lineWidth: NewOrder.Layout.stepperBorderWidth)
            )
            .accessibilityElement(children: .ignore)
            .accessibility(label: Text("Quantity"))
            .accessibility(value: Text("1")) // Fake static data - quantity
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .decrement:
                    break // TODO: Decrement the product quantity
                case .increment:
                    break // TODO: Increment the product quantity
                @unknown default:
                    break
                }
            }
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
        static let stepperButtonSize: CGFloat = 22.0
        static let stepperSpacing: CGFloat = 22.0
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
