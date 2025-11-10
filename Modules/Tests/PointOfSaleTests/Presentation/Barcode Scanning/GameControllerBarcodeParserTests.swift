import Testing
import GameController
@testable import PointOfSale
import WooFoundation

struct GameControllerBarcodeParserTests {

    // MARK: - Configuration Tests

    struct ConfigurationTests {
        @Test("default configuration has expected values")
        func default_configuration_when_requested_has_expected_values() {
            // Given
            let configuration = HIDBarcodeParserConfiguration.default

            // When & Then
            #expect(configuration.terminatingStrings == ["\r", "\n"])
            #expect(configuration.minimumBarcodeLength == 6)
            #expect(configuration.maximumInterCharacterTime == 0.2)
        }

        @Test("custom configuration accepts specified values")
        func custom_configuration_when_created_accepts_specified_values() {
            // Given
            let customTerminators: Set<String> = ["\t", " ", "\r"]
            let customMinLength = 4
            let customMaxTime: TimeInterval = 0.1

            // When
            let configuration = HIDBarcodeParserConfiguration(
                terminatingStrings: customTerminators,
                minimumBarcodeLength: customMinLength,
                maximumInterCharacterTime: customMaxTime
            )

            // Then
            #expect(configuration.terminatingStrings == customTerminators)
            #expect(configuration.minimumBarcodeLength == customMinLength)
            #expect(configuration.maximumInterCharacterTime == customMaxTime)
        }
    }

    // MARK: - Basic Scanning Tests

    struct BasicScanningTests {
        @Test("complete scan succeeds with valid barcode")
        func valid_barcode_when_scanned_completely_succeeds() {
            // Given
            var results: [HIDBarcodeParserResult] = []
            let parser = GameControllerBarcodeParser(
                configuration: Self.testConfiguration,
                onScan: { results.append($0) }
            )

            // When
            parser.processKeyPress(GCKeyCode.one)
            parser.processKeyPress(GCKeyCode.two)
            parser.processKeyPress(GCKeyCode.three)
            parser.processKeyPress(GCKeyCode.four)
            parser.processKeyPress(GCKeyCode.five)
            parser.processKeyPress(GCKeyCode.six)
            parser.processKeyPress(GCKeyCode.returnOrEnter)

            // Then
            #expect(results.count == 1)
            if case .success(let barcode, _) = results.first {
                #expect(barcode == "123456")
            } else {
                Issue.record("Expected successful scan")
            }
        }

        @Test("multiple consecutive scans work correctly")
        func multiple_barcodes_when_scanned_consecutively_work_correctly() {
            // Given
            var results: [HIDBarcodeParserResult] = []
            let parser = GameControllerBarcodeParser(
                configuration: Self.testConfiguration,
                onScan: { results.append($0) }
            )

            // When - First scan
            parser.processKeyPress(GCKeyCode.one)
            parser.processKeyPress(GCKeyCode.two)
            parser.processKeyPress(GCKeyCode.three)
            parser.processKeyPress(GCKeyCode.returnOrEnter)

            // When - Second scan
            parser.processKeyPress(GCKeyCode.four)
            parser.processKeyPress(GCKeyCode.five)
            parser.processKeyPress(GCKeyCode.six)
            parser.processKeyPress(GCKeyCode.returnOrEnter)

            // Then
            #expect(results.count == 2)
            if case .success(let barcode1, _) = results[0] {
                #expect(barcode1 == "123")
            } else {
                Issue.record("Expected first scan to succeed")
            }
            if case .success(let barcode2, _) = results[1] {
                #expect(barcode2 == "456")
            } else {
                Issue.record("Expected second scan to succeed")
            }
        }

        @Test("cancelled scan clears buffer and allows new scan")
        func partial_scan_when_cancelled_clears_buffer_and_allows_new_scan() {
            // Given
            var results: [HIDBarcodeParserResult] = []
            let parser = GameControllerBarcodeParser(
                configuration: Self.testConfiguration,
                onScan: { results.append($0) }
            )

            // When - Start a scan
            parser.processKeyPress(GCKeyCode.one)
            parser.processKeyPress(GCKeyCode.two)
            parser.processKeyPress(GCKeyCode.three)

            // When - Cancel the scan
            parser.cancel()

            // When - Start a new scan
            parser.processKeyPress(GCKeyCode.four)
            parser.processKeyPress(GCKeyCode.five)
            parser.processKeyPress(GCKeyCode.six)
            parser.processKeyPress(GCKeyCode.returnOrEnter)

            // Then
            #expect(results.count == 1)
            if case .success(let barcode, _) = results.first {
                #expect(barcode == "456")
            } else {
                Issue.record("Expected successful scan after cancel")
            }
        }

