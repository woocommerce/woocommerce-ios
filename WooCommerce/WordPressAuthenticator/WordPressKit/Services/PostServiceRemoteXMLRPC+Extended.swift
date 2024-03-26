import Foundation
import wpxmlrpc

extension PostServiceRemoteXMLRPC: PostServiceRemoteExtended {
    public func createPost(with parameters: RemotePostCreateParameters) async throws -> RemotePost {
        let dictionary = try makeParameters(from: RemotePostCreateParametersXMLRPCEncoder(parameters: parameters))
        let parameters = xmlrpcArguments(withExtra: dictionary) as [AnyObject]
        let response = try await api.call(method: "metaWeblog.newPost", parameters: parameters).get()
        guard let postID = (response.body as? NSObject)?.numericValue() else {
            throw URLError(.unknown) // Should never happen
        }
        return try await getPost(withID: postID)
    }

    public func patchPost(withID postID: Int, parameters: RemotePostUpdateParameters) async throws -> RemotePost {
        let dictionary = try makeParameters(from: RemotePostUpdateParametersXMLRPCEncoder(parameters: parameters))
        var parameters = xmlrpcArguments(withExtra: dictionary) as [AnyObject]
        if parameters.count > 0 {
            parameters[0] = postID as NSNumber
        }
        let result = await api.call(method: "metaWeblog.editPost", parameters: parameters)
        switch result {
        case .success:
            return try await getPost(withID: postID as NSNumber)
        case .failure(let error):
            guard case .endpointError(let error) = error else {
                throw error
            }
            switch error.code ?? 0 {
            case 404: throw PostServiceRemoteUpdatePostError.notFound
            case 409: throw PostServiceRemoteUpdatePostError.conflict
            default: throw error
            }
        }
    }

    private func getPost(withID postID: NSNumber) async throws -> RemotePost {
        try await withUnsafeThrowingContinuation { continuation in
            getPostWithID(postID) { post in
                guard let post else {
                    return continuation.resume(throwing: URLError(.unknown)) // Should never happen
                }
                continuation.resume(returning: post)
            } failure: { error in
                continuation.resume(throwing: error ?? URLError(.unknown))
            }
        }
    }
}

private func makeParameters<T: Encodable>(from value: T) throws -> [String: AnyObject] {
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .xml
    let data = try encoder.encode(value)
    let object = try PropertyListSerialization.propertyList(from: data, format: nil)
    guard let dictionary = object as? [String: AnyObject] else {
        throw URLError(.unknown) // This should never happen
    }
    return dictionary
}
