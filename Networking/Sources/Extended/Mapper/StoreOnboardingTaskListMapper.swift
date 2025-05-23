import Foundation

/// Mapper: StoreOnboardingTask
///
struct StoreOnboardingTaskListMapper: Mapper {
    func map(response: Data) throws -> [StoreOnboardingTask] {
        let decoder = JSONDecoder()
        let taskGroup: [StoreOnboardingTaskGroup]

        if hasDataEnvelope(in: response) {
            taskGroup = try decoder
                .decode(StoreOnboardingTaskEnvelope.self, from: response)
                .group
        } else {
            taskGroup = try decoder.decode([StoreOnboardingTaskGroup].self, from: response)
        }

        // Only the `setup` tasks are related to store onboarding and relevant to mobile app
        let setupGroup = taskGroup.first(where: { $0.id == Constants.setupTasksID })

        return setupGroup?.tasks ?? []
    }
}

private extension StoreOnboardingTaskListMapper {
    enum Constants {
        static let setupTasksID = "setup"
    }
}

private struct StoreOnboardingTaskGroup: Decodable {
    let id: String
    let tasks: [StoreOnboardingTask]

    private enum CodingKeys: String, CodingKey {
        case id
        case tasks
    }
}

private struct StoreOnboardingTaskEnvelope: Decodable {
    let group: [StoreOnboardingTaskGroup]

    private enum CodingKeys: String, CodingKey {
        case group = "data"
    }
}
