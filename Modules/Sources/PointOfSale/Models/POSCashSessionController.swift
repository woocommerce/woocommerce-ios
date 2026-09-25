import Foundation
import Observation

@MainActor
@Observable
final class POSCashSessionController {
    private(set) var currentSession: POSCashSession?
    private(set) var pastSessions: [POSCashSession] = []
    private(set) var sessionDetail: POSCashSession?
    private(set) var isLoading = false
    private(set) var isLoadingPastSessions = false
    private(set) var isLoadingNextPastSessions = false
    private(set) var isLoadingSessionDetail = false
    private(set) var isSaving = false
    private(set) var hasMorePastSessions = false
    private(set) var currentLoadError: String?
    private(set) var pastLoadError: String?
    private(set) var pastPageError: String?
    private(set) var sessionDetailError: String?
    var errorMessage: String?

    @ObservationIgnored private let service: any POSCashSessionService
    @ObservationIgnored private var pastPage = 0
    @ObservationIgnored private var hasLoadedPastSessions = false
    @ObservationIgnored private var detailRequest = 0
    @ObservationIgnored private let pageSize = 20

    init(service: any POSCashSessionService) {
        self.service = service
    }

    func load() async {
        await loadCurrentSession()
        await loadPastSessions()
    }

    func loadCurrentSession() async {
        guard !isLoading else { return }
        isLoading = true
        currentLoadError = nil
        defer { isLoading = false }
        do {
            currentSession = try await service.currentSession()
        } catch {
            currentLoadError = error.localizedDescription
        }
    }

    func loadPastSessions(force: Bool = false) async {
        guard !isLoadingPastSessions, !isLoadingNextPastSessions else { return }
        guard force || !hasLoadedPastSessions else { return }
        isLoadingPastSessions = true
        pastLoadError = nil
        pastPageError = nil
        defer { isLoadingPastSessions = false }
        do {
            let result = try await service.pastSessions(page: 1, perPage: pageSize)
            pastSessions = result.sessions
            hasMorePastSessions = result.hasMore
            pastPage = 1
            hasLoadedPastSessions = true
        } catch {
            pastLoadError = error.localizedDescription
        }
    }

    func loadNextPastSessions() async {
        guard hasLoadedPastSessions, hasMorePastSessions, !isLoadingPastSessions, !isLoadingNextPastSessions else { return }
        isLoadingNextPastSessions = true
        pastPageError = nil
        defer { isLoadingNextPastSessions = false }
        do {
            let nextPage = pastPage + 1
            let result = try await service.pastSessions(page: nextPage, perPage: pageSize)
            let knownIDs = Set(pastSessions.map(\.id))
            pastSessions.append(contentsOf: result.sessions.filter { !knownIDs.contains($0.id) })
            hasMorePastSessions = result.hasMore
            pastPage = nextPage
        } catch {
            pastPageError = error.localizedDescription
        }
    }

    func loadSessionDetail(id: Int64) async {
        guard sessionDetail?.id != id else { return }
        detailRequest += 1
        let request = detailRequest
        isLoadingSessionDetail = true
        sessionDetail = nil
        sessionDetailError = nil
        defer { if detailRequest == request { isLoadingSessionDetail = false } }
        do {
            let session = try await service.session(id: id)
            if detailRequest == request { sessionDetail = session }
        } catch {
            if detailRequest == request, !Task.isCancelled { sessionDetailError = error.localizedDescription }
        }
    }

    func start(openingCash: Decimal) async -> Bool {
        await save {
            currentSession = try await service.startSession(openingCash: openingCash)
        }
    }

    func record(kind: POSCashSessionMovement.Kind, amount: Decimal, note: String?) async -> Bool {
        guard let session = currentSession else { return false }
        return await save {
            currentSession = try await service.recordMovement(sessionID: session.id, kind: kind, amount: amount, note: note)
        }
    }

    func close(countedCash: Decimal, note: String?) async -> POSCashSession? {
        guard let session = currentSession else { return nil }
        var closedSession: POSCashSession?
        let saved = await save {
            let closed = try await service.closeSession(sessionID: session.id, expectedRevision: session.revision,
                                                        countedCash: countedCash, note: note)
            currentSession = nil
            detailRequest += 1
            isLoadingSessionDetail = false
            sessionDetail = closed
            pastSessions.removeAll { $0.id == closed.id }
            pastSessions.insert(closed, at: 0)
            hasLoadedPastSessions = false
            closedSession = closed
        }
        return saved ? closedSession : nil
    }

    private func save(_ operation: () async throws -> Void) async -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            try await operation()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
