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

public import Byte_Primitives
import Cardinal_Primitives_Standard_Library_Integration
public import Index_Primitives
public import Span_Protocol_Primitives

/// Immutable singleton sentinel for empty raw spans.
///
/// ## Invariants
///
/// - Allocated once at startup, never deallocated
/// - Page-aligned (4096 bytes) to maintain prior address invariant
/// - Provenance-correct: backed by real allocation, valid for pointer arithmetic
/// - Must NEVER be dereferenced (valid only as a sentinel address)
/// - Valid for empty spans where count == 0
@usableFromInline
nonisolated(unsafe) let _emptyRawSpanSentinel: UnsafeRawPointer =
    UnsafeRawPointer(UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 4096))

extension __Span {
    /// A Copyable, non-owning raw byte view with a guaranteed non-null start address.
    ///
    /// `Span.Raw` is the namespace-neutral home for the integer-address raw buffer
    /// descriptor formerly spelled `Memory.Buffer` (Cleave-8 item 8): a contiguous
    /// view is a cross-cutting Span capability, not a Memory core concern (placement
    /// calculus §1.3). Unlike `Swift.Span` / `Swift.RawSpan` (both `~Escapable`),
    /// `Span.Raw` is **Copyable, storable, and `Sendable`**, so it can be held in a
    /// stored property or crossed through a `@Sendable` closure — while still vending
    /// a `Swift.Span<Byte>` via ``Span/Protocol``.
    ///
    /// ## Invariants
    ///
    /// - `start` is always non-null (even for empty spans)
    /// - Memory is only valid to access within `0..<count`
    /// - For empty spans, `start` points to a sentinel; do not dereference
    ///
    /// ## Mutable Variant
    ///
    /// For read-write access, use ``Span/Raw/Mutable``.
    @safe
    // WHY: Category D — structural Sendable workaround (SP-5, inherited from Memory.Buffer).
    // WHY: `Span.Raw` is a Copyable descriptor struct (NOT ~Copyable). Stored fields are a
    // WHY: raw `UnsafeRawPointer` and a typed `Index<Byte>.Count` — both let, both pure value
    // WHY: bytes. No mutex, no deinit, no ownership invariant. It does NOT own the region it
    // WHY: describes; the caller manages the allocation separately.
    // WHEN TO REMOVE: when the compiler gains structural Sendable inference for raw-pointer
    // WHEN TO REMOVE: descriptor structs.
    public struct Raw: Hashable, @unchecked Sendable {

        // MARK: - Stored Properties

        /// Non-null start address.
        ///
        /// For empty spans, points to sentinel.
        @usableFromInline
        internal let _start: UnsafeRawPointer

        /// Byte count.
        @usableFromInline
        internal let _count: Index<Byte>.Count

        // MARK: - Initialization

        /// Creates a raw span from a start address and byte count.
        @inlinable
        public init(start: UnsafeRawPointer, count: Index<Byte>.Count) {
            unsafe self._start = start
            self._count = count
        }

        /// Creates an empty raw span.
        @inlinable
        public init() {
            unsafe self._start = _emptyRawSpanSentinel
            self._count = .zero
        }

        /// Creates a raw span from an `UnsafeRawBufferPointer`.
        ///
        /// If the source buffer is empty (nil baseAddress), uses the sentinel.
        @inlinable
        public init(_ buffer: UnsafeRawBufferPointer) {
            if let baseAddress = buffer.baseAddress {
                unsafe self._start = baseAddress
            } else {
                unsafe self._start = _emptyRawSpanSentinel
            }
            self._count = Index<Byte>.Count(UInt(buffer.count))
        }
    }
}

// MARK: - Properties

extension Span.Raw {
    /// The number of bytes in the span.
    @inlinable
    public var count: Index<Byte>.Count { _count }

    /// A Boolean value indicating whether the span is empty.
    @inlinable
    public var isEmpty: Bool { _count == .zero }
}

// MARK: - Span.Protocol Conformance

extension Span.Raw: Span.`Protocol` {
    /// The element type vended through the span.
    public typealias Element = Byte

    /// A read-only contiguous view of the bytes, borrowing `self`.
    @inlinable
    public var span: Swift.Span<Byte> {
        @_lifetime(borrow self)
        borrowing get {
            let typed = unsafe _start.assumingMemoryBound(to: Byte.self)
            return unsafe Swift.Span(_unsafeStart: typed, count: _count)
        }
    }
}

// MARK: - Type Reinterpretation

extension Span.Raw {
    /// Executes a closure with the span's memory temporarily bound to a typed buffer.
    @inlinable
    public func withRebound<T, Result, E: Swift.Error>(
        to type: T.Type,
        _ body: (UnsafeBufferPointer<T>) throws(E) -> Result
    ) throws(E) -> Result {
        try unsafe base.nullable.withMemoryRebound(to: type) { typedBuffer throws(E) in
            try unsafe body(typedBuffer)
        }
    }
}

// MARK: - CustomStringConvertible

extension Span.Raw: CustomStringConvertible {
    /// A textual representation of the span's start address and byte count.
    public var description: String {
        let address = unsafe UInt(bitPattern: _start)
        return "Span.Raw(start: 0x\(String(address, radix: 16)), count: \(Int(bitPattern: _count)))"
    }
}

// MARK: - CustomDebugStringConvertible

extension Span.Raw: CustomDebugStringConvertible {
    /// A textual representation of the span suitable for debugging.
    public var debugDescription: String {
        let address = unsafe UInt(bitPattern: _start)
        return "Span.Raw(start: 0x\(String(address, radix: 16)), count: \(Int(bitPattern: _count)))"
    }
}

// MARK: - Equatable

extension Span.Raw {
    /// Returns whether two spans share the same start address and byte count.
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        unsafe lhs._start == rhs._start && lhs._count == rhs._count
    }
}

// MARK: - Hashable

extension Span.Raw {
    /// Hashes the span's start address and byte count.
    @inlinable
    public func hash(into hasher: inout Hasher) {
        unsafe hasher.combine(_start)
        hasher.combine(_count)
    }
}
