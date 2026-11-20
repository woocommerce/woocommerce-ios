import StoreDesignSystem
import SwiftUI

struct StoreMostActiveCouponRow: View {
    let viewModel: MostActiveCouponRowViewModel
    let tapHandler: (() -> Void)

    var body: some View {
        Button(action: tapHandler) {
            VStack(spacing: StoreSpacing.s2) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: StoreSpacing.s2) {
                        Text(viewModel.code)
                            .storeTextStyle(.titleMedium)
                        Text(viewModel.summary)
                            .storeTextStyle(.bodyMedium)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Text(viewModel.uses)
                        .storeTextStyle(.titleMedium)
                }
                .foregroundStyle(.storeOnSurface)
                .padding(.horizontal, StorePadding.p5)

                StoreDivider(variant: .inset)
            }
            .padding(.top, StorePadding.p3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
