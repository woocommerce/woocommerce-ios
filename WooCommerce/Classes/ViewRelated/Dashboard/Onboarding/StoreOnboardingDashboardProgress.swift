import StoreDesignSystem
import SwiftUI

struct StoreOnboardingDashboardProgress: View {
    let completedTasks: Int
    let totalTasks: Int
    let isRedacted: Bool

    var body: some View {
        HStack(spacing: StoreSpacing.s0) {
            VStack(alignment: .leading, spacing: StoreSpacing.s3) {
                ProgressView(value: Double(completedTasks), total: Double(max(totalTasks, 1)))
                    .tint(.storePrimary)

                Text(String.localizedStringWithFormat(Localization.collapsed, completedTasks, totalTasks))
                    .storeTextStyle(.bodySmall)
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
    typealias Localization = StoreSetupProgressView.Localization.TasksCompleted
}
