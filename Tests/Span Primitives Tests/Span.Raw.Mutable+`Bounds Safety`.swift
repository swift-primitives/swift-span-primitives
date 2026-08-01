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

import Byte_Primitives
import Byte_Protocol_Primitives
import Index_Primitives
import Span_Primitives_Test_Support
import Testing

// Regression coverage for fable-448 F-001 (blocker): Span.Raw.Mutable's safe APIs
// (`mutableSpan(count:)`, both `copy(from:)` overloads) did not enforce the
// documented `0..<count` invariant. `mutableSpan(count:)` vended a
// `Swift.MutableSpan<Byte>` over an arbitrary caller-supplied `count`, regardless
// of the descriptor's own `_count`, so any `count` larger than the described
// region produced an out-of-bounds mutable view with no check at all, in any
// build configuration. `copy(from:)` delegated straight to
// `UnsafeMutableRawBufferPointer.copyMemory(from:)`, whose own bounds check is a
// `_debugPrecondition` — compiled out under `-O`/`-c release` — so a release
// build silently copied an oversized source straight past the destination's
// allocation. The fix adds an explicit, always-on `precondition` to all three
// APIs and respells `copy(from:)` as `mutating`.
//
// Deviation from [INST-TEST-013]'s default shape (see REPORT.md (f)): the
// extension target below is spelled `__Span.Raw.Mutable`, the hidden backing
// namespace, not the public `Span.Raw.Mutable` alias spelling. `Span` is an
// UNBOUND `typealias Span = Swift.Span` (see `Sources/Span Primitive/Span.swift`
// / `__Span.swift`), and `Span.Raw.Mutable` only resolves through a
// non-generic-dependent member typealias on `Swift.Span`. That resolves fine
// as a type annotation (`let x: Span.Raw.Mutable = ...`, used throughout the
// bodies below), but the `@Test`/`@Suite` macros must additionally emit a bare
// `<EnclosingType>.self` metatype expression to register each suite/test, and
// the general expression-level constraint solver cannot infer `Swift.Span`'s
// `Element` from a context-free `.self` — confirmed with a direct
// `swift build --build-tests` probe: `extension Span.Raw.Mutable { @Suite
// struct X { ... } }` fails every generated test/suite registration site with
// "generic parameter 'Element' could not be inferred". `__Span.Raw.Mutable` is
// the literal, non-generic, concretely-declared type `Span.Raw.Mutable` is an
// alias for (`Sources/Span Raw Primitives/Span.Raw.Mutable.swift` declares
// `Mutable` inside `extension Span.Raw` there, which is itself `__Span.Raw`) —
// same nominal type, sound per [INST-TEST-013]'s carve-out for "an extension of
// a non-generic parent / `@_exported` namespace".
extension __Span.Raw.Mutable {
    // `.serialized`: several `Edge Case` tests below are Swift Testing exit tests,
    // which fork the process. Forking while sibling tests run concurrently on
    // Swift Testing's thread pool is a documented hazard (a lock held by another
    // thread at fork time never releases in the child); observed directly here as
    // an intermittent SIGBUS crash of the whole test runner when this suite's
    // tests were allowed to interleave with each other. Serializing this suite
    // avoids the race; it does not change what any individual test asserts.
    @Suite(.serialized) struct `Bounds Safety` {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
    }
}

// MARK: - Unit

