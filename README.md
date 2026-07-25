# swift-rfc-3492

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Punycode encoding and decoding of Unicode labels, as specified in RFC 3492.

## Standard Reference

- **RFC**: 3492
- **Title**: Punycode: A Bootstring encoding of Unicode for IDNA

## Installation

Add the package to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/swift-ietf/swift-rfc-3492.git", from: "0.1.2")
]
```

Add the product to a target that needs it:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "RFC 3492", package: "swift-rfc-3492")
    ]
)
```

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
