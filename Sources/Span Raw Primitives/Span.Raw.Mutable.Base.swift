import Cardinal_Primitives_Standard_Library_Integration
public import Index_Primitives

extension Span.Raw.Mutable {

    public struct Base {
        @usableFromInline
        internal let _parent: Span.Raw.Mutable

        @inlinable
        package init(_ parent: Span.Raw.Mutable) {
            self._parent = parent
        }
    }

    @inlinable
    public var base: Base { Base(self) }
}

extension Span.Raw.Mutable.Base {

    @inlinable
    public var nullable: UnsafeMutableRawBufferPointer {
        if _parent.isEmpty {
            return unsafe UnsafeMutableRawBufferPointer(start: nil, count: 0)
        }
        return unsafe UnsafeMutableRawBufferPointer(
            start: _parent._start,
            count: Int(bitPattern: _parent._count)
        )
    }

    @inlinable
    public var nonNull: UnsafeMutableRawBufferPointer {
        unsafe UnsafeMutableRawBufferPointer(
            start: _parent._start,
            count: Int(bitPattern: _parent._count)
        )
    }
}
