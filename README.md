# swift-rfc-3492

Use this package when you need the Punycode algorithm itself, to turn one Unicode string into ASCII and back. Start from `Punycode.encode(_:)` and `Punycode.decode(_:)`. To convert whole domain names label by label, with the xn-- prefix, use swift-rfc-5890.

## Laws

- Encoding and decoding work on Unicode scalars, with no normalization or case folding, and never add or strip the xn-- prefix.
- Encoding copies the ASCII scalars first, in order and with their case, then writes `-` if there were any, then the rest as lowercase base-36 digits. An ASCII-only string therefore gains a trailing `-`, so `example` becomes `example-`. The empty string encodes to itself.
- Decoding takes everything before the last `-` as the ASCII part. A non-ASCII character there, a character that is not a letter or digit after it, and input that ends in the middle of a number are refused.
- A number too large for 32 bits is refused as an overflow rather than crashing.
