import Foundation

/// OpenAI-compatible chat-completion wire types.
///
/// Both `jetpack-ai-query` and `ai-api-proxy/v1/chat/completions` accept this
/// shape verbatim, so a single set of types covers today's backend and the
/// expected future swap. Tool calling follows the OpenAI spec
/// (`finish_reason: "tool_calls"`, `tool_calls[i].function.{name,arguments}`).
public enum OpenAIChat {

    // MARK: - Roles

    public enum Role: String, Codable, Sendable {
        case system
        case user
        case assistant
        case tool
    }

    // MARK: - Messages

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
        /// required to satisfy the proxy's validator. Verified empirically
        /// via a live probe of the endpoint (probes E1/E2: `""` and
        /// `"Calling tool"` both return 200 against an otherwise-failing
        /// body).
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(role, forKey: .role)
            if role == .assistant && toolCalls?.isEmpty == false {
                // Empty string, NOT null and NOT omitted.
                try container.encode(content ?? "", forKey: .content)
            } else {
                try container.encodeIfPresent(content, forKey: .content)
            }
            try container.encodeIfPresent(toolCalls, forKey: .toolCalls)
            try container.encodeIfPresent(toolCallID, forKey: .toolCallID)
        }

        public static func system(_ text: String) -> Message {
            Message(role: .system, content: text)
        }
        public static func user(_ text: String) -> Message {
            Message(role: .user, content: text)
        }
        public static func assistant(_ text: String) -> Message {
            Message(role: .assistant, content: text)
        }
        public static func assistant(toolCalls: [ToolCall]) -> Message {
            Message(role: .assistant, toolCalls: toolCalls)
        }
        public static func tool(callID: String, content: String) -> Message {
            Message(role: .tool, content: content, toolCallID: callID)
        }
    }

    // MARK: - Tool calls

    /// Assistant-emitted request to invoke a function. `arguments` is a JSON
    /// string the caller must parse against the tool's declared schema.
    public struct ToolCall: Codable, Sendable, Equatable {
        public let id: String
        public let type: String
        public let function: FunctionCall

        public init(id: String, function: FunctionCall, type: String = "function") {
            self.id = id
            self.type = type
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

    // MARK: - Tool definitions (request side)

    /// Function declaration sent in the `tools` array of a request. The
    /// `parameters` field is a JSON Schema object describing the function's
    /// argument shape - encoded as `AnyCodableJSON` so any valid schema
    /// round-trips.
    public struct ToolDefinition: Codable, Sendable, Equatable {
        public let type: String
        public let function: FunctionDefinition

        public init(function: FunctionDefinition, type: String = "function") {
            self.type = type
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

    /// Wire-level `tool_choice` parameter. OpenAI accepts `"auto"`,
    /// `"required"`, or a specific-function object. Used by the
    /// orchestrator to pin `respond` on forced follow-up turns when the
    /// model emitted plain text instead of calling the terminal tool.
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

    // MARK: - Request

    public struct Request: Encodable, Sendable {
        public let messages: [Message]
        public let tools: [ToolDefinition]?
        public let toolChoice: ToolChoice?
        public let model: String?
        public let stream: Bool
        public let feature: String
        public let temperature: Double?
        public let maxTokens: Int?

        public init(messages: [Message],
                    tools: [ToolDefinition]? = nil,
                    toolChoice: ToolChoice? = nil,
                    model: String? = nil,
                    stream: Bool = false,
                    feature: String,
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
    }

    // MARK: - Response (non-streaming)

    public struct Response: Decodable, Sendable, Equatable {
        public let id: String?
        public let model: String?
        public let choices: [Choice]
        public let usage: Usage?

        public init(id: String? = nil,
                    model: String? = nil,
                    choices: [Choice],
                    usage: Usage? = nil) {
            self.id = id
            self.model = model
            self.choices = choices
            self.usage = usage
        }
    }

    public struct Choice: Decodable, Sendable, Equatable {
        public let index: Int
        public let message: Message
        public let finishReason: FinishReason?

        public init(index: Int, message: Message, finishReason: FinishReason? = nil) {
            self.index = index
            self.message = message
            self.finishReason = finishReason
        }

        enum CodingKeys: String, CodingKey {
            case index, message
            case finishReason = "finish_reason"
        }
    }

    /// `finish_reason` value from the API. Decode falls back to `.stop` for
    /// unknown strings so a future server-side enum addition does not break
    /// in-flight responses; the orchestrator inspects `tool_calls` directly
    /// for tool-driven turns and treats anything else as a terminal stop.
    public enum FinishReason: String, Sendable, Equatable {
        case stop
        case toolCalls = "tool_calls"
        case length
        case contentFilter = "content_filter"
        case functionCall = "function_call"
    }

    public struct Usage: Decodable, Sendable, Equatable {
        public let promptTokens: Int?
        public let completionTokens: Int?
        public let totalTokens: Int?

        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }

    // MARK: - Streaming chunk (SSE)

    /// Streaming chunk in the OpenAI SSE format. Multiple chunks build up a
    /// single response; tool-call arguments arrive as fragments and must be
    /// concatenated by index across chunks.
    public struct Chunk: Decodable, Sendable, Equatable {
        public let id: String?
        public let model: String?
        public let choices: [ChunkChoice]
        public let usage: Usage?
    }

    public struct ChunkChoice: Decodable, Sendable, Equatable {
        public let index: Int
        public let delta: Delta
        public let finishReason: FinishReason?

        enum CodingKeys: String, CodingKey {
            case index, delta
            case finishReason = "finish_reason"
        }
    }

    public struct Delta: Decodable, Sendable, Equatable {
        public let role: Role?
        public let content: String?
        public let toolCalls: [ToolCallDelta]?

        enum CodingKeys: String, CodingKey {
            case role, content
            case toolCalls = "tool_calls"
        }
    }

    /// Partial tool call fragment streamed inside a `Delta`. `index` identifies
    /// which tool call this fragment belongs to (0-based across the response).
    /// All other fields are present in the first fragment and absent in
    /// subsequent fragments that only carry more `arguments` characters.
    public struct ToolCallDelta: Decodable, Sendable, Equatable {
        public let index: Int
        public let id: String?
        public let type: String?
        public let function: FunctionDelta?
    }

    public struct FunctionDelta: Decodable, Sendable, Equatable {
        public let name: String?
        public let arguments: String?
    }
}

extension OpenAIChat.FinishReason: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = OpenAIChat.FinishReason(rawValue: raw) ?? .stop
    }
}
