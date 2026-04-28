import Foundation
import Testing
@testable import WooAIAssistant

struct OpenAIChatTests {

    @Test
    func test_message_encode_when_assistant_with_tool_calls_then_content_is_empty_string() throws {
        // Given
        let toolCall = OpenAIChat.ToolCall(
            id: "call_1",
            function: .init(name: "orders_get", arguments: "{}")
        )
        let message = OpenAIChat.Message(role: .assistant, content: nil, toolCalls: [toolCall])

        // When
        let data = try JSONEncoder().encode(message)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        // Then
        let content = try #require(json["content"] as? String)
        #expect(content.isEmpty)
        #expect(json["tool_calls"] != nil)
    }

    @Test
    func test_response_decode_when_choices_empty_then_does_not_crash() throws {
        // Given
        let json = try #require("""
        {
          "id": "chatcmpl-1",
          "model": "gpt-4o-mini",
          "choices": [],
          "usage": {
            "prompt_tokens": 12,
            "completion_tokens": 0,
            "total_tokens": 12
          }
        }
        """.data(using: .utf8))

        // When
        let response = try JSONDecoder().decode(OpenAIChat.Response.self, from: json)

        // Then
        #expect(response.choices.isEmpty)
        #expect(response.usage?.promptTokens == 12)
    }

    @Test
    func test_chunk_decode_when_choices_empty_then_does_not_crash() throws {
        // Given
        let json = try #require("""
        {
          "id": "chatcmpl-3",
          "model": "gpt-4o-mini",
          "choices": [],
          "usage": {
            "prompt_tokens": 9,
            "completion_tokens": 1,
            "total_tokens": 10
          }
        }
        """.data(using: .utf8))

        // When
        let chunk = try JSONDecoder().decode(OpenAIChat.Chunk.self, from: json)

        // Then
        #expect(chunk.choices.isEmpty)
        #expect(chunk.usage?.totalTokens == 10)
    }

    @Test
    func test_chunk_decode_when_tool_call_delta_only_arguments_then_index_assigns_correctly() throws {
        // Given
        let json = try #require("""
        {
          "id": "chatcmpl-2",
          "model": "gpt-4o-mini",
          "choices": [
            {
              "index": 0,
              "delta": {
                "tool_calls": [
                  {
                    "index": 0,
                    "function": { "arguments": "{\\"site_id\\":1}" }
                  }
                ]
              }
            }
          ]
        }
        """.data(using: .utf8))

        // When
        let chunk = try JSONDecoder().decode(OpenAIChat.Chunk.self, from: json)

        // Then
        let choice = try #require(chunk.choices.first)
        let toolCallDelta = try #require(choice.delta.toolCalls?.first)
        #expect(toolCallDelta.index == 0)
        #expect(toolCallDelta.id == nil)
        #expect(toolCallDelta.function?.name == nil)
        #expect(toolCallDelta.function?.arguments == "{\"site_id\":1}")
    }

    @Test
    func test_finishReason_when_unknown_string_then_decodes_to_other() throws {
        // Given
        let json = try #require("\"some_future_value\"".data(using: .utf8))

        // When
        let finishReason = try JSONDecoder().decode(OpenAIChat.FinishReason.self, from: json)

        // Then
        #expect(finishReason == .other)
    }

    @Test
    func test_roundTrip_when_message_with_text_then_decodes_back_equal() throws {
        // Given
        let original = OpenAIChat.Message(role: .assistant, content: "hi")

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(OpenAIChat.Message.self, from: data)

        // Then
        #expect(decoded == original)
    }

    @Test
    func test_request_encode_uses_snake_case_keys_and_omits_nil_fields() throws {
        // Given
        let request = OpenAIChat.Request(
            messages: [.init(role: .user, content: "hi")],
            tools: [
                .init(function: .init(name: "orders_list",
                                      description: "List orders",
                                      parameters: .object([:])))
            ],
            toolChoice: .auto,
            model: "gpt-4o-mini",
            stream: true,
            feature: "woo-ai-assistant",
            maxTokens: 256
        )

        // When
        let data = try JSONEncoder().encode(request)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        // Then
        #expect(json["tool_choice"] as? String == "auto")
        #expect(json["max_tokens"] as? Int == 256)
        #expect(json["model"] as? String == "gpt-4o-mini")
        #expect(json["stream"] as? Bool == true)
        #expect(json["feature"] as? String == "woo-ai-assistant")
        #expect(json["temperature"] == nil)
        let messages = try #require(json["messages"] as? [[String: Any]])
        #expect(messages.first?["role"] as? String == "user")
        let tools = try #require(json["tools"] as? [[String: Any]])
        let toolFunction = try #require(tools.first?["function"] as? [String: Any])
        #expect(toolFunction["name"] as? String == "orders_list")
    }
}
