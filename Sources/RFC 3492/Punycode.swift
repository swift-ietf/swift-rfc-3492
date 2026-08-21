public enum Punycode {
}

extension Punycode {

    private static let base: UInt32 = 36
    private static let tmin: UInt32 = 1
    private static let tmax: UInt32 = 26
    private static let skew: UInt32 = 38
    private static let damp: UInt32 = 700
    private static let initialBias: UInt32 = 72
    private static let initialN: UInt32 = 128
    private static let delimiter: Character = "-"
}

extension Punycode {

    public static func encode(_ input: String) -> String {
        var output = ""
        let scalars = Array(input.unicodeScalars)

        let basicScalars = scalars.filter { $0.value < 0x80 }
        output += String(String.UnicodeScalarView(basicScalars))

        let basicLength = basicScalars.count
        var handledCount = basicLength

        if handledCount > 0 && handledCount < scalars.count {
            output.append(delimiter)
        }

        if handledCount == scalars.count {
            return output
        }

        var n = initialN
        var delta: UInt32 = 0
        var bias = initialBias

        while handledCount < scalars.count {

            var minScalar = UInt32.max
            for scalar in scalars {
                if scalar.value >= n && scalar.value < minScalar {
                    minScalar = scalar.value
                }
            }

            delta += (minScalar - n) * UInt32(handledCount + 1)
            n = minScalar

            for scalar in scalars {
                if scalar.value < n {
                    delta += 1
                } else if scalar.value == n {

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

    public static func decode(_ input: String) throws(Error) -> String {

        if input.isEmpty {
            return input
        }

        var output: [Unicode.Scalar] = []

        if let delimiterIndex = input.lastIndex(of: delimiter) {

            let basicPart = input[..<delimiterIndex]
            for char in basicPart {
                guard let scalar = Unicode.Scalar(String(char)) else {
                    throw Error.badInput
                }
                output.append(scalar)
            }
        }

        let nonBasicStart =
            input.lastIndex(of: delimiter)?.utf16Offset(in: input).advanced(by: 1) ?? 0
        let nonBasicPart = String(input.dropFirst(nonBasicStart))

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

            guard let scalar = Unicode.Scalar(n) else {
                throw Error.badInput
            }
            output.insert(scalar, at: Int(i))
            i += 1
        }

        return String(String.UnicodeScalarView(output))
    }
}

extension Punycode {

    private static func threshold(k: UInt32, bias: UInt32) -> UInt32 {
        if k <= bias + tmin {
            return tmin
        } else if k >= bias + tmax {
            return tmax
        } else {
            return k - bias
        }
    }

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

    private static func digitToChar(_ digit: UInt32) -> Character {

        if digit < 26 {
            return Character(UnicodeScalar(UInt8(digit) + UInt8(ascii: "a")))
        } else {
            return Character(UnicodeScalar(UInt8(digit - 26) + UInt8(ascii: "0")))
        }
    }

    private static func charToDigit(_ char: Character) throws(Error) -> UInt32 {
        guard let ascii = char.asciiValue else {
            throw Error.badInput
        }

        if ascii >= 0x41 && ascii <= 0x5A {
            return UInt32(ascii - 0x41)
        } else if ascii >= 0x61 && ascii <= 0x7A {
            return UInt32(ascii - 0x61)
        } else if ascii >= 0x30 && ascii <= 0x39 {
            return UInt32(ascii - 0x30) + 26
        } else {
            throw Error.badInput
        }
    }
}
