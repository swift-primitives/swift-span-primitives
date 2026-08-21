public import Span_Primitive

extension __Span {

    public protocol `Protocol`: ~Copyable, ~Escapable {

        associatedtype Element: ~Copyable

        var span: Swift.Span<Element> { @_lifetime(borrow self) get }
    }
}
