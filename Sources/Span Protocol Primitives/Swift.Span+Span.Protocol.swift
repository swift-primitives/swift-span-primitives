public import Span_Primitive

extension Swift.Span {

    public typealias `Protocol` = __Span.`Protocol`
}

extension Swift.Span: __Span.`Protocol` {

    @inlinable
    public var span: Swift.Span<Element> {
        @_lifetime(borrow self) get { self }
    }
}