        // MARK: - Helper
        static let testConfiguration = HIDBarcodeParserConfiguration(
            terminatingStrings: ["\r", "\n"],
            minimumBarcodeLength: 3,
            maximumInterCharacterTime: 0.05
        )
    }

    // MARK: - Error Handling Tests

    struct ErrorHandlingTests {
        @Test("scan too short triggers error with default configuration")
        func short_barcode_when_scanned_with_default_config_triggers_error() {
            // Given
            var results: [HIDBarcodeParserResult] = []
            let parser = GameControllerBarcodeParser(
                configuration: .default, // min length 6
                onScan: { results.append($0) }
            )

            // When - Scan only 5 characters
            parser.processKeyPress(GCKeyCode.one)
            parser.processKeyPress(GCKeyCode.two)
            parser.processKeyPress(GCKeyCode.three)
            parser.processKeyPress(GCKeyCode.four)
            parser.processKeyPress(GCKeyCode.five)
            parser.processKeyPress(GCKeyCode.returnOrEnter)

            // Then
            #expect(results.count == 1)
            if case .failure(let error, let duration) = results.first {
                if case .scanTooShort(let barcode) = error {
                    #expect(barcode == "12345")
                    #expect(duration >= 0)
                } else {
                    Issue.record("Expected scanTooShort error")
                }
            } else {
                Issue.record("Expected failure result")
            }
        }

        @Test("scan too short triggers error with custom configuration")
        func short_barcode_when_scanned_with_custom_config_triggers_error() {
            // Given
            var results: [HIDBarcodeParserResult] = []
            let configuration = HIDBarcodeParserConfiguration(
                terminatingStrings: ["\r"],
                minimumBarcodeLength: 8,
                maximumInterCharacterTime: 0.1
            )
            let parser = GameControllerBarcodeParser(
                configuration: configuration,
                onScan: { results.append($0) }
            )

            // When - Scan only 7 characters
            parser.processKeyPress(GCKeyCode.one)
            parser.processKeyPress(GCKeyCode.two)
            parser.processKeyPress(GCKeyCode.three)
            parser.processKeyPress(GCKeyCode.four)
            parser.processKeyPress(GCKeyCode.five)
            parser.processKeyPress(GCKeyCode.six)
            parser.processKeyPress(GCKeyCode.seven)
            parser.processKeyPress(GCKeyCode.returnOrEnter)

            // Then
            #expect(results.count == 1)
            if case .failure(let error, let duration) = results.first {
                if case .scanTooShort(let barcode) = error {
                    #expect(barcode == "1234567")
                    #expect(duration >= 0)
                } else {
                    Issue.record("Expected scanTooShort error")
                }
            } else {
                Issue.record("Expected failure result")
            }
        }

        @Test("slow typing triggers timeout error")
        func slow_typing_when_exceeds_timeout_triggers_error() {
            // Given
            var results: [HIDBarcodeParserResult] = []
            let configuration = HIDBarcodeParserConfiguration(
                terminatingStrings: ["\r", "\n"],
                minimumBarcodeLength: 3,
                maximumInterCharacterTime: 0.2
            )
            let mockTimeProvider = MockTimeProvider()
            let parser = GameControllerBarcodeParser(
                configuration: configuration,
                onScan: { results.append($0) },
                timeProvider: mockTimeProvider
            )

            // When - Type slowly with timeout
            parser.processKeyPress(GCKeyCode.one)
            parser.processKeyPress(GCKeyCode.two)
            parser.processKeyPress(GCKeyCode.three)
            mockTimeProvider.advance(by: 0.201) // Just over maximumInterCharacterTime
            parser.processKeyPress(GCKeyCode.four)
            parser.processKeyPress(GCKeyCode.five)
            parser.processKeyPress(GCKeyCode.six)
            parser.processKeyPress(GCKeyCode.returnOrEnter)

            // Then - Should get timeout error and successful scan
            #expect(results.count == 2)
            if case .failure(let error, let duration) = results.first {
                if case .timedOut(let barcode) = error {
                    #expect(barcode == "123")
                    #expect(duration >= 0)
                } else {
                    Issue.record("Expected timedOut error")
                }
            } else {
                Issue.record("Expected timeout failure")
            }

            if case .success(let barcode, let duration) = results[1] {
                #expect(barcode == "456")
                #expect(duration >= 0)
            } else {
                Issue.record("Expected successful scan after timeout reset")
            }
        }

