extension UIPasteboard {

    /// Detects patterns and values from the UIPasteboard. This will not trigger the pasteboard alert in iOS 14.
    /// - Parameters:
    ///   - patterns: The patterns to detect.
    ///   - completion: Called with the patterns and values if any were detected, otherwise contains the errors from UIPasteboard.
    @available(iOS 14.0, *)
    func detect(patterns: Set<UIPasteboard.DetectionPattern>, completion: @escaping (Result<[UIPasteboard.DetectionPattern: Any], Error>) -> Void) {
        UIPasteboard.general.detectPatterns(for: [.number]) { [weak self] result in
            switch result {
            case .success(let detections):
                guard detections.isEmpty == false else {
                    completion(.success([UIPasteboard.DetectionPattern : Any]()))
                    return
                }
                UIPasteboard.general.detectValues(for: [.number]) { [weak self] valuesResult in
                    completion(valuesResult)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
