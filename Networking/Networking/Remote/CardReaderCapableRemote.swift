public protocol CardReaderCapableRemote {
    func loadConnectionToken(for siteID: Int64,
                             completion: @escaping(Result<ReaderConnectionToken, Error>) -> Void)
    func loadDefaultReaderLocation(for siteID: Int64,
                                   onCompletion: @escaping (Result<RemoteReaderLocation, Error>) -> Void)
}
