@testable import WooCommerce

struct MockApplicationLogProvider: ApplicationLogProvider {
    let logs: String?

    func applicationLogs(cappedTo: Int?) -> String? {
        logs
    }
}
