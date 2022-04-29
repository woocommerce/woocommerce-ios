import SwiftUI
import Combine

/// Hosting controller that wraps an `NewOrder` view.
///
final class NewOrderHostingController: UIHostingController<NewOrder> {

    /// References to keep the Combine subscriptions alive within the lifecycle of the object.
    ///
    private var subscriptions: Set<AnyCancellable> = []
    private let viewModel: NewOrderViewModel

    init(viewModel: NewOrderViewModel) {
        self.viewModel = viewModel
        super.init(rootView: NewOrder(viewModel: viewModel))

        // Needed because a `SwiftUI` cannot be dismissed when being presented by a UIHostingController
        rootView.dismissHandler = { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.splitViewInOrdersTab) {
            // Set presentation delegate to track the user dismiss flow event
            if let navigationController = navigationController {
                navigationController.presentationController?.delegate = self
            } else {
                presentationController?.delegate = self
            }
        } else {
            handleSwipeBackGesture()
        }
    }
}

/// Intercepts back navigation (selecting back button or swiping back).
///
extension NewOrderHostingController {
    override func shouldPopOnBackButton() -> Bool {
        guard !viewModel.hasChanges else {
            presentDiscardChangesActionSheet(onDiscard: { [weak self] in
                self?.discardOrderAndPop()
            })
            return false
        }
        return true
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }
}

/// Intercepts to the dismiss drag gesture.
///
extension NewOrderHostingController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return !viewModel.hasChanges
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        presentDiscardChangesActionSheet(onDiscard: { [weak self] in
            self?.discardOrderAndDismiss()
        })
    }
}

/// Private methods
///
private extension NewOrderHostingController {
    func presentDiscardChangesActionSheet(onDiscard: @escaping () -> Void) {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: onDiscard)
    }

    func discardOrderAndDismiss() {
        viewModel.discardOrder()
        dismiss(animated: true)
    }

    func discardOrderAndPop() {
        viewModel.discardOrder()
        navigationController?.popViewController(animated: true)
    }
}

/// View to create a new manual order
///
struct NewOrder: View {
    /// Set this closure with UIKit dismiss code. Needed because we need access to the UIHostingController `dismiss` method.
    ///
    var dismissHandler: (() -> Void) = {}

    @ObservedObject var viewModel: NewOrderViewModel

    /// Fix for breaking navbar button
    @State private var navigationButtonID = UUID()

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scroll in
                ScrollView {
                    VStack(spacing: Layout.noSpacing) {
                        OrderStatusSection(viewModel: viewModel)

                        Spacer(minLength: Layout.sectionSpacing)

                        ProductsSection(scroll: scroll, viewModel: viewModel, navigationButtonID: $navigationButtonID)

                        Spacer(minLength: Layout.sectionSpacing)

                        OrderPaymentSection(viewModel: viewModel.paymentDataViewModel)

                        Spacer(minLength: Layout.sectionSpacing)

                        OrderCustomerSection(viewModel: viewModel, addressFormViewModel: viewModel.addressFormViewModel)

                        Spacer(minLength: Layout.sectionSpacing)

                        CustomerNoteSection(viewModel: viewModel)
                    }
                    .disabled(viewModel.disabled)
                }
                .background(Color(.listBackground).ignoresSafeArea())
                .ignoresSafeArea(.container, edges: [.horizontal])
            }
        }
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(Localization.cancelButton) {
                    dismissHandler()
                }
                .accessibilityIdentifier(Accessibility.cancelButtonIdentifier)
                .renderedIf(viewModel.shouldShowCancelButton)
            }
            ToolbarItem(placement: .confirmationAction) {
                switch viewModel.navigationTrailingItem {
                case .create:
                    Button(Localization.createButton) {
                        viewModel.createOrder()
                    }
                    .id(navigationButtonID)
                    .accessibilityIdentifier(Accessibility.createButtonIdentifier)
                    .disabled(viewModel.disabled)

                case .loading:
                    ProgressView()
                }
            }
        }
        .wooNavigationBarStyle()
        .notice($viewModel.notice, autoDismiss: false)
    }
}

