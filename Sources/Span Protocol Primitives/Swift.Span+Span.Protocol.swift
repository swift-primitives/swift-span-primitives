// Swift.Span+Span.Protocol.swift
//
// Swift.Span's relationship to the read capability, in two parts:
//
// (1) SURFACING: the public spelling `Span.Protocol` resolves through a member
//     typealias on `Swift.Span` (the underlying type of the `Span` alias) →
//     `__Span.Protocol`. This is what keeps every `extension X: Span.Protocol`
//     conformer compiling unchanged after the namespace rename.
//
// (2) THE LINCHPIN conformance: `Swift.Span<Element>` IS the span-vending
//     capability, by identity — a span vends itself. This lets region views
//     simply BE `Swift.Span` rather than wrap it in a nominal `.Borrowed` type,
//     and lets byte/binary domain operations attach to bare spans through the
//     capability with no nominal carrier (per the `.Borrowed`-prune disposition
//     in swift-institute/Research/memory-byte-bit-domain-orthogonality.md).
//     Same-package conformance (the protocol is ours), so NO `@retroactive`.

public import Span_Primitive

extension Swift.Span {
    /// The public spelling `Span.Protocol` (= `Swift.Span.Protocol`) resolves here.
    public typealias `Protocol` = __Span.`Protocol`
}

// NOTE: this one conformance must name `__Span.Protocol` directly — spelling it
// `Span.Protocol` is circular (resolving `Span.Protocol` = `Swift.Span.Protocol`
// would require the very conformance being declared here).
extension Swift.Span: __Span.`Protocol` {
    /// A `Swift.Span` is the span-vending capability — it vends itself.
    ///
    /// `@_lifetime(borrow self)` matches the contract: for a borrowed view the
    /// `self` value *is* the borrow, so forwarding it under a borrow of `self`
    /// shares its lifetime — no `_overrideLifetime` needed.
    @inlinable
    public var span: Swift.Span<Element> {
        @_lifetime(borrow self) get { self }
    }
}
