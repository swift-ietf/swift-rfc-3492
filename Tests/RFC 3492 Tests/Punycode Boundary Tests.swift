import Testing

@testable import RFC_3492

@Suite
struct `Punycode boundaries` {
    @Test
    func `empty input encodes and decodes to empty`() throws {
        #expect(Punycode.encode("") == "")
        #expect(try Punycode.decode("") == "")
    }

    @Test
    func `a delimited all-basic input decodes to its basic part`() throws {
        #expect(try Punycode.decode("abc-") == "abc")
        #expect(try Punycode.decode("ABC-def-") == "ABC-def")
    }

    @Test
    func `a single non-basic code point matches the reference encoder`() throws {
        #expect(Punycode.encode("ü") == "tda")
        #expect(Punycode.encode("aü") == "a-eha")
        #expect(try Punycode.decode("a-eha") == "aü")
    }

    @Test
    func `a character that is not a base-36 digit is rejected`() {
        #expect(throws: Punycode.Error.self) { try Punycode.decode("a-!") }
    }

    @Test
    func `a non-basic code point before the delimiter is rejected`() {
        #expect(throws: Punycode.Error.self) { try Punycode.decode("ü-a") }
    }
}
