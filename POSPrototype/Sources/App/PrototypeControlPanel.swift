import SwiftUI
import Combine
import PointOfSale
import enum Yosemite.CardReaderSoftwareUpdateState

/// A collapsible debug overlay for manually driving POS payment states,
/// reader connection, and other mock behaviors during prototyping.
struct PrototypeControlPanel: View {
    let paymentService: StatefulPaymentService
    @State private var isExpanded = false
    @State private var selectedReaderStatus: ReaderStatusOption = .connected
    @State private var selectedPaymentEvent: PaymentEventOption = .idle

    var body: some View {
        VStack(spacing: 0) {
            toggleBar
            if isExpanded {
                controlContent
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var toggleBar: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        } label: {
            HStack {
                Image(systemName: "slider.horizontal.3")
                Text("Prototype Controls")
                    .font(.subheadline.bold())
                Spacer()
                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var controlContent: some View {
        VStack(spacing: 16) {
            Divider()

            // Reader Connection Status
            VStack(alignment: .leading, spacing: 6) {
                Text("Card Reader")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    ForEach(ReaderStatusOption.allCases) { option in
                        Button {
                            selectedReaderStatus = option
                            applyReaderStatus(option)
                        } label: {
                            Text(option.label)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(selectedReaderStatus == option
                                            ? Color.blue : Color.secondary.opacity(0.15))
                                .foregroundStyle(selectedReaderStatus == option
                                                 ? .white : .primary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Payment State
            VStack(alignment: .leading, spacing: 6) {
                Text("Payment Event")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(PaymentEventOption.allCases) { option in
                            Button {
                                selectedPaymentEvent = option
                                applyPaymentEvent(option)
                            } label: {
                                Text(option.label)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(selectedPaymentEvent == option
                                                ? Color.blue : Color.secondary.opacity(0.15))
                                    .foregroundStyle(selectedPaymentEvent == option
                                                     ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            // Quick Actions
            VStack(alignment: .leading, spacing: 6) {
                Text("Sequences")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Button("Run Payment (slow)") {
                        Task { await runSlowPaymentSequence() }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button("Fail Payment") {
                        Task { await runFailSequence() }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.red)

                    Button("Disconnect") {
                        applyReaderStatus(.disconnected)
                        selectedReaderStatus = .disconnected
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.orange)
                }
            }

            Spacer().frame(height: 4)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Actions

    private func applyReaderStatus(_ option: ReaderStatusOption) {
        switch option {
        case .disconnected:
            paymentService.readerConnectionStatusSubject.send(.disconnected)
        case .connected:
            let reader = CardPresentPaymentCardReader(name: "Prototype Reader", batteryLevel: 0.92)
            paymentService.readerConnectionStatusSubject.send(.connected(reader))
        case .disconnecting:
            paymentService.readerConnectionStatusSubject.send(.disconnecting)
        }
    }

    private func applyPaymentEvent(_ option: PaymentEventOption) {
        let event: CardPresentPaymentEvent
        switch option {
        case .idle:
            event = .idle
        case .validatingOrder:
            event = .show(eventDetails: .validatingOrder(cancelPayment: {}))
        case .preparing:
            event = .show(eventDetails: .preparingForPayment(cancelPayment: {}))
        case .tapSwipeInsert:
            event = .show(eventDetails: .tapSwipeOrInsertCard(inputMethods: [], cancelPayment: {}))
        case .cardInserted:
            event = .show(eventDetails: .cardInserted(cancelPayment: {}))
        case .processing:
            event = .show(eventDetails: .processing)
        case .success:
            event = .show(eventDetails: .paymentSuccess(done: {}))
        case .error:
            let error = NSError(domain: "POSPrototype", code: 99,
                                userInfo: [NSLocalizedDescriptionKey: "Simulated payment error"])
            event = .show(eventDetails: .paymentError(
                error: error,
                retryApproach: .tryAgain(retryAction: {}),
                cancelPayment: {}
            ))
        }
        paymentService.paymentEventSubject.send(event)
    }

    private func runSlowPaymentSequence() async {
        let steps: [(PaymentEventOption, UInt64)] = [
            (.validatingOrder, 1_500_000_000),
            (.preparing, 1_500_000_000),
            (.tapSwipeInsert, 3_000_000_000),
            (.cardInserted, 1_500_000_000),
            (.processing, 2_000_000_000),
            (.success, 0),
        ]

        for (step, delay) in steps {
            selectedPaymentEvent = step
            applyPaymentEvent(step)
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
        }
    }

    private func runFailSequence() async {
        let steps: [(PaymentEventOption, UInt64)] = [
            (.validatingOrder, 1_000_000_000),
            (.preparing, 1_500_000_000),
            (.tapSwipeInsert, 2_000_000_000),
            (.error, 0),
        ]

        for (step, delay) in steps {
            selectedPaymentEvent = step
            applyPaymentEvent(step)
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
        }
    }
}

// MARK: - Options

enum ReaderStatusOption: String, CaseIterable, Identifiable {
    case disconnected
    case connected
    case disconnecting

    var id: String { rawValue }

    var label: String {
        switch self {
        case .disconnected: "Disconnected"
        case .connected: "Connected"
        case .disconnecting: "Disconnecting"
        }
    }
}

enum PaymentEventOption: String, CaseIterable, Identifiable {
    case idle
    case validatingOrder
    case preparing
    case tapSwipeInsert
    case cardInserted
    case processing
    case success
    case error

    var id: String { rawValue }

    var label: String {
        switch self {
        case .idle: "Idle"
        case .validatingOrder: "Validating"
        case .preparing: "Preparing"
        case .tapSwipeInsert: "Tap/Swipe"
        case .cardInserted: "Inserted"
        case .processing: "Processing"
        case .success: "Success"
        case .error: "Error"
        }
    }
}
