extension Punycode {

    public enum Error: Swift.Error, Equatable {
        case overflow
        case badInput
        case invalidEncoding
    }
}
