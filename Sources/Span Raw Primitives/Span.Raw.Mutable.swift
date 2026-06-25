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

extension Span.Raw {
    /// A Copyable, non-owning **mutable** raw byte view with a guaranteed non-null start.
    ///
    /// The read-write peer of ``Span/Raw`` (Cleave-8 item 8; relocated from
    /// `Memory.Buffer.Mutable`). It describes a region the caller owns separately — it
    /// does **not** allocate or free. Conforms ``Span/Mutable/Protocol`` (vends both
    /// `Swift.Span<Byte>` and `Swift.MutableSpan<Byte>`).
    ///
    /// ## Invariants
    ///
    /// - `start` is always non-null (even for empty spans)
    /// - Memory is only valid to access within `0..<count`
    /// - For empty spans, `start` points to a sentinel; do not dereference
    @safe
    // WHY: Category D — structural Sendable workaround (SP-5, inherited from Memory.Buffer.Mutable).
    // WHY: A Copyable descriptor struct (NOT ~Copyable); fields are a raw mutable pointer and a
    // WHY: typed count, both let, both pure value bytes. No mutex, no deinit, no owned allocation.
    // WHEN TO REMOVE: when the compiler gains structural Sendable inference for raw-pointer descriptors.
    public struct Mutable: Hashable, @unchecked Sendable {

        // MARK: - Stored Properties

        /// Non-null start address.
        ///
        /// For empty spans, points to sentinel.
        @usableFromInline
        internal let _start: UnsafeMutableRawPointer

        /// Byte count.
        @usableFromInline
        internal let _count: Index<Byte>.Count

        // MARK: - Initialization

        /// Creates a mutable raw span from a start address and byte count.
        @inlinable
        public init(start: UnsafeMutableRawPointer, count: Index<Byte>.Count) {
            unsafe self._start = start
            self._count = count
        }

        /// Creates an empty mutable raw span.
        @inlinable
        public init() {
            unsafe self._start = _emptyMutableRawSpanSentinel
            self._count = .zero
        }

        /// Creates a mutable raw span from an `UnsafeMutableRawBufferPointer`.
        ///
        /// If the source buffer is empty (nil baseAddress), uses the sentinel.
        @inlinable
        public init(_ buffer: UnsafeMutableRawBufferPointer) {
            if let baseAddress = buffer.baseAddress {
                unsafe self._start = baseAddress
            } else {
                unsafe self._start = _emptyMutableRawSpanSentinel
            }
            self._count = Index<Byte>.Count(UInt(buffer.count))
        }
    }
}

/// Mutable singleton sentinel for empty mutable raw spans.
///
/// See ``_emptyRawSpanSentinel`` for invariants.
@usableFromInline
nonisolated(unsafe) let _emptyMutableRawSpanSentinel: UnsafeMutableRawPointer =
    UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 4096)

// MARK: - Properties

extension Span.Raw.Mutable {
    /// The number of bytes in the span.
    @inlinable
    public var count: Index<Byte>.Count { _count }

    /// A Boolean value indicating whether the span is empty.
    @inlinable
    public var isEmpty: Bool { _count == .zero }
}

// MARK: - Span.Mutable.Protocol Conformance

extension Span.Raw.Mutable: Span.Mutable.`Protocol` {
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

    /// A mutable contiguous view of the bytes, exclusively borrowing `self`.
    @inlinable
    public var mutableSpan: Swift.MutableSpan<Byte> {
        @_lifetime(&self)
        mutating get {
            let typed = unsafe _start.assumingMemoryBound(to: Byte.self)
            return unsafe Swift.MutableSpan(_unsafeStart: typed, count: _count)
        }
    }

    /// A mutable span over the first `count` bytes.
    @inlinable
    @_lifetime(&self)
    public mutating func mutableSpan(count: Index<Byte>.Count) -> Swift.MutableSpan<Byte> {
        let typed = unsafe _start.assumingMemoryBound(to: Byte.self)
        return unsafe Swift.MutableSpan(_unsafeStart: typed, count: count)
    }
}

// MARK: - Copy Operations

extension Span.Raw.Mutable {
    /// Copies bytes from a source raw span.
    @inlinable
    public func copy(from source: Span.Raw) {
        unsafe base.nullable.copyMemory(from: source.base.nullable)
    }

    /// Copies bytes from a raw buffer pointer.
    @inlinable
    public func copy(from source: UnsafeRawBufferPointer) {
        unsafe base.nullable.copyMemory(from: source)
    }
}

// MARK: - Type Reinterpretation

extension Span.Raw.Mutable {
    /// Executes a closure with the span's memory temporarily bound to a typed mutable buffer.
    @inlinable
    public func withRebound<T, Result, E: Swift.Error>(
        to type: T.Type,
        _ body: (UnsafeMutableBufferPointer<T>) throws(E) -> Result
    ) throws(E) -> Result {
        try unsafe base.nullable.withMemoryRebound(to: type) { typedBuffer throws(E) in
            try unsafe body(typedBuffer)
        }
    }
}

// MARK: - Conversion

extension Span.Raw.Mutable {
    /// Creates an immutable raw span from this mutable raw span.
    @inlinable
    public var immutable: Span.Raw {
        unsafe Span<Byte>.Raw(start: UnsafeRawPointer(_start), count: _count)
    }
}

// MARK: - CustomStringConvertible

extension Span.Raw.Mutable: CustomStringConvertible {
    /// A textual representation of the span's start address and byte count.
    public var description: String {
        let address = unsafe UInt(bitPattern: _start)
        return "Span.Raw.Mutable(start: 0x\(String(address, radix: 16)), count: \(Int(bitPattern: _count)))"
    }
}

// MARK: - CustomDebugStringConvertible

extension Span.Raw.Mutable: CustomDebugStringConvertible {
    /// A textual representation of the span suitable for debugging.
    public var debugDescription: String {
        let address = unsafe UInt(bitPattern: _start)
        return "Span.Raw.Mutable(start: 0x\(String(address, radix: 16)), count: \(Int(bitPattern: _count)))"
    }
}

// MARK: - Equatable

extension Span.Raw.Mutable {
    /// Returns whether two spans share the same start address and byte count.
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        unsafe lhs._start == rhs._start && lhs._count == rhs._count
    }
}

// MARK: - Hashable

extension Span.Raw.Mutable {
    /// Hashes the span's start address and byte count.
    @inlinable
    public func hash(into hasher: inout Hasher) {
        unsafe hasher.combine(_start)
        hasher.combine(_count)
    }
}
