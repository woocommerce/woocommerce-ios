import Foundation

/// OpenAI-compatible chat-completion wire types.
///
/// Both `jetpack-ai-query` and `ai-api-proxy/v1/chat/completions` accept this
/// shape verbatim, so a single set of types covers today's backend and the
/// expected future swap. Tool calling follows the OpenAI spec
/// (`finish_reason: "tool_calls"`, `tool_calls[i].function.{name,arguments}`).
public enum OpenAIChat {

    public enum Role: String, Codable, Sendable {
        case system
        case user
        case assistant
        case tool
    }

    /// One message in the chat history. Field validity depends on `role`:
    /// - `.system` / `.user`: `content` set; `toolCalls` and `toolCallID` nil.
    /// - `.assistant`: either `content` set (text response) OR `toolCalls`
    ///   set (model wants to call functions). Never both populated together
    ///   in a real response, but both fields exist for round-tripping.
    /// - `.tool`: `content` is the tool result (typically a JSON string),
    ///   `toolCallID` references the originating assistant tool call.
    public struct Message: Codable, Sendable, Equatable {
        public let role: Role
        public let content: String?
        public let toolCalls: [ToolCall]?
        public let toolCallID: String?

        public init(role: Role,
                    content: String? = nil,
                    toolCalls: [ToolCall]? = nil,
                    toolCallID: String? = nil) {
            self.role = role
            self.content = content
            self.toolCalls = toolCalls
            self.toolCallID = toolCallID
        }

        enum CodingKeys: String, CodingKey {
            case role
            case content
            case toolCalls = "tool_calls"
            case toolCallID = "tool_call_id"
        }

