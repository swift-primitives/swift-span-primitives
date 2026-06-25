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

import Cardinal_Primitives_Standard_Library_Integration
public import Index_Primitives

extension Span.Raw.Mutable {
    /// Namespace for stdlib buffer pointer conversions.
    ///
    /// Provides two conversion modes for crossing to `UnsafeMutableRawBufferPointer`:
    ///
    /// ```swift
    /// let raw: Span.Raw.Mutable = ...
    /// raw.base.nullable  // nil base address for empty (stdlib convention)
    /// raw.base.nonNull   // sentinel base address for empty (C interop)
    /// ```
    public struct Base {
        @usableFromInline
        internal let _parent: Span.Raw.Mutable

        @inlinable
        internal init(_ parent: Span.Raw.Mutable) {
            self._parent = parent
        }
    }

    /// Stdlib buffer-pointer conversion namespace.
    @inlinable
    public var base: Base { Base(self) }
}

extension Span.Raw.Mutable.Base {
    /// The underlying stdlib mutable buffer pointer (stdlib-normal form).
    ///
    /// For empty spans, returns `(start: nil, count: 0)` per stdlib convention.
    @inlinable
    public var nullable: UnsafeMutableRawBufferPointer {
        if _parent.isEmpty {
            return unsafe UnsafeMutableRawBufferPointer(start: nil, count: 0)
        }
        return unsafe UnsafeMutableRawBufferPointer(
            start: _parent._start,
            count: Int(bitPattern: _parent._count)
        )
    }

    /// The underlying stdlib mutable buffer pointer with non-null start.
    ///
    /// For empty spans, returns `(start: sentinel, count: 0)`.
    /// Use this for C APIs that reject null pointers even with count 0.
    @inlinable
    public var nonNull: UnsafeMutableRawBufferPointer {
        unsafe UnsafeMutableRawBufferPointer(
            start: _parent._start,
            count: Int(bitPattern: _parent._count)
        )
    }
}
