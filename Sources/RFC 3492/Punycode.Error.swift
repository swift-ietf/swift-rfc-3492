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

extension Punycode {
    /// Errors that can occur during Punycode encoding/decoding
    public enum Error: Swift.Error, Equatable {
        case overflow
        case badInput
        case invalidEncoding
    }
}
