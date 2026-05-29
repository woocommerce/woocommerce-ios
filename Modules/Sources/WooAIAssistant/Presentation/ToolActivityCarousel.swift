import SwiftUI

struct ToolCallSnapshot: Identifiable, Equatable {
    let id: UUID
    let toolName: String
    let status: ToolCallStatus

    var isRunning: Bool {
        if case .running = status { return true }
        return false
    }
}

struct ToolActivityCarousel: View {

    /// Wait this long with no running tool before flipping to terminal status,
    /// so the pill does not flick between consecutive tool iterations.
    static let settleDebounce: TimeInterval = 0.35

    let snapshots: [ToolCallSnapshot]

    @State private var displayedID: UUID?
    @State private var allDoneAt: Date?
    @State private var hasSettled: Bool = false

    private let cycleTimer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()
    private let watchdog = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        if let displayed = Self.displayed(snapshots: snapshots,
                                          displayedID: displayedID,
                                          hasSettled: hasSettled) {
            ToolActivityPill(toolName: displayed.toolName, status: displayed.status)
                .onAppear {
                    displayedID = snapshots.first(where: \.isRunning)?.id ?? snapshots.last?.id
                    let anyRunning = snapshots.contains(where: \.isRunning)
                    hasSettled = !snapshots.isEmpty && !anyRunning
                    allDoneAt = anyRunning ? nil : Date.distantPast
                }
                .onReceive(cycleTimer) { _ in advanceLabelCursor() }
                .onChange(of: snapshots.contains(where: \.isRunning)) { _, anyRunning in
                    if anyRunning {
                        allDoneAt = nil
                        hasSettled = false
                    } else {
                        allDoneAt = Date()
                    }
                }
                .onReceive(watchdog) { now in
                    guard !hasSettled, let allDoneAt else { return }
                    if now.timeIntervalSince(allDoneAt) >= Self.settleDebounce {
                        hasSettled = true
                    }
                }
        }
    }

    private func advanceLabelCursor() {
        let running = snapshots.filter(\.isRunning)
        guard running.count > 1 else { return }
        let currentIndex = running.firstIndex(where: { $0.id == displayedID }) ?? -1
        let nextIndex = (currentIndex + 1) % running.count
        displayedID = running[nextIndex].id
    }

    /// Picks which snapshot to render. Forces running shape unless we have settled
    /// past the debounce window with no tool currently active.
    static func displayed(snapshots: [ToolCallSnapshot],
                          displayedID: UUID?,
                          hasSettled: Bool) -> ToolCallSnapshot? {
        guard !snapshots.isEmpty else { return nil }
        let anyRunning = snapshots.contains(where: \.isRunning)
        if hasSettled, !anyRunning {
            return snapshots.last
        }
        let pinned = snapshots.first(where: { $0.id == displayedID })
            ?? snapshots.first(where: \.isRunning)
            ?? snapshots.last
        guard let pinned else { return nil }
        return ToolCallSnapshot(id: pinned.id, toolName: pinned.toolName, status: .running)
    }
}

#if DEBUG
#Preview("Single running") {
    ToolActivityCarousel(snapshots: [
        ToolCallSnapshot(id: UUID(), toolName: "orders_list", status: .running)
    ])
    .padding()
}

#Preview("Multiple running") {
    ToolActivityCarousel(snapshots: [
        ToolCallSnapshot(id: UUID(), toolName: "orders_list", status: .running),
        ToolCallSnapshot(id: UUID(), toolName: "products_list", status: .running),
        ToolCallSnapshot(id: UUID(), toolName: "customers_list", status: .running),
        ToolCallSnapshot(id: UUID(), toolName: "analytics_orders", status: .running)
    ])
    .padding()
}

#Preview("All completed") {
    ToolActivityCarousel(snapshots: [
        ToolCallSnapshot(id: UUID(), toolName: "orders_list", status: .completed(summary: nil)),
        ToolCallSnapshot(id: UUID(), toolName: "analytics_orders", status: .completed(summary: nil))
    ])
    .padding()
}
#endif
