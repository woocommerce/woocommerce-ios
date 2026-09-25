#if DEBUG
import SwiftUI

/// Stable cash management states for reviewing the UI without a store connection.
private struct POSCashSessionPreviewGallery: View {
    enum Screen: Equatable {
        case start
        case current
        case past
        case detail
        case payIn
        case payInNote
        case payOut
        case payOutNote
        case close
        case closeWithAmount
        case closeNote
        case startError
        case currentError
        case pastError
    }

    let screen: Screen
    @State private var controller: POSCashSessionController
    @State private var isReady = false
    @State private var detailNavigationPath = NavigationPath()

    init(screen: Screen) {
        self.screen = screen
        let service = POSMockCashSessionService(failCurrentLoad: screen == .currentError,
                                                failPastLoad: screen == .pastError)
        _controller = State(initialValue: POSCashSessionController(service: service))
    }

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
        case .startError:
            POSStartCashSessionView(controller: controller, onStarted: {}, initialError: "Could not start the session. Try again.")
        case .current:
            POSCurrentCashSessionView(controller: controller, onClosed: { _ in })
        case .currentError:
            POSCashManagementView(controller: controller)
        case .past:
            pastSessionsPreview
        case .pastError:
            pastSessionsPreview
        case .detail:
            if let session = controller.pastSessions.first {
                POSCashSessionDetailView(session: session, onBack: {})
            }
        case .payIn:
            POSCashSessionEntryView(action: .payIn, controller: controller, onClosed: { _ in })
        case .payInNote:
            POSCashSessionEntryView(action: .payIn, controller: controller, onClosed: { _ in }, previewNoteStep: true)
        case .payOut:
            POSCashSessionEntryView(action: .payOut, controller: controller, onClosed: { _ in })
        case .payOutNote:
            POSCashSessionEntryView(action: .payOut, controller: controller, onClosed: { _ in }, previewNoteStep: true)
        case .close:
            POSCashSessionEntryView(action: .close, controller: controller, onClosed: { _ in })
        case .closeWithAmount:
            POSCashSessionEntryView(action: .close, controller: controller, onClosed: { _ in }, previewNoteStep: false)
        case .closeNote:
            POSCashSessionEntryView(action: .close, controller: controller, onClosed: { _ in }, previewNoteStep: true)
        }
    }

    private var pastSessionsPreview: some View {
        NavigationStack(path: $detailNavigationPath) {
            POSPastCashSessionsView(detailNavigationPath: $detailNavigationPath,
                                    controller: controller)
                .navigationBarHidden(true)
        }
    }

    private func prepare() async {
        switch screen {
        case .start, .startError:
            break
        case .current, .payIn, .payInNote, .payOut, .payOutNote, .close, .closeWithAmount, .closeNote:
            _ = await controller.start(openingCash: 200)
            _ = await controller.record(kind: .payIn, amount: 100, note: "Change order from bank")
            _ = await controller.record(kind: .payOut, amount: 30, note: "Window cleaner")
        case .past, .detail:
            await controller.load()
        case .currentError:
            await controller.loadCurrentSession()
        case .pastError:
            await controller.loadPastSessions()
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

#Preview("Pay in note") {
    POSCashSessionPreviewGallery(screen: .payInNote)
}

#Preview("Pay out") {
    POSCashSessionPreviewGallery(screen: .payOut)
}

#Preview("Pay out note") {
    POSCashSessionPreviewGallery(screen: .payOutNote)
}

#Preview("Close session") {
    POSCashSessionPreviewGallery(screen: .close)
}

#Preview("Close session amount entered") {
    POSCashSessionPreviewGallery(screen: .closeWithAmount)
}

#Preview("Close session note") {
    POSCashSessionPreviewGallery(screen: .closeNote)
}

#Preview("Start error") {
    POSCashSessionPreviewGallery(screen: .startError)
}

#Preview("Current load error") {
    POSCashSessionPreviewGallery(screen: .currentError)
}

#Preview("Past load error") {
    POSCashSessionPreviewGallery(screen: .pastError)
}

#endif
