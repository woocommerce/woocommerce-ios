import Foundation

/// Mapper for the WooShipping service status notices.
///
/// Invalid entries or fields are dropped instead of failing the whole response, so one malformed notice
/// can't hide the others. Repeated ids keep their first notice.
struct WooShippingServiceStatusMapper: Mapper {
    func map(response: Data) throws -> [WooShippingServiceStatusNotice] {
        let decoder = JSONDecoder()
        let serviceStatus: ServiceStatusResponse
        if hasDataEnvelope(in: response) {
            serviceStatus = try decoder.decode(ServiceStatusEnvelope.self, from: response).data
        } else {
            serviceStatus = try decoder.decode(ServiceStatusResponse.self, from: response)
        }
        var seenIDs = Set<String>()
        return serviceStatus.notices
            .compactMap { $0.notice?.toNotice() }
            .filter { seenIDs.insert($0.id).inserted }
    }
}

private struct ServiceStatusEnvelope: Decodable {
    let data: ServiceStatusResponse
}

private struct ServiceStatusResponse: Decodable {
    let notices: [LossyNoticeResponse]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        notices = (try? container.decodeIfPresent([LossyNoticeResponse].self, forKey: .notices)) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case notices
    }
}

/// Decodes `null` or non-object entries as `nil` instead of throwing.
private struct LossyNoticeResponse: Decodable {
    let notice: ServiceStatusNoticeResponse?

    init(from decoder: Decoder) throws {
        notice = try? ServiceStatusNoticeResponse(from: decoder)
    }
}

private struct ServiceStatusNoticeResponse: Decodable {
    let id: String?
    let type: String?
    let message: String?
    let dismissible: Bool?
    let action: String?

    /// A field with an unexpected type is treated as missing.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try? container.decodeIfPresent(String.self, forKey: .id)
        type = try? container.decodeIfPresent(String.self, forKey: .type)
        message = try? container.decodeIfPresent(String.self, forKey: .message)
        dismissible = try? container.decodeIfPresent(Bool.self, forKey: .dismissible)
        action = try? container.decodeIfPresent(String.self, forKey: .action)
    }

    private enum CodingKeys: String, CodingKey {
        case id, type, message, dismissible, action
    }

    func toNotice() -> WooShippingServiceStatusNotice? {
        guard let id, id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
              let message, message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            return nil
        }
        return WooShippingServiceStatusNotice(id: id,
                                              severity: severity,
                                              message: message,
                                              isDismissible: dismissible ?? false,
                                              actionURL: actionURL)
    }

    private var severity: WooShippingServiceStatusSeverity {
        type.flatMap { WooShippingServiceStatusSeverity(rawValue: $0.lowercased()) } ?? .info
    }

    private var actionURL: URL? {
        guard let action,
              let components = URLComponents(string: action),
              let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme),
              let host = components.host, host.isEmpty == false else {
            return nil
        }
        return URL(string: action)
    }
}