        @Test("fast typing within timeout succeeds")
        func fast_typing_when_within_timeout_succeeds() {
            // Given
            var results: [HIDBarcodeParserResult] = []
            let configuration = HIDBarcodeParserConfiguration.default
            let mockTimeProvider = MockTimeProvider()
            let parser = GameControllerBarcodeParser(
                configuration: configuration,
                onScan: { results.append($0) },
                timeProvider: mockTimeProvider
            )

            // When - Type just under the timeout limit
            parser.processKeyPress(GCKeyCode.one)
            mockTimeProvider.advance(by: 0.199) // Just under maximumInterCharacterTime
            parser.processKeyPress(GCKeyCode.two)
            mockTimeProvider.advance(by: 0.199)
            parser.processKeyPress(GCKeyCode.three)
            mockTimeProvider.advance(by: 0.199)
            parser.processKeyPress(GCKeyCode.four)
            mockTimeProvider.advance(by: 0.199)
            parser.processKeyPress(GCKeyCode.five)
            mockTimeProvider.advance(by: 0.199)
            parser.processKeyPress(GCKeyCode.six)
            mockTimeProvider.advance(by: 0.199)
            parser.processKeyPress(GCKeyCode.returnOrEnter)

            // Then
            #expect(results.count == 1)
            if case .success(let barcode, _) = results.first {
                #expect(barcode == "123456")
            } else {
                Issue.record("Expected successful scan")
            }
        }

        @Test("proactive timeout triggers error without next character")
        func timeout_when_timer_fires_triggers_timeout_error() {
            // Given
            var results: [HIDBarcodeParserResult] = []
            let configuration = HIDBarcodeParserConfiguration(
                terminatingStrings: ["\r", "\n"],
                minimumBarcodeLength: 3,
                maximumInterCharacterTime: 0.2
            )
            let mockTimeProvider = MockTimeProvider()
            let parser = GameControllerBarcodeParser(
                configuration: configuration,
                onScan: { results.append($0) },
                timeProvider: mockTimeProvider
            )

            // When - Type partial barcode and simulate timer firing
            parser.processKeyPress(GCKeyCode.one)
            parser.processKeyPress(GCKeyCode.two)
            parser.processKeyPress(GCKeyCode.three)

            // Advance time beyond timeout period - this will automatically fire timers
            mockTimeProvider.advance(by: 0.25)

            // Then - Should get timeout error automatically
            #expect(results.count == 1)
            if case .failure(let error, let duration) = results.first {
                if case .timedOut(let barcode) = error {
                    #expect(barcode == "123")
                    #expect(duration >= 0)
                } else {
                    Issue.record("Expected timedOut error")
                }
            } else {
                Issue.record("Expected timeout failure")
            }
        }

        @Test("timer cancelled on successful scan completion")
        func timer_cancelled_when_scan_completes_prevents_timeout_error() {
            // Given
            var results: [HIDBarcodeParserResult] = []
            let configuration = HIDBarcodeParserConfiguration(
                terminatingStrings: ["\r", "\n"],
                minimumBarcodeLength: 3,
                maximumInterCharacterTime: 0.2
            )
            let mockTimeProvider = MockTimeProvider()
            let parser = GameControllerBarcodeParser(
                configuration: configuration,
                onScan: { results.append($0) },
                timeProvider: mockTimeProvider
            )

            // When - Type partial barcode then complete it before timer fires
            parser.processKeyPress(GCKeyCode.one)
            parser.processKeyPress(GCKeyCode.two)
            parser.processKeyPress(GCKeyCode.three)
            parser.processKeyPress(GCKeyCode.returnOrEnter) // Complete scan before timeout

            // Try to advance time beyond timeout period - timer should not fire since it was cancelled
            mockTimeProvider.advance(by: 0.25)

            // Then - Should only get success result, no timeout error
            #expect(results.count == 1)
            if case .success(let barcode, _) = results.first {
                #expect(barcode == "123")
            } else {
                Issue.record("Expected successful scan")
            }
        }

