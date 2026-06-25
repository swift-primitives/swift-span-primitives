// Swift.MutableSpan+Span.Mutable.Protocol.swift
//
// SURFACING: the public spelling `Span.Mutable.Protocol` resolves through a
// member typealias on `Swift.MutableSpan` (the underlying type of the
// `Span.Mutable` alias) → `__Span.Mutable.Protocol`. This keeps every
// `extension X: Span.Mutable.Protocol` conformer compiling unchanged.
//
// Note: there is no `Swift.MutableSpan` linchpin conformance here — the mutable
// capability is owned-only by design (a borrowed MutableSpan vending itself is a
// soundness-confirmed but deferred frontier; see
// Research/span-capability-stdlib-alignment-and-escapable.md and
// Experiments/mutablespan-self-vend-soundness/).

public import Span_Primitive

extension Swift.MutableSpan {
    /// The public spelling `Span.Mutable.Protocol` (= `Swift.MutableSpan.Protocol`)
    /// resolves here.
    public typealias `Protocol` = __Span.Mutable.`Protocol`
}
