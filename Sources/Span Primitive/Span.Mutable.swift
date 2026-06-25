// Span.Mutable.swift
//
// Two facets of "Mutable", both spelled `Span.Mutable…`:
//   • `Span.Mutable<Element>` is the stdlib MUTABLE span — the Element-free member
//     typealias `Mutable = Swift.MutableSpan` surfaced on `Swift.Span`.
//   • `__Span.Mutable` is the hidden backing namespace that houses the mutable
//     capability protocol (``Span/Mutable/Protocol`` = `__Span.Mutable.Protocol`,
//     declared in the Span Protocol Primitives target).

extension __Span {
    /// Hidden backing namespace for the mutable span-vending capability.
    public enum Mutable {}
}

extension Swift.Span {
    /// `Span.Mutable<Element>` is `Swift.MutableSpan<Element>` — the stdlib
    /// mutable contiguous view, surfaced under the `Span.` prefix.
    public typealias Mutable = Swift.MutableSpan
}
