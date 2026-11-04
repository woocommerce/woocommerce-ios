import SwiftUI

struct PointOfSaleOrderSyncErrorMessageView: View {
    @Environment(\.posMetrics) private var metrics
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    init(message: String, retryHandler: @escaping () -> Void) {
        self.title = Localization.title
        self.message = message
        self.actionTitle = Localization.retryActionTitle
        self.action = retryHandler
    }

    init(title: String, message: String, actionTitle: String, action: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center, spacing: metrics.spacing.none) {
                Spacer()
                POSErrorExclamationMark(size: .large)
                Spacer().frame(height: metrics.spacing.large)
                VStack(alignment: .center, spacing: metrics.spacing.small) {
                    Text(title)
                        .foregroundStyle(Color.posOnSurface)
                        .font(.posHeadingBold)

                    Text(message)
                        .foregroundStyle(Color.posOnSurface)
                        .font(.posBodyLargeRegular())
                        .padding([.leading, .trailing])
                }
                Spacer().frame(height: metrics.spacing.xxLarge)
                Button(actionTitle, action: action)
                    .buttonStyle(POSFilledButtonStyle(size: .normal))
                    .padding([.leading, .trailing], metrics.padding.xxLarge)
                    .padding([.bottom], metrics.padding.medium)
                Spacer()
            }
            .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

private extension PointOfSaleOrderSyncErrorMessageView {
    enum Constants {
    }
}

private extension PointOfSaleOrderSyncErrorMessageView {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.orderSync.error.title",
            value: "Couldn't load totals",
            comment: "Title of the error when failing to synchronize order and calculate order totals"
        )

        static let retryActionTitle = NSLocalizedString(
            "pointOfSale.orderSync.error.tryAgain",
            value: "Try again",
            comment: "Button title to retry synchronizing order and calculating order totals"
        )
    }
}

#Preview {
    PointOfSaleOrderSyncErrorMessageView(message: "An error happened!") {}
}
