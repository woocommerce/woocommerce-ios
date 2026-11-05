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
                        HStack(spacing: StoreSpacing.s3) {
                            statusBadge(data.statusDescription, background: data.statusBackgroundColor)
                            if let fulfillmentText = data.fulfillmentBadgeText {
                                statusBadge(fulfillmentText,
                                            background: data.fulfillmentBadgeBackgroundColor ?? .clear)
                            }
                            if let salesChannelText = data.salesChannelText {
                                Text(salesChannelText)
                                    .storeTextStyle(.labelSmall)
                                    .foregroundStyle(.storeOnPrimaryContainer)
                                    .padding(.horizontal, StorePadding.p3 + StorePadding.p1)
                                    .padding(.vertical, StorePadding.p2)
                                    .background(Color.storePrimaryContainer)
                                    .clipShape(.rect(cornerRadius: StoreRadius.small))
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

    private func statusBadge(_ text: String, background: Color) -> some View {
        Text(text)
            .storeTextStyle(.labelSmall)
            .foregroundStyle(.storePaletteBlack)
            .padding(.horizontal, StorePadding.p3 + StorePadding.p1)
            .padding(.vertical, StorePadding.p2)
            .background(background)
            .clipShape(.rect(cornerRadius: StoreRadius.small))
    }
}