        /// Custom encoder so an assistant turn carrying `tool_calls` still
        /// emits a present, non-null `content` field. jetpack-ai-query's
        /// pre-filter rejects `"content": null` AND an omitted `content`
        /// key with `jetpack_ai_error: Invalid message format`; it accepts
        /// an empty string. OpenAI's downstream model ignores `content`
        /// when `tool_calls` is set, so the empty string is cosmetic but
        /// required to satisfy the proxy's validator.
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(role, forKey: .role)
            if role == .assistant && toolCalls?.isEmpty == false {
                try container.encode(content ?? "", forKey: .content)
            } else {
                try container.encodeIfPresent(content, forKey: .content)
            }
            try container.encodeIfPresent(toolCalls, forKey: .toolCalls)
            try container.encodeIfPresent(toolCallID, forKey: .toolCallID)
        }
    }

    /// `arguments` is a JSON string the caller must parse against the tool's
    /// declared schema; OpenAI sends arguments as a serialised string rather
    /// than an inline object.
    public struct ToolCall: Codable, Sendable, Equatable {
        public let id: String
        public let type: String
        public let function: FunctionCall

        public init(id: String, function: FunctionCall) {
            self.id = id
            self.type = "function"
            self.function = function
        }
    }

    public struct FunctionCall: Codable, Sendable, Equatable {
        public let name: String
        public let arguments: String

        public init(name: String, arguments: String) {
            self.name = name
            self.arguments = arguments
        }
    }

    /// `parameters` is a JSON Schema object describing the function's
    /// argument shape. Stored as `AnyCodableJSON` so any valid schema
    /// round-trips without bespoke decoding per tool.
    public struct ToolDefinition: Codable, Sendable, Equatable {
        public let type: String
        public let function: FunctionDefinition

        public init(function: FunctionDefinition) {
            self.type = "function"
            self.function = function
        }
    }

    public struct FunctionDefinition: Codable, Sendable, Equatable {
        public let name: String
        public let description: String
        public let parameters: AnyCodableJSON

        public init(name: String, description: String, parameters: AnyCodableJSON) {
            self.name = name
            self.description = description
            self.parameters = parameters
        }
    }

    /// Encoded-only; `jetpack-ai-query` never returns `tool_choice`.
    public enum ToolChoice: Encodable, Sendable, Equatable {
        case auto
        case required
        case function(name: String)

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .auto:
                try container.encode("auto")
            case .required:
                try container.encode("required")
            case .function(let name):
                try container.encode(SpecificFunctionChoice(
                    type: "function",
                    function: .init(name: name)
                ))
            }
        }

        private struct SpecificFunctionChoice: Encodable {
            let type: String
            let function: FunctionName
            struct FunctionName: Encodable { let name: String }
        }
    }

    struct Request: Encodable, Sendable {
        let messages: [Message]
        let tools: [ToolDefinition]?
        let toolChoice: ToolChoice?
        let model: String?
        let stream: Bool
        let feature: String?
        let temperature: Double?
        let maxTokens: Int?

        init(messages: [Message],
             tools: [ToolDefinition]? = nil,
             toolChoice: ToolChoice? = nil,
             model: String? = nil,
             stream: Bool = false,
             feature: String? = nil,
             temperature: Double? = nil,
             maxTokens: Int? = nil) {
            self.messages = messages
            self.tools = tools
            self.toolChoice = toolChoice
            self.model = model
            self.stream = stream
            self.feature = feature
            self.temperature = temperature
            self.maxTokens = maxTokens
        }

        enum CodingKeys: String, CodingKey {
            case messages, tools, model, stream, feature, temperature
            case toolChoice = "tool_choice"
            case maxTokens = "max_tokens"
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(messages, forKey: .messages)
            try container.encodeIfPresent(tools, forKey: .tools)
            try container.encodeIfPresent(toolChoice, forKey: .toolChoice)
            try container.encodeIfPresent(model, forKey: .model)
            try container.encode(stream, forKey: .stream)
            try container.encodeIfPresent(feature, forKey: .feature)
            try container.encodeIfPresent(temperature, forKey: .temperature)
            try container.encodeIfPresent(maxTokens, forKey: .maxTokens)
        }
    }

    struct Response: Decodable, Sendable, Equatable {
        let id: String?
        let model: String?
        let choices: [Choice]
        let usage: Usage?
    }

    struct Choice: Decodable, Sendable, Equatable {
        let index: Int
        let message: Message
        let finishReason: FinishReason?

        enum CodingKeys: String, CodingKey {
            case index, message
            case finishReason = "finish_reason"
        }
    }

    /// `finish_reason` value from the API. Unknown strings decode to `.other`
    /// so a future server-side enum addition does not break in-flight
    /// responses; matches Android's `FinishReason.OTHER` for cross-platform
    /// parity. Callers that need to react only to a terminal stop should
    /// match `.stop` explicitly.
    public enum FinishReason: String, Sendable, Equatable {
        case stop
        case toolCalls = "tool_calls"
        case length
        case contentFilter = "content_filter"
        case functionCall = "function_call"
        case other
    }

    struct Usage: Decodable, Sendable, Equatable {
        let promptTokens: Int?
        let completionTokens: Int?
        let totalTokens: Int?

        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }

    /// Multiple chunks build up a single response; tool-call arguments arrive
    /// as fragments and must be concatenated by index across chunks.
    struct Chunk: Decodable, Sendable, Equatable {
        let id: String?
        let model: String?
        let choices: [ChunkChoice]
        let usage: Usage?
    }

    struct ChunkChoice: Decodable, Sendable, Equatable {
        let index: Int
        let delta: Delta
        let finishReason: FinishReason?

        enum CodingKeys: String, CodingKey {
            case index, delta
            case finishReason = "finish_reason"
        }
    }

    struct Delta: Decodable, Sendable, Equatable {
        let role: Role?
        let content: String?
        let toolCalls: [ToolCallDelta]?

        enum CodingKeys: String, CodingKey {
            case role, content
            case toolCalls = "tool_calls"
        }
    }

    /// All fields except `index` are present only in the first fragment of a
    /// given tool call. Subsequent fragments carry just `index` and a slice
    /// of `function.arguments` to be concatenated by the consumer.
    struct ToolCallDelta: Decodable, Sendable, Equatable {
        let index: Int
        let id: String?
        let type: String?
        let function: FunctionDelta?
    }

    struct FunctionDelta: Decodable, Sendable, Equatable {
        let name: String?
        let arguments: String?
    }
}

extension OpenAIChat.FinishReason: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = OpenAIChat.FinishReason(rawValue: raw) ?? .other
    }
}
