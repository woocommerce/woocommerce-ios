import StoreDesignSystem
import SwiftUI

struct StoreOnboardingDashboardProgress: View {
    let completedTasks: Int
    let totalTasks: Int
    let isRedacted: Bool

    var body: some View {
        HStack(spacing: StoreSpacing.s0) {
            VStack(alignment: .leading, spacing: StoreSpacing.s2) {
                ProgressView(value: Double(completedTasks), total: Double(max(totalTasks, 1)))
                    .tint(.storePrimary)

                Text(String.localizedStringWithFormat(Localization.completed, completedTasks, totalTasks))
                    .storeTextStyle(.bodyMedium)
                    .foregroundStyle(.storeOnSurface)
                    .redacted(reason: isRedacted ? .placeholder : [])
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: StoreSpacing.s0)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, StorePadding.p5)
        .padding(.bottom, StorePadding.p5)
    }
}

private extension StoreOnboardingDashboardProgress {
    enum Localization {
        static let completed = NSLocalizedString(
            "storeOnboardingDashboardProgress.completed",
            value: "%1$d/%2$d completed",
            comment: "Store Setup progress. %1$d is the completed task count and %2$d is the total task count."
        )
    }
}
