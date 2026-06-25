// Span.swift
//
// `Span` is the package's top-level name for the standard-library contiguous
// view type. It is an UNBOUND typealias to `Swift.Span` — no generic parameter
// list — so:
//
//   • `Span<Element>` IS `Swift.Span<Element>` (resolving the historical
//     collision: the package's namespace no longer shadows the stdlib type), and
//   • because an unbound alias behaves like the type name itself, member access
//     `Span.Protocol` / `Span.Mutable.Protocol` / `Span.Raw` resolves through the
//     Element-free member typealiases surfaced on `Swift.Span` (see ``__Span``).
//
// A BOUND generic alias (`Span<Element> = Swift.Span<Element>`) would break the
// bare member spelling; the unbound form is load-bearing. See
// `Research/span-capability-stdlib-alignment-and-escapable.md` and
// `Experiments/span-typealias-hosting/`.

/// The package's name for the standard-library contiguous-view type, `Swift.Span`.
public typealias Span = Swift.Span
