#if DEBUG
import SwiftUI

/// Stable cash drawer states for reviewing the UI without a store connection.
private struct POSCashSessionPreviewGallery: View {
    enum Screen {
        case start
        case current
        case past
        case detail
        case payIn
        case payOut
        case close
    }

    let screen: Screen
    @State private var controller = POSCashSessionController(service: POSMockCashSessionService())
    @State private var isReady = false
    @State private var selectedSessionID: Int64?

    var body: some View {
        Group {
            if isReady {
                content
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(\.horizontalSizeClass, .regular)
        .posRootModal()
        .environmentObject(POSModalManager())
        .environmentObject(POSFullScreenCoverManager())
        .task {
            await prepare()
            isReady = true
        }
    }

    @ViewBuilder
    private var content: some View {
        switch screen {
        case .start:
            POSStartCashSessionView(controller: controller, onStarted: {})
        case .current:
            POSCurrentCashSessionView(controller: controller, onClosed: { _ in })
        case .past:
            POSPastCashSessionsView(selectedSessionID: $selectedSessionID, controller: controller)
        case .detail:
            if let session = controller.pastSessions.first {
                POSCashSessionDetailView(session: session, onBack: {})
            }
        case .payIn:
            POSCashSessionEntryView(action: .payIn, controller: controller, onClosed: { _ in })
        case .payOut:
            POSCashSessionEntryView(action: .payOut, controller: controller, onClosed: { _ in })
        case .close:
            POSCashSessionEntryView(action: .close, controller: controller, onClosed: { _ in })
        }
    }

    private func prepare() async {
        switch screen {
        case .start:
            break
        case .current, .payIn, .payOut, .close:
            _ = await controller.start(openingCash: 200)
            _ = await controller.record(kind: .payIn, amount: 100, note: "Change order from bank")
            _ = await controller.record(kind: .payOut, amount: 30, note: "Window cleaner")
        case .past, .detail:
            await controller.load()
        }
    }
}

#Preview("Start session") {
    POSCashSessionPreviewGallery(screen: .start)
}

#Preview("Current session") {
    POSCashSessionPreviewGallery(screen: .current)
}

#Preview("Past sessions") {
    POSCashSessionPreviewGallery(screen: .past)
}

#Preview("Closed session detail") {
    POSCashSessionPreviewGallery(screen: .detail)
}

#Preview("Pay in") {
    POSCashSessionPreviewGallery(screen: .payIn)
}

#Preview("Pay out") {
    POSCashSessionPreviewGallery(screen: .payOut)
}

#Preview("Close session") {
    POSCashSessionPreviewGallery(screen: .close)
}

#endif
