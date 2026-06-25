// Swift.Span+Span.Raw.swift
//
// SURFACING: the public spelling `Span.Raw` (and its nested `Span.Raw.Mutable`,
// `Span.Raw.Base`, …) resolves through a member typealias on `Swift.Span` →
// `__Span.Raw`. `Span.Raw` as a TYPE resolves bare; constructing a `Span.Raw`
// VALUE needs a bound element (`Span<Byte>.Raw(...)`) or the `.init(...)` form in
// a typed context — the package's own code constructs via the `__Span.Raw` name.

public import Span_Primitive

extension Swift.Span {
    /// The public spelling `Span.Raw` (= `Swift.Span.Raw`) resolves here.
    public typealias Raw = __Span.Raw
}