extension __Span.Raw.Mutable.`Bounds Safety`.Unit {
    @Test
    func `mutableSpan(count:) at exactly the span's own count vends a fully usable span`() {
        let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 4, alignment: 1)
        defer { unsafe buffer.deallocate() }
        var raw: Span.Raw.Mutable = unsafe .init(buffer)
        var span = raw.mutableSpan(count: raw.count)
        #expect(span.count == 4)
        let first = span[0]
        let last = span[3]
        span[0] = last
        span[3] = first
        #expect(span[0] == last)
        #expect(span[3] == first)
    }

    @Test
    func `copy(from Span.Raw) with an exactly-sized source copies every byte`() {
        let dstBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 4, alignment: 1)
        defer { unsafe dstBuffer.deallocate() }
        var dst: Span.Raw.Mutable = unsafe .init(dstBuffer)

        let srcBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 4, alignment: 1)
        defer { unsafe srcBuffer.deallocate() }
        (0..<4).forEach { i in unsafe srcBuffer[i] = UInt8(i + 1) }
        let src: Span.Raw = unsafe .init(UnsafeRawBufferPointer(srcBuffer))

        dst.copy(from: src)
        #expect(unsafe Array(dstBuffer) == [1, 2, 3, 4])
    }

    @Test
    func `copy(from UnsafeRawBufferPointer) with a smaller source only overwrites the leading bytes`() {
        let dstBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 4, alignment: 1)
        defer { unsafe dstBuffer.deallocate() }
        (0..<4).forEach { i in unsafe dstBuffer[i] = 0xff }
        var dst: Span.Raw.Mutable = unsafe .init(dstBuffer)

        let srcBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 2, alignment: 1)
        defer { unsafe srcBuffer.deallocate() }
        unsafe srcBuffer[0] = 0x01
        unsafe srcBuffer[1] = 0x02

        unsafe dst.copy(from: UnsafeRawBufferPointer(srcBuffer))
        #expect(unsafe Array(dstBuffer) == [0x01, 0x02, 0xff, 0xff])
    }
}

// MARK: - Edge Case

extension __Span.Raw.Mutable.`Bounds Safety`.`Edge Case` {
    /// fable-448 F-001.
    ///
    /// Pre-fix, `mutableSpan(count:)` had no bounds check
    /// anywhere (not even in debug) — it vended a `MutableSpan` over a
    /// caller-supplied `count` regardless of the descriptor's real `_count`.
    /// This is the one part of F-001 whose regression is directly observable
    /// under `swift test`'s default debug configuration; see REPORT.md (d)/(g)
    /// for the release-only evidence covering the two `copy(from:)` overloads
    /// below.
    @Test
    func `mutableSpan(count:) traps when count exceeds the span's byte capacity`() async {
        await #expect(processExitsWith: .failure) {
            let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 4, alignment: 1)
            defer { unsafe buffer.deallocate() }
            var raw: Span.Raw.Mutable = unsafe .init(buffer)
            _ = raw.mutableSpan(count: Index<Byte>.Count(UInt(8)))
        }
    }

    /// fable-448 F-001: the bounds check built into
    /// `UnsafeMutableRawBufferPointer.copyMemory(from:)` is a
    /// `_debugPrecondition`, so under the default debug configuration of
    /// `swift test` this scenario already traps via that stdlib guard —
    /// both pre-fix and post-fix — and cannot distinguish the two on its own.
    ///
    /// The real fable-448 defect (a silent release-mode overrun) only manifests
    /// once that debug-only guard is compiled out; this test asserts the fix's
    /// own always-on `precondition` covers it under `-c release`. See
    /// REPORT.md (d) for the explicit `swift test -c release` red/green
    /// capture.
    @Test
    func `copy(from Span.Raw) traps under release when source has more bytes than the destination can hold`() async {
        guard !_isDebugAssertConfiguration() else { return }
        await #expect(processExitsWith: .failure) {
            let dstBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 4, alignment: 1)
            defer { unsafe dstBuffer.deallocate() }
            var dst: Span.Raw.Mutable = unsafe .init(dstBuffer)

            let srcBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 16, alignment: 1)
            defer { unsafe srcBuffer.deallocate() }
            let src: Span.Raw = unsafe .init(UnsafeRawBufferPointer(srcBuffer))

            dst.copy(from: src)
        }
    }

    /// fable-448 F-001: same release-only reasoning as the `Span.Raw` overload
    /// above, for the `UnsafeRawBufferPointer` overload.
    @Test
    func `copy(from UnsafeRawBufferPointer) traps under release when source has more bytes than the destination can hold`() async {
        guard !_isDebugAssertConfiguration() else { return }
        await #expect(processExitsWith: .failure) {
            let dstBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 4, alignment: 1)
            defer { unsafe dstBuffer.deallocate() }
            var dst: Span.Raw.Mutable = unsafe .init(dstBuffer)

            let srcBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 16, alignment: 1)
            defer { unsafe srcBuffer.deallocate() }

            unsafe dst.copy(from: UnsafeRawBufferPointer(srcBuffer))
        }
    }
}
