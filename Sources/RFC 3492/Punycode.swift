// ===----------------------------------------------------------------------===//
//
// Copyright (c) 2025 Coen ten Thije Boonkkamp
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of project contributors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

/// Punycode encoding per RFC 3492
///
/// Punycode is a Bootstring encoding that uniquely and reversibly transforms
/// a Unicode string into an ASCII string. It is used by IDNA to encode
/// internationalized domain names.
///
/// ## Reference
///
/// RFC 3492: Punycode: A Bootstring encoding of Unicode for Internationalized Domain Names in Applications (IDNA)
/// https://datatracker.ietf.org/doc/html/rfc3492
///
/// ## Example
///
/// ```swift
/// // Encode Unicode domain label to Punycode
/// let encoded = try Punycode.encode("münchen")
/// // Result: "mnchen-3ya"
///
/// // Decode Punycode back to Unicode
/// let decoded = try Punycode.decode("mnchen-3ya")
/// // Result: "münchen"
/// ```
public enum Punycode {
}

extension Punycode {
    /// Punycode parameters per RFC 3492 Section 5
    private static let base: UInt32 = 36
    private static let tmin: UInt32 = 1
    private static let tmax: UInt32 = 26
    private static let skew: UInt32 = 38
    private static let damp: UInt32 = 700
    private static let initialBias: UInt32 = 72
    private static let initialN: UInt32 = 128  // 0x80
    private static let delimiter: Character = "-"
}

extension Punycode {
    /// Errors that can occur during Punycode encoding/decoding
    public enum Error: Swift.Error, Equatable {
        case overflow
        case badInput
        case invalidEncoding
    }
}

extension Punycode {
    /// Encodes a Unicode string to Punycode
    ///
    /// - Parameter input: Unicode string to encode
    /// - Returns: Punycode-encoded ASCII string
    /// - Throws: `Punycode.Error` if encoding fails
    public static func encode(_ input: String) -> String {
        var output = ""
        let scalars = Array(input.unicodeScalars)

        // Extract and copy all basic code points (ASCII)
        let basicScalars = scalars.filter { $0.value < 0x80 }
        output += String(String.UnicodeScalarView(basicScalars))

        let basicLength = basicScalars.count
        var handledCount = basicLength

        // If we have basic characters, add delimiter
        if handledCount > 0 && handledCount < scalars.count {
            output.append(delimiter)
        }

        // Nothing more to do if all ASCII
        if handledCount == scalars.count {
            return output
        }

        // Encode non-ASCII characters
        var n = initialN
        var delta: UInt32 = 0
        var bias = initialBias

        while handledCount < scalars.count {
            // Find the next code point to encode
            var minScalar = UInt32.max
            for scalar in scalars {
                if scalar.value >= n && scalar.value < minScalar {
                    minScalar = scalar.value
                }
            }

            // Calculate delta
            delta += (minScalar - n) * UInt32(handledCount + 1)
            n = minScalar

            // Process each scalar
            for scalar in scalars {
                if scalar.value < n {
                    delta += 1
                } else if scalar.value == n {
                    // Encode delta
                    var q = delta
                    var k = base

                    while true {
                        let t = threshold(k: k, bias: bias)
                        if q < t {
                            break
                        }

                        let digit = t + ((q - t) % (base - t))
                        output.append(digitToChar(digit))

                        q = (q - t) / (base - t)
                        k += base
                    }

                    output.append(digitToChar(q))
                    bias = adapt(
                        delta: delta,
                        numPoints: UInt32(handledCount + 1),
                        firstTime: handledCount == basicLength
                    )
                    delta = 0
                    handledCount += 1
                }
            }

            delta += 1
            n += 1
        }

        return output
    }

