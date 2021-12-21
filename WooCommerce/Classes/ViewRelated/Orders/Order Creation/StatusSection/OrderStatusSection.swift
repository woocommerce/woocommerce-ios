import SwiftUI
import Yosemite

/// Represents the Status section with date label, status badge and edit button.
///
struct OrderStatusSection: View {
    let geometry: GeometryProxy
    @ObservedObject var viewModel: NewOrderViewModel

    var body: some View {
        Divider()

        VStack(alignment: .leading) {
            Text(viewModel.dateString)
                .footnoteStyle()

            HStack {
                Text(viewModel.statusBadgeViewModel.title)
                    .foregroundColor(.black)
                    .footnoteStyle()
                    .padding(.horizontal, Layout.StatusBadge.horizontalPadding)
                    .padding(.vertical, Layout.StatusBadge.verticalPadding)
                    .background(Color(viewModel.statusBadgeViewModel.color))
                    .cornerRadius(Layout.StatusBadge.cornerRadius)

                Spacer()

                Button(Localization.editButton) {
                    viewModel.shouldShowOrderStatusList = true
                }
                .buttonStyle(LinkButtonStyle())
                .fixedSize(horizontal: true, vertical: true)
                .padding(.trailing, -Layout.linkButtonTrailingPadding) // remove trailing padding to align button title to the side
                .sheet(isPresented: $viewModel.shouldShowOrderStatusList) {
                    OrderStatusList(siteID: viewModel.siteID, status: viewModel.orderDetails.status) { newStatus in
                        viewModel.orderDetails.status = newStatus
                    }
                }
            }
        }
        .padding(.horizontal, insets: geometry.safeAreaInsets)
        .padding([.leading, .trailing, .top])
        .background(Color(.listForeground))

        Divider()
    }
}

// MARK: Constants
private extension OrderStatusSection {
    enum Layout {
        enum StatusBadge {
            static let horizontalPadding: CGFloat = 12.0
            static let verticalPadding: CGFloat = 4.0
            static let cornerRadius: CGFloat = 4.0
        }
        static let linkButtonTrailingPadding: CGFloat = 22.0
    }

    enum Localization {
        static let editButton = NSLocalizedString("Edit", comment: "Button to edit an order status on the New Order screen")
    }
}

struct OrderStatusSection_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = NewOrderViewModel(siteID: 123)

        GeometryReader { geometry in
            ScrollView {
                OrderStatusSection(geometry: geometry, viewModel: viewModel)
            }
        }
    }
}