// MARK: Order Sections
/// Represents the Products section
///
private struct ProductsSection: View {
    let scroll: ScrollViewProxy

    /// View model to drive the view content
    @ObservedObject var viewModel: NewOrderViewModel

    /// Fix for breaking navbar button
    @Binding var navigationButtonID: UUID

    /// Defines whether `AddProduct` modal is presented.
    ///
    @State private var showAddProduct: Bool = false

    /// ID for Add Product button
    ///
    @Namespace var addProductButton

    ///   Environment safe areas
    ///
    @Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    var body: some View {
        Group {
            Divider()

            VStack(alignment: .leading, spacing: NewOrder.Layout.verticalSpacing) {
                Text(NewOrder.Localization.products)
                    .accessibilityAddTraits(.isHeader)
                    .headlineStyle()

                ForEach(viewModel.productRows) { productRow in
                    ProductRow(viewModel: productRow, accessibilityHint: NewOrder.Localization.productRowAccessibilityHint)
                        .onTapGesture {
                            viewModel.selectOrderItem(productRow.id)
                        }
                        .sheet(item: $viewModel.selectedProductViewModel) { productViewModel in
                            ProductInOrder(viewModel: productViewModel)
                        }

                    Divider()
                }

                Button(NewOrder.Localization.addProduct) {
                    showAddProduct.toggle()
                }
                .id(addProductButton)
                .buttonStyle(PlusButtonStyle())
                .sheet(isPresented: $showAddProduct, onDismiss: {
                    scroll.scrollTo(addProductButton)
                }, content: {
                    ProductSelector(configuration: ProductSelector.Configuration.addProductToOrder,
                                    isPresented: $showAddProduct,
                                    viewModel: viewModel.addProductViewModel)
                        .onDisappear {
                            viewModel.addProductViewModel.clearSearchAndFilters()
                            navigationButtonID = UUID()
                        }
                })
            }
            .padding(.horizontal, insets: safeAreaInsets)
            .padding()
            .background(Color(.listForeground))

            Divider()
        }
    }
}

// MARK: Constants
private extension NewOrder {
    enum Layout {
        static let sectionSpacing: CGFloat = 16.0
        static let verticalSpacing: CGFloat = 22.0
        static let noSpacing: CGFloat = 0.0
    }

    enum Localization {
        static let title = NSLocalizedString("New Order", comment: "Title for the order creation screen")
        static let createButton = NSLocalizedString("Create", comment: "Button to create an order on the New Order screen")
        static let cancelButton = NSLocalizedString("Cancel", comment: "Button to cancel the creation of an order on the New Order screen")
        static let products = NSLocalizedString("Products", comment: "Title text of the section that shows the Products when creating a new order")
        static let addProduct = NSLocalizedString("Add Product", comment: "Title text of the button that adds a product when creating a new order")
        static let productRowAccessibilityHint = NSLocalizedString("Opens product detail.",
                                                                   comment: "Accessibility hint for selecting a product in a new order")
    }

    enum Accessibility {
        static let createButtonIdentifier = "new-order-create-button"
        static let cancelButtonIdentifier = "new-order-cancel-button"
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

private extension ProductSelector.Configuration {
    static let addProductToOrder: Self =
        .init(searchHeaderBackgroundColor: .listBackground,
              prefersLargeTitle: false,
              title: Localization.title,
              cancelButtonTitle: Localization.close,
              productRowAccessibilityHint: Localization.productRowAccessibilityHint,
              variableProductRowAccessibilityHint: Localization.variableProductRowAccessibilityHint)

    enum Localization {
        static let title = NSLocalizedString("Add Product", comment: "Title for the screen to add a product to an order")
        static let close = NSLocalizedString("Close", comment: "Text for the close button in the Add Product screen")
        static let productRowAccessibilityHint = NSLocalizedString("Adds product to order.",
                                                                   comment: "Accessibility hint for selecting a product in the Add Product screen")
        static let variableProductRowAccessibilityHint = NSLocalizedString(
            "Opens list of product variations.",
            comment: "Accessibility hint for selecting a variable product in the Add Product screen"
        )
    }
}
