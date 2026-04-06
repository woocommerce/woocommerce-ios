import SwiftUI
import Combine
import PointOfSale

// MARK: - Entry Point

struct PrototypeControlPanel: View {
    let paymentService: StatefulPaymentService
    @State private var isExpanded = false
    @State private var selectedTab: ControlTab = .payment

    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            toggleBar
        }
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
    }

    // MARK: - Toggle Bar

    private var toggleBar: some View {
        HStack {
            if !isExpanded {
                Button {
                    isExpanded = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.subheadline.bold())
                        Text("Controls")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Expanded Panel

    private var expandedPanel: some View {
        VStack(spacing: 0) {
            // Header with close
            HStack {
                Picker("", selection: $selectedTab) {
                    ForEach(ControlTab.allCases) { tab in
                        Text(tab.label).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                Button {
                    isExpanded = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 8)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 6)

            Divider()

            // Tab content
            ScrollView {
                switch selectedTab {
                case .payment:
                    PaymentTabContent(paymentService: paymentService)
                case .reader:
                    ReaderTabContent(paymentService: paymentService)
                case .errors:
                    ErrorsTabContent(paymentService: paymentService)
                }
            }
            .frame(maxHeight: 260)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8)
        .padding(.horizontal, 12)
    }
}

// MARK: - Tabs

private enum ControlTab: String, CaseIterable, Identifiable {
    case payment
    case reader
    case errors

    var id: String { rawValue }

    var label: String {
        switch self {
        case .payment: "Payment"
        case .reader: "Reader"
        case .errors: "Errors"
        }
    }
}

// MARK: - Payment Tab

private struct PaymentTabContent: View {
    let paymentService: StatefulPaymentService
    @State private var isManual = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Mode toggle
            HStack {
                Text("Mode")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: $isManual) {
                    Text("Manual").tag(true)
                    Text("Auto").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                .onChange(of: isManual) { _, newValue in
                    paymentService.controlMode = newValue ? .manual : .automatic
                }
            }

            // Payment steps
            Text("Steps")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            FlowLayout(spacing: 6) {
                StepChip("Validating", icon: "doc.text.magnifyingglass") {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .validatingOrder(cancelPayment: {})))
                }
                StepChip("Preparing", icon: "antenna.radiowaves.left.and.right") {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .preparingForPayment(cancelPayment: {})))
                }
                StepChip("Tap/Swipe", icon: "creditcard") {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .tapSwipeOrInsertCard(inputMethods: [], cancelPayment: {})))
                }
                StepChip("Inserted", icon: "arrow.down.doc") {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .cardInserted(cancelPayment: {})))
                }
                StepChip("Processing", icon: "arrow.triangle.2.circlepath") {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .processing))
                }
            }

            // Resolve
            Text("Resolve")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .paymentSuccess(done: {})))
                    paymentService.resolveManualPayment()
                } label: {
                    Label("Success", systemImage: "checkmark.circle.fill")
                        .font(.caption.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.small)

                Button {
                    let error = NSError(domain: "POSPrototype", code: 99,
                                        userInfo: [NSLocalizedDescriptionKey: "Payment declined"])
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .paymentError(
                            error: error,
                            retryApproach: .tryAgain(retryAction: {}),
                            cancelPayment: {})))
                    paymentService.failManualPayment(message: "Payment declined")
                } label: {
                    Label("Fail", systemImage: "xmark.circle.fill")
                        .font(.caption.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.small)

                Button {
                    paymentService.cancelPayment()
                } label: {
                    Label("Cancel", systemImage: "stop.circle")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    paymentService.paymentEventSubject.send(.idle)
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(12)
        .onAppear {
            isManual = paymentService.controlMode == .manual
        }
    }
}

// MARK: - Reader Tab

