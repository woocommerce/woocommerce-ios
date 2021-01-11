extension UIPasteboard {

    /// Detects patterns and values from the UIPasteboard. This will not trigger the pasteboard alert in iOS 14.
    /// - Parameters:
    ///   - patterns: The patterns to detect.
    ///   - completion: Called with the patterns and values if any were detected, otherwise contains the errors from UIPasteboard.
    @available(iOS 14.0, *)
    func detect(patterns: Set<UIPasteboard.DetectionPattern>, completion: @escaping (Result<[UIPasteboard.DetectionPattern: Any], Error>) -> Void) {
        UIPasteboard.general.detectPatterns(for: patterns) { result in
            switch result {
            case .success(let detections):
                guard detections.isEmpty == false else {
                    DispatchQueue.main.async {
                        completion(.success([UIPasteboard.DetectionPattern : Any]()))
                    }
                    return
                }
                UIPasteboard.general.detectValues(for: patterns) { valuesResult in
                    DispatchQueue.main.async {
                        completion(valuesResult)
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Detects whether UIPasteboard.general contains a 2FA code.
    /// - Parameters:
    ///   - completion: Called with the 2FA code on success, or failure otherwise
    @available(iOS 14.0, *)
    func detectTwoFactorCode(completion: @escaping (Result<String, Error>) -> Void) {
        UIPasteboard.general.detect(patterns: [.number]) { result in
            switch result {
                case .success(let detections):
                    if let twoFactorCode = detections.first?.value as? String {
                        completion(.success(twoFactorCode))
                        return
                    }
                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }
}
