// exports.swift
// The Span Primitive target declares the namespace-only root per [MOD-017]:
// the `Span` namespace enum plus the `Span.Mutable` sub-namespace shell. It
// has zero external dependencies — the invariant that makes it cheap for any
// domain to import when conforming to the span capability. There are no
// upstream modules to re-export here.
