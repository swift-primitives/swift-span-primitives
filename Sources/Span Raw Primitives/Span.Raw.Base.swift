import Cardinal_Primitives_Standard_Library_Integration
public import Index_Primitives

extension Span.Raw {

    public struct Base {
        @usableFromInline
        internal let _parent: Span.Raw

        @inlinable
        package init(_ parent: Span.Raw) {
            self._parent = parent
        }
    }

    @inlinable
    public var base: Base { Base(self) }
}

extension Span.Raw.Base {

    @inlinable
    public var nullable: UnsafeRawBufferPointer {
        if _parent.isEmpty {
            return unsafe UnsafeRawBufferPointer(start: nil, count: 0)
        }
        return unsafe UnsafeRawBufferPointer(
            start: _parent._start,
            count: Int(bitPattern: _parent._count)
        )
    }

    @inlinable
    public var nonNull: UnsafeRawBufferPointer {
        unsafe UnsafeRawBufferPointer(
            start: _parent._start,
            count: Int(bitPattern: _parent._count)
        )
    }
}
