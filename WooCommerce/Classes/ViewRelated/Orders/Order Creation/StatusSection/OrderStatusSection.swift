import SwiftUI
import Yosemite

/// Represents the Status section with date label, status badge and edit button.
///
struct OrderStatusSection: View {

    @ObservedObject var viewModel: EditableOrderViewModel

    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    /// Set false to not render the top divider.
    /// Useful when there is a content on top that has its own divider.
    ///
    private(set) var topDivider: Bool = true

    var body: some View {
        Divider()
            .renderedIf(topDivider)

        VStack(alignment: .leading, spacing: .zero) {
            Text(viewModel.dateString)
                .footnoteStyle()

            HStack(alignment: .lastTextBaseline) {
                Text(viewModel.statusBadgeViewModel.title)
                    .foregroundColor(.black)
                    .footnoteStyle()
                    .padding(.horizontal, Layout.StatusBadge.horizontalPadding)
                    .padding(.vertical, Layout.StatusBadge.verticalPadding)
                    .background(Color(viewModel.statusBadgeViewModel.color))
                    .cornerRadius(Layout.StatusBadge.cornerRadius)
                    .padding(.top, Layout.StatusBadge.topPadding)
                    .padding(.bottom, Layout.StatusBadge.bottomPadding)

                Spacer()

                PencilEditButton {
                    viewModel.shouldShowOrderStatusList = true
                }
                .accessibilityLabel(Text(Localization.editButtonAccessibilityLabel))
                .accessibilityIdentifier("order-status-section-edit-button")
                .sheet(isPresented: $viewModel.shouldShowOrderStatusList) {
                    OrderStatusList(siteID: viewModel.siteID, status: viewModel.currentOrderStatus, autoConfirmSelection: true) { newStatus in
                        viewModel.updateOrderStatus(newStatus: newStatus)
                    }.ignoresSafeArea()
                }
            }
        }
        .padding(.horizontal, insets: safeAreaInsets)
        .padding([.leading, .trailing, .top])
        .background(Color(.listForeground(modal: true)))

        Divider()
    }
}

// MARK: Constants
private extension OrderStatusSection {
    enum Layout {
        enum StatusBadge {
            static let horizontalPadding: CGFloat = 12.0
            static let verticalPadding: CGFloat = 4.0
            static let topPadding: CGFloat = 8.0
            static let bottomPadding: CGFloat = 16.0
            static let cornerRadius: CGFloat = 4.0
        }
        static let linkButtonTrailingPadding: CGFloat = 22.0
    }

    enum Localization {
        static let editButtonAccessibilityLabel = NSLocalizedString("Edit Status",
                                                                    comment: "Accessibility label for the button to edit order status on the New Order screen")
    }
}

struct OrderStatusSection_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = EditableOrderViewModel(siteID: 123)

        ScrollView {
            OrderStatusSection(viewModel: viewModel)
        }
    }
}
