// exports.swift
// Umbrella re-export of the full Span surface: the namespace root + the
// capability-protocol surface (the three protocols and the Swift.Span identity
// conformance). Per [MOD-005] this target's sole content is `@_exported public
// import` re-exports of the sub-namespace targets. Consumers importing
// Span_Primitives get the union.

@_exported public import Span_Primitive
@_exported public import Span_Protocol_Primitives
