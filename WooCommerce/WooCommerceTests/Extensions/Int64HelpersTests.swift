import Testing
@testable import WooCommerce

struct Int64HelpersTests {

    @Test func test_englishByteCountRepresentable_when_below_one_KB_then_renders_bytes() {
        #expect(Int64(0).englishByteCountRepresentable == "0.00 bytes")
        #expect(Int64(1023).englishByteCountRepresentable == "1023.00 bytes")
    }

    @Test func test_englishByteCountRepresentable_when_exactly_1024_then_renders_one_KB() {
        #expect(Int64(1024).englishByteCountRepresentable == "1.00 KB")
    }

    @Test func test_englishByteCountRepresentable_when_between_units_then_renders_fraction() {
        #expect(Int64(1536).englishByteCountRepresentable == "1.50 KB")
    }

    @Test func test_englishByteCountRepresentable_when_gigabytes_then_renders_GB() {
        // 12.4 GB, the doc comment's example.
        #expect(Int64(13314398618).englishByteCountRepresentable == "12.40 GB")
    }

    @Test func test_englishByteCountRepresentable_when_Int64_max_then_renders_EB_without_overrunning_units() {
        #expect(Int64.max.englishByteCountRepresentable == "8.00 EB")
    }
}