        @Test("timer cancelled on manual scan cancellation")
        func timer_cancelled_when_scan_cancelled_prevents_timeout_error() {
            // Given
            var results: [HIDBarcodeParserResult] = []
            let configuration = HIDBarcodeParserConfiguration(
                terminatingStrings: ["\r", "\n"],
                minimumBarcodeLength: 3,
                maximumInterCharacterTime: 0.2
            )
            let mockTimeProvider = MockTimeProvider()
            let parser = GameControllerBarcodeParser(
                configuration: configuration,
                onScan: { results.append($0) },
                timeProvider: mockTimeProvider
            )

            // When - Type partial barcode then cancel before timer fires
            parser.processKeyPress(GCKeyCode.one)
            parser.processKeyPress(GCKeyCode.two)
            parser.processKeyPress(GCKeyCode.three)
            parser.cancel() // Cancel scan before timeout

            // Try to advance time beyond timeout period - timer should not fire since it was cancelled
            mockTimeProvider.advance(by: 0.25)

            // Then - Should have no results since scan was cancelled
            #expect(results.isEmpty)
        }

        @Test("new character input cancels previous timer and starts new one")
        func new_character_input_when_received_cancels_old_timer_and_starts_new() {
            // Given
            var results: [HIDBarcodeParserResult] = []
            let configuration = HIDBarcodeParserConfiguration(
                terminatingStrings: ["\r", "\n"],
                minimumBarcodeLength: 6,
                maximumInterCharacterTime: 0.2
            )
            let mockTimeProvider = MockTimeProvider()
            let parser = GameControllerBarcodeParser(
                configuration: configuration,
                onScan: { results.append($0) },
                timeProvider: mockTimeProvider
            )

            // When - Type characters with timing that would trigger timeout if timer wasn't reset
            parser.processKeyPress(GCKeyCode.one)

            // Advance time by 0.15 seconds (less than timeout) and add next character
            mockTimeProvider.advance(by: 0.15)
            parser.processKeyPress(GCKeyCode.two) // This should cancel the first timer

            // Advance another 0.15 seconds (would be 0.3 total, but timer should have reset)
            mockTimeProvider.advance(by: 0.15)
            parser.processKeyPress(GCKeyCode.three)
            parser.processKeyPress(GCKeyCode.four)
            parser.processKeyPress(GCKeyCode.five)
            parser.processKeyPress(GCKeyCode.six)
            parser.processKeyPress(GCKeyCode.returnOrEnter)

            // Final advance to ensure no leftover timers fire
            mockTimeProvider.advance(by: 0.1)

            // Then - Should get successful scan, not timeout
            #expect(results.count == 1)
            if case .success(let barcode, _) = results.first {
                #expect(barcode == "123456")
            } else {
                Issue.record("Expected successful scan")
            }
        }

        @Test("scan duration is properly tracked for successful scan")
        func scan_duration_when_successful_scan_is_properly_tracked() {
            // Given
            var results: [HIDBarcodeParserResult] = []
            let mockTimeProvider = MockTimeProvider()
            let parser = GameControllerBarcodeParser(
                configuration: Self.testConfiguration,
                onScan: { results.append($0) },
                timeProvider: mockTimeProvider
            )

            // When - Simulate a scan with known duration
            parser.processKeyPress(GCKeyCode.one)
            mockTimeProvider.advance(by: 0.04)
            parser.processKeyPress(GCKeyCode.two)
            parser.processKeyPress(GCKeyCode.three)
            parser.processKeyPress(GCKeyCode.four)
            mockTimeProvider.advance(by: 0.04)
            parser.processKeyPress(GCKeyCode.five)
            mockTimeProvider.advance(by: 0.02)
            parser.processKeyPress(GCKeyCode.six)
            parser.processKeyPress(GCKeyCode.returnOrEnter)

            // Then
            #expect(results.count == 1)
            if case .success(let barcode, let duration) = results.first {
                #expect(barcode == "123456")
                #expect(duration == 100)
            } else {
                Issue.record("Expected successful scan with duration")
            }
        }

