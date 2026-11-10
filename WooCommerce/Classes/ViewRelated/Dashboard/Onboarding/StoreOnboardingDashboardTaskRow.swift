import StoreDesignSystem
import SwiftUI
import struct Yosemite.StoreOnboardingTask

struct StoreOnboardingDashboardTaskRow: View {
    @ScaledMetric(relativeTo: .body) private var iconSize = Layout.iconSize

    let viewModel: StoreOnboardingTaskViewModel
    let isRedacted: Bool
    let onTap: (StoreOnboardingTask) -> Void

    var body: some View {
        Button(action: selectTask) {
            HStack(spacing: StoreSpacing.s5) {
                Image(uiImage: viewModel.isComplete ? .checkCircleImage : viewModel.icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(viewModel.isComplete ? Color.storePrimary : Color.storeOnSurface)
                    .frame(width: iconSize, height: iconSize)
                    .redacted(reason: isRedacted ? .placeholder : [])
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: StoreSpacing.s1) {
                    HStack(spacing: StoreSpacing.s3) {
                        Text(viewModel.title)
                            .storeTextStyle(.titleMedium.emphasized)
                            .foregroundStyle(.storeOnSurface)

                        if !isRedacted && viewModel.task.type == .launchStore && !viewModel.isComplete {
                            StoreBadge(Localization.privateLabel.uppercased())
                        }
                    }

                    Text(viewModel.subtitle)
                        .storeTextStyle(.bodyMedium)
                        .foregroundStyle(.storeOnSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)

                    if let badgeText = viewModel.badgeText {
                        StoreBadge(badgeText)
                    }
                }
                .multilineTextAlignment(.leading)
                .redacted(reason: isRedacted ? .placeholder : [])
                .frame(maxWidth: .infinity, alignment: .leading)

                if !isRedacted && !viewModel.isComplete {
                    StoreIcon.AngleRight.regular.image(size: .medium)
                        .foregroundStyle(.storeOnSurfaceVariant)
                        .flipsForRightToLeftLayoutDirection(true)
                        .accessibilityHidden(true)
                }
            }
            .padding(StorePadding.p5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isRedacted || viewModel.isComplete)
    }

    private func selectTask() {
        onTap(viewModel.task)
    }
}

private extension StoreOnboardingDashboardTaskRow {
    typealias Localization = StoreOnboardingTaskView.Localization

    enum Layout {
        static let iconSize: CGFloat = 24
    }
}
