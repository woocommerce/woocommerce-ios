import SwiftUI
import Combine
import PointOfSale

// MARK: - FAB Entry Point

struct PrototypeControlPanel: View {
    let paymentService: StatefulPaymentService
    @State private var showSheet = false

    var body: some View {
        Button {
            showSheet = true
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .sheet(isPresented: $showSheet) {
            ControlStationView(paymentService: paymentService)
        }
    }
}

// MARK: - Control Station Sheet

private struct ControlStationView: View {
    let paymentService: StatefulPaymentService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        PaymentControlView(paymentService: paymentService)
                    } label: {
                        Label("Payment Flow", systemImage: "creditcard")
                    }

                    NavigationLink {
                        ReaderControlView(paymentService: paymentService)
                    } label: {
                        Label("Card Reader", systemImage: "wave.3.right")
                    }

                    NavigationLink {
                        ErrorCatalogView(paymentService: paymentService)
                    } label: {
                        Label("Error Catalog", systemImage: "exclamationmark.triangle")
                    }
                } header: {
                    Text("Controls")
                }

                Section {
                    Button("Run Full Payment (slow)") {
                        paymentService.controlMode = .automatic
                        dismiss()
                    }

                    Button("Disconnect Reader") {
                        paymentService.readerConnectionStatusSubject.send(.disconnected)
                    }
                    .foregroundStyle(.orange)

                    Button("Reset to Idle") {
                        paymentService.paymentEventSubject.send(.idle)
                        let reader = CardPresentPaymentCardReader(name: "Prototype Reader", batteryLevel: 0.92)
                        paymentService.readerConnectionStatusSubject.send(.connected(reader))
                    }
                } header: {
                    Text("Quick Actions")
                }
            }
            .navigationTitle("Control Station")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Payment Control

private struct PaymentControlView: View {
    let paymentService: StatefulPaymentService
    @State private var isManual: Bool = true

    var body: some View {
        List {
            Section {
                Toggle("Manual Control", isOn: $isManual)
                    .onChange(of: isManual) { _, newValue in
                        paymentService.controlMode = newValue ? .manual : .automatic
                    }

                if !isManual {
                    Text("Payment will auto-progress when checkout is tapped.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Use the steps below to drive each payment state. Checkout will wait for you.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Mode")
            }

            Section {
                PaymentStepButton(label: "Validating Order", icon: "doc.text.magnifyingglass") {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .validatingOrder(cancelPayment: {})))
                }
                PaymentStepButton(label: "Preparing Reader", icon: "antenna.radiowaves.left.and.right") {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .preparingForPayment(cancelPayment: {})))
                }
                PaymentStepButton(label: "Tap / Swipe / Insert", icon: "creditcard.and.123") {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .tapSwipeOrInsertCard(inputMethods: [], cancelPayment: {})))
                }
                PaymentStepButton(label: "Card Inserted", icon: "rectangle.and.arrow.up.right.and.arrow.down.left") {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .cardInserted(cancelPayment: {})))
                }
                PaymentStepButton(label: "Processing", icon: "arrow.triangle.2.circlepath") {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .processing))
                }
            } header: {
                Text("Payment Steps")
            }

            Section {
                PaymentStepButton(label: "Payment Success", icon: "checkmark.circle.fill", tint: .green) {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .paymentSuccess(done: {})))
                    paymentService.resolveManualPayment()
                }
                PaymentStepButton(label: "Payment Failed", icon: "xmark.circle.fill", tint: .red) {
                    let error = NSError(domain: "POSPrototype", code: 99,
                                        userInfo: [NSLocalizedDescriptionKey: "Simulated payment failure"])
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .paymentError(
                            error: error,
                            retryApproach: .tryAgain(retryAction: {}),
                            cancelPayment: {})))
                    paymentService.failManualPayment(message: "Simulated payment failure")
                }
                PaymentStepButton(label: "Cancel Payment", icon: "stop.circle", tint: .orange) {
                    paymentService.cancelPayment()
                }
            } header: {
                Text("Resolve Payment")
            }

            Section {
                PaymentStepButton(label: "Idle", icon: "moon") {
                    paymentService.paymentEventSubject.send(.idle)
                }
            } header: {
                Text("Reset")
            }
        }
        .navigationTitle("Payment Flow")
        .onAppear {
            isManual = paymentService.controlMode == .manual
        }
    }
}

// MARK: - Reader Control

private struct ReaderControlView: View {
    let paymentService: StatefulPaymentService

