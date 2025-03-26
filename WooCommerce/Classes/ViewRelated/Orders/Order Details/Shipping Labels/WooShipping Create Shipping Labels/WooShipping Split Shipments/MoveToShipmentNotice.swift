import SwiftUI

struct MoveToShipmentNoticeViewModel {
    enum Destination {
        case existingShipment(index: Int)
        case newShipment
    }

    let selectedItemsCount: Int
    let existingShipmentsCount: Int
    let currentShipmentIndex: Int?
}

struct MoveToShipmentNotice: View {
    let viewModel: MoveToShipmentNoticeViewModel
    let onMoving: ((MoveToShipmentNoticeViewModel.Destination) -> Void)

    var body: some View {
        AdaptiveStack(horizontalAlignment: .leading) {
            Text(String.localizedStringWithFormat(Localization.message, viewModel.selectedItemsCount))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color(uiColor: .text))
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            if viewModel.existingShipmentsCount == 1 {
                moveToNewShipment
            } else {
                menuWithExistingShipments
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.vertical, Layout.verticalPadding)
        .background(.thickMaterial)
        .cornerRadius(Layout.cornerRadius)
        .shadow(color: .black.opacity(Layout.shadowColorOpacity),
                radius: Layout.cornerRadius,
                y: Layout.shadowYOffset)
    }
}

private extension MoveToShipmentNotice {
    var moveToNewShipment: some View {
        Button {
            onMoving(.newShipment)
        } label: {
            HStack(spacing: Layout.horizontalSpacing) {
                Text(Localization.moveToNewShipment)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(Color(.accent))
        }
    }

    var menuWithExistingShipments: some View {
        Menu {
            ForEach(0..<viewModel.existingShipmentsCount, id: \.self) { index in
                if viewModel.currentShipmentIndex != index {
                    Button(String.localizedStringWithFormat(Localization.shipment, index + 1), action: {
                        onMoving(.existingShipment(index: index))
                    })
                }
            }

            Button(Localization.newShipment, action: {
                onMoving(.newShipment)
            })
        } label: {
            HStack(spacing: Layout.horizontalSpacing) {
                Text(Localization.moveTo)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Image(systemName: "chevron.up.chevron.down")
            }
            .foregroundColor(Color(.accent))
        }
        .environment(\.menuOrder, .fixed)
    }
}

private extension MoveToShipmentNotice {
    enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 22
        static let horizontalSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 8
        static let shadowYOffset: CGFloat = 2
        static let shadowColorOpacity: CGFloat = 0.16
    }

    enum Localization {
        static let message = NSLocalizedString(
            "wooShippingSplitShipments.MoveToShipmentNotice.title",
            value: "%1$d selected",
            comment: "The number of selected items in split shipments flow. %1$d is the number of selected items. Reads like: 2 selected"
        )
        static let shipment = NSLocalizedString(
            "wooShippingSplitShipments.MoveToShipmentNotice.shipment",
            value: "Shipment %1$d",
            comment: "Label used in the button to select the shipment in split shipments flow. %1$d is the shipment number. Reads like: Shipment 1"
        )
        static let moveTo = NSLocalizedString(
            "wooShippingSplitShipments.MoveToShipmentNotice.moveTo",
            value: "Move to",
            comment: "Button to move selected items to a shipment in split shipments flow"
        )
        static let moveToNewShipment = NSLocalizedString(
            "wooShippingSplitShipments.MoveToShipmentNotice.moveToNewShipment",
            value: "Move to new shipment",
            comment: "Button to move selected items to a new shipment in split shipments flow"
        )
        static let newShipment = NSLocalizedString(
            "wooShippingSplitShipments.MoveToShipmentNotice.newShipment",
            value: "New shipment",
            comment: "Title of the button to move selected items to a new shipment in split shipments flow"
        )
    }
}

#Preview {
    MoveToShipmentNotice(viewModel: MoveToShipmentNoticeViewModel(selectedItemsCount: 4,
                                                                  existingShipmentsCount: 3,
                                                                  currentShipmentIndex: 1),
                         onMoving: { _ in })
}
