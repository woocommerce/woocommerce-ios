import SwiftUI
import Yosemite

struct WooShippingSplitShipmentsDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: WooShippingSplitShipmentsViewModel

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Layout.contentPadding) {
                        AdaptiveStack(horizontalAlignment: .leading) {
                            Text(viewModel.itemsCountLabel)
                                .headlineStyle()
                            Spacer()
                            Text(viewModel.itemsDetailLabel)
                                .foregroundStyle(Color(.textSubtle))
                        }

                        VStack(spacing: Layout.verticalSpacing) {
                            ForEach(viewModel.shipmentCardViewModels) { item in
                                CollapsibleShipmentCard(viewModel: item)
                            }
                        }
                    }
                    .padding(Layout.contentPadding)
                }

                noticeStack
                    .padding(Layout.contentPadding)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Localization.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.selectAll) {
                        viewModel.selectAll()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.done) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}

private extension WooShippingSplitShipmentsDetailView {
    var noticeStack: some View {
        VStack(spacing: Layout.contentPadding) {
            if let message = viewModel.instructions {
                InstructionsSnackbar(message: message) {
                    viewModel.dismissInstructions()
                }
            }

            if let moveTo = viewModel.moveToNoticeViewModel {
                MoveToShipmentNotice(viewModel: moveTo)
            }
        }
    }
}

private struct InstructionsSnackbar: View {
    let message: String
    let actionHandler: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Layout.hSpacing) {
            BoldableTextView(message)
                .foregroundStyle(Color(.textInverted))

            Spacer()

            Button {
                actionHandler()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(Color(.withColorStudio(.gray)))
            }
        }
        .padding(WooShippingSplitShipmentsDetailView.Layout.contentPadding)
        .background {
            RoundedRectangle(cornerRadius: WooShippingSplitShipmentsDetailView.Layout.cornerRadius)
                .fill(Color(.text))
                .shadow(color: Color(.text).opacity(Layout.shadowColorOpacity),
                        radius: WooShippingSplitShipmentsDetailView.Layout.shadowRadius,
                        y: WooShippingSplitShipmentsDetailView.Layout.shadowYOffset)
        }
    }

    private enum Layout {
        static let hSpacing: CGFloat = 8
        static let shadowColorOpacity: CGFloat = 0.16
    }
}

fileprivate extension WooShippingSplitShipmentsDetailView {
    enum Layout {
        static let contentPadding: CGFloat = 16
        static let borderCornerRadius: CGFloat = 8
        static let shadowRadius: CGFloat = 8
        static let shadowYOffset: CGFloat = 2
        static let borderWidth: CGFloat = 0.5
        static let verticalSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 8
    }

    enum Localization {
        static let title = NSLocalizedString(
            "wooShippingSplitShipmentsDetailView.title",
            value: "Split Shipments",
            comment: "Title of the split shipments detail view in the shipping label creation flow"
        )
        static let selectAll = NSLocalizedString(
            "wooShippingSplitShipmentsDetailView.selectAll",
            value: "Select All",
            comment: "Button to select all items in the shipment detail in the shipping label creation flow"
        )
        static let done = NSLocalizedString(
            "wooShippingSplitShipmentsDetailView.done",
            value: "Done",
            comment: "Button to save split shipment configurations in the shipping label creation flow"
        )
    }
}

#if DEBUG
#Preview {
    WooShippingSplitShipmentsDetailView(viewModel: WooShippingSplitShipmentsViewModel(order: ShippingLabelSampleData.sampleOrder(),
                                                                                      config: ShippingLabelSampleData.sampleWooShippingConfig(),
                                                                                      items: [ShippingLabelPackageItem(productOrVariationID: 1,
                                                                                                                       name: "Shirt",
                                                                                                                       weight: 0.5,
                                                                                                                       quantity: 2,
                                                                                                                       value: 9.99,
                                                                                                                       dimensions: ProductDimensions(length: "",
                                                                                                                                                     width: "",
                                                                                                                                                     height: ""),
                                                                                                                       attributes: [],
                                                                                                                       imageURL: nil)]))
}
#endif
