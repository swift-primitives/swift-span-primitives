# ``Span_Primitives``

The span-vending capability: namespace-neutral protocols for types that expose
a contiguous `Swift.Span` / `Swift.MutableSpan` over their elements.

## Overview

`swift-span-primitives` is a tier-0 capability package over the Swift standard
library's `Span` family. It owns the protocols a type conforms to in order to
vend a contiguous view of its elements — independent of which domain the type
belongs to (memory regions, byte streams, binary buffers, …).

The top-level `Span` and `Span.Mutable` are unbound typealiases to `Swift.Span`
and `Swift.MutableSpan`, so `Span<Byte>` *is* the stdlib span; the capability
protocols are surfaced under the `Span.` prefix as ``Span/Protocol`` and
``Span/Mutable/Protocol``.

"Vending a contiguous view" is a *capability*, not a location or a storage
strategy. Hosting it here, decoupled from any single domain namespace, lets
each domain conform to the same capability with no cross-domain dependency edge
— the resolution to the byte/binary ↔ memory coupling identified in
`memory-byte-bit-domain-orthogonality.md` and folded into
`cross-layer-capability-protocol-model.md` §12.

## The capability lattice

ONE read capability and its mutable refinement. `Self` suppresses both
`Copyable` and `Escapable`, so the same protocol is satisfied by both lifetime
regimes — escapability is an orthogonal property of the conformer, not a fork
in the capability:

- ``Span/Protocol`` — the span-vending capability (`~Copyable & ~Escapable`
  `Self`). **Owned** (Escapable) conformers compute a span borrowing
  themselves; **borrowed** (`~Escapable`) conformers *are* the borrow.
  `Swift.Span` itself conforms by identity — the linchpin. The single
  requirement is `span` under `@_lifetime(borrow self)`, the one contract
  both regimes can witness.
- ``Span/Mutable/Protocol`` — **mutable**: refines ``Span/Protocol`` and adds
  `mutableSpan: Swift.MutableSpan<Element>` under `@_lifetime(&self)`
  (restating `~Copyable`; `Self` is Escapable — mutable conformers are owned).

Design history: the package formerly shipped a separate borrowed leg
(`Span.Borrowed.Protocol`, `@_lifetime(copy self)`), on the claim that the
witness-table contract for `var span` had to differ across the two lifetime
regimes. That claim is refuted for the `borrow self` form — `copy self` is
owned-unsatisfiable and a no-annotation requirement is rejected at the
protocol declaration, so `borrow self` is the unique unifier; the borrowed
leg collapsed into ``Span/Protocol`` (Swift 6.3.2, cursor hot path
0-`witness_method` preserved, byte-identical to the two-protocol baseline).

## Deferred

`Span.Raw[.Mutable]` (over `RawSpan` / `MutableRawSpan`) and
`Span.Output[.Raw]` (over `OutputSpan` / `OutputRawSpan`) follow the same
`Nest.Name` shape and are **deferred** — they ship when a concrete conformer
needs them, per the orthogonality doc's "ship as needed" disposition. This
package currently ships only the typed-element lattice above.

## Topics

### Capability protocols

- ``Span/Protocol``
- ``Span/Mutable/Protocol``
