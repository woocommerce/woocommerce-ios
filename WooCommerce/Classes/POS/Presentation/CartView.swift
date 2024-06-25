import SwiftUI

struct CartView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            HStack {
                Text("Cart")
                    .foregroundColor(Color.posPrimaryTexti3)
                Spacer()
                if let temsInCartLabel = viewModel.itemsInCartLabel {
                    Text(temsInCartLabel)
                        .foregroundColor(Color.posPrimaryTexti3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
            .padding(.vertical, 8)
            .font(.title)
            .foregroundColor(Color.white)
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(viewModel.itemsInCart, id: \.id) { cartItem in
                        ItemRowView(cartItem: cartItem) {
                            viewModel.removeItemFromCart(cartItem)
                        }
                        .id(cartItem.id)
                        .background(Color.posBackgroundGreyi3)
                        .padding(.horizontal, 32)
                    }
                }
                .onChange(of: viewModel.itemToScrollToWhenCartUpdated?.id) { _ in
                    if viewModel.orderStage == .building,
                       let last = viewModel.itemToScrollToWhenCartUpdated?.id {
                        withAnimation {
                            proxy.scrollTo(last)
                        }
                    }
                }
            }
            Spacer()
            switch viewModel.orderStage {
            case .building:
                checkoutButton
                    .padding(32)
            case .finalizing:
                addMoreButton
                    .padding(32)
                    .disabled(viewModel.isAddMoreDisabled)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.posBackgroundWhitei3)
    }
}

/// View sub-components
///
private extension CartView {
    var checkoutButton: some View {
        Button {
            viewModel.submitCart()
        } label: {
            HStack {
                Spacer()
                Text("Checkout")
                    .font(.title)
                    .padding(20)
                Spacer()
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.primaryTint)
    }

    var addMoreButton: some View {
        Button {
            viewModel.addMoreToCart()
        } label: {
            Spacer()
            Text("Add More")
                .font(.title)
                .padding(20)
            Spacer()
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.secondaryBackground)
    }
}

#if DEBUG
#Preview {
    CartView(viewModel: PointOfSaleDashboardViewModel(itemProvider: POSItemProviderPreview(),
                                                      cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                                      orderService: POSOrderPreviewService()))
}
#endif