    var body: some View {
        List {
            Section {
                ReaderButton(label: "Connected", subtitle: "Reader ready for payments", icon: "checkmark.circle.fill", tint: .green) {
                    let reader = CardPresentPaymentCardReader(name: "Prototype Reader", batteryLevel: 0.92)
                    paymentService.readerConnectionStatusSubject.send(.connected(reader))
                }
                ReaderButton(label: "Connected (Low Battery)", subtitle: "Battery at 15%", icon: "battery.25percent", tint: .orange) {
                    let reader = CardPresentPaymentCardReader(name: "Prototype Reader", batteryLevel: 0.15)
                    paymentService.readerConnectionStatusSubject.send(.connected(reader))
                }
                ReaderButton(label: "Disconnected", subtitle: "No reader connected", icon: "xmark.circle", tint: .red) {
                    paymentService.readerConnectionStatusSubject.send(.disconnected)
                }
                ReaderButton(label: "Disconnecting", subtitle: "Reader shutting down", icon: "ellipsis.circle", tint: .orange) {
                    paymentService.readerConnectionStatusSubject.send(.disconnecting)
                }
                ReaderButton(label: "Cancelling Connection", subtitle: "Connection attempt cancelled", icon: "stop.circle", tint: .secondary) {
                    paymentService.readerConnectionStatusSubject.send(.cancellingConnection)
                }
            } header: {
                Text("Connection Status")
            }
        }
        .navigationTitle("Card Reader")
    }
}

// MARK: - Error Catalog

private struct ErrorCatalogView: View {
    let paymentService: StatefulPaymentService

    var body: some View {
        List {
            Section {
                ErrorButton(label: "Scanning Failed", subtitle: "Reader not found during scan") {
                    let error = NSError(domain: "POSPrototype", code: 10,
                                        userInfo: [NSLocalizedDescriptionKey: "No readers found"])
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .scanningFailed(error: error, endSearch: {})))
                }
                ErrorButton(label: "Bluetooth Required", subtitle: "Bluetooth is turned off") {
                    let error = NSError(domain: "POSPrototype", code: 11,
                                        userInfo: [NSLocalizedDescriptionKey: "Bluetooth is required"])
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .bluetoothRequired(error: error, endSearch: {})))
                }
            } header: {
                Text("Scanning Errors")
            }

            Section {
                ErrorButton(label: "Connection Failed (Retryable)", subtitle: "Temporary connection failure") {
                    let error = NSError(domain: "POSPrototype", code: 20,
                                        userInfo: [NSLocalizedDescriptionKey: "Connection timed out"])
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .connectingFailed(error: error, retrySearch: {}, endSearch: {})))
                }
                ErrorButton(label: "Connection Failed (Non-Retryable)", subtitle: "Hardware incompatible") {
                    let error = NSError(domain: "POSPrototype", code: 21,
                                        userInfo: [NSLocalizedDescriptionKey: "Unsupported reader"])
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .connectingFailedNonRetryable(error: error, endSearch: {})))
                }
                ErrorButton(label: "Charge Reader Required", subtitle: "Reader battery too low") {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .connectingFailedChargeReader(retrySearch: {}, endSearch: {})))
                }
                ErrorButton(label: "Update Postal Code", subtitle: "Store address incomplete") {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .connectingFailedUpdatePostalCode(retrySearch: {}, endSearch: {})))
                }
            } header: {
                Text("Connection Errors")
            }

            Section {
                ErrorButton(label: "Payment Error (Generic)", subtitle: "Card declined or processing error") {
                    let error = NSError(domain: "POSPrototype", code: 30,
                                        userInfo: [NSLocalizedDescriptionKey: "Card declined - insufficient funds"])
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .paymentError(
                            error: error,
                            retryApproach: .tryAgain(retryAction: {}),
                            cancelPayment: {})))
                }
                ErrorButton(label: "Payment Intent Creation Error", subtitle: "Server rejected payment request") {
                    let error = NSError(domain: "POSPrototype", code: 31,
                                        userInfo: [NSLocalizedDescriptionKey: "Could not create payment intent"])
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .paymentIntentCreationError(error: error, cancelPayment: {})))
                }
                ErrorButton(label: "Payment Capture Error", subtitle: "Payment captured but confirmation failed") {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .paymentCaptureError(cancelPayment: {})))
                }
                ErrorButton(label: "Cancelled on Reader", subtitle: "Customer cancelled on the reader device") {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .cancelledOnReader))
                }
            } header: {
                Text("Payment Errors")
            }

            Section {
                ErrorButton(label: "Update Failed (Retryable)", subtitle: "Firmware update failed, can retry") {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .updateFailed(tryAgain: {}, cancelUpdate: {})))
                }
                ErrorButton(label: "Update Failed (Non-Retryable)", subtitle: "Firmware update permanently failed") {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .updateFailedNonRetryable(cancelUpdate: {})))
                }
                ErrorButton(label: "Update Failed (Low Battery)", subtitle: "Battery too low for firmware update") {
                    paymentService.paymentEventSubject.send(
                        .show(eventDetails: .updateFailedLowBattery(
                            batteryLevel: 0.05, retrySearch: {}, cancelUpdate: {})))
                }
            } header: {
                Text("Firmware Update Errors")
            }
        }
        .navigationTitle("Error Catalog")
    }
}

// MARK: - Reusable Row Components

private struct PaymentStepButton: View {
    let label: String
    let icon: String
    var tint: Color = .blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
        }
        .tint(tint)
    }
}

private struct ReaderButton: View {
    let label: String
    let subtitle: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .frame(width: 24)
                VStack(alignment: .leading) {
                    Text(label)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .tint(.primary)
    }
}

private struct ErrorButton: View {
    let label: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .tint(.primary)
    }
}
