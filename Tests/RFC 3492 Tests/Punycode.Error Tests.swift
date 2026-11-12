import RFC_3492
import Testing

enum `Punycode.Error Tests` {}

extension `Punycode.Error Tests` {
    @Suite struct `Errors describe themselves` {}
}

extension `Punycode.Error Tests`.`Errors describe themselves` {
    @Test
    func `each error has its own description`() {
        let descriptions = [Punycode.Error.overflow, .badInput, .invalidEncoding].map { $0.description }
        #expect(Set(descriptions).count == 3)
        #expect(Punycode.Error.overflow.description == "Punycode value overflow")
    }
}
