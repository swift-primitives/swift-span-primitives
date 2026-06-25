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

extension Span.Raw {
    /// Namespace for stdlib buffer pointer conversions.
    ///
    /// Provides two conversion modes for crossing to `UnsafeRawBufferPointer`:
    ///
    /// ```swift
    /// let raw: Span.Raw = ...
    /// raw.base.nullable  // nil base address for empty (stdlib convention)
    /// raw.base.nonNull   // sentinel base address for empty (C interop)
    /// ```
    public struct Base {
        @usableFromInline
        internal let _parent: Span.Raw

        @inlinable
        internal init(_ parent: Span.Raw) {
            self._parent = parent
        }
    }

    /// Stdlib buffer-pointer conversion namespace.
    @inlinable
    public var base: Base { Base(self) }
}

extension Span.Raw.Base {
    /// The underlying stdlib buffer pointer (stdlib-normal form).
    ///
    /// For empty spans, returns `(start: nil, count: 0)` per stdlib convention.
    @inlinable
    public var nullable: UnsafeRawBufferPointer {
        if _parent.isEmpty {
            return unsafe UnsafeRawBufferPointer(start: nil, count: 0)
        }
        return unsafe UnsafeRawBufferPointer(
            start: _parent._start,
            count: Int(bitPattern: _parent._count)
        )
    }

    /// The underlying stdlib buffer pointer with non-null start.
    ///
    /// For empty spans, returns `(start: sentinel, count: 0)`.
    /// Use this for C APIs that reject null pointers even with count 0.
    @inlinable
    public var nonNull: UnsafeRawBufferPointer {
        unsafe UnsafeRawBufferPointer(
            start: _parent._start,
            count: Int(bitPattern: _parent._count)
        )
    }
}