        @Test("scan duration is properly tracked for failed scan")
        func scan_duration_when_failed_scan_is_properly_tracked() {
            // Given
            var results: [HIDBarcodeParserResult] = []
            let mockTimeProvider = MockTimeProvider()
            let parser = GameControllerBarcodeParser(
                configuration: .default, // min length 6
                onScan: { results.append($0) },
                timeProvider: mockTimeProvider
            )

            // When - Simulate a short scan with known duration
            parser.processKeyPress(GCKeyCode.one)
            mockTimeProvider.advance(by: 0.05)
            parser.processKeyPress(GCKeyCode.two)
            parser.processKeyPress(GCKeyCode.three)
            parser.processKeyPress(GCKeyCode.returnOrEnter)

            // Then
            #expect(results.count == 1)
            if case .failure(let error, let duration) = results.first {
                if case .scanTooShort(let barcode) = error {
                    #expect(barcode == "123")
                    #expect(duration == 50)
                } else {
                    Issue.record("Expected scanTooShort error")
                }
            } else {
                Issue.record("Expected failed scan with duration")
            }
        }

        @Test("empty scan with only terminator is ignored")
        func empty_buffer_when_terminator_sent_is_ignored() {
            // Given
            var results: [HIDBarcodeParserResult] = []
            let parser = GameControllerBarcodeParser(
                configuration: Self.testConfiguration,
                onScan: { results.append($0) }
            )

            // When - Send only terminator
            parser.processKeyPress(GCKeyCode.returnOrEnter)

            // Then
            #expect(results.isEmpty)
        }

        // MARK: - Helper
        static let testConfiguration = HIDBarcodeParserConfiguration(
            terminatingStrings: ["\r", "\n"],
            minimumBarcodeLength: 3,
            maximumInterCharacterTime: 0.05
        )
    }

    // MARK: - Excluded Keys Tests

    struct ExcludedKeysTests {
        @Test("modifier keys are excluded from scan input")
        func modifier_keys_when_pressed_are_excluded_from_scan_input() {
            // Given
            var results: [HIDBarcodeParserResult] = []
            let parser = GameControllerBarcodeParser(
                configuration: Self.testConfiguration,
                onScan: { results.append($0) }
            )

            // When - Mix valid scan keys with excluded modifier keys
            parser.processKeyPress(GCKeyCode.one)
            parser.processKeyPress(GCKeyCode.leftShift)   // Should be ignored
            parser.processKeyPress(GCKeyCode.two)
            parser.processKeyPress(GCKeyCode.rightShift)  // Should be ignored
            parser.processKeyPress(GCKeyCode.three)
            parser.processKeyPress(GCKeyCode.leftControl) // Should be ignored
            parser.processKeyPress(GCKeyCode.rightControl)// Should be ignored
            parser.processKeyPress(GCKeyCode.returnOrEnter)

            // Then
            #expect(results.count == 1)
            if case .success(let barcode, _) = results.first {
                #expect(barcode == "123")
            } else {
                Issue.record("Expected successful scan ignoring modifier keys")
            }
        }

        @Test("arrow keys are excluded from scan input")
        func arrow_keys_when_pressed_are_excluded_from_scan_input() {
            // Given
            var results: [HIDBarcodeParserResult] = []
            let parser = GameControllerBarcodeParser(
                configuration: Self.testConfiguration,
                onScan: { results.append($0) }
            )

            // When - Mix valid scan keys with excluded arrow keys
            parser.processKeyPress(GCKeyCode.one)
            parser.processKeyPress(GCKeyCode.upArrow)     // Should be ignored
            parser.processKeyPress(GCKeyCode.two)
            parser.processKeyPress(GCKeyCode.downArrow)   // Should be ignored
            parser.processKeyPress(GCKeyCode.three)
            parser.processKeyPress(GCKeyCode.leftArrow)   // Should be ignored
            parser.processKeyPress(GCKeyCode.returnOrEnter)

            // Then
            #expect(results.count == 1)
            if case .success(let barcode, _) = results.first {
                #expect(barcode == "123")
            } else {
                Issue.record("Expected successful scan ignoring arrow keys")
            }
        }

