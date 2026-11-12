extension Punycode {

    public enum Error: Swift::Error, Equatable {
        case overflow
        case badInput
        case invalidEncoding
    }
}

extension Punycode.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .overflow: "Punycode value overflow"
        case .badInput: "Punycode input is not valid"
        case .invalidEncoding: "Punycode encoding is not valid"
        }
    }
}
