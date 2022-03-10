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
        let view = NewOrder(viewModel: viewModel)
        super.init(rootView: view)
        rootView.dismissAction = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set presentation delegate to track the user dismiss flow event
        if let navigationController = navigationController {
            navigationController.presentationController?.delegate = self
        } else {
            presentationController?.delegate = self
        }
    }
}

/// Intercepts to the dismiss drag gesture.
///
extension NewOrderHostingController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        guard viewModel.hasChanges else {
            return true
        }
        let actionSheet = UIAlertController(title: Localization.dismissAlertTitle, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = .text
        actionSheet.addAction(UIAlertAction(title: Localization.discardButton, style: .destructive, handler: { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }))
        actionSheet.addAction(UIAlertAction(title: Localization.keepEditingButton, style: .cancel))

        if let popoverController = actionSheet.popoverPresentationController {
            let sourceView: UIView = navigationController?.navigationBar ?? view
            popoverController.sourceView = sourceView
            popoverController.sourceRect = sourceView.bounds
        }

        present(actionSheet, animated: true, completion: nil)

        return false
    }
}

private extension NewOrderHostingController {
    enum Localization {
        static let dismissAlertTitle = NSLocalizedString(
            "You have unsaved changes",
            comment: "Message on the alert presented when user swipes to dismiss the Simple Payments flow"
        )
        static let discardButton = NSLocalizedString(
            "Discard",
            comment: "Discard button on the alert presented when user swipes to dismiss the Simple Payments flow"
        )
        static let keepEditingButton = NSLocalizedString(
            "Keep Editing",
            comment: "Keep Editing button on the alert presented when user swipes to dismiss the Simple Payments flow"
        )
    }
}

/// View to create a new manual order
///
struct NewOrder: View {
    @ObservedObject var viewModel: NewOrderViewModel
    var dismissAction: () -> Void = {}

    /// Fix for breaking navbar button
    @State private var navigationButtonID = UUID()

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scroll in
                ScrollView {
                    VStack(spacing: Layout.noSpacing) {
                        OrderStatusSection(viewModel: viewModel)

                        Spacer(minLength: Layout.sectionSpacing)

                        ProductsSection(geometry: geometry, scroll: scroll, viewModel: viewModel, navigationButtonID: $navigationButtonID)

                        Spacer(minLength: Layout.sectionSpacing)

                        OrderPaymentSection(viewModel: viewModel.paymentDataViewModel)

                        Spacer(minLength: Layout.sectionSpacing)

                        OrderCustomerSection(viewModel: viewModel)
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
            ToolbarItem(placement: .confirmationAction) {
                switch viewModel.navigationTrailingItem {
                case .create:
                    Button(Localization.createButton) {
                        viewModel.createOrder()
                    }
                    .id(navigationButtonID)
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
    let geometry: GeometryProxy
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

    var body: some View {
        Group {
            Divider()

            VStack(alignment: .leading, spacing: NewOrder.Layout.verticalSpacing) {
                Text(NewOrder.Localization.products)
                    .headlineStyle()

                ForEach(viewModel.productRows) { productRow in
                    ProductRow(viewModel: productRow)
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
                    AddProductToOrder(isPresented: $showAddProduct, viewModel: viewModel.addProductViewModel)
                        .onDisappear {
                            viewModel.addProductViewModel.clearSearch()
                            navigationButtonID = UUID()
                        }
                })
            }
            .padding(.horizontal, insets: geometry.safeAreaInsets)
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
        static let products = NSLocalizedString("Products", comment: "Title text of the section that shows the Products when creating a new order")
        static let addProduct = NSLocalizedString("Add Product", comment: "Title text of the button that adds a product when creating a new order")
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
