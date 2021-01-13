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

    /// Attempts to detect and return a authenticator code from the pasteboard.
    /// Expects to run on main thread.
    /// - Parameters:
    ///   - completion: Called with a six digit authentication code on success
    @available(iOS 14.0, *)
    func detectAuthenticatorCode(completion: @escaping (Result<String, Error>) -> Void) {
        UIPasteboard.general.detect(patterns: [.number]) { result in
            switch result {
                case .success(let detections):
                    guard let firstMatch = detections.first else {
                        completion(.success(""))
                        return
                    }
                    guard let matchedNumber = firstMatch.value as? NSNumber else {
                        completion(.success(""))
                        return
                    }

                    var authenticationCode = matchedNumber.stringValue

                    /// Reject numbers with decimal points or signs in them
                    let codeCharacterSet = CharacterSet(charactersIn: authenticationCode)
                    if !codeCharacterSet.isSubset(of: CharacterSet.decimalDigits) {
                        completion(.success(""))
                        return
                    }

                    /// We need 6 digits. No more, no less.
                    if authenticationCode.count > 6 {
                        completion(.success(""))
                        return
                    }

                    while authenticationCode.count < 6 {
                        authenticationCode = "0" + authenticationCode
                    }

                    completion(.success(authenticationCode))
                    return
                case .failure(let error):
                    completion(.failure(error))
                    return
            }
        }
    }
}
