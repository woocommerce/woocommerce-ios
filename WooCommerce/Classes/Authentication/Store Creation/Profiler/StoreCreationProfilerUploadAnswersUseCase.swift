import Foundation
import Yosemite

protocol StoreCreationProfilerUploadAnswersUseCaseProtocol {
    func storeAnswers(_ data: StoreProfilerAnswers)

    func uploadAnswers() async
}

/// Uploads the answers from the store creation profiler questions
/// - Stores the answers locally. (We do this becase we want to wait until the new store is created and fully connected with Jetpack tunnel.(
/// - Uploads the answers when requested.
/// - Clears the stored answers upon successful upload.
struct StoreCreationProfilerUploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCaseProtocol {
    private let siteID: Int64
    private let stores: StoresManager
    private let userDefaults: UserDefaults

    private var idAsString: String {
        "\(siteID)"
    }

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         userDefaults: UserDefaults = .standard) {
        self.siteID = siteID
        self.stores = stores
        self.userDefaults = userDefaults
    }

    func storeAnswers(_ data: StoreProfilerAnswers) {
        guard let data = try? JSONEncoder().encode(data) else {
            return
        }

        if var answers = userDefaults[.storeProfilerAnswers] as? [String: Data] {
            answers[idAsString] = data
            userDefaults[.storeProfilerAnswers] = answers
        } else {
            userDefaults[.storeProfilerAnswers] = [idAsString: data]
        }
    }

    func uploadAnswers() async {
        guard let answers = getStoredAnswers() else {
            return
        }

        let result = await uploadStoreProfilerAnswers(siteID: siteID, answers: answers)
        switch result {
        case .success:
            if var answers = userDefaults[.storeProfilerAnswers] as? [String: Data] {
                answers[idAsString] = nil
                userDefaults[.storeProfilerAnswers] = answers
            }
        case .failure(let error):
            DDLogError("⛔️ Error uploading store profiler answers \(error)")
        }
    }
}

private extension StoreCreationProfilerUploadAnswersUseCase {
    func getStoredAnswers() -> StoreProfilerAnswers? {
        guard let storeProfilerAnswers = userDefaults[.storeProfilerAnswers] as? [String: Data],
              let data = storeProfilerAnswers[idAsString] else {
            return nil
        }

        let decoder = JSONDecoder()
        if let profilerData = try? decoder.decode(StoreProfilerAnswers.self, from: data) {
            return profilerData
        } else {
            return nil
        }
    }

    @MainActor
    func uploadStoreProfilerAnswers(siteID: Int64, answers: StoreProfilerAnswers) async -> Result<Void, Error> {
        await withCheckedContinuation { continuation in
            stores.dispatch(SiteAction.uploadStoreProfilerAnswers(siteID: siteID, answers: answers) { result in
                continuation.resume(returning: result)
            })
        }
    }
}
