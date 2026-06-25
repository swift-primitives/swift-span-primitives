// __Span.swift
//
// `__Span` is the HIDDEN backing namespace for the span-vending capability. It
// carries the soft-hidden (`__`-prefixed) declarations — the capability protocols
// and the `Raw` family — that are surfaced to consumers under the `Span.` prefix
// via Element-free member typealiases on `Swift.Span` / `Swift.MutableSpan`:
//
//   public surface          backing (here)
//   ----------------------  --------------------------
//   Span<E>                 Swift.Span<E>   (the `Span` alias)
//   Span.Mutable<E>         Swift.MutableSpan<E>
//   Span.Protocol           __Span.Protocol
//   Span.Mutable.Protocol   __Span.Mutable.Protocol
//   Span.Raw                __Span.Raw
//
// The namespace was formerly the public `enum Span`; it was renamed to vacate the
// name `Span` for the stdlib alias (resolving the `Swift.Span` collision) while
// keeping every `Span.Protocol`-style spelling working unchanged.

/// The span-vending capability domain (hidden backing; see ``Span``).
///
/// Answers "what can vend a contiguous view of its elements?" — a *capability*,
/// not a storage strategy and not a location. It is the namespace-neutral home
/// for the protocols a type conforms to in order to expose a `Swift.Span` /
/// `Swift.MutableSpan` over its elements, regardless of which domain the type
/// belongs to (memory regions, byte streams, binary buffers, …).
///
/// ## Capability lattice
///
/// ONE read capability and its mutable refinement. `Swift.Span` is `~Escapable`,
/// and a conformer either *computes* a span borrowing `self` (owned) or *is* the
/// borrow (`~Escapable`) — but both witness the same `@_lifetime(borrow self)`
/// contract, so escapability is an orthogonal property of the conformer, not a
/// fork in the capability:
///
/// | Public spelling | `Self` | Vends | Lifetime |
/// |-----------------|--------|-------|----------|
/// | ``Span/Protocol`` | `~Copyable & ~Escapable` | `Span<Element>` | `@_lifetime(borrow self)` |
/// | ``Span/Mutable/Protocol`` | owned (Escapable) | `Span` + `MutableSpan` | refines ``Span/Protocol``; `@_lifetime(&self)` |
///
/// ## The linchpin conformance
///
/// `Swift.Span<Element>` itself conforms to ``Span/Protocol`` by identity
/// (`var span { self }`) — a span *is* the span-vending capability.
///
/// - SeeAlso: `swift-institute/Research/memory-byte-bit-domain-orthogonality.md`,
///   `cross-layer-capability-protocol-model.md` §12, and this package's
///   `Research/span-capability-stdlib-alignment-and-escapable.md`.
public enum __Span {}
