import Alamofire
import Combine

public struct NetworkingReachability {
    public static func notifyOnceWhenApiReachable(completion: @escaping () -> Void) {
        let reachabilityManager = NetworkReachabilityManager(host: Settings.wordpressApiBaseURL)!
        reachabilityManager.listener = { status in
            if case .reachable(_) = status {
                reachabilityManager.stopListening()
                completion()
            }
        }
        reachabilityManager.startListening()
    }

    public static func notifyOnceWhenApiReachable() -> Future<Void, Never> {
        Future { promise in
            notifyOnceWhenApiReachable {
                promise(.success(()))
            }
        }
    }
}
