import StoreDesignSystem
import SwiftUI

struct StoreLastOrderDashboardRow: View {
    let data: LastOrderDashboardRow.RowData
    let tapHandler: () -> Void

    var body: some View {
        Button(action: tapHandler) {
            VStack(spacing: StoreSpacing.s0) {
                HStack(alignment: .top, spacing: StoreSpacing.s5) {
                    VStack(alignment: .leading, spacing: StoreSpacing.s3) {
                        HStack(spacing: StoreSpacing.s3) {
                            Text(data.number)
                            Text(data.date)
                        }
                        .storeTextStyle(.bodyMedium)

                        Text(data.customerName)
                            .storeTextStyle(.titleMedium)
                    }

                    Spacer(minLength: StoreSpacing.s0)

                    VStack(alignment: .trailing, spacing: StoreSpacing.s3) {
                        CollapsibleHStack(horizontalAlignment: .trailing,
                                          spacing: StoreSpacing.s3) {
                            StoreBadge(data.statusDescription,
                                       tone: .custom(background: data.statusBackgroundColor,
                                                     foreground: .storePaletteBlack))
                            if let fulfillmentText = data.fulfillmentBadgeText {
                                StoreBadge(fulfillmentText,
                                           tone: .custom(background: data.fulfillmentBadgeBackgroundColor ?? .clear,
                                                         foreground: .storePaletteBlack))
                            }
                            if let salesChannelText = data.salesChannelText {
                                StoreBadge(salesChannelText,
                                           tone: .custom(background: .storePrimaryContainer,
                                                         foreground: .storeOnPrimaryContainer))
                            }
                        }

                        Text(data.total)
                            .storeTextStyle(.titleMedium)
                    }
                }
                .foregroundStyle(.storeOnSurface)
                .padding(StorePadding.p5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)

                StoreDivider(variant: .inset)
            }
        }
        .buttonStyle(.plain)
    }
}
