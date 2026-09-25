import SwiftUI

struct POSCashSessionActivityView: View {
    @Environment(\.posCurrencyProvider) private var currencyProvider
    let session: POSCashSession

    private var money: POSCashSessionMoney { .init(settings: currencyProvider.currencySettings) }

    var body: some View {
        POSInformationCard {
            VStack(alignment: .leading, spacing: POSSpacing.medium) {
                Text(Localization.title)
                    .font(.posBodyMediumBold)
                    .foregroundStyle(.secondary)

                if let closedAt = session.closedAt, let countedCash = session.countedCash {
                    row(title: Localization.closed, detail: activityDetail(date: closedAt, actor: session.closedBy ?? session.openedBy,
                                                                         note: session.closingNote), amount: money.format(countedCash))
                }

                ForEach(session.movements.sorted(by: { $0.date > $1.date })) { movement in
                    row(title: title(for: movement.kind), detail: detail(for: movement), amount: money.formatSigned(movement.signedAmount))
                }

                row(title: Localization.started,
                    detail: activityDetail(date: session.openedAt, actor: session.openedBy, note: nil),
                    amount: money.format(session.openingCash))
            }
        }
    }

    private func row(title: String, detail: String, amount: String) -> some View {
        HStack(alignment: .top, spacing: POSSpacing.medium) {
            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                Text(title)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurface)
                Text(detail)
                    .font(.posBodySmallRegular())
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: POSSpacing.small)
            Text(amount)
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurface)
        }
        .accessibilityElement(children: .combine)
    }

    private func title(for kind: POSCashSessionMovement.Kind) -> String {
        switch kind {
        case .cashSale: Localization.cashSale
        case .cashRefund: Localization.cashRefund
        case .payIn: Localization.payIn
        case .payOut: Localization.payOut
        }
    }

    private func detail(for movement: POSCashSessionMovement) -> String {
        let reference = movement.orderID.map { String.localizedStringWithFormat(Localization.orderNumber, String($0)) }
        return activityDetail(date: movement.date, actor: movement.actor, note: movement.note ?? reference)
    }

    private func activityDetail(date: Date, actor: String, note: String?) -> String {
        let time = date.formatted(date: .omitted, time: .shortened)
        if let note, !note.isEmpty {
            return String.localizedStringWithFormat(Localization.timeActorAndNote, time, actor, note)
        }
        return String.localizedStringWithFormat(Localization.timeAndActor, time, actor)
    }
}

private extension POSCashSessionActivityView {
    enum Localization {
        static let title = NSLocalizedString("pos.cashSession.activity.title", value: "Activity summary", comment: "Cash session activity heading")
        static let started = NSLocalizedString("pos.cashSession.activity.started", value: "Session started", comment: "Cash session activity")
        static let closed = NSLocalizedString("pos.cashSession.activity.closed", value: "Session closed", comment: "Cash session activity")
        static let cashSale = NSLocalizedString("pos.cashSession.activity.sale", value: "Cash sale", comment: "Cash session activity")
        static let cashRefund = NSLocalizedString("pos.cashSession.activity.refund", value: "Cash refund issued", comment: "Cash session activity")
        static let payIn = NSLocalizedString("pos.cashSession.activity.payIn", value: "Pay in recorded", comment: "Cash session activity")
        static let payOut = NSLocalizedString("pos.cashSession.activity.payOut", value: "Pay out recorded", comment: "Cash session activity")
        static let orderNumber = NSLocalizedString("pos.cashSession.activity.orderNumber", value: "Order #%1$@", comment: "Order reference in cash activity")
        static let timeActorAndNote = NSLocalizedString("pos.cashSession.activity.timeActorAndNote", value: "%1$@ · By %2$@ · %3$@",
                                                       comment: "Time, staff member, and note in cash activity")
        static let timeAndActor = NSLocalizedString("pos.cashSession.activity.timeAndActor", value: "%1$@ · By %2$@", comment: "Time and staff name in cash activity")
    }
}
