// exports.swift
// The Span Raw Primitives target houses the Copyable raw byte view `Span.Raw`
// (and its mutable peer `Span.Raw.Mutable`) relocated from `Memory.Buffer`
// (Cleave-8 item 8). Re-export the Span namespace + protocol surface so a single
// `import Span_Raw_Primitives` brings `Span`, `Span.Protocol`, and `Span.Raw`.

@_exported public import Span_Primitive
@_exported public import Span_Protocol_Primitives
