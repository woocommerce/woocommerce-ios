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
    private(set) var isRefreshingPastSessions = false
    private(set) var isLoadingSessionDetail = false
    private(set) var isSaving = false
    private(set) var hasMorePastSessions = false
    private(set) var currentLoadError: String?
    private(set) var isCashSessionsUnsupported = false
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
        isCashSessionsUnsupported = false
        defer { isLoading = false }
        do {
            currentSession = try await service.currentSession()
        } catch POSCashSessionServiceError.unsupported {
            isCashSessionsUnsupported = true
        } catch {
            currentLoadError = POSCashSessionErrorMessage.message(for: error, operation: .loadCurrent)
        }
    }

    func loadPastSessions(force: Bool = false) async {
        guard !isLoadingPastSessions, !isLoadingNextPastSessions, !isRefreshingPastSessions else { return }
        guard force || !hasLoadedPastSessions else { return }
        isLoadingPastSessions = true
        defer { isLoadingPastSessions = false }
        await loadFirstPastSessionsPage()
    }

    func refreshPastSessions() async {
        guard !isLoadingPastSessions, !isLoadingNextPastSessions, !isRefreshingPastSessions else { return }
        isRefreshingPastSessions = true
        defer { isRefreshingPastSessions = false }
        await loadFirstPastSessionsPage()
    }

    private func loadFirstPastSessionsPage() async {
        pastLoadError = nil
        pastPageError = nil
        do {
            let result = try await service.pastSessions(page: 1, perPage: pageSize)
            pastSessions = result.sessions
            hasMorePastSessions = result.hasMore
            pastPage = 1
            hasLoadedPastSessions = true
        } catch {
            pastLoadError = POSCashSessionErrorMessage.message(for: error, operation: .loadPast)
        }
    }

    func loadNextPastSessions() async {
        guard hasLoadedPastSessions, hasMorePastSessions,
              !isLoadingPastSessions, !isLoadingNextPastSessions, !isRefreshingPastSessions else { return }
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
            pastPageError = POSCashSessionErrorMessage.message(for: error, operation: .loadMorePast)
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
            if detailRequest == request, !Task.isCancelled {
                sessionDetailError = POSCashSessionErrorMessage.message(for: error, operation: .loadDetail)
            }
        }
    }

    func start(openingCash: Decimal) async -> Bool {
        await save(operation: .start) {
            currentSession = try await service.startSession(openingCash: openingCash)
        }
    }

    func record(kind: POSCashSessionMovement.Kind, amount: Decimal, note: String?) async -> Bool {
        guard let session = currentSession else { return false }
        return await save(operation: .record) {
            currentSession = try await service.recordMovement(sessionID: session.id, kind: kind, amount: amount, note: note)
        }
    }

    func close(countedCash: Decimal, note: String?) async -> POSCashSession? {
        guard let session = currentSession else { return nil }
        var closedSession: POSCashSession?
        let saved = await save(operation: .close) {
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

    private func save(operation: POSCashSessionErrorMessage.Operation, _ perform: () async throws -> Void) async -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            try await perform()
            return true
        } catch {
            errorMessage = POSCashSessionErrorMessage.message(for: error, operation: operation)
            return false
        }
    }
}
