public import Byte_Primitives
import Cardinal_Primitives_Standard_Library_Integration
public import Index_Primitives
public import Span_Protocol_Primitives

extension Span.Raw {

    @safe

    public struct Mutable: Hashable, @unchecked Sendable {

        @usableFromInline
        internal let _start: UnsafeMutableRawPointer

        @usableFromInline
        internal let _count: Index<Byte>.Count

        @inlinable
        public init(start: UnsafeMutableRawPointer, count: Index<Byte>.Count) {
            unsafe self._start = start
            self._count = count
        }

        @inlinable
        public init() {
            unsafe self._start = _emptyMutableRawSpanSentinel
            self._count = .zero
        }

        @inlinable
        public init(_ buffer: UnsafeMutableRawBufferPointer) {
            if let baseAddress = buffer.baseAddress {
                unsafe self._start = baseAddress
            } else {
                unsafe self._start = _emptyMutableRawSpanSentinel
            }
            self._count = Index<Byte>.Count(UInt(buffer.count))
        }
    }
}

@usableFromInline

nonisolated(unsafe) let _emptyMutableRawSpanSentinel: UnsafeMutableRawPointer =
    UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 4096)

extension Span.Raw.Mutable {

    @inlinable
    public var count: Index<Byte>.Count { _count }

    @inlinable
    public var isEmpty: Bool { _count == .zero }
}

extension Span.Raw.Mutable: Span.Mutable.`Protocol` {

    public typealias Element = Byte

    @inlinable
    public var span: Swift.Span<Byte> {
        @_lifetime(borrow self)
        borrowing get {
            let typed = unsafe _start.assumingMemoryBound(to: Byte.self)
            return unsafe Swift.Span(_unsafeStart: typed, count: _count)
        }
    }

    @inlinable
    public var mutableSpan: Swift.MutableSpan<Byte> {
        @_lifetime(&self)
        mutating get {
            let typed = unsafe _start.assumingMemoryBound(to: Byte.self)
            return unsafe Swift.MutableSpan(_unsafeStart: typed, count: _count)
        }
    }

    @inlinable
    @_lifetime(&self)
    public mutating func mutableSpan(count: Index<Byte>.Count) -> Swift.MutableSpan<Byte> {
        precondition(
            count <= _count,
            "Span.Raw.Mutable.mutableSpan(count:): count (\(Int(bitPattern: count))) exceeds span capacity (\(Int(bitPattern: _count)))"
        )
        let typed = unsafe _start.assumingMemoryBound(to: Byte.self)
        return unsafe Swift.MutableSpan(_unsafeStart: typed, count: count)
    }
}

extension Span.Raw.Mutable {

    @inlinable
    public mutating func copy(from source: Span.Raw) {
        precondition(
            source.count <= _count,
            "Span.Raw.Mutable.copy(from:): source count (\(Int(bitPattern: source.count))) exceeds destination capacity (\(Int(bitPattern: _count)))"
        )
        unsafe base.nullable.copyMemory(from: source.base.nullable)
    }

    @inlinable
    public mutating func copy(from source: UnsafeRawBufferPointer) {
        precondition(
            source.count <= Int(bitPattern: _count),
            "Span.Raw.Mutable.copy(from:): source count (\(source.count)) exceeds destination capacity (\(Int(bitPattern: _count)))"
        )
        unsafe base.nullable.copyMemory(from: source)
    }
}

extension Span.Raw.Mutable {

    @inlinable
    public func withRebound<T, Result, E: Swift.Error>(
        to type: T.Type,
        _ body: (UnsafeMutableBufferPointer<T>) throws(E) -> Result
    ) throws(E) -> Result {
        try unsafe base.nullable.withMemoryRebound(to: type) { typedBuffer throws(E) in
            try unsafe body(typedBuffer)
        }
    }
}

extension Span.Raw.Mutable {

    @inlinable
    public var immutable: Span.Raw {
        unsafe Span<Byte>.Raw(start: UnsafeRawPointer(_start), count: _count)
    }
}

extension Span.Raw.Mutable: CustomStringConvertible {

    public var description: String {
        let address = unsafe UInt(bitPattern: _start)
        return
            "Span.Raw.Mutable(start: 0x\(String(address, radix: 16)), count: \(Int(bitPattern: _count)))"
    }
}

extension Span.Raw.Mutable: CustomDebugStringConvertible {

    public var debugDescription: String {
        let address = unsafe UInt(bitPattern: _start)
        return
            "Span.Raw.Mutable(start: 0x\(String(address, radix: 16)), count: \(Int(bitPattern: _count)))"
    }
}

extension Span.Raw.Mutable {

    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        unsafe lhs._start == rhs._start && lhs._count == rhs._count
    }
}

extension Span.Raw.Mutable {

    @inlinable
    public func hash(into hasher: inout Hasher) {
        unsafe hasher.combine(_start)
        hasher.combine(_count)
    }
}