private struct ReaderTabContent: View {
    let paymentService: StatefulPaymentService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connection Status")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            ReaderRow(label: "Connected", subtitle: "Ready, 92% battery",
                      icon: "checkmark.circle.fill", tint: .green) {
                let reader = CardPresentPaymentCardReader(name: "Prototype Reader", batteryLevel: 0.92)
                paymentService.readerConnectionStatusSubject.send(.connected(reader))
            }
            ReaderRow(label: "Connected (Low Battery)", subtitle: "15% battery",
                      icon: "battery.25percent", tint: .orange) {
                let reader = CardPresentPaymentCardReader(name: "Prototype Reader", batteryLevel: 0.15)
                paymentService.readerConnectionStatusSubject.send(.connected(reader))
            }
            ReaderRow(label: "Disconnected", subtitle: "No reader",
                      icon: "xmark.circle", tint: .red) {
                paymentService.readerConnectionStatusSubject.send(.disconnected)
            }
            ReaderRow(label: "Disconnecting", subtitle: "Shutting down",
                      icon: "ellipsis.circle", tint: .orange) {
                paymentService.readerConnectionStatusSubject.send(.disconnecting)
            }
            ReaderRow(label: "Cancelling Connection", subtitle: "Aborting",
                      icon: "stop.circle", tint: .secondary) {
                paymentService.readerConnectionStatusSubject.send(.cancellingConnection)
            }
        }
        .padding(12)
    }
}

// MARK: - Errors Tab

private struct ErrorsTabContent: View {
    let paymentService: StatefulPaymentService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                Text("Scanning")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                ErrorRow(label: "Scanning Failed") {
                    let error = NSError(domain: "Mock", code: 10,
                                        userInfo: [NSLocalizedDescriptionKey: "No readers found"])
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .scanningFailed(error: error, endSearch: {})))
                }
                ErrorRow(label: "Bluetooth Required") {
                    let error = NSError(domain: "Mock", code: 11,
                                        userInfo: [NSLocalizedDescriptionKey: "Bluetooth is off"])
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .bluetoothRequired(error: error, endSearch: {})))
                }
            }

            Group {
                Text("Connection")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                ErrorRow(label: "Connection Failed (Retryable)") {
                    let error = NSError(domain: "Mock", code: 20,
                                        userInfo: [NSLocalizedDescriptionKey: "Timed out"])
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .connectingFailed(
                            error: error, retrySearch: {}, endSearch: {})))
                }
                ErrorRow(label: "Connection Failed (Non-Retryable)") {
                    let error = NSError(domain: "Mock", code: 21,
                                        userInfo: [NSLocalizedDescriptionKey: "Unsupported reader"])
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .connectingFailedNonRetryable(
                            error: error, endSearch: {})))
                }
                ErrorRow(label: "Charge Reader Required") {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .connectingFailedChargeReader(
                            retrySearch: {}, endSearch: {})))
                }
            }

            Group {
                Text("Payment")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                ErrorRow(label: "Card Declined") {
                    let error = NSError(domain: "Mock", code: 30,
                                        userInfo: [NSLocalizedDescriptionKey: "Insufficient funds"])
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .paymentError(
                            error: error,
                            retryApproach: .tryAgain(retryAction: {}),
                            cancelPayment: {})))
                }
                ErrorRow(label: "Intent Creation Error") {
                    let error = NSError(domain: "Mock", code: 31,
                                        userInfo: [NSLocalizedDescriptionKey: "Server rejected"])
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .paymentIntentCreationError(
                            error: error, cancelPayment: {})))
                }
                ErrorRow(label: "Capture Error") {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .paymentCaptureError(cancelPayment: {})))
                }
                ErrorRow(label: "Cancelled on Reader") {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .cancelledOnReader))
                }
            }

            Group {
                Text("Firmware")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                ErrorRow(label: "Update Failed (Retryable)") {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .updateFailed(
                            tryAgain: {}, cancelUpdate: {})))
                }
                ErrorRow(label: "Update Failed (Low Battery)") {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .updateFailedLowBattery(
                            batteryLevel: 0.05, retrySearch: {}, cancelUpdate: {})))
                }
            }
        }
        .padding(12)
    }
}

// MARK: - Reusable Components

private struct StepChip: View {
    let label: String
    let icon: String
    let action: () -> Void

    init(_ label: String, icon: String, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(.caption2.bold())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.12))
            .foregroundStyle(.blue)
            .clipShape(Capsule())
        }
    }
}

private struct ReaderRow: View {
    let label: String
    let subtitle: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 1) {
                    Text(label).font(.caption.bold())
                    Text(subtitle).font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }
}

private struct ErrorRow: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text(label)
                    .font(.caption)
                Spacer()
                Image(systemName: "play.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                                  proposal: .unspecified)
        }
    }

    private struct ArrangeResult {
        var size: CGSize
        var positions: [CGPoint]
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> ArrangeResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = max(totalHeight, y + rowHeight)
        }

        return ArrangeResult(size: CGSize(width: maxWidth, height: totalHeight), positions: positions)
    }
}