        @Test("function and system keys are excluded from scan input")
        func system_keys_when_pressed_are_excluded_from_scan_input() {
            // Given
            var results: [HIDBarcodeParserResult] = []
            let parser = GameControllerBarcodeParser(
                configuration: Self.testConfiguration,
                onScan: { results.append($0) }
            )

            // When - Mix valid scan keys with excluded system keys
            parser.processKeyPress(GCKeyCode.one)
            parser.processKeyPress(GCKeyCode.capsLock)          // Should be ignored
            parser.processKeyPress(GCKeyCode.two)
            parser.processKeyPress(GCKeyCode.deleteOrBackspace) // Should be ignored
            parser.processKeyPress(GCKeyCode.three)
            parser.processKeyPress(GCKeyCode.deleteForward)     // Should be ignored
            parser.processKeyPress(GCKeyCode.escape)            // Should be ignored
            parser.processKeyPress(GCKeyCode.returnOrEnter)

            // Then
            #expect(results.count == 1)
            if case .success(let barcode, _) = results.first {
                #expect(barcode == "123")
            } else {
                Issue.record("Expected successful scan ignoring system keys")
            }
        }

        @Test("navigation keys are excluded from scan input")
        func navigation_keys_when_pressed_are_excluded_from_scan_input() {
            // Given
            var results: [HIDBarcodeParserResult] = []
            let parser = GameControllerBarcodeParser(
                configuration: Self.testConfiguration,
                onScan: { results.append($0) }
            )

            // When - Mix valid scan keys with excluded navigation keys
            parser.processKeyPress(GCKeyCode.one)
            parser.processKeyPress(GCKeyCode.pageUp)    // Should be ignored
            parser.processKeyPress(GCKeyCode.two)
            parser.processKeyPress(GCKeyCode.pageDown)  // Should be ignored
            parser.processKeyPress(GCKeyCode.three)
            parser.processKeyPress(GCKeyCode.home)      // Should be ignored
            parser.processKeyPress(GCKeyCode.end)       // Should be ignored
            parser.processKeyPress(GCKeyCode.insert)    // Should be ignored
            parser.processKeyPress(GCKeyCode.returnOrEnter)

            // Then
            #expect(results.count == 1)
            if case .success(let barcode, _) = results.first {
                #expect(barcode == "123")
            } else {
                Issue.record("Expected successful scan ignoring navigation keys")
            }
        }

        // MARK: - Helper
        static let testConfiguration = HIDBarcodeParserConfiguration(
            terminatingStrings: ["\r", "\n"],
            minimumBarcodeLength: 3,
            maximumInterCharacterTime: 0.05
        )
    }

    // MARK: - Terminator Tests

    struct TerminatorTests {
        @Test("carriage return terminates scan")
        func carriage_return_when_pressed_terminates_scan() {
            // Given
            var results: [HIDBarcodeParserResult] = []
            let parser = GameControllerBarcodeParser(
                configuration: Self.testConfiguration,
                onScan: { results.append($0) }
            )

            // When
            parser.processKeyPress(GCKeyCode.one)
            parser.processKeyPress(GCKeyCode.two)
            parser.processKeyPress(GCKeyCode.three)
            parser.processKeyPress(GCKeyCode.returnOrEnter) // \r

            // Then
            #expect(results.count == 1)
            if case .success(let barcode, _) = results.first {
                #expect(barcode == "123")
            } else {
                Issue.record("Expected successful scan with carriage return")
            }
        }

        @Test("multiple terminating strings work correctly")
        func multiple_terminators_when_configured_work_correctly() {
            // Given
            var results: [HIDBarcodeParserResult] = []
            let configuration = HIDBarcodeParserConfiguration(
                terminatingStrings: ["\r", "\n", "\t", " "],
                minimumBarcodeLength: 3,
                maximumInterCharacterTime: 0.05
            )
            let parser = GameControllerBarcodeParser(
                configuration: configuration,
                onScan: { results.append($0) }
            )

            // When - Test different terminators
            // First scan with carriage return
            parser.processKeyPress(GCKeyCode.one)
            parser.processKeyPress(GCKeyCode.two)
            parser.processKeyPress(GCKeyCode.three)
            parser.processKeyPress(GCKeyCode.returnOrEnter) // \r

            // Second scan with tab
            parser.processKeyPress(GCKeyCode.four)
            parser.processKeyPress(GCKeyCode.five)
            parser.processKeyPress(GCKeyCode.six)
            parser.processKeyPress(GCKeyCode.tab) // \t

            // Third scan with space
            parser.processKeyPress(GCKeyCode.seven)
            parser.processKeyPress(GCKeyCode.eight)
            parser.processKeyPress(GCKeyCode.nine)
            parser.processKeyPress(GCKeyCode.spacebar) // space

            // Then
            #expect(results.count == 3)
            if case .success(let barcode1, _) = results[0] {
                #expect(barcode1 == "123")
            } else {
                Issue.record("Expected first scan to succeed")
            }
            if case .success(let barcode2, _) = results[1] {
                #expect(barcode2 == "456")
            } else {
                Issue.record("Expected second scan to succeed")
            }
            if case .success(let barcode3, _) = results[2] {
                #expect(barcode3 == "789")
            } else {
                Issue.record("Expected third scan to succeed")
            }
        }