    /// Decodes a Punycode string to Unicode
    ///
    /// - Parameter input: Punycode-encoded ASCII string
    /// - Returns: Decoded Unicode string
    /// - Throws: `Punycode.Error` if decoding fails
    public static func decode(_ input: String) throws(Error) -> String {
        // Handle empty input
        if input.isEmpty {
            return input
        }

        var output: [Unicode.Scalar] = []

        // Find the last delimiter
        if let delimiterIndex = input.lastIndex(of: delimiter) {
            // Copy everything before the delimiter as basic code points
            let basicPart = input[..<delimiterIndex]
            for char in basicPart {
                guard let scalar = Unicode.Scalar(String(char)) else {
                    throw Error.badInput
                }
                output.append(scalar)
            }
        }

        // Decode the non-basic part
        let nonBasicStart =
            input.lastIndex(of: delimiter)?.utf16Offset(in: input).advanced(by: 1) ?? 0
        let nonBasicPart = String(input.dropFirst(nonBasicStart))

        // If non-basic part is empty, return what we have
        if nonBasicPart.isEmpty {
            return String(String.UnicodeScalarView(output))
        }

        var n = initialN
        var i: UInt32 = 0
        var bias = initialBias
        var pos = 0

        while pos < nonBasicPart.count {
            let oldi = i
            var w: UInt32 = 1
            var k = base

            while pos < nonBasicPart.count {
                let char = nonBasicPart[nonBasicPart.index(nonBasicPart.startIndex, offsetBy: pos)]
                pos += 1

                let digit = try charToDigit(char)
                i += digit * w

                let t = threshold(k: k, bias: bias)
                if digit < t {
                    break
                }

                w *= (base - t)
                k += base
            }

            bias = adapt(delta: i - oldi, numPoints: UInt32(output.count + 1), firstTime: oldi == 0)
            n += i / UInt32(output.count + 1)
            i %= UInt32(output.count + 1)

            // Insert n at position i
            guard let scalar = Unicode.Scalar(n) else {
                throw Error.badInput
            }
            output.insert(scalar, at: Int(i))
            i += 1
        }

        return String(String.UnicodeScalarView(output))
    }
}

// MARK: - Helper Functions

extension Punycode {
    /// Calculates the threshold for a given k and bias
    private static func threshold(k: UInt32, bias: UInt32) -> UInt32 {
        if k <= bias + tmin {
            return tmin
        } else if k >= bias + tmax {
            return tmax
        } else {
            return k - bias
        }
    }

    /// Adapts the bias after each delta
    private static func adapt(delta: UInt32, numPoints: UInt32, firstTime: Bool) -> UInt32 {
        var delta = delta
        delta = firstTime ? delta / damp : delta / 2
        delta += delta / numPoints

        var k: UInt32 = 0
        while delta > ((base - tmin) * tmax) / 2 {
            delta /= (base - tmin)
            k += base
        }

        return k + (((base - tmin + 1) * delta) / (delta + skew))
    }

    /// Converts a digit (0-35) to its character representation
    private static func digitToChar(_ digit: UInt32) -> Character {
        // 0-25 => 'a'-'z', 26-35 => '0'-'9'
        if digit < 26 {
            return Character(UnicodeScalar(UInt8(digit) + UInt8(ascii: "a")))
        } else {
            return Character(UnicodeScalar(UInt8(digit - 26) + UInt8(ascii: "0")))
        }
    }

    /// Converts a character to its digit value (0-35)
    private static func charToDigit(_ char: Character) throws(Error) -> UInt32 {
        guard let ascii = char.asciiValue else {
            throw Error.badInput
        }

        // 'a'-'z' or 'A'-'Z' => 0-25
        if ascii >= 0x41 && ascii <= 0x5A {  // A-Z
            return UInt32(ascii - 0x41)
        } else if ascii >= 0x61 && ascii <= 0x7A {  // a-z
            return UInt32(ascii - 0x61)
        } else if ascii >= 0x30 && ascii <= 0x39 {  // 0-9
            return UInt32(ascii - 0x30) + 26
        } else {
            throw Error.badInput
        }
    }
}
