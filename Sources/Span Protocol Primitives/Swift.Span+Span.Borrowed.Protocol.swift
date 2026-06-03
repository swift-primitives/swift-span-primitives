// Swift.Span+Span.Borrowed.Protocol.swift
//
// THE LINCHPIN conformance: `Swift.Span<Element>` IS the borrowed-span
// capability, by identity. A span vends itself.
//
// This conformance is what lets region views simply BE `Swift.Span` rather
// than wrap it in a nominal `.Borrowed` type, and lets byte/binary domain
// operations attach to bare spans through `Span.Borrowed.`Protocol`` with no
// nominal carrier (per the `.Borrowed`-prune disposition in
// swift-institute/Research/memory-byte-bit-domain-orthogonality.md).
//
// Same-package conformance (Span.Borrowed.`Protocol` is declared in this
// package), so NO `@retroactive` — Swift.Span is a stdlib type but the
// protocol is ours; the conformance is local to this package's authority over
// the protocol. (@retroactive applies only when neither the type nor the
// protocol is yours.)

public import Span_Primitive

extension Swift.Span: Span.Borrowed.`Protocol` {
    /// A `Swift.Span` is the borrowed-span capability — it vends itself.
    ///
    /// `@_lifetime(copy self)` matches ``Span/Borrowed/Protocol``'s contract:
    /// the produced span shares the lifetime of `self` (which is the borrow).
    @inlinable
    public var span: Swift.Span<Element> {
        @_lifetime(copy self) get { self }
    }
}
