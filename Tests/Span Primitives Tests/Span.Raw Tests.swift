// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

import Span_Primitives_Test_Support
import Testing

// Span.Raw / Span.Raw.Mutable: the Copyable raw byte view relocated from
// Memory.Buffer (Cleave-8 item 8). Conforms Span.Protocol / Span.Mutable.Protocol.
@Suite("Span.Raw Tests")
struct SpanRawTests {

    @Test
    func `wraps a buffer and vends spans via the Span capability`() {
        let n = 16
        let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: n, alignment: 8)
        defer { unsafe buffer.deallocate() }
        let raw: Span.Raw.Mutable = unsafe .init(buffer)
        #expect(!raw.isEmpty)
        let spanCount = raw.span.count
        #expect(spanCount == n)
        let immutableCount = raw.immutable.span.count
        #expect(immutableCount == n)
    }

    @Test
    func `empty raw span is empty with a non-null sentinel`() {
        let raw: Span.Raw = .init()
        #expect(raw.isEmpty)
        let spanEmpty = raw.span.isEmpty
        #expect(spanEmpty)
        #expect(unsafe raw.base.nonNull.baseAddress != nil)
        #expect(unsafe raw.base.nullable.baseAddress == nil)
    }
}
