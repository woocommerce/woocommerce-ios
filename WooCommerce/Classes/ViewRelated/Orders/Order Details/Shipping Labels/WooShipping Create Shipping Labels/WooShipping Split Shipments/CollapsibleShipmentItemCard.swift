import Yosemite
import SwiftUI

/// Displays a single collapsible shipment item row or grouped parent and child shipment item rows
struct CollapsibleShipmentItemCard: View {
    @State private var isCollapsed: Bool = true

    private let viewModel: CollapsibleShipmentItemCardViewModel

    init(viewModel: CollapsibleShipmentItemCardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            mainShipmentRow
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.vertical, Layout.verticalPadding)
                .background(
                    mainShipmentRowBackground
                )

            if !isCollapsed {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.childItemRows.enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: 0) {
                            Divider()

                            SelectableShipmentItemRow(viewModel: item)
                                .padding(.leading, Layout.horizontalPadding * 2)
                                .padding(.trailing, Layout.horizontalPadding)
                                .padding(.vertical, Layout.verticalPadding)
                                .background(backgroundForChildShipmentRow(isFinalRow: index == viewModel.childItemRows.count - 1))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .roundedBorder(cornerRadius: Layout.borderCornerRadius, lineColor: Color(.separator), lineWidth: Layout.borderWidth)
    }
}

private extension CollapsibleShipmentItemCard {
    @ViewBuilder
    var mainShipmentRow: some View {
        if viewModel.childItemRows.isEmpty {
            SelectableShipmentItemRow(viewModel: viewModel.mainItemRow)
        } else {
            Button(action: {
                withAnimation {
                    isCollapsed.toggle()
                }
            }, label: {
                ZStack(alignment: .topTrailing) {
                    SelectableShipmentItemRow(viewModel: viewModel.mainItemRow)
                        .contentShape(Rectangle())

                    Image(uiImage: isCollapsed ? .chevronDownImage : .chevronUpImage)
                        .foregroundColor(Color(.accent))
                }
            })
        }
    }

    @ViewBuilder
    var mainShipmentRowBackground: some View {
        if isCollapsed {
            RoundedRectangle(cornerRadius: Layout.borderCornerRadius)
                .fill(Color(.listForeground(modal: false)))
        } else {
            UnevenRoundedRectangle(cornerRadii: .init(topLeading: Layout.borderCornerRadius, topTrailing: Layout.borderCornerRadius))
                .fill(Color(.listForeground(modal: false)))
        }
    }

    @ViewBuilder
    func backgroundForChildShipmentRow(isFinalRow: Bool) -> some View {
        if isFinalRow {
            UnevenRoundedRectangle(cornerRadii: .init(bottomLeading: Layout.borderCornerRadius, bottomTrailing: Layout.borderCornerRadius))
                .fill(Color(.listForeground(modal: false)))
        } else {
            Color(.listForeground(modal: false))
        }
    }
}

private extension CollapsibleShipmentItemCard {
    enum Layout {
        static let borderCornerRadius: CGFloat = 8
        static let borderWidth: CGFloat = 0.5
        static let borderLineWidth: CGFloat = 1
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 8
    }
}
