// exports.swift
// Re-export this package's umbrella for test consumers. Per [MOD-024] the
// Test Support target re-exports its own product so the namespace is uniform;
// there is no upstream Test Support to chain to (this package has zero
// external dependencies), so the spine consists solely of the own-product
// re-export.

@_exported public import Span_Primitives