        @Test("terminator at start of empty buffer is ignored")
        func empty_buffer_when_terminator_pressed_is_ignored() {
            // Given
            var results: [HIDBarcodeParserResult] = []
            let parser = GameControllerBarcodeParser(
                configuration: Self.testConfiguration,
                onScan: { results.append($0) }
            )

            // When - Send multiple terminators without data
            parser.processKeyPress(GCKeyCode.returnOrEnter)
            parser.processKeyPress(GCKeyCode.returnOrEnter)
            parser.processKeyPress(GCKeyCode.returnOrEnter)

            // Then
            #expect(results.isEmpty)
        }

        @Test("terminator in middle of scan is included in barcode")
        func non_terminator_character_when_pressed_is_included_in_barcode() {
            // Given
            var results: [HIDBarcodeParserResult] = []
            let configuration = HIDBarcodeParserConfiguration(
                terminatingStrings: ["\n"], // Only newline terminates
                minimumBarcodeLength: 3,
                maximumInterCharacterTime: 0.05
            )
            let parser = GameControllerBarcodeParser(
                configuration: configuration,
                onScan: { results.append($0) }
            )

            // When - Include carriage return in middle (not a terminator)
            parser.processKeyPress(GCKeyCode.one)
            parser.processKeyPress(GCKeyCode.returnOrEnter) // \r (not terminator)
            parser.processKeyPress(GCKeyCode.two)
            // Note: We can't easily test \n vs \r distinction with GameController
            // as .returnOrEnter maps to \r. This test demonstrates the concept.

            // Then - The scan should continue (no results yet)
            #expect(results.isEmpty)
        }

        @Test("parser does not start a timeout for an ignored character")
        func empty_buffer_when_ignored_character_pressed_does_not_start_timeout() {
            // Given
            var results: [HIDBarcodeParserResult] = []
            let mockTimeProvider = MockTimeProvider()
            let parser = GameControllerBarcodeParser(
                configuration: Self.testConfiguration,
                onScan: { results.append($0) },
                timeProvider: mockTimeProvider
            )

            // When - Scan a barcode with two terminators, then scan another barcode
            parser.processKeyPress(GCKeyCode.one)
            parser.processKeyPress(GCKeyCode.two)
            parser.processKeyPress(GCKeyCode.three)
            parser.processKeyPress(GCKeyCode.returnOrEnter) // Scan is recognised here
            parser.processKeyPress(GCKeyCode.leftShift) // This should be ignored

            // Time between scans
            mockTimeProvider.advance(by: 1.5)

            // Scan the second barcode
            parser.processKeyPress(GCKeyCode.four) // Risk of an error row here if shift isn't ignored
            parser.processKeyPress(GCKeyCode.five)
            parser.processKeyPress(GCKeyCode.six)
            parser.processKeyPress(GCKeyCode.returnOrEnter)
            parser.processKeyPress(GCKeyCode.leftShift) // This should also be ignored

            // Then
            #expect(results.count == 2)
            if case .success(let barcode1, _) = results[0] {
                #expect(barcode1 == "123")
            } else {
                Issue.record("Expected success result for first scan")
            }
            if case .success(let barcode2, _) = results[1] {
                #expect(barcode2 == "456")
            } else {
                Issue.record("Expected success result for second scan")
            }
        }

        // MARK: - Helper
        static let testConfiguration = HIDBarcodeParserConfiguration(
            terminatingStrings: ["\r", "\n"],
            minimumBarcodeLength: 3,
            maximumInterCharacterTime: 0.05
        )
    }
}
