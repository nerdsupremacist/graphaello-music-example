// swiftlint:disable all
// This file was automatically generated and should not be edited.

import Apollo
import Combine
import Foundation
import SwiftUI

// MARK: Basic API

protocol Target {}

protocol API: Target {
    var client: ApolloClient { get }
}

extension API {
    func fetch<Query: GraphQLQuery>(query: Query, completion: @escaping (Result<Query.Data, GraphQLLoadingError<Self>>) -> Void) {
        client.fetch(query: query) { result in
            switch result {
            case let .success(result):
                guard let data = result.data else {
                    if let errors = result.errors, errors.count > 0 {
                        return completion(.failure(.graphQLErrors(errors)))
                    }
                    return completion(.failure(.emptyData(api: self)))
                }
                completion(.success(data))
            case let .failure(error):
                completion(.failure(.networkError(error)))
            }
        }
    }
}

protocol MutationTarget: Target {}

protocol Connection: Target {
    associatedtype Node
}

protocol Fragment {
    associatedtype UnderlyingType
    static var placeholder: Self { get }
}

extension Array: Fragment where Element: Fragment {
    typealias UnderlyingType = [Element.UnderlyingType]

    static var placeholder: [Element] {
        return Array(repeating: Element.placeholder, count: 5)
    }
}

extension Optional: Fragment where Wrapped: Fragment {
    typealias UnderlyingType = Wrapped.UnderlyingType?

    static var placeholder: Wrapped? {
        return Wrapped.placeholder
    }
}

protocol Mutation: ObservableObject {
    associatedtype Value

    var isLoading: Bool { get }
}

protocol CurrentValueMutation: ObservableObject {
    associatedtype Value

    var isLoading: Bool { get }
    var value: Value { get }
    var error: Error? { get }
}

// MARK: - Basic API: Paths

struct GraphQLPath<TargetType: Target, Value> {
    fileprivate init() {}
}

struct GraphQLFragmentPath<TargetType: Target, UnderlyingType> {
    fileprivate init() {}
}

extension GraphQLFragmentPath {
    typealias Path<V> = GraphQLPath<TargetType, V>
    typealias FragmentPath<V> = GraphQLFragmentPath<TargetType, V>
}

extension GraphQLFragmentPath {
    var _fragment: FragmentPath<UnderlyingType> {
        return self
    }
}

extension GraphQLFragmentPath {
    func _forEach<Value, Output>(_: KeyPath<GraphQLFragmentPath<TargetType, Value>, GraphQLPath<TargetType, Output>>) -> GraphQLPath<TargetType, [Output]> where UnderlyingType == [Value] {
        return .init()
    }

    func _forEach<Value, Output>(_: KeyPath<GraphQLFragmentPath<TargetType, Value>, GraphQLPath<TargetType, Output>>) -> GraphQLPath<TargetType, [Output]?> where UnderlyingType == [Value]? {
        return .init()
    }
}

extension GraphQLFragmentPath {
    func _forEach<Value, Output>(_: KeyPath<GraphQLFragmentPath<TargetType, Value>, GraphQLFragmentPath<TargetType, Output>>) -> GraphQLFragmentPath<TargetType, [Output]> where UnderlyingType == [Value] {
        return .init()
    }

    func _forEach<Value, Output>(_: KeyPath<GraphQLFragmentPath<TargetType, Value>, GraphQLFragmentPath<TargetType, Output>>) -> GraphQLFragmentPath<TargetType, [Output]?> where UnderlyingType == [Value]? {
        return .init()
    }
}

extension GraphQLFragmentPath {
    func _flatten<T>() -> GraphQLFragmentPath<TargetType, [T]> where UnderlyingType == [[T]] {
        return .init()
    }

    func _flatten<T>() -> GraphQLFragmentPath<TargetType, [T]?> where UnderlyingType == [[T]]? {
        return .init()
    }
}

extension GraphQLPath {
    func _flatten<T>() -> GraphQLPath<TargetType, [T]> where Value == [[T]] {
        return .init()
    }

    func _flatten<T>() -> GraphQLPath<TargetType, [T]?> where Value == [[T]]? {
        return .init()
    }
}

extension GraphQLFragmentPath {
    func _compactMap<T>() -> GraphQLFragmentPath<TargetType, [T]> where UnderlyingType == [T?] {
        return .init()
    }

    func _compactMap<T>() -> GraphQLFragmentPath<TargetType, [T]?> where UnderlyingType == [T?]? {
        return .init()
    }
}

extension GraphQLPath {
    func _compactMap<T>() -> GraphQLPath<TargetType, [T]> where Value == [T?] {
        return .init()
    }

    func _compactMap<T>() -> GraphQLPath<TargetType, [T]?> where Value == [T?]? {
        return .init()
    }
}

extension GraphQLFragmentPath {
    func _nonNull<T>() -> GraphQLFragmentPath<TargetType, T> where UnderlyingType == T? {
        return .init()
    }
}

extension GraphQLPath {
    func _nonNull<T>() -> GraphQLPath<TargetType, T> where Value == T? {
        return .init()
    }
}

extension GraphQLFragmentPath {
    func _withDefault<T>(_: @autoclosure () -> T) -> GraphQLFragmentPath<TargetType, T> where UnderlyingType == T? {
        return .init()
    }
}

extension GraphQLPath {
    func _withDefault<T>(_: @autoclosure () -> T) -> GraphQLPath<TargetType, T> where Value == T? {
        return .init()
    }
}

// MARK: - Basic API: Arguments

enum GraphQLArgument<Value> {
    enum QueryArgument {
        case withDefault(Value)
        case forced
    }

    case value(Value)
    case argument(QueryArgument)
}

extension GraphQLArgument {
    static var argument: GraphQLArgument<Value> {
        return .argument(.forced)
    }

    static func argument(default value: Value) -> GraphQLArgument<Value> {
        return .argument(.withDefault(value))
    }
}

// MARK: - Basic API: Paging

class Paging<Value: Fragment>: DynamicProperty, ObservableObject {
    fileprivate struct Response {
        let values: [Value]
        let cursor: String?
        let hasMore: Bool

        static var empty: Response {
            Response(values: [], cursor: nil, hasMore: false)
        }
    }

    fileprivate typealias Completion = (Result<Response, Error>) -> Void
    fileprivate typealias Loader = (String, Int?, @escaping Completion) -> Void

    private let loader: Loader

    @Published
    private(set) var isLoading: Bool = false

    @Published
    private(set) var values: [Value] = []

    private var cursor: String?

    @Published
    private(set) var hasMore: Bool = false

    @Published
    private(set) var error: Error? = nil

    fileprivate init(_ response: Response, loader: @escaping Loader) {
        self.loader = loader
        use(response)
    }

    func loadMore(pageSize: Int? = nil) {
        guard let cursor = cursor, !isLoading else { return }
        isLoading = true
        loader(cursor, pageSize) { [weak self] result in
            switch result {
            case let .success(response):
                self?.use(response)
            case let .failure(error):
                self?.handle(error)
            }
        }
    }

    private func use(_ response: Response) {
        isLoading = false
        values += response.values
        cursor = response.cursor
        hasMore = response.hasMore
    }

    private func handle(_ error: Error) {
        isLoading = false
        hasMore = false
        self.error = error
    }
}

// MARK: - Basic API: Error Types

enum GraphQLLoadingError<T: API>: Error {
    case emptyData(api: T)
    case graphQLErrors([GraphQLError])
    case networkError(Error)
}

// MARK: - Basic API: Refresh

protocol QueryRefreshController {
    func refresh()
    func refresh(completion: @escaping (Error?) -> Void)
}

private struct QueryRefreshControllerEnvironmentKey: EnvironmentKey {
    static let defaultValue: QueryRefreshController? = nil
}

extension EnvironmentValues {
    var queryRefreshController: QueryRefreshController? {
        get {
            self[QueryRefreshControllerEnvironmentKey.self]
        } set {
            self[QueryRefreshControllerEnvironmentKey.self] = newValue
        }
    }
}

// MARK: - Error Handling

enum QueryError {
    case network(Error)
    case graphql([GraphQLError])
}

extension QueryError: CustomStringConvertible {
    var description: String {
        switch self {
        case let .network(error):
            return error.localizedDescription
        case let .graphql(errors):
            return errors.map { $0.description }.joined(separator: ", ")
        }
    }
}

extension QueryError {
    var networkError: Error? {
        guard case let .network(error) = self else { return nil }
        return error
    }

    var graphQLErrors: [GraphQLError]? {
        guard case let .graphql(errors) = self else { return nil }
        return errors
    }
}

protocol QueryErrorController {
    var error: QueryError? { get }
    func clear()
}

private struct QueryErrorControllerEnvironmentKey: EnvironmentKey {
    static let defaultValue: QueryErrorController? = nil
}

extension EnvironmentValues {
    var queryErrorController: QueryErrorController? {
        get {
            self[QueryErrorControllerEnvironmentKey.self]
        } set {
            self[QueryErrorControllerEnvironmentKey.self] = newValue
        }
    }
}

// MARK: - Basic API: Views

private struct QueryRenderer<Query: GraphQLQuery, Loading: View, Error: View, Content: View>: View {
    typealias ContentFactory = (Query.Data) -> Content
    typealias ErrorFactory = (QueryError) -> Error

    private final class ViewModel: ObservableObject {
        @Published var isLoading: Bool = false
        @Published var value: Query.Data? = nil
        @Published var error: QueryError? = nil

        private var previous: Query?
        private var cancellable: Apollo.Cancellable?

        deinit {
            cancel()
        }

        func load(client: ApolloClient, query: Query) {
            guard previous !== query || (value == nil && !isLoading) else { return }
            perform(client: client, query: query)
        }

        func refresh(client: ApolloClient, query: Query, completion: ((Swift.Error?) -> Void)? = nil) {
            perform(client: client, query: query, cachePolicy: .fetchIgnoringCacheData, completion: completion)
        }

        private func perform(client: ApolloClient, query: Query, cachePolicy: CachePolicy = .returnCacheDataElseFetch, completion: ((Swift.Error?) -> Void)? = nil) {
            previous = query
            cancellable = client.fetch(query: query, cachePolicy: cachePolicy) { [weak self] result in
                defer {
                    self?.cancellable = nil
                    self?.isLoading = false
                }
                switch result {
                case let .success(result):
                    self?.value = result.data
                    self?.error = result.errors.map { .graphql($0) }
                    completion?(nil)
                case let .failure(error):
                    self?.error = .network(error)
                    completion?(error)
                }
            }
            isLoading = true
        }

        func cancel() {
            cancellable?.cancel()
        }
    }

    private struct RefreshController: QueryRefreshController {
        let client: ApolloClient
        let query: Query
        let viewModel: ViewModel

        func refresh() {
            viewModel.refresh(client: client, query: query)
        }

        func refresh(completion: @escaping (Swift.Error?) -> Void) {
            viewModel.refresh(client: client, query: query, completion: completion)
        }
    }

    private struct ErrorController: QueryErrorController {
        let viewModel: ViewModel

        var error: QueryError? {
            return viewModel.error
        }

        func clear() {
            viewModel.error = nil
        }
    }

    let client: ApolloClient
    let query: Query
    let loading: Loading
    let error: ErrorFactory
    let factory: ContentFactory

    @ObservedObject private var viewModel = ViewModel()
    @State private var hasAppeared = false

    var body: some View {
        if hasAppeared {
            self.viewModel.load(client: self.client, query: self.query)
        }
        return VStack {
            viewModel.isLoading && viewModel.value == nil && viewModel.error == nil ? loading : nil
            viewModel.value == nil ? viewModel.error.map(error) : nil
            viewModel
                .value
                .map(factory)
                .environment(\.queryRefreshController, RefreshController(client: client, query: query, viewModel: viewModel))
                .environment(\.queryErrorController, ErrorController(viewModel: viewModel))
        }
        .onAppear {
            DispatchQueue.main.async {
                self.hasAppeared = true
            }
            self.viewModel.load(client: self.client, query: self.query)
        }
        .onDisappear {
            DispatchQueue.main.async {
                self.hasAppeared = false
            }
            self.viewModel.cancel()
        }
    }
}

private struct BasicErrorView: View {
    let error: QueryError

    var body: some View {
        Text("Error: \(error.description)")
    }
}

private struct BasicLoadingView: View {
    var body: some View {
        Text("Loading")
    }
}

struct PagingView<Value: Fragment>: View {
    enum Mode {
        case list
        case vertical(alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, insets: EdgeInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        case horizontal(alignment: VerticalAlignment = .center, spacing: CGFloat? = nil, insets: EdgeInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }

    enum Data {
        case item(Value, Int)
        case loading
        case error(Error)

        fileprivate var id: String {
            switch self {
            case let .item(_, int):
                return int.description
            case .error:
                return "error"
            case .loading:
                return "loading"
            }
        }
    }

    @ObservedObject private var paging: Paging<Value>
    private let mode: Mode
    private let pageSize: Int?
    private var loader: (Data) -> AnyView

    @State private var visibleRect: CGRect = .zero

    init(_ paging: Paging<Value>, mode: Mode = .list, pageSize: Int? = nil, loader: @escaping (Data) -> AnyView) {
        self.paging = paging
        self.mode = mode
        self.pageSize = pageSize
        self.loader = loader
    }

    var body: some View {
        let data = self.paging.values.enumerated().map { Data.item($0.element, $0.offset) } +
            [self.paging.isLoading ? Data.loading : nil, self.paging.error.map(Data.error)].compactMap { $0 }

        switch mode {
        case .list:
            return AnyView(
                List(data, id: \.id) { data in
                    self.loader(data).onAppear { self.onAppear(data: data) }
                }
            )
        case let .vertical(alignment, spacing, insets):
            return AnyView(
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: alignment, spacing: spacing) {
                        ForEach(data, id: \.id) { data in
                            self.loader(data).ifVisible(in: self.visibleRect, in: .named("InfiniteVerticalScroll")) { self.onAppear(data: data) }
                        }
                    }
                    .padding(insets)
                }
                .coordinateSpace(name: "InfiniteVerticalScroll")
                .rectReader($visibleRect, in: .named("InfiniteVerticalScroll"))
            )
        case let .horizontal(alignment, spacing, insets):
            return AnyView(
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: alignment, spacing: spacing) {
                        ForEach(data, id: \.id) { data in
                            self.loader(data).ifVisible(in: self.visibleRect, in: .named("InfiniteHorizontalScroll")) { self.onAppear(data: data) }
                        }
                    }
                    .padding(insets)
                }
                .coordinateSpace(name: "InfiniteHorizontalScroll")
                .rectReader($visibleRect, in: .named("InfiniteHorizontalScroll"))
            )
        }
    }

    private func onAppear(data: Data) {
        guard !paging.isLoading,
            paging.hasMore,
            case let .item(_, index) = data,
            index > paging.values.count - 2 else { return }

        DispatchQueue.main.async {
            paging.loadMore(pageSize: pageSize)
        }
    }
}

extension PagingView {
    init<Loading: View, Error: View, Data: View>(_ paging: Paging<Value>,
                                                 mode: Mode = .list,
                                                 pageSize: Int? = nil,
                                                 loading loadingView: @escaping () -> Loading,
                                                 error errorView: @escaping (Swift.Error) -> Error,
                                                 item itemView: @escaping (Value) -> Data) {
        self.init(paging, mode: mode, pageSize: pageSize) { data in
            switch data {
            case let .item(item, _):
                return AnyView(itemView(item))
            case let .error(error):
                return AnyView(errorView(error))
            case .loading:
                return AnyView(loadingView())
            }
        }
    }

    init<Error: View, Data: View>(_ paging: Paging<Value>,
                                  mode: Mode = .list,
                                  pageSize: Int? = nil,
                                  error errorView: @escaping (Swift.Error) -> Error,
                                  item itemView: @escaping (Value) -> Data) {
        self.init(paging,
                  mode: mode,
                  pageSize: pageSize,
                  loading: { PagingBasicLoadingView(content: itemView) },
                  error: errorView,
                  item: itemView)
    }

    init<Loading: View, Data: View>(_ paging: Paging<Value>,
                                    mode: Mode = .list,
                                    pageSize: Int? = nil,
                                    loading loadingView: @escaping () -> Loading,
                                    item itemView: @escaping (Value) -> Data) {
        self.init(paging,
                  mode: mode,
                  pageSize: pageSize,
                  loading: loadingView,
                  error: { Text("Error: \($0.localizedDescription)") },
                  item: itemView)
    }

    init<Data: View>(_ paging: Paging<Value>,
                     mode: Mode = .list,
                     pageSize: Int? = nil,
                     item itemView: @escaping (Value) -> Data) {
        self.init(paging,
                  mode: mode,
                  pageSize: pageSize,
                  loading: { PagingBasicLoadingView(content: itemView) },
                  error: { Text("Error: \($0.localizedDescription)") },
                  item: itemView)
    }
}

private struct PagingBasicLoadingView<Value: Fragment, Content: View>: View {
    let content: (Value) -> Content

    var body: some View {
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            content(.placeholder).disabled(true).redacted(reason: .placeholder)
        } else {
            BasicLoadingView()
        }
    }
}

extension PagingView.Mode {
    static func vertical(alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, padding edges: Edge.Set, by padding: CGFloat) -> PagingView.Mode {
        return .vertical(alignment: alignment,
                         spacing: spacing,
                         insets: EdgeInsets(top: edges.contains(.top) ? padding : 0,
                                            leading: edges.contains(.leading) ? padding : 0,
                                            bottom: edges.contains(.bottom) ? padding : 0,
                                            trailing: edges.contains(.trailing) ? padding : 0))
    }

    static func vertical(alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, padding: CGFloat) -> PagingView.Mode {
        return .vertical(alignment: alignment, spacing: spacing, padding: .all, by: padding)
    }

    static var vertical: PagingView.Mode { .vertical() }

    static func horizontal(alignment: VerticalAlignment = .center, spacing: CGFloat? = nil, padding edges: Edge.Set, by padding: CGFloat) -> PagingView.Mode {
        return .horizontal(alignment: alignment,
                           spacing: spacing,
                           insets: EdgeInsets(top: edges.contains(.top) ? padding : 0,
                                              leading: edges.contains(.leading) ? padding : 0,
                                              bottom: edges.contains(.bottom) ? padding : 0,
                                              trailing: edges.contains(.trailing) ? padding : 0))
    }

    static func horizontal(alignment: VerticalAlignment = .center, spacing: CGFloat? = nil, padding: CGFloat) -> PagingView.Mode {
        return .horizontal(alignment: alignment, spacing: spacing, padding: .all, by: padding)
    }

    static var horizontal: PagingView.Mode { .horizontal() }
}

extension View {
    fileprivate func rectReader(_ binding: Binding<CGRect>, in space: CoordinateSpace) -> some View {
        background(GeometryReader { (geometry) -> AnyView in
            let rect = geometry.frame(in: space)
            DispatchQueue.main.async {
                binding.wrappedValue = rect
            }
            return AnyView(Rectangle().fill(Color.clear))
        })
    }
}

extension View {
    fileprivate func ifVisible(in rect: CGRect, in space: CoordinateSpace, execute: @escaping () -> Void) -> some View {
        background(GeometryReader { (geometry) -> AnyView in
            let frame = geometry.frame(in: space)
            if frame.intersects(rect) {
                execute()
            }
            return AnyView(Rectangle().fill(Color.clear))
        })
    }
}

// MARK: - Basic API: Decoders

protocol GraphQLValueDecoder {
    associatedtype Encoded
    associatedtype Decoded

    static func decode(encoded: Encoded) throws -> Decoded
}

enum NoOpDecoder<T>: GraphQLValueDecoder {
    static func decode(encoded: T) throws -> T {
        return encoded
    }
}

// MARK: - Basic API: Scalar Handling

protocol GraphQLScalar {
    associatedtype Scalar
    static var placeholder: Self { get }
    init(from scalar: Scalar) throws
}

extension Array: GraphQLScalar where Element: GraphQLScalar {
    static var placeholder: [Element] {
        return Array(repeating: Element.placeholder, count: 5)
    }

    init(from scalar: [Element.Scalar]) throws {
        self = try scalar.map { try Element(from: $0) }
    }
}

extension Optional: GraphQLScalar where Wrapped: GraphQLScalar {
    static var placeholder: Wrapped? {
        return Wrapped.placeholder
    }

    init(from scalar: Wrapped.Scalar?) throws {
        guard let scalar = scalar else {
            self = .none
            return
        }
        self = .some(try Wrapped(from: scalar))
    }
}

extension URL: GraphQLScalar {
    typealias Scalar = String

    static let placeholder: URL = URL(string: "https://graphaello.dev/assets/logo.png")!

    private struct URLScalarDecodingError: Error {
        let string: String
    }

    init(from string: Scalar) throws {
        guard let url = URL(string: string) else {
            throw URLScalarDecodingError(string: string)
        }
        self = url
    }
}

enum ScalarDecoder<ScalarType: GraphQLScalar>: GraphQLValueDecoder {
    typealias Encoded = ScalarType.Scalar
    typealias Decoded = ScalarType

    static func decode(encoded: ScalarType.Scalar) throws -> ScalarType {
        if let encoded = encoded as? String, encoded == "__GRAPHAELLO_PLACEHOLDER__" {
            return Decoded.placeholder
        }
        return try ScalarType(from: encoded)
    }
}

// MARK: - Basic API: HACK - AnyObservableObject

private class AnyObservableObject: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    var cancellable: AnyCancellable?

    func use<O: ObservableObject>(_ object: O) {
        cancellable?.cancel()
        cancellable = object.objectWillChange.sink { [unowned self] _ in self.objectWillChange.send() }
    }
}

// MARK: - Basic API: Graph QL Property Wrapper

@propertyWrapper
struct GraphQL<Decoder: GraphQLValueDecoder>: DynamicProperty {
    private let initialValue: Decoder.Decoded

    @State
    private var value: Decoder.Decoded? = nil

    @ObservedObject
    private var observed: AnyObservableObject = AnyObservableObject()
    private let updateObserved: ((Decoder.Decoded) -> Void)?

    var wrappedValue: Decoder.Decoded {
        get {
            return value ?? initialValue
        }
        nonmutating set {
            value = newValue
            updateObserved?(newValue)
        }
    }

    var projectedValue: Binding<Decoder.Decoded> {
        return Binding(get: { self.wrappedValue }, set: { newValue in self.wrappedValue = newValue })
    }

    init<T: Target>(_: @autoclosure () -> GraphQLPath<T, Decoder.Encoded>) {
        fatalError("Initializer with path only should never be used")
    }

    init<T: Target, Value>(_: @autoclosure () -> GraphQLPath<T, Value>) where Decoder == NoOpDecoder<Value> {
        fatalError("Initializer with path only should never be used")
    }

    init<T: Target, Value: GraphQLScalar>(_: @autoclosure () -> GraphQLPath<T, Value.Scalar>) where Decoder == ScalarDecoder<Value> {
        fatalError("Initializer with path only should never be used")
    }

    fileprivate init(_ wrappedValue: Decoder.Encoded) {
        initialValue = try! Decoder.decode(encoded: wrappedValue)
        updateObserved = nil
    }

    mutating func update() {
        _value.update()
        _observed.update()
    }
}

extension GraphQL where Decoder.Decoded: ObservableObject {
    fileprivate init(_ wrappedValue: Decoder.Encoded) {
        let value = try! Decoder.decode(encoded: wrappedValue)
        initialValue = value

        let observed = AnyObservableObject()
        observed.use(value)

        self.observed = observed
        updateObserved = { observed.use($0) }
    }
}

extension GraphQL {
    init<T: Target, Value: Fragment>(_: @autoclosure () -> GraphQLFragmentPath<T, Value.UnderlyingType>) where Decoder == NoOpDecoder<Value> {
        fatalError("Initializer with path only should never be used")
    }
}

extension GraphQL {
    init<T: API, C: Connection, F: Fragment>(_: @autoclosure () -> GraphQLFragmentPath<T, C>) where Decoder == NoOpDecoder<Paging<F>>, C.Node == F.UnderlyingType {
        fatalError("Initializer with path only should never be used")
    }

    init<T: API, C: Connection, F: Fragment>(_: @autoclosure () -> GraphQLFragmentPath<T, C?>) where Decoder == NoOpDecoder<Paging<F>?>, C.Node == F.UnderlyingType {
        fatalError("Initializer with path only should never be used")
    }
}

extension GraphQL {
    init<T: MutationTarget, MutationType: Mutation>(_: @autoclosure () -> GraphQLPath<T, MutationType.Value>) where Decoder == NoOpDecoder<MutationType> {
        fatalError("Initializer with path only should never be used")
    }

    init<T: MutationTarget, MutationType: Mutation>(_: @autoclosure () -> GraphQLFragmentPath<T, MutationType.Value.UnderlyingType>) where Decoder == NoOpDecoder<MutationType>, MutationType.Value: Fragment {
        fatalError("Initializer with path only should never be used")
    }
}

extension GraphQL {
    init<T: Target, M: MutationTarget, MutationType: CurrentValueMutation>(_: @autoclosure () -> GraphQLPath<T, MutationType.Value>, mutation _: @autoclosure () -> GraphQLPath<M, MutationType.Value>) where Decoder == NoOpDecoder<MutationType> {
        fatalError("Initializer with path only should never be used")
    }

    init<T: Target, M: MutationTarget, MutationType: CurrentValueMutation>(_: @autoclosure () -> GraphQLFragmentPath<T, MutationType.Value.UnderlyingType>, mutation _: @autoclosure () -> GraphQLFragmentPath<M, MutationType.Value.UnderlyingType>) where Decoder == NoOpDecoder<MutationType>, MutationType.Value: Fragment {
        fatalError("Initializer with path only should never be used")
    }
}


// MARK: - Music

#if GRAPHAELLO_MUSIC_TARGET

    struct Music: API {
        let client: ApolloClient

        typealias Query = Music
        typealias Path<V> = GraphQLPath<Music, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<Music, V>

        static var lookup: FragmentPath<Music.LookupQuery?> { .init() }

        static var browse: FragmentPath<Music.BrowseQuery?> { .init() }

        static var search: FragmentPath<Music.SearchQuery?> { .init() }

        static func node(id _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Node?> {
            return .init()
        }

        static var node: FragmentPath<Music.Node?> { .init() }

        static var lastFm: FragmentPath<Music.LastFmQuery?> { .init() }

        static var spotify: FragmentPath<Music.SpotifyQuery> { .init() }

        enum LookupQuery: Target {
            typealias Path<V> = GraphQLPath<LookupQuery, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<LookupQuery, V>

            static func area(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Area?> {
                return .init()
            }

            static var area: FragmentPath<Music.Area?> { .init() }

            static func artist(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Artist?> {
                return .init()
            }

            static var artist: FragmentPath<Music.Artist?> { .init() }

            static func collection(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Collection?> {
                return .init()
            }

            static var collection: FragmentPath<Music.Collection?> { .init() }

            static func disc(discID _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Disc?> {
                return .init()
            }

            static var disc: FragmentPath<Music.Disc?> { .init() }

            static func event(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Event?> {
                return .init()
            }

            static var event: FragmentPath<Music.Event?> { .init() }

            static func instrument(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Instrument?> {
                return .init()
            }

            static var instrument: FragmentPath<Music.Instrument?> { .init() }

            static func label(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Label?> {
                return .init()
            }

            static var label: FragmentPath<Music.Label?> { .init() }

            static func place(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Place?> {
                return .init()
            }

            static var place: FragmentPath<Music.Place?> { .init() }

            static func recording(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Recording?> {
                return .init()
            }

            static var recording: FragmentPath<Music.Recording?> { .init() }

            static func release(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Release?> {
                return .init()
            }

            static var release: FragmentPath<Music.Release?> { .init() }

            static func releaseGroup(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.ReleaseGroup?> {
                return .init()
            }

            static var releaseGroup: FragmentPath<Music.ReleaseGroup?> { .init() }

            static func series(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Series?> {
                return .init()
            }

            static var series: FragmentPath<Music.Series?> { .init() }

            static func url(mbid _: GraphQLArgument<String?> = .argument,
                            resource _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.Url?> {
                return .init()
            }

            static var url: FragmentPath<Music.Url?> { .init() }

            static func work(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Work?> {
                return .init()
            }

            static var work: FragmentPath<Music.Work?> { .init() }

            static var _fragment: FragmentPath<LookupQuery> { .init() }
        }

        enum Area: Target {
            typealias Path<V> = GraphQLPath<Area, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<Area, V>

            static var id: Path<String> { .init() }

            static var mbid: Path<String> { .init() }

            static var name: Path<String?> { .init() }

            static var sortName: Path<String?> { .init() }

            static var disambiguation: Path<String?> { .init() }

            static var aliases: FragmentPath<[Music.Alias?]?> { .init() }

            static func isoCodes(standard _: GraphQLArgument<String?> = .argument) -> Path<[String?]?> {
                return .init()
            }

            static var isoCodes: Path<[String?]?> { .init() }

            static var type: Path<String?> { .init() }

            static var typeId: Path<String?> { .init() }

            static func artists(after _: GraphQLArgument<String?> = .argument,
                                first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
                return .init()
            }

            static var artists: FragmentPath<Music.ArtistConnection?> { .init() }

            static func events(after _: GraphQLArgument<String?> = .argument,
                               first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.EventConnection?> {
                return .init()
            }

            static var events: FragmentPath<Music.EventConnection?> { .init() }

            static func labels(after _: GraphQLArgument<String?> = .argument,
                               first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.LabelConnection?> {
                return .init()
            }

            static var labels: FragmentPath<Music.LabelConnection?> { .init() }

            static func places(after _: GraphQLArgument<String?> = .argument,
                               first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.PlaceConnection?> {
                return .init()
            }

            static var places: FragmentPath<Music.PlaceConnection?> { .init() }

            static func releases(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                                 status _: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument,
                                 after _: GraphQLArgument<String?> = .argument,
                                 first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
                return .init()
            }

            static var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

            static var relationships: FragmentPath<Music.Relationships?> { .init() }

            static func collections(after _: GraphQLArgument<String?> = .argument,
                                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
                return .init()
            }

            static var collections: FragmentPath<Music.CollectionConnection?> { .init() }

            static func tags(after _: GraphQLArgument<String?> = .argument,
                             first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
                return .init()
            }

            static var tags: FragmentPath<Music.TagConnection?> { .init() }

            static var lastFm: FragmentPath<Music.LastFmCountry?> { .init() }

            static var node: FragmentPath<Node> { .init() }

            static var entity: FragmentPath<Entity> { .init() }

            static var _fragment: FragmentPath<Area> { .init() }
        }

        enum Node: Target {
            typealias Path<V> = GraphQLPath<Node, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<Node, V>

            static var id: Path<String> { .init() }

            static var area: FragmentPath<Area?> { .init() }

            static var artist: FragmentPath<Artist?> { .init() }

            static var recording: FragmentPath<Recording?> { .init() }

            static var release: FragmentPath<Release?> { .init() }

            static var disc: FragmentPath<Disc?> { .init() }

            static var label: FragmentPath<Label?> { .init() }

            static var collection: FragmentPath<Collection?> { .init() }

            static var event: FragmentPath<Event?> { .init() }

            static var instrument: FragmentPath<Instrument?> { .init() }

            static var place: FragmentPath<Place?> { .init() }

            static var releaseGroup: FragmentPath<ReleaseGroup?> { .init() }

            static var series: FragmentPath<Series?> { .init() }

            static var work: FragmentPath<Work?> { .init() }

            static var url: FragmentPath<Url?> { .init() }

            static var _fragment: FragmentPath<Node> { .init() }
        }

        enum Entity: Target {
            typealias Path<V> = GraphQLPath<Entity, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<Entity, V>

            static var mbid: Path<String> { .init() }

            static var area: FragmentPath<Area?> { .init() }

            static var artist: FragmentPath<Artist?> { .init() }

            static var recording: FragmentPath<Recording?> { .init() }

            static var release: FragmentPath<Release?> { .init() }

            static var track: FragmentPath<Track?> { .init() }

            static var label: FragmentPath<Label?> { .init() }

            static var collection: FragmentPath<Collection?> { .init() }

            static var event: FragmentPath<Event?> { .init() }

            static var instrument: FragmentPath<Instrument?> { .init() }

            static var place: FragmentPath<Place?> { .init() }

            static var releaseGroup: FragmentPath<ReleaseGroup?> { .init() }

            static var series: FragmentPath<Series?> { .init() }

            static var work: FragmentPath<Work?> { .init() }

            static var url: FragmentPath<Url?> { .init() }

            static var _fragment: FragmentPath<Entity> { .init() }
        }

        enum Alias: Target {
            typealias Path<V> = GraphQLPath<Alias, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<Alias, V>

            static var name: Path<String?> { .init() }

            static var sortName: Path<String?> { .init() }

            static var locale: Path<String?> { .init() }

            static var primary: Path<Bool?> { .init() }

            static var type: Path<String?> { .init() }

            static var typeId: Path<String?> { .init() }

            static var _fragment: FragmentPath<Alias> { .init() }
        }

        enum ArtistConnection: Target, Connection {
            typealias Node = Music.Artist
            typealias Path<V> = GraphQLPath<ArtistConnection, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<ArtistConnection, V>

            static var pageInfo: FragmentPath<Music.PageInfo> { .init() }

            static var edges: FragmentPath<[Music.ArtistEdge?]?> { .init() }

            static var nodes: FragmentPath<[Music.Artist?]?> { .init() }

            static var totalCount: Path<Int?> { .init() }

            static var _fragment: FragmentPath<ArtistConnection> { .init() }
        }

        enum PageInfo: Target {
            typealias Path<V> = GraphQLPath<PageInfo, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<PageInfo, V>

            static var hasNextPage: Path<Bool> { .init() }

            static var hasPreviousPage: Path<Bool> { .init() }

            static var startCursor: Path<String?> { .init() }

            static var endCursor: Path<String?> { .init() }

            static var _fragment: FragmentPath<PageInfo> { .init() }
        }

        enum ArtistEdge: Target {
            typealias Path<V> = GraphQLPath<ArtistEdge, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<ArtistEdge, V>

            static var node: FragmentPath<Music.Artist?> { .init() }

            static var cursor: Path<String> { .init() }

            static var score: Path<Int?> { .init() }

            static var _fragment: FragmentPath<ArtistEdge> { .init() }
        }

        enum Artist: Target {
            typealias Path<V> = GraphQLPath<Artist, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<Artist, V>

            static var id: Path<String> { .init() }

            static var mbid: Path<String> { .init() }

            static var name: Path<String?> { .init() }

            static var sortName: Path<String?> { .init() }

            static var disambiguation: Path<String?> { .init() }

            static var aliases: FragmentPath<[Music.Alias?]?> { .init() }

            static var country: Path<String?> { .init() }

            static var area: FragmentPath<Music.Area?> { .init() }

            static var beginArea: FragmentPath<Music.Area?> { .init() }

            static var endArea: FragmentPath<Music.Area?> { .init() }

            static var lifeSpan: FragmentPath<Music.LifeSpan?> { .init() }

            static var gender: Path<String?> { .init() }

            static var genderId: Path<String?> { .init() }

            static var type: Path<String?> { .init() }

            static var typeId: Path<String?> { .init() }

            static var ipis: Path<[String?]?> { .init() }

            static var isnis: Path<[String?]?> { .init() }

            static func recordings(after _: GraphQLArgument<String?> = .argument,
                                   first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RecordingConnection?> {
                return .init()
            }

            static var recordings: FragmentPath<Music.RecordingConnection?> { .init() }

            static func releases(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                                 status _: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument,
                                 after _: GraphQLArgument<String?> = .argument,
                                 first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
                return .init()
            }

            static var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

            static func releaseGroups(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                                      after _: GraphQLArgument<String?> = .argument,
                                      first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseGroupConnection?> {
                return .init()
            }

            static var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }

            static func works(after _: GraphQLArgument<String?> = .argument,
                              first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.WorkConnection?> {
                return .init()
            }

            static var works: FragmentPath<Music.WorkConnection?> { .init() }

            static var relationships: FragmentPath<Music.Relationships?> { .init() }

            static func collections(after _: GraphQLArgument<String?> = .argument,
                                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
                return .init()
            }

            static var collections: FragmentPath<Music.CollectionConnection?> { .init() }

            static var rating: FragmentPath<Music.Rating?> { .init() }

            static func tags(after _: GraphQLArgument<String?> = .argument,
                             first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
                return .init()
            }

            static var tags: FragmentPath<Music.TagConnection?> { .init() }

            static var fanArt: FragmentPath<Music.FanArtArtist?> { .init() }

            static func mediaWikiImages(type _: GraphQLArgument<String?> = .argument) -> FragmentPath<[Music.MediaWikiImage?]> {
                return .init()
            }

            static var mediaWikiImages: FragmentPath<[Music.MediaWikiImage?]> { .init() }

            static var theAudioDb: FragmentPath<Music.TheAudioDbArtist?> { .init() }

            static var discogs: FragmentPath<Music.DiscogsArtist?> { .init() }

            static var lastFm: FragmentPath<Music.LastFmArtist?> { .init() }

            static var spotify: FragmentPath<Music.SpotifyArtist?> { .init() }

            static var node: FragmentPath<Node> { .init() }

            static var entity: FragmentPath<Entity> { .init() }

            static var _fragment: FragmentPath<Artist> { .init() }
        }

        enum LifeSpan: Target {
            typealias Path<V> = GraphQLPath<LifeSpan, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<LifeSpan, V>

            static var begin: Path<String?> { .init() }

            static var end: Path<String?> { .init() }

            static var ended: Path<Bool?> { .init() }

            static var _fragment: FragmentPath<LifeSpan> { .init() }
        }

        enum RecordingConnection: Target, Connection {
            typealias Node = Music.Recording
            typealias Path<V> = GraphQLPath<RecordingConnection, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<RecordingConnection, V>

            static var pageInfo: FragmentPath<Music.PageInfo> { .init() }

            static var edges: FragmentPath<[Music.RecordingEdge?]?> { .init() }

            static var nodes: FragmentPath<[Music.Recording?]?> { .init() }

            static var totalCount: Path<Int?> { .init() }

            static var _fragment: FragmentPath<RecordingConnection> { .init() }
        }

        enum RecordingEdge: Target {
            typealias Path<V> = GraphQLPath<RecordingEdge, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<RecordingEdge, V>

            static var node: FragmentPath<Music.Recording?> { .init() }

            static var cursor: Path<String> { .init() }

            static var score: Path<Int?> { .init() }

            static var _fragment: FragmentPath<RecordingEdge> { .init() }
        }

        enum Recording: Target {
            typealias Path<V> = GraphQLPath<Recording, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<Recording, V>

            static var id: Path<String> { .init() }

            static var mbid: Path<String> { .init() }

            static var title: Path<String?> { .init() }

            static var disambiguation: Path<String?> { .init() }

            static var aliases: FragmentPath<[Music.Alias?]?> { .init() }

            static var artistCredit: FragmentPath<[Music.ArtistCredit?]?> { .init() }

            static var artistCredits: FragmentPath<[Music.ArtistCredit?]?> { .init() }

            static var isrcs: Path<[String?]?> { .init() }

            static var length: Path<String?> { .init() }

            static var video: Path<Bool?> { .init() }

            static func artists(after _: GraphQLArgument<String?> = .argument,
                                first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
                return .init()
            }

            static var artists: FragmentPath<Music.ArtistConnection?> { .init() }

            static func releases(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                                 status _: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument,
                                 after _: GraphQLArgument<String?> = .argument,
                                 first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
                return .init()
            }

            static var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

            static var relationships: FragmentPath<Music.Relationships?> { .init() }

            static func collections(after _: GraphQLArgument<String?> = .argument,
                                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
                return .init()
            }

            static var collections: FragmentPath<Music.CollectionConnection?> { .init() }

            static var rating: FragmentPath<Music.Rating?> { .init() }

            static func tags(after _: GraphQLArgument<String?> = .argument,
                             first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
                return .init()
            }

            static var tags: FragmentPath<Music.TagConnection?> { .init() }

            static var theAudioDb: FragmentPath<Music.TheAudioDbTrack?> { .init() }

            static var lastFm: FragmentPath<Music.LastFmTrack?> { .init() }

            static func spotify(strategy _: GraphQLArgument<[Music.SpotifyMatchStrategy]?> = .argument) -> FragmentPath<Music.SpotifyTrack?> {
                return .init()
            }

            static var spotify: FragmentPath<Music.SpotifyTrack?> { .init() }

            static var node: FragmentPath<Node> { .init() }

            static var entity: FragmentPath<Entity> { .init() }

            static var _fragment: FragmentPath<Recording> { .init() }
        }

        enum ArtistCredit: Target {
            typealias Path<V> = GraphQLPath<ArtistCredit, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<ArtistCredit, V>

            static var artist: FragmentPath<Music.Artist?> { .init() }

            static var name: Path<String?> { .init() }

            static var joinPhrase: Path<String?> { .init() }

            static var _fragment: FragmentPath<ArtistCredit> { .init() }
        }

        typealias ReleaseGroupType = ApolloMusic.ReleaseGroupType

        typealias ReleaseStatus = ApolloMusic.ReleaseStatus

        enum ReleaseConnection: Target, Connection {
            typealias Node = Music.Release
            typealias Path<V> = GraphQLPath<ReleaseConnection, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<ReleaseConnection, V>

            static var pageInfo: FragmentPath<Music.PageInfo> { .init() }

            static var edges: FragmentPath<[Music.ReleaseEdge?]?> { .init() }

            static var nodes: FragmentPath<[Music.Release?]?> { .init() }

            static var totalCount: Path<Int?> { .init() }

            static var _fragment: FragmentPath<ReleaseConnection> { .init() }
        }

        enum ReleaseEdge: Target {
            typealias Path<V> = GraphQLPath<ReleaseEdge, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<ReleaseEdge, V>

            static var node: FragmentPath<Music.Release?> { .init() }

            static var cursor: Path<String> { .init() }

            static var score: Path<Int?> { .init() }

            static var _fragment: FragmentPath<ReleaseEdge> { .init() }
        }

        enum Release: Target {
            typealias Path<V> = GraphQLPath<Release, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<Release, V>

            static var id: Path<String> { .init() }

            static var mbid: Path<String> { .init() }

            static var title: Path<String?> { .init() }

            static var disambiguation: Path<String?> { .init() }

            static var aliases: FragmentPath<[Music.Alias?]?> { .init() }

            static var artistCredit: FragmentPath<[Music.ArtistCredit?]?> { .init() }

            static var artistCredits: FragmentPath<[Music.ArtistCredit?]?> { .init() }

            static var releaseEvents: FragmentPath<[Music.ReleaseEvent?]?> { .init() }

            static var date: Path<String?> { .init() }

            static var country: Path<String?> { .init() }

            static var asin: Path<String?> { .init() }

            static var barcode: Path<String?> { .init() }

            static var status: Path<Music.ReleaseStatus?> { .init() }

            static var statusId: Path<String?> { .init() }

            static var packaging: Path<String?> { .init() }

            static var packagingId: Path<String?> { .init() }

            static var quality: Path<String?> { .init() }

            static var media: FragmentPath<[Music.Medium?]?> { .init() }

            static func artists(after _: GraphQLArgument<String?> = .argument,
                                first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
                return .init()
            }

            static var artists: FragmentPath<Music.ArtistConnection?> { .init() }

            static func labels(after _: GraphQLArgument<String?> = .argument,
                               first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.LabelConnection?> {
                return .init()
            }

            static var labels: FragmentPath<Music.LabelConnection?> { .init() }

            static func recordings(after _: GraphQLArgument<String?> = .argument,
                                   first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RecordingConnection?> {
                return .init()
            }

            static var recordings: FragmentPath<Music.RecordingConnection?> { .init() }

            static func releaseGroups(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                                      after _: GraphQLArgument<String?> = .argument,
                                      first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseGroupConnection?> {
                return .init()
            }

            static var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }

            static var relationships: FragmentPath<Music.Relationships?> { .init() }

            static func collections(after _: GraphQLArgument<String?> = .argument,
                                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
                return .init()
            }

            static var collections: FragmentPath<Music.CollectionConnection?> { .init() }

            static func tags(after _: GraphQLArgument<String?> = .argument,
                             first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
                return .init()
            }

            static var tags: FragmentPath<Music.TagConnection?> { .init() }

            static var coverArtArchive: FragmentPath<Music.CoverArtArchiveRelease?> { .init() }

            static var discogs: FragmentPath<Music.DiscogsRelease?> { .init() }

            static var lastFm: FragmentPath<Music.LastFmAlbum?> { .init() }

            static func spotify(strategy _: GraphQLArgument<[Music.SpotifyMatchStrategy]?> = .argument) -> FragmentPath<Music.SpotifyAlbum?> {
                return .init()
            }

            static var spotify: FragmentPath<Music.SpotifyAlbum?> { .init() }

            static var node: FragmentPath<Node> { .init() }

            static var entity: FragmentPath<Entity> { .init() }

            static var _fragment: FragmentPath<Release> { .init() }
        }

        enum ReleaseEvent: Target {
            typealias Path<V> = GraphQLPath<ReleaseEvent, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<ReleaseEvent, V>

            static var area: FragmentPath<Music.Area?> { .init() }

            static var date: Path<String?> { .init() }

            static var _fragment: FragmentPath<ReleaseEvent> { .init() }
        }

        enum Medium: Target {
            typealias Path<V> = GraphQLPath<Medium, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<Medium, V>

            static var title: Path<String?> { .init() }

            static var format: Path<String?> { .init() }

            static var formatId: Path<String?> { .init() }

            static var position: Path<Int?> { .init() }

            static var trackCount: Path<Int?> { .init() }

            static var discs: FragmentPath<[Music.Disc?]?> { .init() }

            static var tracks: FragmentPath<[Music.Track?]?> { .init() }

            static var _fragment: FragmentPath<Medium> { .init() }
        }

        enum Disc: Target {
            typealias Path<V> = GraphQLPath<Disc, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<Disc, V>

            static var id: Path<String> { .init() }

            static var discId: Path<String> { .init() }

            static var offsetCount: Path<Int> { .init() }

            static var offsets: Path<[Int?]?> { .init() }

            static var sectors: Path<Int> { .init() }

            static func releases(after _: GraphQLArgument<String?> = .argument,
                                 first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
                return .init()
            }

            static var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

            static var node: FragmentPath<Node> { .init() }

            static var _fragment: FragmentPath<Disc> { .init() }
        }

        enum Track: Target {
            typealias Path<V> = GraphQLPath<Track, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<Track, V>

            static var mbid: Path<String> { .init() }

            static var title: Path<String?> { .init() }

            static var position: Path<Int?> { .init() }

            static var number: Path<String?> { .init() }

            static var length: Path<String?> { .init() }

            static var recording: FragmentPath<Music.Recording?> { .init() }

            static var entity: FragmentPath<Entity> { .init() }

            static var _fragment: FragmentPath<Track> { .init() }
        }

        enum LabelConnection: Target, Connection {
            typealias Node = Music.Label
            typealias Path<V> = GraphQLPath<LabelConnection, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<LabelConnection, V>

            static var pageInfo: FragmentPath<Music.PageInfo> { .init() }

            static var edges: FragmentPath<[Music.LabelEdge?]?> { .init() }

            static var nodes: FragmentPath<[Music.Label?]?> { .init() }

            static var totalCount: Path<Int?> { .init() }

            static var _fragment: FragmentPath<LabelConnection> { .init() }
        }

        enum LabelEdge: Target {
            typealias Path<V> = GraphQLPath<LabelEdge, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<LabelEdge, V>

            static var node: FragmentPath<Music.Label?> { .init() }

            static var cursor: Path<String> { .init() }

            static var score: Path<Int?> { .init() }

            static var _fragment: FragmentPath<LabelEdge> { .init() }
        }

        enum Label: Target {
            typealias Path<V> = GraphQLPath<Label, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<Label, V>

            static var id: Path<String> { .init() }

            static var mbid: Path<String> { .init() }

            static var name: Path<String?> { .init() }

            static var sortName: Path<String?> { .init() }

            static var disambiguation: Path<String?> { .init() }

            static var aliases: FragmentPath<[Music.Alias?]?> { .init() }

            static var country: Path<String?> { .init() }

            static var area: FragmentPath<Music.Area?> { .init() }

            static var lifeSpan: FragmentPath<Music.LifeSpan?> { .init() }

            static var labelCode: Path<Int?> { .init() }

            static var ipis: Path<[String?]?> { .init() }

            static var type: Path<String?> { .init() }

            static var typeId: Path<String?> { .init() }

            static func releases(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                                 status _: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument,
                                 after _: GraphQLArgument<String?> = .argument,
                                 first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
                return .init()
            }

            static var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

            static var relationships: FragmentPath<Music.Relationships?> { .init() }

            static func collections(after _: GraphQLArgument<String?> = .argument,
                                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
                return .init()
            }

            static var collections: FragmentPath<Music.CollectionConnection?> { .init() }

            static var rating: FragmentPath<Music.Rating?> { .init() }

            static func tags(after _: GraphQLArgument<String?> = .argument,
                             first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
                return .init()
            }

            static var tags: FragmentPath<Music.TagConnection?> { .init() }

            static var fanArt: FragmentPath<Music.FanArtLabel?> { .init() }

            static func mediaWikiImages(type _: GraphQLArgument<String?> = .argument) -> FragmentPath<[Music.MediaWikiImage?]> {
                return .init()
            }

            static var mediaWikiImages: FragmentPath<[Music.MediaWikiImage?]> { .init() }

            static var discogs: FragmentPath<Music.DiscogsLabel?> { .init() }

            static var node: FragmentPath<Node> { .init() }

            static var entity: FragmentPath<Entity> { .init() }

            static var _fragment: FragmentPath<Label> { .init() }
        }

        enum Relationships: Target {
            typealias Path<V> = GraphQLPath<Relationships, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<Relationships, V>

            static func areas(direction _: GraphQLArgument<String?> = .argument,
                              type _: GraphQLArgument<String?> = .argument,
                              typeID _: GraphQLArgument<String?> = .argument,
                              after _: GraphQLArgument<String?> = .argument,
                              first _: GraphQLArgument<Int?> = .argument,
                              before _: GraphQLArgument<String?> = .argument,
                              last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
                return .init()
            }

            static var areas: FragmentPath<Music.RelationshipConnection?> { .init() }

            static func artists(direction _: GraphQLArgument<String?> = .argument,
                                type _: GraphQLArgument<String?> = .argument,
                                typeID _: GraphQLArgument<String?> = .argument,
                                after _: GraphQLArgument<String?> = .argument,
                                first _: GraphQLArgument<Int?> = .argument,
                                before _: GraphQLArgument<String?> = .argument,
                                last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
                return .init()
            }

            static var artists: FragmentPath<Music.RelationshipConnection?> { .init() }

            static func events(direction _: GraphQLArgument<String?> = .argument,
                               type _: GraphQLArgument<String?> = .argument,
                               typeID _: GraphQLArgument<String?> = .argument,
                               after _: GraphQLArgument<String?> = .argument,
                               first _: GraphQLArgument<Int?> = .argument,
                               before _: GraphQLArgument<String?> = .argument,
                               last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
                return .init()
            }

            static var events: FragmentPath<Music.RelationshipConnection?> { .init() }

            static func instruments(direction _: GraphQLArgument<String?> = .argument,
                                    type _: GraphQLArgument<String?> = .argument,
                                    typeID _: GraphQLArgument<String?> = .argument,
                                    after _: GraphQLArgument<String?> = .argument,
                                    first _: GraphQLArgument<Int?> = .argument,
                                    before _: GraphQLArgument<String?> = .argument,
                                    last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
                return .init()
            }

            static var instruments: FragmentPath<Music.RelationshipConnection?> { .init() }

            static func labels(direction _: GraphQLArgument<String?> = .argument,
                               type _: GraphQLArgument<String?> = .argument,
                               typeID _: GraphQLArgument<String?> = .argument,
                               after _: GraphQLArgument<String?> = .argument,
                               first _: GraphQLArgument<Int?> = .argument,
                               before _: GraphQLArgument<String?> = .argument,
                               last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
                return .init()
            }

            static var labels: FragmentPath<Music.RelationshipConnection?> { .init() }

            static func places(direction _: GraphQLArgument<String?> = .argument,
                               type _: GraphQLArgument<String?> = .argument,
                               typeID _: GraphQLArgument<String?> = .argument,
                               after _: GraphQLArgument<String?> = .argument,
                               first _: GraphQLArgument<Int?> = .argument,
                               before _: GraphQLArgument<String?> = .argument,
                               last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
                return .init()
            }

            static var places: FragmentPath<Music.RelationshipConnection?> { .init() }

            static func recordings(direction _: GraphQLArgument<String?> = .argument,
                                   type _: GraphQLArgument<String?> = .argument,
                                   typeID _: GraphQLArgument<String?> = .argument,
                                   after _: GraphQLArgument<String?> = .argument,
                                   first _: GraphQLArgument<Int?> = .argument,
                                   before _: GraphQLArgument<String?> = .argument,
                                   last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
                return .init()
            }

            static var recordings: FragmentPath<Music.RelationshipConnection?> { .init() }

            static func releases(direction _: GraphQLArgument<String?> = .argument,
                                 type _: GraphQLArgument<String?> = .argument,
                                 typeID _: GraphQLArgument<String?> = .argument,
                                 after _: GraphQLArgument<String?> = .argument,
                                 first _: GraphQLArgument<Int?> = .argument,
                                 before _: GraphQLArgument<String?> = .argument,
                                 last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
                return .init()
            }

            static var releases: FragmentPath<Music.RelationshipConnection?> { .init() }

            static func releaseGroups(direction _: GraphQLArgument<String?> = .argument,
                                      type _: GraphQLArgument<String?> = .argument,
                                      typeID _: GraphQLArgument<String?> = .argument,
                                      after _: GraphQLArgument<String?> = .argument,
                                      first _: GraphQLArgument<Int?> = .argument,
                                      before _: GraphQLArgument<String?> = .argument,
                                      last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
                return .init()
            }

            static var releaseGroups: FragmentPath<Music.RelationshipConnection?> { .init() }

            static func series(direction _: GraphQLArgument<String?> = .argument,
                               type _: GraphQLArgument<String?> = .argument,
                               typeID _: GraphQLArgument<String?> = .argument,
                               after _: GraphQLArgument<String?> = .argument,
                               first _: GraphQLArgument<Int?> = .argument,
                               before _: GraphQLArgument<String?> = .argument,
                               last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
                return .init()
            }

            static var series: FragmentPath<Music.RelationshipConnection?> { .init() }

            static func urls(direction _: GraphQLArgument<String?> = .argument,
                             type _: GraphQLArgument<String?> = .argument,
                             typeID _: GraphQLArgument<String?> = .argument,
                             after _: GraphQLArgument<String?> = .argument,
                             first _: GraphQLArgument<Int?> = .argument,
                             before _: GraphQLArgument<String?> = .argument,
                             last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
                return .init()
            }

            static var urls: FragmentPath<Music.RelationshipConnection?> { .init() }

            static func works(direction _: GraphQLArgument<String?> = .argument,
                              type _: GraphQLArgument<String?> = .argument,
                              typeID _: GraphQLArgument<String?> = .argument,
                              after _: GraphQLArgument<String?> = .argument,
                              first _: GraphQLArgument<Int?> = .argument,
                              before _: GraphQLArgument<String?> = .argument,
                              last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
                return .init()
            }

            static var works: FragmentPath<Music.RelationshipConnection?> { .init() }

            static var _fragment: FragmentPath<Relationships> { .init() }
        }

        enum RelationshipConnection: Target, Connection {
            typealias Node = Music.Relationship
            typealias Path<V> = GraphQLPath<RelationshipConnection, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<RelationshipConnection, V>

            static var pageInfo: FragmentPath<Music.PageInfo> { .init() }

            static var edges: FragmentPath<[Music.RelationshipEdge?]?> { .init() }

            static var nodes: FragmentPath<[Music.Relationship?]?> { .init() }

            static var totalCount: Path<Int?> { .init() }

            static var _fragment: FragmentPath<RelationshipConnection> { .init() }
        }

        enum RelationshipEdge: Target {
            typealias Path<V> = GraphQLPath<RelationshipEdge, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<RelationshipEdge, V>

            static var node: FragmentPath<Music.Relationship?> { .init() }

            static var cursor: Path<String> { .init() }

            static var score: Path<Int?> { .init() }

            static var _fragment: FragmentPath<RelationshipEdge> { .init() }
        }

        enum Relationship: Target {
            typealias Path<V> = GraphQLPath<Relationship, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<Relationship, V>

            static var target: FragmentPath<Music.Entity> { .init() }

            static var direction: Path<String> { .init() }

            static var targetType: Path<String> { .init() }

            static var sourceCredit: Path<String?> { .init() }

            static var targetCredit: Path<String?> { .init() }

            static var begin: Path<String?> { .init() }

            static var end: Path<String?> { .init() }

            static var ended: Path<Bool?> { .init() }

            static var attributes: Path<[String?]?> { .init() }

            static var type: Path<String?> { .init() }

            static var typeId: Path<String?> { .init() }

            static var _fragment: FragmentPath<Relationship> { .init() }
        }

        enum CollectionConnection: Target, Connection {
            typealias Node = Music.Collection
            typealias Path<V> = GraphQLPath<CollectionConnection, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<CollectionConnection, V>

            static var pageInfo: FragmentPath<Music.PageInfo> { .init() }

            static var edges: FragmentPath<[Music.CollectionEdge?]?> { .init() }

            static var nodes: FragmentPath<[Music.Collection?]?> { .init() }

            static var totalCount: Path<Int?> { .init() }

            static var _fragment: FragmentPath<CollectionConnection> { .init() }
        }

        enum CollectionEdge: Target {
            typealias Path<V> = GraphQLPath<CollectionEdge, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<CollectionEdge, V>

            static var node: FragmentPath<Music.Collection?> { .init() }

            static var cursor: Path<String> { .init() }

            static var score: Path<Int?> { .init() }

            static var _fragment: FragmentPath<CollectionEdge> { .init() }
        }

        enum Collection: Target {
            typealias Path<V> = GraphQLPath<Collection, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<Collection, V>

            static var id: Path<String> { .init() }

            static var mbid: Path<String> { .init() }

            static var name: Path<String?> { .init() }

            static var editor: Path<String> { .init() }

            static var entityType: Path<String> { .init() }

            static var type: Path<String?> { .init() }

            static var typeId: Path<String?> { .init() }

            static func areas(after _: GraphQLArgument<String?> = .argument,
                              first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.AreaConnection?> {
                return .init()
            }

            static var areas: FragmentPath<Music.AreaConnection?> { .init() }

            static func artists(after _: GraphQLArgument<String?> = .argument,
                                first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
                return .init()
            }

            static var artists: FragmentPath<Music.ArtistConnection?> { .init() }

            static func events(after _: GraphQLArgument<String?> = .argument,
                               first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.EventConnection?> {
                return .init()
            }

            static var events: FragmentPath<Music.EventConnection?> { .init() }

            static func instruments(after _: GraphQLArgument<String?> = .argument,
                                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.InstrumentConnection?> {
                return .init()
            }

            static var instruments: FragmentPath<Music.InstrumentConnection?> { .init() }

            static func labels(after _: GraphQLArgument<String?> = .argument,
                               first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.LabelConnection?> {
                return .init()
            }

            static var labels: FragmentPath<Music.LabelConnection?> { .init() }

            static func places(after _: GraphQLArgument<String?> = .argument,
                               first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.PlaceConnection?> {
                return .init()
            }

            static var places: FragmentPath<Music.PlaceConnection?> { .init() }

            static func recordings(after _: GraphQLArgument<String?> = .argument,
                                   first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RecordingConnection?> {
                return .init()
            }

            static var recordings: FragmentPath<Music.RecordingConnection?> { .init() }

            static func releases(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                                 status _: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument,
                                 after _: GraphQLArgument<String?> = .argument,
                                 first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
                return .init()
            }

            static var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

            static func releaseGroups(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                                      after _: GraphQLArgument<String?> = .argument,
                                      first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseGroupConnection?> {
                return .init()
            }

            static var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }

            static func series(after _: GraphQLArgument<String?> = .argument,
                               first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.SeriesConnection?> {
                return .init()
            }

            static var series: FragmentPath<Music.SeriesConnection?> { .init() }

            static func works(after _: GraphQLArgument<String?> = .argument,
                              first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.WorkConnection?> {
                return .init()
            }

            static var works: FragmentPath<Music.WorkConnection?> { .init() }

            static var node: FragmentPath<Node> { .init() }

            static var entity: FragmentPath<Entity> { .init() }

            static var _fragment: FragmentPath<Collection> { .init() }
        }

        enum AreaConnection: Target, Connection {
            typealias Node = Music.Area
            typealias Path<V> = GraphQLPath<AreaConnection, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<AreaConnection, V>

            static var pageInfo: FragmentPath<Music.PageInfo> { .init() }

            static var edges: FragmentPath<[Music.AreaEdge?]?> { .init() }

            static var nodes: FragmentPath<[Music.Area?]?> { .init() }

            static var totalCount: Path<Int?> { .init() }

            static var _fragment: FragmentPath<AreaConnection> { .init() }
        }

        enum AreaEdge: Target {
            typealias Path<V> = GraphQLPath<AreaEdge, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<AreaEdge, V>

            static var node: FragmentPath<Music.Area?> { .init() }

            static var cursor: Path<String> { .init() }

            static var score: Path<Int?> { .init() }

            static var _fragment: FragmentPath<AreaEdge> { .init() }
        }

        enum EventConnection: Target, Connection {
            typealias Node = Music.Event
            typealias Path<V> = GraphQLPath<EventConnection, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<EventConnection, V>

            static var pageInfo: FragmentPath<Music.PageInfo> { .init() }

            static var edges: FragmentPath<[Music.EventEdge?]?> { .init() }

            static var nodes: FragmentPath<[Music.Event?]?> { .init() }

            static var totalCount: Path<Int?> { .init() }

            static var _fragment: FragmentPath<EventConnection> { .init() }
        }

        enum EventEdge: Target {
            typealias Path<V> = GraphQLPath<EventEdge, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<EventEdge, V>

            static var node: FragmentPath<Music.Event?> { .init() }

            static var cursor: Path<String> { .init() }

            static var score: Path<Int?> { .init() }

            static var _fragment: FragmentPath<EventEdge> { .init() }
        }

        enum Event: Target {
            typealias Path<V> = GraphQLPath<Event, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<Event, V>

            static var id: Path<String> { .init() }

            static var mbid: Path<String> { .init() }

            static var name: Path<String?> { .init() }

            static var disambiguation: Path<String?> { .init() }

            static var aliases: FragmentPath<[Music.Alias?]?> { .init() }

            static var lifeSpan: FragmentPath<Music.LifeSpan?> { .init() }

            static var time: Path<String?> { .init() }

            static var cancelled: Path<Bool?> { .init() }

            static var setlist: Path<String?> { .init() }

            static var type: Path<String?> { .init() }

            static var typeId: Path<String?> { .init() }

            static var relationships: FragmentPath<Music.Relationships?> { .init() }

            static func collections(after _: GraphQLArgument<String?> = .argument,
                                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
                return .init()
            }

            static var collections: FragmentPath<Music.CollectionConnection?> { .init() }

            static var rating: FragmentPath<Music.Rating?> { .init() }

            static func tags(after _: GraphQLArgument<String?> = .argument,
                             first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
                return .init()
            }

            static var tags: FragmentPath<Music.TagConnection?> { .init() }

            static var node: FragmentPath<Node> { .init() }

            static var entity: FragmentPath<Entity> { .init() }

            static var _fragment: FragmentPath<Event> { .init() }
        }

        enum Rating: Target {
            typealias Path<V> = GraphQLPath<Rating, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<Rating, V>

            static var voteCount: Path<Int> { .init() }

            static var value: Path<Double?> { .init() }

            static var _fragment: FragmentPath<Rating> { .init() }
        }

        enum TagConnection: Target, Connection {
            typealias Node = Music.Tag
            typealias Path<V> = GraphQLPath<TagConnection, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<TagConnection, V>

            static var pageInfo: FragmentPath<Music.PageInfo> { .init() }

            static var edges: FragmentPath<[Music.TagEdge?]?> { .init() }

            static var nodes: FragmentPath<[Music.Tag?]?> { .init() }

            static var totalCount: Path<Int?> { .init() }

            static var _fragment: FragmentPath<TagConnection> { .init() }
        }

        enum TagEdge: Target {
            typealias Path<V> = GraphQLPath<TagEdge, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<TagEdge, V>

            static var node: FragmentPath<Music.Tag?> { .init() }

            static var cursor: Path<String> { .init() }

            static var score: Path<Int?> { .init() }

            static var _fragment: FragmentPath<TagEdge> { .init() }
        }

        enum Tag: Target {
            typealias Path<V> = GraphQLPath<Tag, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<Tag, V>

            static var name: Path<String> { .init() }

            static var count: Path<Int?> { .init() }

            static var _fragment: FragmentPath<Tag> { .init() }
        }

        enum InstrumentConnection: Target, Connection {
            typealias Node = Music.Instrument
            typealias Path<V> = GraphQLPath<InstrumentConnection, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<InstrumentConnection, V>

            static var pageInfo: FragmentPath<Music.PageInfo> { .init() }

            static var edges: FragmentPath<[Music.InstrumentEdge?]?> { .init() }

            static var nodes: FragmentPath<[Music.Instrument?]?> { .init() }

            static var totalCount: Path<Int?> { .init() }

            static var _fragment: FragmentPath<InstrumentConnection> { .init() }
        }

        enum InstrumentEdge: Target {
            typealias Path<V> = GraphQLPath<InstrumentEdge, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<InstrumentEdge, V>

            static var node: FragmentPath<Music.Instrument?> { .init() }

            static var cursor: Path<String> { .init() }

            static var score: Path<Int?> { .init() }

            static var _fragment: FragmentPath<InstrumentEdge> { .init() }
        }

        enum Instrument: Target {
            typealias Path<V> = GraphQLPath<Instrument, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<Instrument, V>

            static var id: Path<String> { .init() }

            static var mbid: Path<String> { .init() }

            static var name: Path<String?> { .init() }

            static var disambiguation: Path<String?> { .init() }

            static var aliases: FragmentPath<[Music.Alias?]?> { .init() }

            static var description: Path<String?> { .init() }

            static var type: Path<String?> { .init() }

            static var typeId: Path<String?> { .init() }

            static var relationships: FragmentPath<Music.Relationships?> { .init() }

            static func collections(after _: GraphQLArgument<String?> = .argument,
                                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
                return .init()
            }

            static var collections: FragmentPath<Music.CollectionConnection?> { .init() }

            static func tags(after _: GraphQLArgument<String?> = .argument,
                             first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
                return .init()
            }

            static var tags: FragmentPath<Music.TagConnection?> { .init() }

            static func mediaWikiImages(type _: GraphQLArgument<String?> = .argument) -> FragmentPath<[Music.MediaWikiImage?]> {
                return .init()
            }

            static var mediaWikiImages: FragmentPath<[Music.MediaWikiImage?]> { .init() }

            static var node: FragmentPath<Node> { .init() }

            static var entity: FragmentPath<Entity> { .init() }

            static var _fragment: FragmentPath<Instrument> { .init() }
        }

        enum MediaWikiImage: Target {
            typealias Path<V> = GraphQLPath<MediaWikiImage, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<MediaWikiImage, V>

            static var url: Path<String> { .init() }

            static var descriptionUrl: Path<String?> { .init() }

            static var user: Path<String?> { .init() }

            static var size: Path<Int?> { .init() }

            static var width: Path<Int?> { .init() }

            static var height: Path<Int?> { .init() }

            static var canonicalTitle: Path<String?> { .init() }

            static var objectName: Path<String?> { .init() }

            static var descriptionHtml: Path<String?> { .init() }

            static var originalDateTimeHtml: Path<String?> { .init() }

            static var categories: Path<[String?]> { .init() }

            static var artistHtml: Path<String?> { .init() }

            static var creditHtml: Path<String?> { .init() }

            static var licenseShortName: Path<String?> { .init() }

            static var licenseUrl: Path<String?> { .init() }

            static var metadata: FragmentPath<[Music.MediaWikiImageMetadata?]> { .init() }

            static var _fragment: FragmentPath<MediaWikiImage> { .init() }
        }

        enum MediaWikiImageMetadata: Target {
            typealias Path<V> = GraphQLPath<MediaWikiImageMetadata, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<MediaWikiImageMetadata, V>

            static var name: Path<String> { .init() }

            static var value: Path<String?> { .init() }

            static var source: Path<String?> { .init() }

            static var _fragment: FragmentPath<MediaWikiImageMetadata> { .init() }
        }

        enum PlaceConnection: Target, Connection {
            typealias Node = Music.Place
            typealias Path<V> = GraphQLPath<PlaceConnection, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<PlaceConnection, V>

            static var pageInfo: FragmentPath<Music.PageInfo> { .init() }

            static var edges: FragmentPath<[Music.PlaceEdge?]?> { .init() }

            static var nodes: FragmentPath<[Music.Place?]?> { .init() }

            static var totalCount: Path<Int?> { .init() }

            static var _fragment: FragmentPath<PlaceConnection> { .init() }
        }

        enum PlaceEdge: Target {
            typealias Path<V> = GraphQLPath<PlaceEdge, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<PlaceEdge, V>

            static var node: FragmentPath<Music.Place?> { .init() }

            static var cursor: Path<String> { .init() }

            static var score: Path<Int?> { .init() }

            static var _fragment: FragmentPath<PlaceEdge> { .init() }
        }

        enum Place: Target {
            typealias Path<V> = GraphQLPath<Place, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<Place, V>

            static var id: Path<String> { .init() }

            static var mbid: Path<String> { .init() }

            static var name: Path<String?> { .init() }

            static var disambiguation: Path<String?> { .init() }

            static var aliases: FragmentPath<[Music.Alias?]?> { .init() }

            static var address: Path<String?> { .init() }

            static var area: FragmentPath<Music.Area?> { .init() }

            static var coordinates: FragmentPath<Music.Coordinates?> { .init() }

            static var lifeSpan: FragmentPath<Music.LifeSpan?> { .init() }

            static var type: Path<String?> { .init() }

            static var typeId: Path<String?> { .init() }

            static func events(after _: GraphQLArgument<String?> = .argument,
                               first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.EventConnection?> {
                return .init()
            }

            static var events: FragmentPath<Music.EventConnection?> { .init() }

            static var relationships: FragmentPath<Music.Relationships?> { .init() }

            static func collections(after _: GraphQLArgument<String?> = .argument,
                                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
                return .init()
            }

            static var collections: FragmentPath<Music.CollectionConnection?> { .init() }

            static func tags(after _: GraphQLArgument<String?> = .argument,
                             first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
                return .init()
            }

            static var tags: FragmentPath<Music.TagConnection?> { .init() }

            static func mediaWikiImages(type _: GraphQLArgument<String?> = .argument) -> FragmentPath<[Music.MediaWikiImage?]> {
                return .init()
            }

            static var mediaWikiImages: FragmentPath<[Music.MediaWikiImage?]> { .init() }

            static var node: FragmentPath<Node> { .init() }

            static var entity: FragmentPath<Entity> { .init() }

            static var _fragment: FragmentPath<Place> { .init() }
        }

        enum Coordinates: Target {
            typealias Path<V> = GraphQLPath<Coordinates, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<Coordinates, V>

            static var latitude: Path<String?> { .init() }

            static var longitude: Path<String?> { .init() }

            static var _fragment: FragmentPath<Coordinates> { .init() }
        }

        enum ReleaseGroupConnection: Target, Connection {
            typealias Node = Music.ReleaseGroup
            typealias Path<V> = GraphQLPath<ReleaseGroupConnection, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<ReleaseGroupConnection, V>

            static var pageInfo: FragmentPath<Music.PageInfo> { .init() }

            static var edges: FragmentPath<[Music.ReleaseGroupEdge?]?> { .init() }

            static var nodes: FragmentPath<[Music.ReleaseGroup?]?> { .init() }

            static var totalCount: Path<Int?> { .init() }

            static var _fragment: FragmentPath<ReleaseGroupConnection> { .init() }
        }

        enum ReleaseGroupEdge: Target {
            typealias Path<V> = GraphQLPath<ReleaseGroupEdge, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<ReleaseGroupEdge, V>

            static var node: FragmentPath<Music.ReleaseGroup?> { .init() }

            static var cursor: Path<String> { .init() }

            static var score: Path<Int?> { .init() }

            static var _fragment: FragmentPath<ReleaseGroupEdge> { .init() }
        }

        enum ReleaseGroup: Target {
            typealias Path<V> = GraphQLPath<ReleaseGroup, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<ReleaseGroup, V>

            static var id: Path<String> { .init() }

            static var mbid: Path<String> { .init() }

            static var title: Path<String?> { .init() }

            static var disambiguation: Path<String?> { .init() }

            static var aliases: FragmentPath<[Music.Alias?]?> { .init() }

            static var artistCredit: FragmentPath<[Music.ArtistCredit?]?> { .init() }

            static var artistCredits: FragmentPath<[Music.ArtistCredit?]?> { .init() }

            static var firstReleaseDate: Path<String?> { .init() }

            static var primaryType: Path<Music.ReleaseGroupType?> { .init() }

            static var primaryTypeId: Path<String?> { .init() }

            static var secondaryTypes: Path<[Music.ReleaseGroupType?]?> { .init() }

            static var secondaryTypeIDs: Path<[String?]?> { .init() }

            static func artists(after _: GraphQLArgument<String?> = .argument,
                                first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
                return .init()
            }

            static var artists: FragmentPath<Music.ArtistConnection?> { .init() }

            static func releases(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                                 status _: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument,
                                 after _: GraphQLArgument<String?> = .argument,
                                 first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
                return .init()
            }

            static var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

            static var relationships: FragmentPath<Music.Relationships?> { .init() }

            static func collections(after _: GraphQLArgument<String?> = .argument,
                                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
                return .init()
            }

            static var collections: FragmentPath<Music.CollectionConnection?> { .init() }

            static var rating: FragmentPath<Music.Rating?> { .init() }

            static func tags(after _: GraphQLArgument<String?> = .argument,
                             first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
                return .init()
            }

            static var tags: FragmentPath<Music.TagConnection?> { .init() }

            static var coverArtArchive: FragmentPath<Music.CoverArtArchiveRelease?> { .init() }

            static var fanArt: FragmentPath<Music.FanArtAlbum?> { .init() }

            static var theAudioDb: FragmentPath<Music.TheAudioDbAlbum?> { .init() }

            static var discogs: FragmentPath<Music.DiscogsMaster?> { .init() }

            static var node: FragmentPath<Node> { .init() }

            static var entity: FragmentPath<Entity> { .init() }

            static var _fragment: FragmentPath<ReleaseGroup> { .init() }
        }

        enum CoverArtArchiveRelease: Target {
            typealias Path<V> = GraphQLPath<CoverArtArchiveRelease, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<CoverArtArchiveRelease, V>

            static func front(size _: GraphQLArgument<Music.CoverArtArchiveImageSize?> = .argument) -> Path<String?> {
                return .init()
            }

            static var front: Path<String?> { .init() }

            static func back(size _: GraphQLArgument<Music.CoverArtArchiveImageSize?> = .argument) -> Path<String?> {
                return .init()
            }

            static var back: Path<String?> { .init() }

            static var images: FragmentPath<[Music.CoverArtArchiveImage?]> { .init() }

            static var artwork: Path<Bool> { .init() }

            static var count: Path<Int> { .init() }

            static var release: FragmentPath<Music.Release?> { .init() }

            static var _fragment: FragmentPath<CoverArtArchiveRelease> { .init() }
        }

        typealias CoverArtArchiveImageSize = ApolloMusic.CoverArtArchiveImageSize

        enum CoverArtArchiveImage: Target {
            typealias Path<V> = GraphQLPath<CoverArtArchiveImage, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<CoverArtArchiveImage, V>

            static var fileId: Path<String> { .init() }

            static var image: Path<String> { .init() }

            static var thumbnails: FragmentPath<Music.CoverArtArchiveImageThumbnails> { .init() }

            static var front: Path<Bool> { .init() }

            static var back: Path<Bool> { .init() }

            static var types: Path<[String?]> { .init() }

            static var edit: Path<Int?> { .init() }

            static var approved: Path<Bool?> { .init() }

            static var comment: Path<String?> { .init() }

            static var _fragment: FragmentPath<CoverArtArchiveImage> { .init() }
        }

        enum CoverArtArchiveImageThumbnails: Target {
            typealias Path<V> = GraphQLPath<CoverArtArchiveImageThumbnails, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<CoverArtArchiveImageThumbnails, V>

            static var small: Path<String?> { .init() }

            static var large: Path<String?> { .init() }

            static var _fragment: FragmentPath<CoverArtArchiveImageThumbnails> { .init() }
        }

        enum FanArtAlbum: Target {
            typealias Path<V> = GraphQLPath<FanArtAlbum, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<FanArtAlbum, V>

            static var albumCovers: FragmentPath<[Music.FanArtImage?]?> { .init() }

            static var discImages: FragmentPath<[Music.FanArtDiscImage?]?> { .init() }

            static var _fragment: FragmentPath<FanArtAlbum> { .init() }
        }

        enum FanArtImage: Target {
            typealias Path<V> = GraphQLPath<FanArtImage, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<FanArtImage, V>

            static var imageId: Path<String?> { .init() }

            static func url(size _: GraphQLArgument<Music.FanArtImageSize?> = .argument) -> Path<String?> {
                return .init()
            }

            static var url: Path<String?> { .init() }

            static var likeCount: Path<Int?> { .init() }

            static var _fragment: FragmentPath<FanArtImage> { .init() }
        }

        enum FanArtImageSize: String, Target {
            typealias Path<V> = GraphQLPath<FanArtImageSize, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<FanArtImageSize, V>

            case full = "FULL"

            case preview = "PREVIEW"

            static var _fragment: FragmentPath<FanArtImageSize> { .init() }
        }

        enum FanArtDiscImage: Target {
            typealias Path<V> = GraphQLPath<FanArtDiscImage, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<FanArtDiscImage, V>

            static var imageId: Path<String?> { .init() }

            static func url(size _: GraphQLArgument<Music.FanArtImageSize?> = .argument) -> Path<String?> {
                return .init()
            }

            static var url: Path<String?> { .init() }

            static var likeCount: Path<Int?> { .init() }

            static var discNumber: Path<Int?> { .init() }

            static var size: Path<Int?> { .init() }

            static var _fragment: FragmentPath<FanArtDiscImage> { .init() }
        }

        enum TheAudioDbAlbum: Target {
            typealias Path<V> = GraphQLPath<TheAudioDbAlbum, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<TheAudioDbAlbum, V>

            static var albumId: Path<String?> { .init() }

            static var artistId: Path<String?> { .init() }

            static func description(lang _: GraphQLArgument<String?> = .argument) -> Path<String?> {
                return .init()
            }

            static var description: Path<String?> { .init() }

            static var review: Path<String?> { .init() }

            static var salesCount: Path<Double?> { .init() }

            static var score: Path<Double?> { .init() }

            static var scoreVotes: Path<Double?> { .init() }

            static func discImage(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
                return .init()
            }

            static var discImage: Path<String?> { .init() }

            static func spineImage(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
                return .init()
            }

            static var spineImage: Path<String?> { .init() }

            static func frontImage(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
                return .init()
            }

            static var frontImage: Path<String?> { .init() }

            static func backImage(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
                return .init()
            }

            static var backImage: Path<String?> { .init() }

            static var genre: Path<String?> { .init() }

            static var mood: Path<String?> { .init() }

            static var style: Path<String?> { .init() }

            static var speed: Path<String?> { .init() }

            static var theme: Path<String?> { .init() }

            static var _fragment: FragmentPath<TheAudioDbAlbum> { .init() }
        }

        typealias TheAudioDbImageSize = ApolloMusic.TheAudioDBImageSize

        enum DiscogsMaster: Target {
            typealias Path<V> = GraphQLPath<DiscogsMaster, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<DiscogsMaster, V>

            static var masterId: Path<String> { .init() }

            static var title: Path<String> { .init() }

            static var url: Path<String> { .init() }

            static var artistCredits: FragmentPath<[Music.DiscogsArtistCredit]> { .init() }

            static var genres: Path<[String]> { .init() }

            static var styles: Path<[String]> { .init() }

            static var forSaleCount: Path<Int?> { .init() }

            static func lowestPrice(currency _: GraphQLArgument<String?> = .argument) -> Path<Double?> {
                return .init()
            }

            static var lowestPrice: Path<Double?> { .init() }

            static var year: Path<Int?> { .init() }

            static var mainRelease: FragmentPath<Music.DiscogsRelease?> { .init() }

            static var images: FragmentPath<[Music.DiscogsImage]> { .init() }

            static var videos: FragmentPath<[Music.DiscogsVideo]> { .init() }

            static var dataQuality: Path<String?> { .init() }

            static var _fragment: FragmentPath<DiscogsMaster> { .init() }
        }

        enum DiscogsArtistCredit: Target {
            typealias Path<V> = GraphQLPath<DiscogsArtistCredit, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<DiscogsArtistCredit, V>

            static var name: Path<String?> { .init() }

            static var nameVariation: Path<String?> { .init() }

            static var joinPhrase: Path<String?> { .init() }

            static var roles: Path<[String]> { .init() }

            static var tracks: Path<[String]> { .init() }

            static var artist: FragmentPath<Music.DiscogsArtist?> { .init() }

            static var _fragment: FragmentPath<DiscogsArtistCredit> { .init() }
        }

        enum DiscogsArtist: Target {
            typealias Path<V> = GraphQLPath<DiscogsArtist, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<DiscogsArtist, V>

            static var artistId: Path<String> { .init() }

            static var name: Path<String> { .init() }

            static var nameVariations: Path<[String]> { .init() }

            static var realName: Path<String?> { .init() }

            static var aliases: FragmentPath<[Music.DiscogsArtist]> { .init() }

            static var url: Path<String> { .init() }

            static var urls: Path<[String]> { .init() }

            static var profile: Path<String?> { .init() }

            static var images: FragmentPath<[Music.DiscogsImage]> { .init() }

            static var members: FragmentPath<[Music.DiscogsArtistMember]> { .init() }

            static var dataQuality: Path<String?> { .init() }

            static var _fragment: FragmentPath<DiscogsArtist> { .init() }
        }

        enum DiscogsImage: Target {
            typealias Path<V> = GraphQLPath<DiscogsImage, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<DiscogsImage, V>

            static var url: Path<String> { .init() }

            static var type: Path<Music.DiscogsImageType> { .init() }

            static var width: Path<Int> { .init() }

            static var height: Path<Int> { .init() }

            static var thumbnail: Path<String?> { .init() }

            static var _fragment: FragmentPath<DiscogsImage> { .init() }
        }

        enum DiscogsImageType: String, Target {
            typealias Path<V> = GraphQLPath<DiscogsImageType, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<DiscogsImageType, V>

            case primary = "PRIMARY"

            case secondary = "SECONDARY"

            static var _fragment: FragmentPath<DiscogsImageType> { .init() }
        }

        enum DiscogsArtistMember: Target {
            typealias Path<V> = GraphQLPath<DiscogsArtistMember, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<DiscogsArtistMember, V>

            static var active: Path<Bool?> { .init() }

            static var name: Path<String> { .init() }

            static var artist: FragmentPath<Music.DiscogsArtist?> { .init() }

            static var _fragment: FragmentPath<DiscogsArtistMember> { .init() }
        }

        enum DiscogsRelease: Target {
            typealias Path<V> = GraphQLPath<DiscogsRelease, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<DiscogsRelease, V>

            static var releaseId: Path<String> { .init() }

            static var title: Path<String> { .init() }

            static var url: Path<String> { .init() }

            static var artistCredits: FragmentPath<[Music.DiscogsArtistCredit]> { .init() }

            static var extraArtistCredits: FragmentPath<[Music.DiscogsArtistCredit]> { .init() }

            static var genres: Path<[String]> { .init() }

            static var styles: Path<[String]> { .init() }

            static var forSaleCount: Path<Int?> { .init() }

            static func lowestPrice(currency _: GraphQLArgument<String?> = .argument) -> Path<Double?> {
                return .init()
            }

            static var lowestPrice: Path<Double?> { .init() }

            static var year: Path<Int?> { .init() }

            static var notes: Path<String?> { .init() }

            static var country: Path<String?> { .init() }

            static var master: FragmentPath<Music.DiscogsMaster?> { .init() }

            static var thumbnail: Path<String?> { .init() }

            static var images: FragmentPath<[Music.DiscogsImage]> { .init() }

            static var videos: FragmentPath<[Music.DiscogsVideo]> { .init() }

            static var community: FragmentPath<Music.DiscogsCommunity?> { .init() }

            static var dataQuality: Path<String?> { .init() }

            static var _fragment: FragmentPath<DiscogsRelease> { .init() }
        }

        enum DiscogsVideo: Target {
            typealias Path<V> = GraphQLPath<DiscogsVideo, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<DiscogsVideo, V>

            static var url: Path<String> { .init() }

            static var title: Path<String?> { .init() }

            static var description: Path<String?> { .init() }

            static var duration: Path<String?> { .init() }

            static var embed: Path<Bool?> { .init() }

            static var _fragment: FragmentPath<DiscogsVideo> { .init() }
        }

        enum DiscogsCommunity: Target {
            typealias Path<V> = GraphQLPath<DiscogsCommunity, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<DiscogsCommunity, V>

            static var status: Path<String?> { .init() }

            static var rating: FragmentPath<Music.DiscogsRating?> { .init() }

            static var haveCount: Path<Int?> { .init() }

            static var wantCount: Path<Int?> { .init() }

            static var contributors: FragmentPath<[Music.DiscogsUser]> { .init() }

            static var submitter: FragmentPath<Music.DiscogsUser?> { .init() }

            static var _fragment: FragmentPath<DiscogsCommunity> { .init() }
        }

        enum DiscogsRating: Target {
            typealias Path<V> = GraphQLPath<DiscogsRating, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<DiscogsRating, V>

            static var voteCount: Path<Int> { .init() }

            static var value: Path<Double?> { .init() }

            static var _fragment: FragmentPath<DiscogsRating> { .init() }
        }

        enum DiscogsUser: Target {
            typealias Path<V> = GraphQLPath<DiscogsUser, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<DiscogsUser, V>

            static var username: Path<String> { .init() }

            static var _fragment: FragmentPath<DiscogsUser> { .init() }
        }

        enum SeriesConnection: Target, Connection {
            typealias Node = Music.Series
            typealias Path<V> = GraphQLPath<SeriesConnection, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<SeriesConnection, V>

            static var pageInfo: FragmentPath<Music.PageInfo> { .init() }

            static var edges: FragmentPath<[Music.SeriesEdge?]?> { .init() }

            static var nodes: FragmentPath<[Music.Series?]?> { .init() }

            static var totalCount: Path<Int?> { .init() }

            static var _fragment: FragmentPath<SeriesConnection> { .init() }
        }

        enum SeriesEdge: Target {
            typealias Path<V> = GraphQLPath<SeriesEdge, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<SeriesEdge, V>

            static var node: FragmentPath<Music.Series?> { .init() }

            static var cursor: Path<String> { .init() }

            static var score: Path<Int?> { .init() }

            static var _fragment: FragmentPath<SeriesEdge> { .init() }
        }

        enum Series: Target {
            typealias Path<V> = GraphQLPath<Series, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<Series, V>

            static var id: Path<String> { .init() }

            static var mbid: Path<String> { .init() }

            static var name: Path<String?> { .init() }

            static var disambiguation: Path<String?> { .init() }

            static var type: Path<String?> { .init() }

            static var typeId: Path<String?> { .init() }

            static var relationships: FragmentPath<Music.Relationships?> { .init() }

            static func collections(after _: GraphQLArgument<String?> = .argument,
                                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
                return .init()
            }

            static var collections: FragmentPath<Music.CollectionConnection?> { .init() }

            static func tags(after _: GraphQLArgument<String?> = .argument,
                             first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
                return .init()
            }

            static var tags: FragmentPath<Music.TagConnection?> { .init() }

            static var node: FragmentPath<Node> { .init() }

            static var entity: FragmentPath<Entity> { .init() }

            static var _fragment: FragmentPath<Series> { .init() }
        }

        enum WorkConnection: Target, Connection {
            typealias Node = Music.Work
            typealias Path<V> = GraphQLPath<WorkConnection, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<WorkConnection, V>

            static var pageInfo: FragmentPath<Music.PageInfo> { .init() }

            static var edges: FragmentPath<[Music.WorkEdge?]?> { .init() }

            static var nodes: FragmentPath<[Music.Work?]?> { .init() }

            static var totalCount: Path<Int?> { .init() }

            static var _fragment: FragmentPath<WorkConnection> { .init() }
        }

        enum WorkEdge: Target {
            typealias Path<V> = GraphQLPath<WorkEdge, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<WorkEdge, V>

            static var node: FragmentPath<Music.Work?> { .init() }

            static var cursor: Path<String> { .init() }

            static var score: Path<Int?> { .init() }

            static var _fragment: FragmentPath<WorkEdge> { .init() }
        }

        enum Work: Target {
            typealias Path<V> = GraphQLPath<Work, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<Work, V>

            static var id: Path<String> { .init() }

            static var mbid: Path<String> { .init() }

            static var title: Path<String?> { .init() }

            static var disambiguation: Path<String?> { .init() }

            static var aliases: FragmentPath<[Music.Alias?]?> { .init() }

            static var iswcs: Path<[String?]?> { .init() }

            static var language: Path<String?> { .init() }

            static var type: Path<String?> { .init() }

            static var typeId: Path<String?> { .init() }

            static func artists(after _: GraphQLArgument<String?> = .argument,
                                first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
                return .init()
            }

            static var artists: FragmentPath<Music.ArtistConnection?> { .init() }

            static var relationships: FragmentPath<Music.Relationships?> { .init() }

            static func collections(after _: GraphQLArgument<String?> = .argument,
                                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
                return .init()
            }

            static var collections: FragmentPath<Music.CollectionConnection?> { .init() }

            static var rating: FragmentPath<Music.Rating?> { .init() }

            static func tags(after _: GraphQLArgument<String?> = .argument,
                             first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
                return .init()
            }

            static var tags: FragmentPath<Music.TagConnection?> { .init() }

            static var node: FragmentPath<Node> { .init() }

            static var entity: FragmentPath<Entity> { .init() }

            static var _fragment: FragmentPath<Work> { .init() }
        }

        enum FanArtLabel: Target {
            typealias Path<V> = GraphQLPath<FanArtLabel, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<FanArtLabel, V>

            static var logos: FragmentPath<[Music.FanArtLabelImage?]?> { .init() }

            static var _fragment: FragmentPath<FanArtLabel> { .init() }
        }

        enum FanArtLabelImage: Target {
            typealias Path<V> = GraphQLPath<FanArtLabelImage, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<FanArtLabelImage, V>

            static var imageId: Path<String?> { .init() }

            static func url(size _: GraphQLArgument<Music.FanArtImageSize?> = .argument) -> Path<String?> {
                return .init()
            }

            static var url: Path<String?> { .init() }

            static var likeCount: Path<Int?> { .init() }

            static var color: Path<String?> { .init() }

            static var _fragment: FragmentPath<FanArtLabelImage> { .init() }
        }

        enum DiscogsLabel: Target {
            typealias Path<V> = GraphQLPath<DiscogsLabel, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<DiscogsLabel, V>

            static var labelId: Path<String> { .init() }

            static var name: Path<String> { .init() }

            static var url: Path<String> { .init() }

            static var profile: Path<String?> { .init() }

            static var contactInfo: Path<String?> { .init() }

            static var parentLabel: FragmentPath<Music.DiscogsLabel?> { .init() }

            static var subLabels: FragmentPath<[Music.DiscogsLabel]> { .init() }

            static var images: FragmentPath<[Music.DiscogsImage]> { .init() }

            static var dataQuality: Path<String?> { .init() }

            static var _fragment: FragmentPath<DiscogsLabel> { .init() }
        }

        enum LastFmAlbum: Target {
            typealias Path<V> = GraphQLPath<LastFmAlbum, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<LastFmAlbum, V>

            static var mbid: Path<String?> { .init() }

            static var title: Path<String?> { .init() }

            static var url: Path<String> { .init() }

            static func image(size _: GraphQLArgument<Music.LastFmImageSize?> = .argument) -> Path<String?> {
                return .init()
            }

            static var image: Path<String?> { .init() }

            static var listenerCount: Path<Double?> { .init() }

            static var playCount: Path<Double?> { .init() }

            static func description(lang _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmWikiContent?> {
                return .init()
            }

            static var description: FragmentPath<Music.LastFmWikiContent?> { .init() }

            static var artist: FragmentPath<Music.LastFmArtist?> { .init() }

            static func topTags(first _: GraphQLArgument<Int?> = .argument,
                                after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTagConnection?> {
                return .init()
            }

            static var topTags: FragmentPath<Music.LastFmTagConnection?> { .init() }

            static var _fragment: FragmentPath<LastFmAlbum> { .init() }
        }

        typealias LastFmImageSize = ApolloMusic.LastFMImageSize

        enum LastFmWikiContent: Target {
            typealias Path<V> = GraphQLPath<LastFmWikiContent, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<LastFmWikiContent, V>

            static var summaryHtml: Path<String?> { .init() }

            static var contentHtml: Path<String?> { .init() }

            static var publishDate: Path<String?> { .init() }

            static var publishTime: Path<String?> { .init() }

            static var url: Path<String?> { .init() }

            static var _fragment: FragmentPath<LastFmWikiContent> { .init() }
        }

        enum LastFmArtist: Target {
            typealias Path<V> = GraphQLPath<LastFmArtist, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<LastFmArtist, V>

            static var mbid: Path<String?> { .init() }

            static var name: Path<String?> { .init() }

            static var url: Path<String> { .init() }

            static func image(size _: GraphQLArgument<Music.LastFmImageSize?> = .argument) -> Path<String?> {
                return .init()
            }

            static var image: Path<String?> { .init() }

            static var listenerCount: Path<Double?> { .init() }

            static var playCount: Path<Double?> { .init() }

            static func similarArtists(first _: GraphQLArgument<Int?> = .argument,
                                       after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmArtistConnection?> {
                return .init()
            }

            static var similarArtists: FragmentPath<Music.LastFmArtistConnection?> { .init() }

            static func topAlbums(first _: GraphQLArgument<Int?> = .argument,
                                  after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmAlbumConnection?> {
                return .init()
            }

            static var topAlbums: FragmentPath<Music.LastFmAlbumConnection?> { .init() }

            static func topTags(first _: GraphQLArgument<Int?> = .argument,
                                after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTagConnection?> {
                return .init()
            }

            static var topTags: FragmentPath<Music.LastFmTagConnection?> { .init() }

            static func topTracks(first _: GraphQLArgument<Int?> = .argument,
                                  after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTrackConnection?> {
                return .init()
            }

            static var topTracks: FragmentPath<Music.LastFmTrackConnection?> { .init() }

            static func biography(lang _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmWikiContent?> {
                return .init()
            }

            static var biography: FragmentPath<Music.LastFmWikiContent?> { .init() }

            static var _fragment: FragmentPath<LastFmArtist> { .init() }
        }

        enum LastFmArtistConnection: Target, Connection {
            typealias Node = Music.LastFmArtist
            typealias Path<V> = GraphQLPath<LastFmArtistConnection, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<LastFmArtistConnection, V>

            static var pageInfo: FragmentPath<Music.PageInfo> { .init() }

            static var edges: FragmentPath<[Music.LastFmArtistEdge?]?> { .init() }

            static var nodes: FragmentPath<[Music.LastFmArtist?]?> { .init() }

            static var totalCount: Path<Int?> { .init() }

            static var _fragment: FragmentPath<LastFmArtistConnection> { .init() }
        }

        enum LastFmArtistEdge: Target {
            typealias Path<V> = GraphQLPath<LastFmArtistEdge, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<LastFmArtistEdge, V>

            static var node: FragmentPath<Music.LastFmArtist?> { .init() }

            static var cursor: Path<String> { .init() }

            static var matchScore: Path<Double?> { .init() }

            static var _fragment: FragmentPath<LastFmArtistEdge> { .init() }
        }

        enum LastFmAlbumConnection: Target, Connection {
            typealias Node = Music.LastFmAlbum
            typealias Path<V> = GraphQLPath<LastFmAlbumConnection, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<LastFmAlbumConnection, V>

            static var pageInfo: FragmentPath<Music.PageInfo> { .init() }

            static var edges: FragmentPath<[Music.LastFmAlbumEdge?]?> { .init() }

            static var nodes: FragmentPath<[Music.LastFmAlbum?]?> { .init() }

            static var totalCount: Path<Int?> { .init() }

            static var _fragment: FragmentPath<LastFmAlbumConnection> { .init() }
        }

        enum LastFmAlbumEdge: Target {
            typealias Path<V> = GraphQLPath<LastFmAlbumEdge, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<LastFmAlbumEdge, V>

            static var node: FragmentPath<Music.LastFmAlbum?> { .init() }

            static var cursor: Path<String> { .init() }

            static var _fragment: FragmentPath<LastFmAlbumEdge> { .init() }
        }

        enum LastFmTagConnection: Target, Connection {
            typealias Node = Music.LastFmTag
            typealias Path<V> = GraphQLPath<LastFmTagConnection, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<LastFmTagConnection, V>

            static var pageInfo: FragmentPath<Music.PageInfo> { .init() }

            static var edges: FragmentPath<[Music.LastFmTagEdge?]?> { .init() }

            static var nodes: FragmentPath<[Music.LastFmTag?]?> { .init() }

            static var totalCount: Path<Int?> { .init() }

            static var _fragment: FragmentPath<LastFmTagConnection> { .init() }
        }

        enum LastFmTagEdge: Target {
            typealias Path<V> = GraphQLPath<LastFmTagEdge, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<LastFmTagEdge, V>

            static var node: FragmentPath<Music.LastFmTag?> { .init() }

            static var cursor: Path<String> { .init() }

            static var tagCount: Path<Int?> { .init() }

            static var _fragment: FragmentPath<LastFmTagEdge> { .init() }
        }

        enum LastFmTag: Target {
            typealias Path<V> = GraphQLPath<LastFmTag, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<LastFmTag, V>

            static var name: Path<String> { .init() }

            static var url: Path<String> { .init() }

            static var _fragment: FragmentPath<LastFmTag> { .init() }
        }

        enum LastFmTrackConnection: Target, Connection {
            typealias Node = Music.LastFmTrack
            typealias Path<V> = GraphQLPath<LastFmTrackConnection, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<LastFmTrackConnection, V>

            static var pageInfo: FragmentPath<Music.PageInfo> { .init() }

            static var edges: FragmentPath<[Music.LastFmTrackEdge?]?> { .init() }

            static var nodes: FragmentPath<[Music.LastFmTrack?]?> { .init() }

            static var totalCount: Path<Int?> { .init() }

            static var _fragment: FragmentPath<LastFmTrackConnection> { .init() }
        }

        enum LastFmTrackEdge: Target {
            typealias Path<V> = GraphQLPath<LastFmTrackEdge, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<LastFmTrackEdge, V>

            static var node: FragmentPath<Music.LastFmTrack?> { .init() }

            static var cursor: Path<String> { .init() }

            static var matchScore: Path<Double?> { .init() }

            static var _fragment: FragmentPath<LastFmTrackEdge> { .init() }
        }

        enum LastFmTrack: Target {
            typealias Path<V> = GraphQLPath<LastFmTrack, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<LastFmTrack, V>

            static var mbid: Path<String?> { .init() }

            static var title: Path<String?> { .init() }

            static var url: Path<String> { .init() }

            static var duration: Path<String?> { .init() }

            static var listenerCount: Path<Double?> { .init() }

            static var playCount: Path<Double?> { .init() }

            static func description(lang _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmWikiContent?> {
                return .init()
            }

            static var description: FragmentPath<Music.LastFmWikiContent?> { .init() }

            static var artist: FragmentPath<Music.LastFmArtist?> { .init() }

            static var album: FragmentPath<Music.LastFmAlbum?> { .init() }

            static func similarTracks(first _: GraphQLArgument<Int?> = .argument,
                                      after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTrackConnection?> {
                return .init()
            }

            static var similarTracks: FragmentPath<Music.LastFmTrackConnection?> { .init() }

            static func topTags(first _: GraphQLArgument<Int?> = .argument,
                                after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTagConnection?> {
                return .init()
            }

            static var topTags: FragmentPath<Music.LastFmTagConnection?> { .init() }

            static var _fragment: FragmentPath<LastFmTrack> { .init() }
        }

        enum SpotifyMatchStrategy: String, Target {
            typealias Path<V> = GraphQLPath<SpotifyMatchStrategy, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<SpotifyMatchStrategy, V>

            case url = "URL"

            case externalid = "EXTERNALID"

            static var _fragment: FragmentPath<SpotifyMatchStrategy> { .init() }
        }

        enum SpotifyAlbum: Target {
            typealias Path<V> = GraphQLPath<SpotifyAlbum, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<SpotifyAlbum, V>

            static var albumId: Path<String> { .init() }

            static var uri: Path<String> { .init() }

            static var href: Path<String> { .init() }

            static var title: Path<String?> { .init() }

            static var albumType: Path<Music.ReleaseGroupType> { .init() }

            static var artists: FragmentPath<[Music.SpotifyArtist]> { .init() }

            static var availableMarkets: Path<[String]> { .init() }

            static var copyrights: FragmentPath<[Music.SpotifyCopyright]> { .init() }

            static var externalIDs: FragmentPath<[Music.SpotifyExternalId]> { .init() }

            static var externalUrLs: FragmentPath<[Music.SpotifyExternalUrl]> { .init() }

            static var genres: Path<[String]> { .init() }

            static var images: FragmentPath<[Music.SpotifyImage]> { .init() }

            static var label: Path<String?> { .init() }

            static var popularity: Path<Int> { .init() }

            static var releaseDate: Path<String?> { .init() }

            static var _fragment: FragmentPath<SpotifyAlbum> { .init() }
        }

        enum SpotifyArtist: Target {
            typealias Path<V> = GraphQLPath<SpotifyArtist, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<SpotifyArtist, V>

            static var artistId: Path<String> { .init() }

            static var uri: Path<String> { .init() }

            static var href: Path<String> { .init() }

            static var name: Path<String> { .init() }

            static var externalUrLs: FragmentPath<[Music.SpotifyExternalUrl]> { .init() }

            static var genres: Path<[String]> { .init() }

            static var popularity: Path<Int> { .init() }

            static var images: FragmentPath<[Music.SpotifyImage]> { .init() }

            static func topTracks(market _: GraphQLArgument<String> = .argument) -> FragmentPath<[Music.SpotifyTrack]> {
                return .init()
            }

            static var topTracks: FragmentPath<[Music.SpotifyTrack]> { .init() }

            static var relatedArtists: FragmentPath<[Music.SpotifyArtist]> { .init() }

            static var _fragment: FragmentPath<SpotifyArtist> { .init() }
        }

        enum SpotifyExternalUrl: Target {
            typealias Path<V> = GraphQLPath<SpotifyExternalUrl, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<SpotifyExternalUrl, V>

            static var type: Path<String> { .init() }

            static var url: Path<String> { .init() }

            static var _fragment: FragmentPath<SpotifyExternalUrl> { .init() }
        }

        enum SpotifyImage: Target {
            typealias Path<V> = GraphQLPath<SpotifyImage, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<SpotifyImage, V>

            static var url: Path<String> { .init() }

            static var width: Path<Int?> { .init() }

            static var height: Path<Int?> { .init() }

            static var _fragment: FragmentPath<SpotifyImage> { .init() }
        }

        enum SpotifyTrack: Target {
            typealias Path<V> = GraphQLPath<SpotifyTrack, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<SpotifyTrack, V>

            static var trackId: Path<String> { .init() }

            static var uri: Path<String> { .init() }

            static var href: Path<String> { .init() }

            static var title: Path<String> { .init() }

            static var audioFeatures: FragmentPath<Music.SpotifyAudioFeatures?> { .init() }

            static var album: FragmentPath<Music.SpotifyAlbum?> { .init() }

            static var artists: FragmentPath<[Music.SpotifyArtist]> { .init() }

            static var availableMarkets: Path<[String]> { .init() }

            static var discNumber: Path<Int> { .init() }

            static var duration: Path<String> { .init() }

            static var explicit: Path<Bool?> { .init() }

            static var externalIDs: FragmentPath<[Music.SpotifyExternalId]> { .init() }

            static var externalUrLs: FragmentPath<[Music.SpotifyExternalUrl]> { .init() }

            static var popularity: Path<Int> { .init() }

            static var previewUrl: Path<String?> { .init() }

            static var trackNumber: Path<Int> { .init() }

            static func musicBrainz(strategy _: GraphQLArgument<[Music.SpotifyMatchStrategy]?> = .argument) -> FragmentPath<Music.Recording?> {
                return .init()
            }

            static var musicBrainz: FragmentPath<Music.Recording?> { .init() }

            static var _fragment: FragmentPath<SpotifyTrack> { .init() }
        }

        enum SpotifyAudioFeatures: Target {
            typealias Path<V> = GraphQLPath<SpotifyAudioFeatures, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<SpotifyAudioFeatures, V>

            static var acousticness: Path<Double> { .init() }

            static var danceability: Path<Double> { .init() }

            static var duration: Path<String> { .init() }

            static var energy: Path<Double> { .init() }

            static var instrumentalness: Path<Double> { .init() }

            static var key: Path<Int> { .init() }

            static var keyName: Path<String> { .init() }

            static var liveness: Path<Double> { .init() }

            static var loudness: Path<Double> { .init() }

            static var mode: Path<Music.SpotifyTrackMode> { .init() }

            static var speechiness: Path<Double> { .init() }

            static var tempo: Path<Double> { .init() }

            static var timeSignature: Path<Double> { .init() }

            static var valence: Path<Double> { .init() }

            static var _fragment: FragmentPath<SpotifyAudioFeatures> { .init() }
        }

        enum SpotifyTrackMode: String, Target {
            typealias Path<V> = GraphQLPath<SpotifyTrackMode, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<SpotifyTrackMode, V>

            case major = "MAJOR"

            case minor = "MINOR"

            static var _fragment: FragmentPath<SpotifyTrackMode> { .init() }
        }

        enum SpotifyExternalId: Target {
            typealias Path<V> = GraphQLPath<SpotifyExternalId, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<SpotifyExternalId, V>

            static var type: Path<String> { .init() }

            static var id: Path<String> { .init() }

            static var _fragment: FragmentPath<SpotifyExternalId> { .init() }
        }

        enum SpotifyCopyright: Target {
            typealias Path<V> = GraphQLPath<SpotifyCopyright, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<SpotifyCopyright, V>

            static var text: Path<String> { .init() }

            static var type: Path<Music.SpotifyCopyrightType> { .init() }

            static var _fragment: FragmentPath<SpotifyCopyright> { .init() }
        }

        enum SpotifyCopyrightType: String, Target {
            typealias Path<V> = GraphQLPath<SpotifyCopyrightType, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<SpotifyCopyrightType, V>

            case copyright = "COPYRIGHT"

            case performance = "PERFORMANCE"

            static var _fragment: FragmentPath<SpotifyCopyrightType> { .init() }
        }

        enum TheAudioDbTrack: Target {
            typealias Path<V> = GraphQLPath<TheAudioDbTrack, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<TheAudioDbTrack, V>

            static var trackId: Path<String?> { .init() }

            static var albumId: Path<String?> { .init() }

            static var artistId: Path<String?> { .init() }

            static func description(lang _: GraphQLArgument<String?> = .argument) -> Path<String?> {
                return .init()
            }

            static var description: Path<String?> { .init() }

            static func thumbnail(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
                return .init()
            }

            static var thumbnail: Path<String?> { .init() }

            static var score: Path<Double?> { .init() }

            static var scoreVotes: Path<Double?> { .init() }

            static var trackNumber: Path<Int?> { .init() }

            static var musicVideo: FragmentPath<Music.TheAudioDbMusicVideo?> { .init() }

            static var genre: Path<String?> { .init() }

            static var mood: Path<String?> { .init() }

            static var style: Path<String?> { .init() }

            static var theme: Path<String?> { .init() }

            static var _fragment: FragmentPath<TheAudioDbTrack> { .init() }
        }

        enum TheAudioDbMusicVideo: Target {
            typealias Path<V> = GraphQLPath<TheAudioDbMusicVideo, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<TheAudioDbMusicVideo, V>

            static var url: Path<String?> { .init() }

            static var companyName: Path<String?> { .init() }

            static var directorName: Path<String?> { .init() }

            static func screenshots(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<[String?]> {
                return .init()
            }

            static var screenshots: Path<[String?]> { .init() }

            static var viewCount: Path<Double?> { .init() }

            static var likeCount: Path<Double?> { .init() }

            static var dislikeCount: Path<Double?> { .init() }

            static var commentCount: Path<Double?> { .init() }

            static var _fragment: FragmentPath<TheAudioDbMusicVideo> { .init() }
        }

        enum FanArtArtist: Target {
            typealias Path<V> = GraphQLPath<FanArtArtist, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<FanArtArtist, V>

            static var backgrounds: FragmentPath<[Music.FanArtImage?]?> { .init() }

            static var banners: FragmentPath<[Music.FanArtImage?]?> { .init() }

            static var logos: FragmentPath<[Music.FanArtImage?]?> { .init() }

            static var logosHd: FragmentPath<[Music.FanArtImage?]?> { .init() }

            static var thumbnails: FragmentPath<[Music.FanArtImage?]?> { .init() }

            static var _fragment: FragmentPath<FanArtArtist> { .init() }
        }

        enum TheAudioDbArtist: Target {
            typealias Path<V> = GraphQLPath<TheAudioDbArtist, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<TheAudioDbArtist, V>

            static var artistId: Path<String?> { .init() }

            static func biography(lang _: GraphQLArgument<String?> = .argument) -> Path<String?> {
                return .init()
            }

            static var biography: Path<String?> { .init() }

            static var memberCount: Path<Int?> { .init() }

            static func banner(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
                return .init()
            }

            static var banner: Path<String?> { .init() }

            static func fanArt(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<[String?]> {
                return .init()
            }

            static var fanArt: Path<[String?]> { .init() }

            static func logo(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
                return .init()
            }

            static var logo: Path<String?> { .init() }

            static func thumbnail(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
                return .init()
            }

            static var thumbnail: Path<String?> { .init() }

            static var genre: Path<String?> { .init() }

            static var mood: Path<String?> { .init() }

            static var style: Path<String?> { .init() }

            static var _fragment: FragmentPath<TheAudioDbArtist> { .init() }
        }

        enum LastFmCountry: Target {
            typealias Path<V> = GraphQLPath<LastFmCountry, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<LastFmCountry, V>

            static func topArtists(first _: GraphQLArgument<Int?> = .argument,
                                   after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmArtistConnection?> {
                return .init()
            }

            static var topArtists: FragmentPath<Music.LastFmArtistConnection?> { .init() }

            static func topTracks(first _: GraphQLArgument<Int?> = .argument,
                                  after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTrackConnection?> {
                return .init()
            }

            static var topTracks: FragmentPath<Music.LastFmTrackConnection?> { .init() }

            static var _fragment: FragmentPath<LastFmCountry> { .init() }
        }

        enum Url: Target {
            typealias Path<V> = GraphQLPath<Url, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<Url, V>

            static var id: Path<String> { .init() }

            static var mbid: Path<String> { .init() }

            static var resource: Path<String> { .init() }

            static var relationships: FragmentPath<Music.Relationships?> { .init() }

            static var node: FragmentPath<Node> { .init() }

            static var entity: FragmentPath<Entity> { .init() }

            static var _fragment: FragmentPath<Url> { .init() }
        }

        enum BrowseQuery: Target {
            typealias Path<V> = GraphQLPath<BrowseQuery, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<BrowseQuery, V>

            static func areas(collection _: GraphQLArgument<String?> = .argument,
                              after _: GraphQLArgument<String?> = .argument,
                              first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.AreaConnection?> {
                return .init()
            }

            static var areas: FragmentPath<Music.AreaConnection?> { .init() }

            static func artists(area _: GraphQLArgument<String?> = .argument,
                                collection _: GraphQLArgument<String?> = .argument,
                                recording _: GraphQLArgument<String?> = .argument,
                                release _: GraphQLArgument<String?> = .argument,
                                releaseGroup _: GraphQLArgument<String?> = .argument,
                                work _: GraphQLArgument<String?> = .argument,
                                after _: GraphQLArgument<String?> = .argument,
                                first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
                return .init()
            }

            static var artists: FragmentPath<Music.ArtistConnection?> { .init() }

            static func collections(area _: GraphQLArgument<String?> = .argument,
                                    artist _: GraphQLArgument<String?> = .argument,
                                    editor _: GraphQLArgument<String?> = .argument,
                                    event _: GraphQLArgument<String?> = .argument,
                                    label _: GraphQLArgument<String?> = .argument,
                                    place _: GraphQLArgument<String?> = .argument,
                                    recording _: GraphQLArgument<String?> = .argument,
                                    release _: GraphQLArgument<String?> = .argument,
                                    releaseGroup _: GraphQLArgument<String?> = .argument,
                                    work _: GraphQLArgument<String?> = .argument,
                                    after _: GraphQLArgument<String?> = .argument,
                                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
                return .init()
            }

            static var collections: FragmentPath<Music.CollectionConnection?> { .init() }

            static func events(area _: GraphQLArgument<String?> = .argument,
                               artist _: GraphQLArgument<String?> = .argument,
                               collection _: GraphQLArgument<String?> = .argument,
                               place _: GraphQLArgument<String?> = .argument,
                               after _: GraphQLArgument<String?> = .argument,
                               first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.EventConnection?> {
                return .init()
            }

            static var events: FragmentPath<Music.EventConnection?> { .init() }

            static func labels(area _: GraphQLArgument<String?> = .argument,
                               collection _: GraphQLArgument<String?> = .argument,
                               release _: GraphQLArgument<String?> = .argument,
                               after _: GraphQLArgument<String?> = .argument,
                               first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.LabelConnection?> {
                return .init()
            }

            static var labels: FragmentPath<Music.LabelConnection?> { .init() }

            static func places(area _: GraphQLArgument<String?> = .argument,
                               collection _: GraphQLArgument<String?> = .argument,
                               after _: GraphQLArgument<String?> = .argument,
                               first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.PlaceConnection?> {
                return .init()
            }

            static var places: FragmentPath<Music.PlaceConnection?> { .init() }

            static func recordings(artist _: GraphQLArgument<String?> = .argument,
                                   collection _: GraphQLArgument<String?> = .argument,
                                   isrc _: GraphQLArgument<String?> = .argument,
                                   release _: GraphQLArgument<String?> = .argument,
                                   after _: GraphQLArgument<String?> = .argument,
                                   first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RecordingConnection?> {
                return .init()
            }

            static var recordings: FragmentPath<Music.RecordingConnection?> { .init() }

            static func releases(area _: GraphQLArgument<String?> = .argument,
                                 artist _: GraphQLArgument<String?> = .argument,
                                 collection _: GraphQLArgument<String?> = .argument,
                                 discID _: GraphQLArgument<String?> = .argument,
                                 label _: GraphQLArgument<String?> = .argument,
                                 recording _: GraphQLArgument<String?> = .argument,
                                 releaseGroup _: GraphQLArgument<String?> = .argument,
                                 track _: GraphQLArgument<String?> = .argument,
                                 trackArtist _: GraphQLArgument<String?> = .argument,
                                 type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                                 status _: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument,
                                 after _: GraphQLArgument<String?> = .argument,
                                 first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
                return .init()
            }

            static var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

            static func releaseGroups(artist _: GraphQLArgument<String?> = .argument,
                                      collection _: GraphQLArgument<String?> = .argument,
                                      release _: GraphQLArgument<String?> = .argument,
                                      type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                                      after _: GraphQLArgument<String?> = .argument,
                                      first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseGroupConnection?> {
                return .init()
            }

            static var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }

            static func works(artist _: GraphQLArgument<String?> = .argument,
                              collection _: GraphQLArgument<String?> = .argument,
                              iswc _: GraphQLArgument<String?> = .argument,
                              after _: GraphQLArgument<String?> = .argument,
                              first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.WorkConnection?> {
                return .init()
            }

            static var works: FragmentPath<Music.WorkConnection?> { .init() }

            static var _fragment: FragmentPath<BrowseQuery> { .init() }
        }

        enum SearchQuery: Target {
            typealias Path<V> = GraphQLPath<SearchQuery, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<SearchQuery, V>

            static func areas(query _: GraphQLArgument<String> = .argument,
                              after _: GraphQLArgument<String?> = .argument,
                              first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.AreaConnection?> {
                return .init()
            }

            static var areas: FragmentPath<Music.AreaConnection?> { .init() }

            static func artists(query _: GraphQLArgument<String> = .argument,
                                after _: GraphQLArgument<String?> = .argument,
                                first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
                return .init()
            }

            static var artists: FragmentPath<Music.ArtistConnection?> { .init() }

            static func events(query _: GraphQLArgument<String> = .argument,
                               after _: GraphQLArgument<String?> = .argument,
                               first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.EventConnection?> {
                return .init()
            }

            static var events: FragmentPath<Music.EventConnection?> { .init() }

            static func instruments(query _: GraphQLArgument<String> = .argument,
                                    after _: GraphQLArgument<String?> = .argument,
                                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.InstrumentConnection?> {
                return .init()
            }

            static var instruments: FragmentPath<Music.InstrumentConnection?> { .init() }

            static func labels(query _: GraphQLArgument<String> = .argument,
                               after _: GraphQLArgument<String?> = .argument,
                               first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.LabelConnection?> {
                return .init()
            }

            static var labels: FragmentPath<Music.LabelConnection?> { .init() }

            static func places(query _: GraphQLArgument<String> = .argument,
                               after _: GraphQLArgument<String?> = .argument,
                               first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.PlaceConnection?> {
                return .init()
            }

            static var places: FragmentPath<Music.PlaceConnection?> { .init() }

            static func recordings(query _: GraphQLArgument<String> = .argument,
                                   after _: GraphQLArgument<String?> = .argument,
                                   first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RecordingConnection?> {
                return .init()
            }

            static var recordings: FragmentPath<Music.RecordingConnection?> { .init() }

            static func releases(query _: GraphQLArgument<String> = .argument,
                                 after _: GraphQLArgument<String?> = .argument,
                                 first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
                return .init()
            }

            static var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

            static func releaseGroups(query _: GraphQLArgument<String> = .argument,
                                      after _: GraphQLArgument<String?> = .argument,
                                      first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseGroupConnection?> {
                return .init()
            }

            static var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }

            static func series(query _: GraphQLArgument<String> = .argument,
                               after _: GraphQLArgument<String?> = .argument,
                               first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.SeriesConnection?> {
                return .init()
            }

            static var series: FragmentPath<Music.SeriesConnection?> { .init() }

            static func works(query _: GraphQLArgument<String> = .argument,
                              after _: GraphQLArgument<String?> = .argument,
                              first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.WorkConnection?> {
                return .init()
            }

            static var works: FragmentPath<Music.WorkConnection?> { .init() }

            static var _fragment: FragmentPath<SearchQuery> { .init() }
        }

        enum LastFmQuery: Target {
            typealias Path<V> = GraphQLPath<LastFmQuery, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<LastFmQuery, V>

            static var chart: FragmentPath<Music.LastFmChartQuery> { .init() }

            static var _fragment: FragmentPath<LastFmQuery> { .init() }
        }

        enum LastFmChartQuery: Target {
            typealias Path<V> = GraphQLPath<LastFmChartQuery, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<LastFmChartQuery, V>

            static func topArtists(country _: GraphQLArgument<String?> = .argument,
                                   first _: GraphQLArgument<Int?> = .argument,
                                   after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmArtistConnection?> {
                return .init()
            }

            static var topArtists: FragmentPath<Music.LastFmArtistConnection?> { .init() }

            static func topTags(first _: GraphQLArgument<Int?> = .argument,
                                after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTagConnection?> {
                return .init()
            }

            static var topTags: FragmentPath<Music.LastFmTagConnection?> { .init() }

            static func topTracks(country _: GraphQLArgument<String?> = .argument,
                                  first _: GraphQLArgument<Int?> = .argument,
                                  after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTrackConnection?> {
                return .init()
            }

            static var topTracks: FragmentPath<Music.LastFmTrackConnection?> { .init() }

            static var _fragment: FragmentPath<LastFmChartQuery> { .init() }
        }

        enum SpotifyQuery: Target {
            typealias Path<V> = GraphQLPath<SpotifyQuery, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<SpotifyQuery, V>

            static func recommendations(seedArtists _: GraphQLArgument<[String]?> = .argument,
                                        seedGenres _: GraphQLArgument<[String]?> = .argument,
                                        seedTracks _: GraphQLArgument<[String]?> = .argument,
                                        limit _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.SpotifyRecommendations> {
                return .init()
            }

            static var recommendations: FragmentPath<Music.SpotifyRecommendations> { .init() }

            static var _fragment: FragmentPath<SpotifyQuery> { .init() }
        }

        enum SpotifyRecommendations: Target {
            typealias Path<V> = GraphQLPath<SpotifyRecommendations, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<SpotifyRecommendations, V>

            static var tracks: FragmentPath<[Music.SpotifyTrack]> { .init() }

            static var _fragment: FragmentPath<SpotifyRecommendations> { .init() }
        }

        enum DiscogsReleaseConnection: Target {
            typealias Path<V> = GraphQLPath<DiscogsReleaseConnection, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<DiscogsReleaseConnection, V>

            static var pageInfo: FragmentPath<Music.PageInfo> { .init() }

            static var edges: FragmentPath<[Music.DiscogsReleaseEdge]> { .init() }

            static var nodes: FragmentPath<[Music.DiscogsRelease]> { .init() }

            static var totalCount: Path<Int?> { .init() }

            static var _fragment: FragmentPath<DiscogsReleaseConnection> { .init() }
        }

        enum DiscogsReleaseEdge: Target {
            typealias Path<V> = GraphQLPath<DiscogsReleaseEdge, V>
            typealias FragmentPath<V> = GraphQLFragmentPath<DiscogsReleaseEdge, V>

            static var node: FragmentPath<Music.DiscogsRelease> { .init() }

            static var _fragment: FragmentPath<DiscogsReleaseEdge> { .init() }
        }
    }

    extension Music {
        init(url: URL = URL(string: "https://graphbrainz.herokuapp.com")!,
             client: URLSessionClient = URLSessionClient(),
             useGETForQueries: Bool = false,
             enableAutoPersistedQueries: Bool = false,
             useGETForPersistedQueryRetry: Bool = false,
             requestBodyCreator: RequestBodyCreator = ApolloRequestBodyCreator(),
             store: ApolloStore = ApolloStore(cache: InMemoryNormalizedCache())) {
            let provider = LegacyInterceptorProvider(client: client, store: store)
            let networkTransport = RequestChainNetworkTransport(interceptorProvider: provider,
                                                                endpointURL: url,
                                                                autoPersistQueries: enableAutoPersistedQueries,
                                                                requestBodyCreator: requestBodyCreator,
                                                                useGETForQueries: useGETForQueries,
                                                                useGETForPersistedQueryRetry: useGETForPersistedQueryRetry)
            self.init(client: ApolloClient(networkTransport: networkTransport, store: store))
        }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LookupQuery {
        func area(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Area?> {
            return .init()
        }

        var area: FragmentPath<Music.Area?> { .init() }

        func artist(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Artist?> {
            return .init()
        }

        var artist: FragmentPath<Music.Artist?> { .init() }

        func collection(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Collection?> {
            return .init()
        }

        var collection: FragmentPath<Music.Collection?> { .init() }

        func disc(discID _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Disc?> {
            return .init()
        }

        var disc: FragmentPath<Music.Disc?> { .init() }

        func event(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Event?> {
            return .init()
        }

        var event: FragmentPath<Music.Event?> { .init() }

        func instrument(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Instrument?> {
            return .init()
        }

        var instrument: FragmentPath<Music.Instrument?> { .init() }

        func label(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Label?> {
            return .init()
        }

        var label: FragmentPath<Music.Label?> { .init() }

        func place(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Place?> {
            return .init()
        }

        var place: FragmentPath<Music.Place?> { .init() }

        func recording(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Recording?> {
            return .init()
        }

        var recording: FragmentPath<Music.Recording?> { .init() }

        func release(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Release?> {
            return .init()
        }

        var release: FragmentPath<Music.Release?> { .init() }

        func releaseGroup(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.ReleaseGroup?> {
            return .init()
        }

        var releaseGroup: FragmentPath<Music.ReleaseGroup?> { .init() }

        func series(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Series?> {
            return .init()
        }

        var series: FragmentPath<Music.Series?> { .init() }

        func url(mbid _: GraphQLArgument<String?> = .argument,
                 resource _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.Url?> {
            return .init()
        }

        var url: FragmentPath<Music.Url?> { .init() }

        func work(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Work?> {
            return .init()
        }

        var work: FragmentPath<Music.Work?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LookupQuery? {
        func area(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Area?> {
            return .init()
        }

        var area: FragmentPath<Music.Area?> { .init() }

        func artist(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Artist?> {
            return .init()
        }

        var artist: FragmentPath<Music.Artist?> { .init() }

        func collection(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Collection?> {
            return .init()
        }

        var collection: FragmentPath<Music.Collection?> { .init() }

        func disc(discID _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Disc?> {
            return .init()
        }

        var disc: FragmentPath<Music.Disc?> { .init() }

        func event(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Event?> {
            return .init()
        }

        var event: FragmentPath<Music.Event?> { .init() }

        func instrument(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Instrument?> {
            return .init()
        }

        var instrument: FragmentPath<Music.Instrument?> { .init() }

        func label(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Label?> {
            return .init()
        }

        var label: FragmentPath<Music.Label?> { .init() }

        func place(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Place?> {
            return .init()
        }

        var place: FragmentPath<Music.Place?> { .init() }

        func recording(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Recording?> {
            return .init()
        }

        var recording: FragmentPath<Music.Recording?> { .init() }

        func release(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Release?> {
            return .init()
        }

        var release: FragmentPath<Music.Release?> { .init() }

        func releaseGroup(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.ReleaseGroup?> {
            return .init()
        }

        var releaseGroup: FragmentPath<Music.ReleaseGroup?> { .init() }

        func series(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Series?> {
            return .init()
        }

        var series: FragmentPath<Music.Series?> { .init() }

        func url(mbid _: GraphQLArgument<String?> = .argument,
                 resource _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.Url?> {
            return .init()
        }

        var url: FragmentPath<Music.Url?> { .init() }

        func work(mbid _: GraphQLArgument<String> = .argument) -> FragmentPath<Music.Work?> {
            return .init()
        }

        var work: FragmentPath<Music.Work?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Area {
        var id: Path<String> { .init() }

        var mbid: Path<String> { .init() }

        var name: Path<String?> { .init() }

        var sortName: Path<String?> { .init() }

        var disambiguation: Path<String?> { .init() }

        var aliases: FragmentPath<[Music.Alias?]?> { .init() }

        func isoCodes(standard _: GraphQLArgument<String?> = .argument) -> Path<[String?]?> {
            return .init()
        }

        var isoCodes: Path<[String?]?> { .init() }

        var type: Path<String?> { .init() }

        var typeId: Path<String?> { .init() }

        func artists(after _: GraphQLArgument<String?> = .argument,
                     first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
            return .init()
        }

        var artists: FragmentPath<Music.ArtistConnection?> { .init() }

        func events(after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.EventConnection?> {
            return .init()
        }

        var events: FragmentPath<Music.EventConnection?> { .init() }

        func labels(after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.LabelConnection?> {
            return .init()
        }

        var labels: FragmentPath<Music.LabelConnection?> { .init() }

        func places(after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.PlaceConnection?> {
            return .init()
        }

        var places: FragmentPath<Music.PlaceConnection?> { .init() }

        func releases(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                      status _: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument,
                      after _: GraphQLArgument<String?> = .argument,
                      first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
            return .init()
        }

        var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        func collections(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        func tags(after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
            return .init()
        }

        var tags: FragmentPath<Music.TagConnection?> { .init() }

        var lastFm: FragmentPath<Music.LastFmCountry?> { .init() }

        var node: FragmentPath<Music.Node> { .init() }

        var entity: FragmentPath<Music.Entity> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Area? {
        var id: Path<String?> { .init() }

        var mbid: Path<String?> { .init() }

        var name: Path<String?> { .init() }

        var sortName: Path<String?> { .init() }

        var disambiguation: Path<String?> { .init() }

        var aliases: FragmentPath<[Music.Alias?]?> { .init() }

        func isoCodes(standard _: GraphQLArgument<String?> = .argument) -> Path<[String?]?> {
            return .init()
        }

        var isoCodes: Path<[String?]?> { .init() }

        var type: Path<String?> { .init() }

        var typeId: Path<String?> { .init() }

        func artists(after _: GraphQLArgument<String?> = .argument,
                     first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
            return .init()
        }

        var artists: FragmentPath<Music.ArtistConnection?> { .init() }

        func events(after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.EventConnection?> {
            return .init()
        }

        var events: FragmentPath<Music.EventConnection?> { .init() }

        func labels(after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.LabelConnection?> {
            return .init()
        }

        var labels: FragmentPath<Music.LabelConnection?> { .init() }

        func places(after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.PlaceConnection?> {
            return .init()
        }

        var places: FragmentPath<Music.PlaceConnection?> { .init() }

        func releases(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                      status _: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument,
                      after _: GraphQLArgument<String?> = .argument,
                      first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
            return .init()
        }

        var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        func collections(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        func tags(after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
            return .init()
        }

        var tags: FragmentPath<Music.TagConnection?> { .init() }

        var lastFm: FragmentPath<Music.LastFmCountry?> { .init() }

        var node: FragmentPath<Music.Node?> { .init() }

        var entity: FragmentPath<Music.Entity?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Node {
        var id: Path<String> { .init() }

        var area: FragmentPath<Music.Area?> { .init() }

        var artist: FragmentPath<Music.Artist?> { .init() }

        var recording: FragmentPath<Music.Recording?> { .init() }

        var release: FragmentPath<Music.Release?> { .init() }

        var disc: FragmentPath<Music.Disc?> { .init() }

        var label: FragmentPath<Music.Label?> { .init() }

        var collection: FragmentPath<Music.Collection?> { .init() }

        var event: FragmentPath<Music.Event?> { .init() }

        var instrument: FragmentPath<Music.Instrument?> { .init() }

        var place: FragmentPath<Music.Place?> { .init() }

        var releaseGroup: FragmentPath<Music.ReleaseGroup?> { .init() }

        var series: FragmentPath<Music.Series?> { .init() }

        var work: FragmentPath<Music.Work?> { .init() }

        var url: FragmentPath<Music.Url?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Node? {
        var id: Path<String?> { .init() }

        var area: FragmentPath<Music.Area?> { .init() }

        var artist: FragmentPath<Music.Artist?> { .init() }

        var recording: FragmentPath<Music.Recording?> { .init() }

        var release: FragmentPath<Music.Release?> { .init() }

        var disc: FragmentPath<Music.Disc?> { .init() }

        var label: FragmentPath<Music.Label?> { .init() }

        var collection: FragmentPath<Music.Collection?> { .init() }

        var event: FragmentPath<Music.Event?> { .init() }

        var instrument: FragmentPath<Music.Instrument?> { .init() }

        var place: FragmentPath<Music.Place?> { .init() }

        var releaseGroup: FragmentPath<Music.ReleaseGroup?> { .init() }

        var series: FragmentPath<Music.Series?> { .init() }

        var work: FragmentPath<Music.Work?> { .init() }

        var url: FragmentPath<Music.Url?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Entity {
        var mbid: Path<String> { .init() }

        var area: FragmentPath<Music.Area?> { .init() }

        var artist: FragmentPath<Music.Artist?> { .init() }

        var recording: FragmentPath<Music.Recording?> { .init() }

        var release: FragmentPath<Music.Release?> { .init() }

        var track: FragmentPath<Music.Track?> { .init() }

        var label: FragmentPath<Music.Label?> { .init() }

        var collection: FragmentPath<Music.Collection?> { .init() }

        var event: FragmentPath<Music.Event?> { .init() }

        var instrument: FragmentPath<Music.Instrument?> { .init() }

        var place: FragmentPath<Music.Place?> { .init() }

        var releaseGroup: FragmentPath<Music.ReleaseGroup?> { .init() }

        var series: FragmentPath<Music.Series?> { .init() }

        var work: FragmentPath<Music.Work?> { .init() }

        var url: FragmentPath<Music.Url?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Entity? {
        var mbid: Path<String?> { .init() }

        var area: FragmentPath<Music.Area?> { .init() }

        var artist: FragmentPath<Music.Artist?> { .init() }

        var recording: FragmentPath<Music.Recording?> { .init() }

        var release: FragmentPath<Music.Release?> { .init() }

        var track: FragmentPath<Music.Track?> { .init() }

        var label: FragmentPath<Music.Label?> { .init() }

        var collection: FragmentPath<Music.Collection?> { .init() }

        var event: FragmentPath<Music.Event?> { .init() }

        var instrument: FragmentPath<Music.Instrument?> { .init() }

        var place: FragmentPath<Music.Place?> { .init() }

        var releaseGroup: FragmentPath<Music.ReleaseGroup?> { .init() }

        var series: FragmentPath<Music.Series?> { .init() }

        var work: FragmentPath<Music.Work?> { .init() }

        var url: FragmentPath<Music.Url?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Alias {
        var name: Path<String?> { .init() }

        var sortName: Path<String?> { .init() }

        var locale: Path<String?> { .init() }

        var primary: Path<Bool?> { .init() }

        var type: Path<String?> { .init() }

        var typeId: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Alias? {
        var name: Path<String?> { .init() }

        var sortName: Path<String?> { .init() }

        var locale: Path<String?> { .init() }

        var primary: Path<Bool?> { .init() }

        var type: Path<String?> { .init() }

        var typeId: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.ArtistConnection {
        var pageInfo: FragmentPath<Music.PageInfo> { .init() }

        var edges: FragmentPath<[Music.ArtistEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Artist?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.ArtistConnection? {
        var pageInfo: FragmentPath<Music.PageInfo?> { .init() }

        var edges: FragmentPath<[Music.ArtistEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Artist?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.PageInfo {
        var hasNextPage: Path<Bool> { .init() }

        var hasPreviousPage: Path<Bool> { .init() }

        var startCursor: Path<String?> { .init() }

        var endCursor: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.PageInfo? {
        var hasNextPage: Path<Bool?> { .init() }

        var hasPreviousPage: Path<Bool?> { .init() }

        var startCursor: Path<String?> { .init() }

        var endCursor: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.ArtistEdge {
        var node: FragmentPath<Music.Artist?> { .init() }

        var cursor: Path<String> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.ArtistEdge? {
        var node: FragmentPath<Music.Artist?> { .init() }

        var cursor: Path<String?> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Artist {
        var id: Path<String> { .init() }

        var mbid: Path<String> { .init() }

        var name: Path<String?> { .init() }

        var sortName: Path<String?> { .init() }

        var disambiguation: Path<String?> { .init() }

        var aliases: FragmentPath<[Music.Alias?]?> { .init() }

        var country: Path<String?> { .init() }

        var area: FragmentPath<Music.Area?> { .init() }

        var beginArea: FragmentPath<Music.Area?> { .init() }

        var endArea: FragmentPath<Music.Area?> { .init() }

        var lifeSpan: FragmentPath<Music.LifeSpan?> { .init() }

        var gender: Path<String?> { .init() }

        var genderId: Path<String?> { .init() }

        var type: Path<String?> { .init() }

        var typeId: Path<String?> { .init() }

        var ipis: Path<[String?]?> { .init() }

        var isnis: Path<[String?]?> { .init() }

        func recordings(after _: GraphQLArgument<String?> = .argument,
                        first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RecordingConnection?> {
            return .init()
        }

        var recordings: FragmentPath<Music.RecordingConnection?> { .init() }

        func releases(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                      status _: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument,
                      after _: GraphQLArgument<String?> = .argument,
                      first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
            return .init()
        }

        var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

        func releaseGroups(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                           after _: GraphQLArgument<String?> = .argument,
                           first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseGroupConnection?> {
            return .init()
        }

        var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }

        func works(after _: GraphQLArgument<String?> = .argument,
                   first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.WorkConnection?> {
            return .init()
        }

        var works: FragmentPath<Music.WorkConnection?> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        func collections(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        var rating: FragmentPath<Music.Rating?> { .init() }

        func tags(after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
            return .init()
        }

        var tags: FragmentPath<Music.TagConnection?> { .init() }

        var fanArt: FragmentPath<Music.FanArtArtist?> { .init() }

        func mediaWikiImages(type _: GraphQLArgument<String?> = .argument) -> FragmentPath<[Music.MediaWikiImage?]> {
            return .init()
        }

        var mediaWikiImages: FragmentPath<[Music.MediaWikiImage?]> { .init() }

        var theAudioDb: FragmentPath<Music.TheAudioDbArtist?> { .init() }

        var discogs: FragmentPath<Music.DiscogsArtist?> { .init() }

        var lastFm: FragmentPath<Music.LastFmArtist?> { .init() }

        var spotify: FragmentPath<Music.SpotifyArtist?> { .init() }

        var node: FragmentPath<Music.Node> { .init() }

        var entity: FragmentPath<Music.Entity> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Artist? {
        var id: Path<String?> { .init() }

        var mbid: Path<String?> { .init() }

        var name: Path<String?> { .init() }

        var sortName: Path<String?> { .init() }

        var disambiguation: Path<String?> { .init() }

        var aliases: FragmentPath<[Music.Alias?]?> { .init() }

        var country: Path<String?> { .init() }

        var area: FragmentPath<Music.Area?> { .init() }

        var beginArea: FragmentPath<Music.Area?> { .init() }

        var endArea: FragmentPath<Music.Area?> { .init() }

        var lifeSpan: FragmentPath<Music.LifeSpan?> { .init() }

        var gender: Path<String?> { .init() }

        var genderId: Path<String?> { .init() }

        var type: Path<String?> { .init() }

        var typeId: Path<String?> { .init() }

        var ipis: Path<[String?]?> { .init() }

        var isnis: Path<[String?]?> { .init() }

        func recordings(after _: GraphQLArgument<String?> = .argument,
                        first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RecordingConnection?> {
            return .init()
        }

        var recordings: FragmentPath<Music.RecordingConnection?> { .init() }

        func releases(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                      status _: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument,
                      after _: GraphQLArgument<String?> = .argument,
                      first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
            return .init()
        }

        var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

        func releaseGroups(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                           after _: GraphQLArgument<String?> = .argument,
                           first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseGroupConnection?> {
            return .init()
        }

        var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }

        func works(after _: GraphQLArgument<String?> = .argument,
                   first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.WorkConnection?> {
            return .init()
        }

        var works: FragmentPath<Music.WorkConnection?> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        func collections(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        var rating: FragmentPath<Music.Rating?> { .init() }

        func tags(after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
            return .init()
        }

        var tags: FragmentPath<Music.TagConnection?> { .init() }

        var fanArt: FragmentPath<Music.FanArtArtist?> { .init() }

        func mediaWikiImages(type _: GraphQLArgument<String?> = .argument) -> FragmentPath<[Music.MediaWikiImage?]?> {
            return .init()
        }

        var mediaWikiImages: FragmentPath<[Music.MediaWikiImage?]?> { .init() }

        var theAudioDb: FragmentPath<Music.TheAudioDbArtist?> { .init() }

        var discogs: FragmentPath<Music.DiscogsArtist?> { .init() }

        var lastFm: FragmentPath<Music.LastFmArtist?> { .init() }

        var spotify: FragmentPath<Music.SpotifyArtist?> { .init() }

        var node: FragmentPath<Music.Node?> { .init() }

        var entity: FragmentPath<Music.Entity?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LifeSpan {
        var begin: Path<String?> { .init() }

        var end: Path<String?> { .init() }

        var ended: Path<Bool?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LifeSpan? {
        var begin: Path<String?> { .init() }

        var end: Path<String?> { .init() }

        var ended: Path<Bool?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.RecordingConnection {
        var pageInfo: FragmentPath<Music.PageInfo> { .init() }

        var edges: FragmentPath<[Music.RecordingEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Recording?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.RecordingConnection? {
        var pageInfo: FragmentPath<Music.PageInfo?> { .init() }

        var edges: FragmentPath<[Music.RecordingEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Recording?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.RecordingEdge {
        var node: FragmentPath<Music.Recording?> { .init() }

        var cursor: Path<String> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.RecordingEdge? {
        var node: FragmentPath<Music.Recording?> { .init() }

        var cursor: Path<String?> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Recording {
        var id: Path<String> { .init() }

        var mbid: Path<String> { .init() }

        var title: Path<String?> { .init() }

        var disambiguation: Path<String?> { .init() }

        var aliases: FragmentPath<[Music.Alias?]?> { .init() }

        var artistCredit: FragmentPath<[Music.ArtistCredit?]?> { .init() }

        var artistCredits: FragmentPath<[Music.ArtistCredit?]?> { .init() }

        var isrcs: Path<[String?]?> { .init() }

        var length: Path<String?> { .init() }

        var video: Path<Bool?> { .init() }

        func artists(after _: GraphQLArgument<String?> = .argument,
                     first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
            return .init()
        }

        var artists: FragmentPath<Music.ArtistConnection?> { .init() }

        func releases(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                      status _: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument,
                      after _: GraphQLArgument<String?> = .argument,
                      first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
            return .init()
        }

        var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        func collections(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        var rating: FragmentPath<Music.Rating?> { .init() }

        func tags(after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
            return .init()
        }

        var tags: FragmentPath<Music.TagConnection?> { .init() }

        var theAudioDb: FragmentPath<Music.TheAudioDbTrack?> { .init() }

        var lastFm: FragmentPath<Music.LastFmTrack?> { .init() }

        func spotify(strategy _: GraphQLArgument<[Music.SpotifyMatchStrategy]?> = .argument) -> FragmentPath<Music.SpotifyTrack?> {
            return .init()
        }

        var spotify: FragmentPath<Music.SpotifyTrack?> { .init() }

        var node: FragmentPath<Music.Node> { .init() }

        var entity: FragmentPath<Music.Entity> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Recording? {
        var id: Path<String?> { .init() }

        var mbid: Path<String?> { .init() }

        var title: Path<String?> { .init() }

        var disambiguation: Path<String?> { .init() }

        var aliases: FragmentPath<[Music.Alias?]?> { .init() }

        var artistCredit: FragmentPath<[Music.ArtistCredit?]?> { .init() }

        var artistCredits: FragmentPath<[Music.ArtistCredit?]?> { .init() }

        var isrcs: Path<[String?]?> { .init() }

        var length: Path<String?> { .init() }

        var video: Path<Bool?> { .init() }

        func artists(after _: GraphQLArgument<String?> = .argument,
                     first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
            return .init()
        }

        var artists: FragmentPath<Music.ArtistConnection?> { .init() }

        func releases(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                      status _: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument,
                      after _: GraphQLArgument<String?> = .argument,
                      first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
            return .init()
        }

        var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        func collections(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        var rating: FragmentPath<Music.Rating?> { .init() }

        func tags(after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
            return .init()
        }

        var tags: FragmentPath<Music.TagConnection?> { .init() }

        var theAudioDb: FragmentPath<Music.TheAudioDbTrack?> { .init() }

        var lastFm: FragmentPath<Music.LastFmTrack?> { .init() }

        func spotify(strategy _: GraphQLArgument<[Music.SpotifyMatchStrategy]?> = .argument) -> FragmentPath<Music.SpotifyTrack?> {
            return .init()
        }

        var spotify: FragmentPath<Music.SpotifyTrack?> { .init() }

        var node: FragmentPath<Music.Node?> { .init() }

        var entity: FragmentPath<Music.Entity?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.ArtistCredit {
        var artist: FragmentPath<Music.Artist?> { .init() }

        var name: Path<String?> { .init() }

        var joinPhrase: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.ArtistCredit? {
        var artist: FragmentPath<Music.Artist?> { .init() }

        var name: Path<String?> { .init() }

        var joinPhrase: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.ReleaseGroupType {}

    extension GraphQLFragmentPath where UnderlyingType == Music.ReleaseGroupType? {}

    extension GraphQLFragmentPath where UnderlyingType == Music.ReleaseStatus {}

    extension GraphQLFragmentPath where UnderlyingType == Music.ReleaseStatus? {}

    extension GraphQLFragmentPath where UnderlyingType == Music.ReleaseConnection {
        var pageInfo: FragmentPath<Music.PageInfo> { .init() }

        var edges: FragmentPath<[Music.ReleaseEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Release?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.ReleaseConnection? {
        var pageInfo: FragmentPath<Music.PageInfo?> { .init() }

        var edges: FragmentPath<[Music.ReleaseEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Release?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.ReleaseEdge {
        var node: FragmentPath<Music.Release?> { .init() }

        var cursor: Path<String> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.ReleaseEdge? {
        var node: FragmentPath<Music.Release?> { .init() }

        var cursor: Path<String?> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Release {
        var id: Path<String> { .init() }

        var mbid: Path<String> { .init() }

        var title: Path<String?> { .init() }

        var disambiguation: Path<String?> { .init() }

        var aliases: FragmentPath<[Music.Alias?]?> { .init() }

        var artistCredit: FragmentPath<[Music.ArtistCredit?]?> { .init() }

        var artistCredits: FragmentPath<[Music.ArtistCredit?]?> { .init() }

        var releaseEvents: FragmentPath<[Music.ReleaseEvent?]?> { .init() }

        var date: Path<String?> { .init() }

        var country: Path<String?> { .init() }

        var asin: Path<String?> { .init() }

        var barcode: Path<String?> { .init() }

        var status: Path<Music.ReleaseStatus?> { .init() }

        var statusId: Path<String?> { .init() }

        var packaging: Path<String?> { .init() }

        var packagingId: Path<String?> { .init() }

        var quality: Path<String?> { .init() }

        var media: FragmentPath<[Music.Medium?]?> { .init() }

        func artists(after _: GraphQLArgument<String?> = .argument,
                     first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
            return .init()
        }

        var artists: FragmentPath<Music.ArtistConnection?> { .init() }

        func labels(after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.LabelConnection?> {
            return .init()
        }

        var labels: FragmentPath<Music.LabelConnection?> { .init() }

        func recordings(after _: GraphQLArgument<String?> = .argument,
                        first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RecordingConnection?> {
            return .init()
        }

        var recordings: FragmentPath<Music.RecordingConnection?> { .init() }

        func releaseGroups(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                           after _: GraphQLArgument<String?> = .argument,
                           first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseGroupConnection?> {
            return .init()
        }

        var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        func collections(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        func tags(after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
            return .init()
        }

        var tags: FragmentPath<Music.TagConnection?> { .init() }

        var coverArtArchive: FragmentPath<Music.CoverArtArchiveRelease?> { .init() }

        var discogs: FragmentPath<Music.DiscogsRelease?> { .init() }

        var lastFm: FragmentPath<Music.LastFmAlbum?> { .init() }

        func spotify(strategy _: GraphQLArgument<[Music.SpotifyMatchStrategy]?> = .argument) -> FragmentPath<Music.SpotifyAlbum?> {
            return .init()
        }

        var spotify: FragmentPath<Music.SpotifyAlbum?> { .init() }

        var node: FragmentPath<Music.Node> { .init() }

        var entity: FragmentPath<Music.Entity> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Release? {
        var id: Path<String?> { .init() }

        var mbid: Path<String?> { .init() }

        var title: Path<String?> { .init() }

        var disambiguation: Path<String?> { .init() }

        var aliases: FragmentPath<[Music.Alias?]?> { .init() }

        var artistCredit: FragmentPath<[Music.ArtistCredit?]?> { .init() }

        var artistCredits: FragmentPath<[Music.ArtistCredit?]?> { .init() }

        var releaseEvents: FragmentPath<[Music.ReleaseEvent?]?> { .init() }

        var date: Path<String?> { .init() }

        var country: Path<String?> { .init() }

        var asin: Path<String?> { .init() }

        var barcode: Path<String?> { .init() }

        var status: Path<Music.ReleaseStatus?> { .init() }

        var statusId: Path<String?> { .init() }

        var packaging: Path<String?> { .init() }

        var packagingId: Path<String?> { .init() }

        var quality: Path<String?> { .init() }

        var media: FragmentPath<[Music.Medium?]?> { .init() }

        func artists(after _: GraphQLArgument<String?> = .argument,
                     first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
            return .init()
        }

        var artists: FragmentPath<Music.ArtistConnection?> { .init() }

        func labels(after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.LabelConnection?> {
            return .init()
        }

        var labels: FragmentPath<Music.LabelConnection?> { .init() }

        func recordings(after _: GraphQLArgument<String?> = .argument,
                        first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RecordingConnection?> {
            return .init()
        }

        var recordings: FragmentPath<Music.RecordingConnection?> { .init() }

        func releaseGroups(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                           after _: GraphQLArgument<String?> = .argument,
                           first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseGroupConnection?> {
            return .init()
        }

        var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        func collections(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        func tags(after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
            return .init()
        }

        var tags: FragmentPath<Music.TagConnection?> { .init() }

        var coverArtArchive: FragmentPath<Music.CoverArtArchiveRelease?> { .init() }

        var discogs: FragmentPath<Music.DiscogsRelease?> { .init() }

        var lastFm: FragmentPath<Music.LastFmAlbum?> { .init() }

        func spotify(strategy _: GraphQLArgument<[Music.SpotifyMatchStrategy]?> = .argument) -> FragmentPath<Music.SpotifyAlbum?> {
            return .init()
        }

        var spotify: FragmentPath<Music.SpotifyAlbum?> { .init() }

        var node: FragmentPath<Music.Node?> { .init() }

        var entity: FragmentPath<Music.Entity?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.ReleaseEvent {
        var area: FragmentPath<Music.Area?> { .init() }

        var date: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.ReleaseEvent? {
        var area: FragmentPath<Music.Area?> { .init() }

        var date: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Medium {
        var title: Path<String?> { .init() }

        var format: Path<String?> { .init() }

        var formatId: Path<String?> { .init() }

        var position: Path<Int?> { .init() }

        var trackCount: Path<Int?> { .init() }

        var discs: FragmentPath<[Music.Disc?]?> { .init() }

        var tracks: FragmentPath<[Music.Track?]?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Medium? {
        var title: Path<String?> { .init() }

        var format: Path<String?> { .init() }

        var formatId: Path<String?> { .init() }

        var position: Path<Int?> { .init() }

        var trackCount: Path<Int?> { .init() }

        var discs: FragmentPath<[Music.Disc?]?> { .init() }

        var tracks: FragmentPath<[Music.Track?]?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Disc {
        var id: Path<String> { .init() }

        var discId: Path<String> { .init() }

        var offsetCount: Path<Int> { .init() }

        var offsets: Path<[Int?]?> { .init() }

        var sectors: Path<Int> { .init() }

        func releases(after _: GraphQLArgument<String?> = .argument,
                      first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
            return .init()
        }

        var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

        var node: FragmentPath<Music.Node> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Disc? {
        var id: Path<String?> { .init() }

        var discId: Path<String?> { .init() }

        var offsetCount: Path<Int?> { .init() }

        var offsets: Path<[Int?]?> { .init() }

        var sectors: Path<Int?> { .init() }

        func releases(after _: GraphQLArgument<String?> = .argument,
                      first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
            return .init()
        }

        var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

        var node: FragmentPath<Music.Node?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Track {
        var mbid: Path<String> { .init() }

        var title: Path<String?> { .init() }

        var position: Path<Int?> { .init() }

        var number: Path<String?> { .init() }

        var length: Path<String?> { .init() }

        var recording: FragmentPath<Music.Recording?> { .init() }

        var entity: FragmentPath<Music.Entity> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Track? {
        var mbid: Path<String?> { .init() }

        var title: Path<String?> { .init() }

        var position: Path<Int?> { .init() }

        var number: Path<String?> { .init() }

        var length: Path<String?> { .init() }

        var recording: FragmentPath<Music.Recording?> { .init() }

        var entity: FragmentPath<Music.Entity?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LabelConnection {
        var pageInfo: FragmentPath<Music.PageInfo> { .init() }

        var edges: FragmentPath<[Music.LabelEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Label?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LabelConnection? {
        var pageInfo: FragmentPath<Music.PageInfo?> { .init() }

        var edges: FragmentPath<[Music.LabelEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Label?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LabelEdge {
        var node: FragmentPath<Music.Label?> { .init() }

        var cursor: Path<String> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LabelEdge? {
        var node: FragmentPath<Music.Label?> { .init() }

        var cursor: Path<String?> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Label {
        var id: Path<String> { .init() }

        var mbid: Path<String> { .init() }

        var name: Path<String?> { .init() }

        var sortName: Path<String?> { .init() }

        var disambiguation: Path<String?> { .init() }

        var aliases: FragmentPath<[Music.Alias?]?> { .init() }

        var country: Path<String?> { .init() }

        var area: FragmentPath<Music.Area?> { .init() }

        var lifeSpan: FragmentPath<Music.LifeSpan?> { .init() }

        var labelCode: Path<Int?> { .init() }

        var ipis: Path<[String?]?> { .init() }

        var type: Path<String?> { .init() }

        var typeId: Path<String?> { .init() }

        func releases(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                      status _: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument,
                      after _: GraphQLArgument<String?> = .argument,
                      first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
            return .init()
        }

        var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        func collections(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        var rating: FragmentPath<Music.Rating?> { .init() }

        func tags(after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
            return .init()
        }

        var tags: FragmentPath<Music.TagConnection?> { .init() }

        var fanArt: FragmentPath<Music.FanArtLabel?> { .init() }

        func mediaWikiImages(type _: GraphQLArgument<String?> = .argument) -> FragmentPath<[Music.MediaWikiImage?]> {
            return .init()
        }

        var mediaWikiImages: FragmentPath<[Music.MediaWikiImage?]> { .init() }

        var discogs: FragmentPath<Music.DiscogsLabel?> { .init() }

        var node: FragmentPath<Music.Node> { .init() }

        var entity: FragmentPath<Music.Entity> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Label? {
        var id: Path<String?> { .init() }

        var mbid: Path<String?> { .init() }

        var name: Path<String?> { .init() }

        var sortName: Path<String?> { .init() }

        var disambiguation: Path<String?> { .init() }

        var aliases: FragmentPath<[Music.Alias?]?> { .init() }

        var country: Path<String?> { .init() }

        var area: FragmentPath<Music.Area?> { .init() }

        var lifeSpan: FragmentPath<Music.LifeSpan?> { .init() }

        var labelCode: Path<Int?> { .init() }

        var ipis: Path<[String?]?> { .init() }

        var type: Path<String?> { .init() }

        var typeId: Path<String?> { .init() }

        func releases(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                      status _: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument,
                      after _: GraphQLArgument<String?> = .argument,
                      first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
            return .init()
        }

        var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        func collections(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        var rating: FragmentPath<Music.Rating?> { .init() }

        func tags(after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
            return .init()
        }

        var tags: FragmentPath<Music.TagConnection?> { .init() }

        var fanArt: FragmentPath<Music.FanArtLabel?> { .init() }

        func mediaWikiImages(type _: GraphQLArgument<String?> = .argument) -> FragmentPath<[Music.MediaWikiImage?]?> {
            return .init()
        }

        var mediaWikiImages: FragmentPath<[Music.MediaWikiImage?]?> { .init() }

        var discogs: FragmentPath<Music.DiscogsLabel?> { .init() }

        var node: FragmentPath<Music.Node?> { .init() }

        var entity: FragmentPath<Music.Entity?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Relationships {
        func areas(direction _: GraphQLArgument<String?> = .argument,
                   type _: GraphQLArgument<String?> = .argument,
                   typeID _: GraphQLArgument<String?> = .argument,
                   after _: GraphQLArgument<String?> = .argument,
                   first _: GraphQLArgument<Int?> = .argument,
                   before _: GraphQLArgument<String?> = .argument,
                   last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var areas: FragmentPath<Music.RelationshipConnection?> { .init() }

        func artists(direction _: GraphQLArgument<String?> = .argument,
                     type _: GraphQLArgument<String?> = .argument,
                     typeID _: GraphQLArgument<String?> = .argument,
                     after _: GraphQLArgument<String?> = .argument,
                     first _: GraphQLArgument<Int?> = .argument,
                     before _: GraphQLArgument<String?> = .argument,
                     last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var artists: FragmentPath<Music.RelationshipConnection?> { .init() }

        func events(direction _: GraphQLArgument<String?> = .argument,
                    type _: GraphQLArgument<String?> = .argument,
                    typeID _: GraphQLArgument<String?> = .argument,
                    after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument,
                    before _: GraphQLArgument<String?> = .argument,
                    last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var events: FragmentPath<Music.RelationshipConnection?> { .init() }

        func instruments(direction _: GraphQLArgument<String?> = .argument,
                         type _: GraphQLArgument<String?> = .argument,
                         typeID _: GraphQLArgument<String?> = .argument,
                         after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument,
                         before _: GraphQLArgument<String?> = .argument,
                         last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var instruments: FragmentPath<Music.RelationshipConnection?> { .init() }

        func labels(direction _: GraphQLArgument<String?> = .argument,
                    type _: GraphQLArgument<String?> = .argument,
                    typeID _: GraphQLArgument<String?> = .argument,
                    after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument,
                    before _: GraphQLArgument<String?> = .argument,
                    last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var labels: FragmentPath<Music.RelationshipConnection?> { .init() }

        func places(direction _: GraphQLArgument<String?> = .argument,
                    type _: GraphQLArgument<String?> = .argument,
                    typeID _: GraphQLArgument<String?> = .argument,
                    after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument,
                    before _: GraphQLArgument<String?> = .argument,
                    last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var places: FragmentPath<Music.RelationshipConnection?> { .init() }

        func recordings(direction _: GraphQLArgument<String?> = .argument,
                        type _: GraphQLArgument<String?> = .argument,
                        typeID _: GraphQLArgument<String?> = .argument,
                        after _: GraphQLArgument<String?> = .argument,
                        first _: GraphQLArgument<Int?> = .argument,
                        before _: GraphQLArgument<String?> = .argument,
                        last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var recordings: FragmentPath<Music.RelationshipConnection?> { .init() }

        func releases(direction _: GraphQLArgument<String?> = .argument,
                      type _: GraphQLArgument<String?> = .argument,
                      typeID _: GraphQLArgument<String?> = .argument,
                      after _: GraphQLArgument<String?> = .argument,
                      first _: GraphQLArgument<Int?> = .argument,
                      before _: GraphQLArgument<String?> = .argument,
                      last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var releases: FragmentPath<Music.RelationshipConnection?> { .init() }

        func releaseGroups(direction _: GraphQLArgument<String?> = .argument,
                           type _: GraphQLArgument<String?> = .argument,
                           typeID _: GraphQLArgument<String?> = .argument,
                           after _: GraphQLArgument<String?> = .argument,
                           first _: GraphQLArgument<Int?> = .argument,
                           before _: GraphQLArgument<String?> = .argument,
                           last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var releaseGroups: FragmentPath<Music.RelationshipConnection?> { .init() }

        func series(direction _: GraphQLArgument<String?> = .argument,
                    type _: GraphQLArgument<String?> = .argument,
                    typeID _: GraphQLArgument<String?> = .argument,
                    after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument,
                    before _: GraphQLArgument<String?> = .argument,
                    last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var series: FragmentPath<Music.RelationshipConnection?> { .init() }

        func urls(direction _: GraphQLArgument<String?> = .argument,
                  type _: GraphQLArgument<String?> = .argument,
                  typeID _: GraphQLArgument<String?> = .argument,
                  after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument,
                  before _: GraphQLArgument<String?> = .argument,
                  last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var urls: FragmentPath<Music.RelationshipConnection?> { .init() }

        func works(direction _: GraphQLArgument<String?> = .argument,
                   type _: GraphQLArgument<String?> = .argument,
                   typeID _: GraphQLArgument<String?> = .argument,
                   after _: GraphQLArgument<String?> = .argument,
                   first _: GraphQLArgument<Int?> = .argument,
                   before _: GraphQLArgument<String?> = .argument,
                   last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var works: FragmentPath<Music.RelationshipConnection?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Relationships? {
        func areas(direction _: GraphQLArgument<String?> = .argument,
                   type _: GraphQLArgument<String?> = .argument,
                   typeID _: GraphQLArgument<String?> = .argument,
                   after _: GraphQLArgument<String?> = .argument,
                   first _: GraphQLArgument<Int?> = .argument,
                   before _: GraphQLArgument<String?> = .argument,
                   last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var areas: FragmentPath<Music.RelationshipConnection?> { .init() }

        func artists(direction _: GraphQLArgument<String?> = .argument,
                     type _: GraphQLArgument<String?> = .argument,
                     typeID _: GraphQLArgument<String?> = .argument,
                     after _: GraphQLArgument<String?> = .argument,
                     first _: GraphQLArgument<Int?> = .argument,
                     before _: GraphQLArgument<String?> = .argument,
                     last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var artists: FragmentPath<Music.RelationshipConnection?> { .init() }

        func events(direction _: GraphQLArgument<String?> = .argument,
                    type _: GraphQLArgument<String?> = .argument,
                    typeID _: GraphQLArgument<String?> = .argument,
                    after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument,
                    before _: GraphQLArgument<String?> = .argument,
                    last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var events: FragmentPath<Music.RelationshipConnection?> { .init() }

        func instruments(direction _: GraphQLArgument<String?> = .argument,
                         type _: GraphQLArgument<String?> = .argument,
                         typeID _: GraphQLArgument<String?> = .argument,
                         after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument,
                         before _: GraphQLArgument<String?> = .argument,
                         last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var instruments: FragmentPath<Music.RelationshipConnection?> { .init() }

        func labels(direction _: GraphQLArgument<String?> = .argument,
                    type _: GraphQLArgument<String?> = .argument,
                    typeID _: GraphQLArgument<String?> = .argument,
                    after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument,
                    before _: GraphQLArgument<String?> = .argument,
                    last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var labels: FragmentPath<Music.RelationshipConnection?> { .init() }

        func places(direction _: GraphQLArgument<String?> = .argument,
                    type _: GraphQLArgument<String?> = .argument,
                    typeID _: GraphQLArgument<String?> = .argument,
                    after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument,
                    before _: GraphQLArgument<String?> = .argument,
                    last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var places: FragmentPath<Music.RelationshipConnection?> { .init() }

        func recordings(direction _: GraphQLArgument<String?> = .argument,
                        type _: GraphQLArgument<String?> = .argument,
                        typeID _: GraphQLArgument<String?> = .argument,
                        after _: GraphQLArgument<String?> = .argument,
                        first _: GraphQLArgument<Int?> = .argument,
                        before _: GraphQLArgument<String?> = .argument,
                        last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var recordings: FragmentPath<Music.RelationshipConnection?> { .init() }

        func releases(direction _: GraphQLArgument<String?> = .argument,
                      type _: GraphQLArgument<String?> = .argument,
                      typeID _: GraphQLArgument<String?> = .argument,
                      after _: GraphQLArgument<String?> = .argument,
                      first _: GraphQLArgument<Int?> = .argument,
                      before _: GraphQLArgument<String?> = .argument,
                      last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var releases: FragmentPath<Music.RelationshipConnection?> { .init() }

        func releaseGroups(direction _: GraphQLArgument<String?> = .argument,
                           type _: GraphQLArgument<String?> = .argument,
                           typeID _: GraphQLArgument<String?> = .argument,
                           after _: GraphQLArgument<String?> = .argument,
                           first _: GraphQLArgument<Int?> = .argument,
                           before _: GraphQLArgument<String?> = .argument,
                           last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var releaseGroups: FragmentPath<Music.RelationshipConnection?> { .init() }

        func series(direction _: GraphQLArgument<String?> = .argument,
                    type _: GraphQLArgument<String?> = .argument,
                    typeID _: GraphQLArgument<String?> = .argument,
                    after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument,
                    before _: GraphQLArgument<String?> = .argument,
                    last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var series: FragmentPath<Music.RelationshipConnection?> { .init() }

        func urls(direction _: GraphQLArgument<String?> = .argument,
                  type _: GraphQLArgument<String?> = .argument,
                  typeID _: GraphQLArgument<String?> = .argument,
                  after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument,
                  before _: GraphQLArgument<String?> = .argument,
                  last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var urls: FragmentPath<Music.RelationshipConnection?> { .init() }

        func works(direction _: GraphQLArgument<String?> = .argument,
                   type _: GraphQLArgument<String?> = .argument,
                   typeID _: GraphQLArgument<String?> = .argument,
                   after _: GraphQLArgument<String?> = .argument,
                   first _: GraphQLArgument<Int?> = .argument,
                   before _: GraphQLArgument<String?> = .argument,
                   last _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RelationshipConnection?> {
            return .init()
        }

        var works: FragmentPath<Music.RelationshipConnection?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.RelationshipConnection {
        var pageInfo: FragmentPath<Music.PageInfo> { .init() }

        var edges: FragmentPath<[Music.RelationshipEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Relationship?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.RelationshipConnection? {
        var pageInfo: FragmentPath<Music.PageInfo?> { .init() }

        var edges: FragmentPath<[Music.RelationshipEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Relationship?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.RelationshipEdge {
        var node: FragmentPath<Music.Relationship?> { .init() }

        var cursor: Path<String> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.RelationshipEdge? {
        var node: FragmentPath<Music.Relationship?> { .init() }

        var cursor: Path<String?> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Relationship {
        var target: FragmentPath<Music.Entity> { .init() }

        var direction: Path<String> { .init() }

        var targetType: Path<String> { .init() }

        var sourceCredit: Path<String?> { .init() }

        var targetCredit: Path<String?> { .init() }

        var begin: Path<String?> { .init() }

        var end: Path<String?> { .init() }

        var ended: Path<Bool?> { .init() }

        var attributes: Path<[String?]?> { .init() }

        var type: Path<String?> { .init() }

        var typeId: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Relationship? {
        var target: FragmentPath<Music.Entity?> { .init() }

        var direction: Path<String?> { .init() }

        var targetType: Path<String?> { .init() }

        var sourceCredit: Path<String?> { .init() }

        var targetCredit: Path<String?> { .init() }

        var begin: Path<String?> { .init() }

        var end: Path<String?> { .init() }

        var ended: Path<Bool?> { .init() }

        var attributes: Path<[String?]?> { .init() }

        var type: Path<String?> { .init() }

        var typeId: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.CollectionConnection {
        var pageInfo: FragmentPath<Music.PageInfo> { .init() }

        var edges: FragmentPath<[Music.CollectionEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Collection?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.CollectionConnection? {
        var pageInfo: FragmentPath<Music.PageInfo?> { .init() }

        var edges: FragmentPath<[Music.CollectionEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Collection?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.CollectionEdge {
        var node: FragmentPath<Music.Collection?> { .init() }

        var cursor: Path<String> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.CollectionEdge? {
        var node: FragmentPath<Music.Collection?> { .init() }

        var cursor: Path<String?> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Collection {
        var id: Path<String> { .init() }

        var mbid: Path<String> { .init() }

        var name: Path<String?> { .init() }

        var editor: Path<String> { .init() }

        var entityType: Path<String> { .init() }

        var type: Path<String?> { .init() }

        var typeId: Path<String?> { .init() }

        func areas(after _: GraphQLArgument<String?> = .argument,
                   first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.AreaConnection?> {
            return .init()
        }

        var areas: FragmentPath<Music.AreaConnection?> { .init() }

        func artists(after _: GraphQLArgument<String?> = .argument,
                     first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
            return .init()
        }

        var artists: FragmentPath<Music.ArtistConnection?> { .init() }

        func events(after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.EventConnection?> {
            return .init()
        }

        var events: FragmentPath<Music.EventConnection?> { .init() }

        func instruments(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.InstrumentConnection?> {
            return .init()
        }

        var instruments: FragmentPath<Music.InstrumentConnection?> { .init() }

        func labels(after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.LabelConnection?> {
            return .init()
        }

        var labels: FragmentPath<Music.LabelConnection?> { .init() }

        func places(after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.PlaceConnection?> {
            return .init()
        }

        var places: FragmentPath<Music.PlaceConnection?> { .init() }

        func recordings(after _: GraphQLArgument<String?> = .argument,
                        first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RecordingConnection?> {
            return .init()
        }

        var recordings: FragmentPath<Music.RecordingConnection?> { .init() }

        func releases(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                      status _: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument,
                      after _: GraphQLArgument<String?> = .argument,
                      first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
            return .init()
        }

        var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

        func releaseGroups(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                           after _: GraphQLArgument<String?> = .argument,
                           first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseGroupConnection?> {
            return .init()
        }

        var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }

        func series(after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.SeriesConnection?> {
            return .init()
        }

        var series: FragmentPath<Music.SeriesConnection?> { .init() }

        func works(after _: GraphQLArgument<String?> = .argument,
                   first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.WorkConnection?> {
            return .init()
        }

        var works: FragmentPath<Music.WorkConnection?> { .init() }

        var node: FragmentPath<Music.Node> { .init() }

        var entity: FragmentPath<Music.Entity> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Collection? {
        var id: Path<String?> { .init() }

        var mbid: Path<String?> { .init() }

        var name: Path<String?> { .init() }

        var editor: Path<String?> { .init() }

        var entityType: Path<String?> { .init() }

        var type: Path<String?> { .init() }

        var typeId: Path<String?> { .init() }

        func areas(after _: GraphQLArgument<String?> = .argument,
                   first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.AreaConnection?> {
            return .init()
        }

        var areas: FragmentPath<Music.AreaConnection?> { .init() }

        func artists(after _: GraphQLArgument<String?> = .argument,
                     first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
            return .init()
        }

        var artists: FragmentPath<Music.ArtistConnection?> { .init() }

        func events(after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.EventConnection?> {
            return .init()
        }

        var events: FragmentPath<Music.EventConnection?> { .init() }

        func instruments(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.InstrumentConnection?> {
            return .init()
        }

        var instruments: FragmentPath<Music.InstrumentConnection?> { .init() }

        func labels(after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.LabelConnection?> {
            return .init()
        }

        var labels: FragmentPath<Music.LabelConnection?> { .init() }

        func places(after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.PlaceConnection?> {
            return .init()
        }

        var places: FragmentPath<Music.PlaceConnection?> { .init() }

        func recordings(after _: GraphQLArgument<String?> = .argument,
                        first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RecordingConnection?> {
            return .init()
        }

        var recordings: FragmentPath<Music.RecordingConnection?> { .init() }

        func releases(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                      status _: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument,
                      after _: GraphQLArgument<String?> = .argument,
                      first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
            return .init()
        }

        var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

        func releaseGroups(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                           after _: GraphQLArgument<String?> = .argument,
                           first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseGroupConnection?> {
            return .init()
        }

        var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }

        func series(after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.SeriesConnection?> {
            return .init()
        }

        var series: FragmentPath<Music.SeriesConnection?> { .init() }

        func works(after _: GraphQLArgument<String?> = .argument,
                   first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.WorkConnection?> {
            return .init()
        }

        var works: FragmentPath<Music.WorkConnection?> { .init() }

        var node: FragmentPath<Music.Node?> { .init() }

        var entity: FragmentPath<Music.Entity?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.AreaConnection {
        var pageInfo: FragmentPath<Music.PageInfo> { .init() }

        var edges: FragmentPath<[Music.AreaEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Area?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.AreaConnection? {
        var pageInfo: FragmentPath<Music.PageInfo?> { .init() }

        var edges: FragmentPath<[Music.AreaEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Area?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.AreaEdge {
        var node: FragmentPath<Music.Area?> { .init() }

        var cursor: Path<String> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.AreaEdge? {
        var node: FragmentPath<Music.Area?> { .init() }

        var cursor: Path<String?> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.EventConnection {
        var pageInfo: FragmentPath<Music.PageInfo> { .init() }

        var edges: FragmentPath<[Music.EventEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Event?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.EventConnection? {
        var pageInfo: FragmentPath<Music.PageInfo?> { .init() }

        var edges: FragmentPath<[Music.EventEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Event?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.EventEdge {
        var node: FragmentPath<Music.Event?> { .init() }

        var cursor: Path<String> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.EventEdge? {
        var node: FragmentPath<Music.Event?> { .init() }

        var cursor: Path<String?> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Event {
        var id: Path<String> { .init() }

        var mbid: Path<String> { .init() }

        var name: Path<String?> { .init() }

        var disambiguation: Path<String?> { .init() }

        var aliases: FragmentPath<[Music.Alias?]?> { .init() }

        var lifeSpan: FragmentPath<Music.LifeSpan?> { .init() }

        var time: Path<String?> { .init() }

        var cancelled: Path<Bool?> { .init() }

        var setlist: Path<String?> { .init() }

        var type: Path<String?> { .init() }

        var typeId: Path<String?> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        func collections(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        var rating: FragmentPath<Music.Rating?> { .init() }

        func tags(after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
            return .init()
        }

        var tags: FragmentPath<Music.TagConnection?> { .init() }

        var node: FragmentPath<Music.Node> { .init() }

        var entity: FragmentPath<Music.Entity> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Event? {
        var id: Path<String?> { .init() }

        var mbid: Path<String?> { .init() }

        var name: Path<String?> { .init() }

        var disambiguation: Path<String?> { .init() }

        var aliases: FragmentPath<[Music.Alias?]?> { .init() }

        var lifeSpan: FragmentPath<Music.LifeSpan?> { .init() }

        var time: Path<String?> { .init() }

        var cancelled: Path<Bool?> { .init() }

        var setlist: Path<String?> { .init() }

        var type: Path<String?> { .init() }

        var typeId: Path<String?> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        func collections(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        var rating: FragmentPath<Music.Rating?> { .init() }

        func tags(after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
            return .init()
        }

        var tags: FragmentPath<Music.TagConnection?> { .init() }

        var node: FragmentPath<Music.Node?> { .init() }

        var entity: FragmentPath<Music.Entity?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Rating {
        var voteCount: Path<Int> { .init() }

        var value: Path<Double?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Rating? {
        var voteCount: Path<Int?> { .init() }

        var value: Path<Double?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.TagConnection {
        var pageInfo: FragmentPath<Music.PageInfo> { .init() }

        var edges: FragmentPath<[Music.TagEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Tag?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.TagConnection? {
        var pageInfo: FragmentPath<Music.PageInfo?> { .init() }

        var edges: FragmentPath<[Music.TagEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Tag?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.TagEdge {
        var node: FragmentPath<Music.Tag?> { .init() }

        var cursor: Path<String> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.TagEdge? {
        var node: FragmentPath<Music.Tag?> { .init() }

        var cursor: Path<String?> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Tag {
        var name: Path<String> { .init() }

        var count: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Tag? {
        var name: Path<String?> { .init() }

        var count: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.InstrumentConnection {
        var pageInfo: FragmentPath<Music.PageInfo> { .init() }

        var edges: FragmentPath<[Music.InstrumentEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Instrument?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.InstrumentConnection? {
        var pageInfo: FragmentPath<Music.PageInfo?> { .init() }

        var edges: FragmentPath<[Music.InstrumentEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Instrument?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.InstrumentEdge {
        var node: FragmentPath<Music.Instrument?> { .init() }

        var cursor: Path<String> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.InstrumentEdge? {
        var node: FragmentPath<Music.Instrument?> { .init() }

        var cursor: Path<String?> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Instrument {
        var id: Path<String> { .init() }

        var mbid: Path<String> { .init() }

        var name: Path<String?> { .init() }

        var disambiguation: Path<String?> { .init() }

        var aliases: FragmentPath<[Music.Alias?]?> { .init() }

        var description: Path<String?> { .init() }

        var type: Path<String?> { .init() }

        var typeId: Path<String?> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        func collections(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        func tags(after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
            return .init()
        }

        var tags: FragmentPath<Music.TagConnection?> { .init() }

        func mediaWikiImages(type _: GraphQLArgument<String?> = .argument) -> FragmentPath<[Music.MediaWikiImage?]> {
            return .init()
        }

        var mediaWikiImages: FragmentPath<[Music.MediaWikiImage?]> { .init() }

        var node: FragmentPath<Music.Node> { .init() }

        var entity: FragmentPath<Music.Entity> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Instrument? {
        var id: Path<String?> { .init() }

        var mbid: Path<String?> { .init() }

        var name: Path<String?> { .init() }

        var disambiguation: Path<String?> { .init() }

        var aliases: FragmentPath<[Music.Alias?]?> { .init() }

        var description: Path<String?> { .init() }

        var type: Path<String?> { .init() }

        var typeId: Path<String?> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        func collections(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        func tags(after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
            return .init()
        }

        var tags: FragmentPath<Music.TagConnection?> { .init() }

        func mediaWikiImages(type _: GraphQLArgument<String?> = .argument) -> FragmentPath<[Music.MediaWikiImage?]?> {
            return .init()
        }

        var mediaWikiImages: FragmentPath<[Music.MediaWikiImage?]?> { .init() }

        var node: FragmentPath<Music.Node?> { .init() }

        var entity: FragmentPath<Music.Entity?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.MediaWikiImage {
        var url: Path<String> { .init() }

        var descriptionUrl: Path<String?> { .init() }

        var user: Path<String?> { .init() }

        var size: Path<Int?> { .init() }

        var width: Path<Int?> { .init() }

        var height: Path<Int?> { .init() }

        var canonicalTitle: Path<String?> { .init() }

        var objectName: Path<String?> { .init() }

        var descriptionHtml: Path<String?> { .init() }

        var originalDateTimeHtml: Path<String?> { .init() }

        var categories: Path<[String?]> { .init() }

        var artistHtml: Path<String?> { .init() }

        var creditHtml: Path<String?> { .init() }

        var licenseShortName: Path<String?> { .init() }

        var licenseUrl: Path<String?> { .init() }

        var metadata: FragmentPath<[Music.MediaWikiImageMetadata?]> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.MediaWikiImage? {
        var url: Path<String?> { .init() }

        var descriptionUrl: Path<String?> { .init() }

        var user: Path<String?> { .init() }

        var size: Path<Int?> { .init() }

        var width: Path<Int?> { .init() }

        var height: Path<Int?> { .init() }

        var canonicalTitle: Path<String?> { .init() }

        var objectName: Path<String?> { .init() }

        var descriptionHtml: Path<String?> { .init() }

        var originalDateTimeHtml: Path<String?> { .init() }

        var categories: Path<[String?]?> { .init() }

        var artistHtml: Path<String?> { .init() }

        var creditHtml: Path<String?> { .init() }

        var licenseShortName: Path<String?> { .init() }

        var licenseUrl: Path<String?> { .init() }

        var metadata: FragmentPath<[Music.MediaWikiImageMetadata?]?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.MediaWikiImageMetadata {
        var name: Path<String> { .init() }

        var value: Path<String?> { .init() }

        var source: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.MediaWikiImageMetadata? {
        var name: Path<String?> { .init() }

        var value: Path<String?> { .init() }

        var source: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.PlaceConnection {
        var pageInfo: FragmentPath<Music.PageInfo> { .init() }

        var edges: FragmentPath<[Music.PlaceEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Place?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.PlaceConnection? {
        var pageInfo: FragmentPath<Music.PageInfo?> { .init() }

        var edges: FragmentPath<[Music.PlaceEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Place?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.PlaceEdge {
        var node: FragmentPath<Music.Place?> { .init() }

        var cursor: Path<String> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.PlaceEdge? {
        var node: FragmentPath<Music.Place?> { .init() }

        var cursor: Path<String?> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Place {
        var id: Path<String> { .init() }

        var mbid: Path<String> { .init() }

        var name: Path<String?> { .init() }

        var disambiguation: Path<String?> { .init() }

        var aliases: FragmentPath<[Music.Alias?]?> { .init() }

        var address: Path<String?> { .init() }

        var area: FragmentPath<Music.Area?> { .init() }

        var coordinates: FragmentPath<Music.Coordinates?> { .init() }

        var lifeSpan: FragmentPath<Music.LifeSpan?> { .init() }

        var type: Path<String?> { .init() }

        var typeId: Path<String?> { .init() }

        func events(after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.EventConnection?> {
            return .init()
        }

        var events: FragmentPath<Music.EventConnection?> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        func collections(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        func tags(after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
            return .init()
        }

        var tags: FragmentPath<Music.TagConnection?> { .init() }

        func mediaWikiImages(type _: GraphQLArgument<String?> = .argument) -> FragmentPath<[Music.MediaWikiImage?]> {
            return .init()
        }

        var mediaWikiImages: FragmentPath<[Music.MediaWikiImage?]> { .init() }

        var node: FragmentPath<Music.Node> { .init() }

        var entity: FragmentPath<Music.Entity> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Place? {
        var id: Path<String?> { .init() }

        var mbid: Path<String?> { .init() }

        var name: Path<String?> { .init() }

        var disambiguation: Path<String?> { .init() }

        var aliases: FragmentPath<[Music.Alias?]?> { .init() }

        var address: Path<String?> { .init() }

        var area: FragmentPath<Music.Area?> { .init() }

        var coordinates: FragmentPath<Music.Coordinates?> { .init() }

        var lifeSpan: FragmentPath<Music.LifeSpan?> { .init() }

        var type: Path<String?> { .init() }

        var typeId: Path<String?> { .init() }

        func events(after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.EventConnection?> {
            return .init()
        }

        var events: FragmentPath<Music.EventConnection?> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        func collections(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        func tags(after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
            return .init()
        }

        var tags: FragmentPath<Music.TagConnection?> { .init() }

        func mediaWikiImages(type _: GraphQLArgument<String?> = .argument) -> FragmentPath<[Music.MediaWikiImage?]?> {
            return .init()
        }

        var mediaWikiImages: FragmentPath<[Music.MediaWikiImage?]?> { .init() }

        var node: FragmentPath<Music.Node?> { .init() }

        var entity: FragmentPath<Music.Entity?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Coordinates {
        var latitude: Path<String?> { .init() }

        var longitude: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Coordinates? {
        var latitude: Path<String?> { .init() }

        var longitude: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.ReleaseGroupConnection {
        var pageInfo: FragmentPath<Music.PageInfo> { .init() }

        var edges: FragmentPath<[Music.ReleaseGroupEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.ReleaseGroup?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.ReleaseGroupConnection? {
        var pageInfo: FragmentPath<Music.PageInfo?> { .init() }

        var edges: FragmentPath<[Music.ReleaseGroupEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.ReleaseGroup?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.ReleaseGroupEdge {
        var node: FragmentPath<Music.ReleaseGroup?> { .init() }

        var cursor: Path<String> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.ReleaseGroupEdge? {
        var node: FragmentPath<Music.ReleaseGroup?> { .init() }

        var cursor: Path<String?> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.ReleaseGroup {
        var id: Path<String> { .init() }

        var mbid: Path<String> { .init() }

        var title: Path<String?> { .init() }

        var disambiguation: Path<String?> { .init() }

        var aliases: FragmentPath<[Music.Alias?]?> { .init() }

        var artistCredit: FragmentPath<[Music.ArtistCredit?]?> { .init() }

        var artistCredits: FragmentPath<[Music.ArtistCredit?]?> { .init() }

        var firstReleaseDate: Path<String?> { .init() }

        var primaryType: Path<Music.ReleaseGroupType?> { .init() }

        var primaryTypeId: Path<String?> { .init() }

        var secondaryTypes: Path<[Music.ReleaseGroupType?]?> { .init() }

        var secondaryTypeIDs: Path<[String?]?> { .init() }

        func artists(after _: GraphQLArgument<String?> = .argument,
                     first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
            return .init()
        }

        var artists: FragmentPath<Music.ArtistConnection?> { .init() }

        func releases(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                      status _: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument,
                      after _: GraphQLArgument<String?> = .argument,
                      first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
            return .init()
        }

        var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        func collections(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        var rating: FragmentPath<Music.Rating?> { .init() }

        func tags(after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
            return .init()
        }

        var tags: FragmentPath<Music.TagConnection?> { .init() }

        var coverArtArchive: FragmentPath<Music.CoverArtArchiveRelease?> { .init() }

        var fanArt: FragmentPath<Music.FanArtAlbum?> { .init() }

        var theAudioDb: FragmentPath<Music.TheAudioDbAlbum?> { .init() }

        var discogs: FragmentPath<Music.DiscogsMaster?> { .init() }

        var node: FragmentPath<Music.Node> { .init() }

        var entity: FragmentPath<Music.Entity> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.ReleaseGroup? {
        var id: Path<String?> { .init() }

        var mbid: Path<String?> { .init() }

        var title: Path<String?> { .init() }

        var disambiguation: Path<String?> { .init() }

        var aliases: FragmentPath<[Music.Alias?]?> { .init() }

        var artistCredit: FragmentPath<[Music.ArtistCredit?]?> { .init() }

        var artistCredits: FragmentPath<[Music.ArtistCredit?]?> { .init() }

        var firstReleaseDate: Path<String?> { .init() }

        var primaryType: Path<Music.ReleaseGroupType?> { .init() }

        var primaryTypeId: Path<String?> { .init() }

        var secondaryTypes: Path<[Music.ReleaseGroupType?]?> { .init() }

        var secondaryTypeIDs: Path<[String?]?> { .init() }

        func artists(after _: GraphQLArgument<String?> = .argument,
                     first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
            return .init()
        }

        var artists: FragmentPath<Music.ArtistConnection?> { .init() }

        func releases(type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                      status _: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument,
                      after _: GraphQLArgument<String?> = .argument,
                      first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
            return .init()
        }

        var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        func collections(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        var rating: FragmentPath<Music.Rating?> { .init() }

        func tags(after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
            return .init()
        }

        var tags: FragmentPath<Music.TagConnection?> { .init() }

        var coverArtArchive: FragmentPath<Music.CoverArtArchiveRelease?> { .init() }

        var fanArt: FragmentPath<Music.FanArtAlbum?> { .init() }

        var theAudioDb: FragmentPath<Music.TheAudioDbAlbum?> { .init() }

        var discogs: FragmentPath<Music.DiscogsMaster?> { .init() }

        var node: FragmentPath<Music.Node?> { .init() }

        var entity: FragmentPath<Music.Entity?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.CoverArtArchiveRelease {
        func front(size _: GraphQLArgument<Music.CoverArtArchiveImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var front: Path<String?> { .init() }

        func back(size _: GraphQLArgument<Music.CoverArtArchiveImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var back: Path<String?> { .init() }

        var images: FragmentPath<[Music.CoverArtArchiveImage?]> { .init() }

        var artwork: Path<Bool> { .init() }

        var count: Path<Int> { .init() }

        var release: FragmentPath<Music.Release?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.CoverArtArchiveRelease? {
        func front(size _: GraphQLArgument<Music.CoverArtArchiveImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var front: Path<String?> { .init() }

        func back(size _: GraphQLArgument<Music.CoverArtArchiveImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var back: Path<String?> { .init() }

        var images: FragmentPath<[Music.CoverArtArchiveImage?]?> { .init() }

        var artwork: Path<Bool?> { .init() }

        var count: Path<Int?> { .init() }

        var release: FragmentPath<Music.Release?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.CoverArtArchiveImageSize {}

    extension GraphQLFragmentPath where UnderlyingType == Music.CoverArtArchiveImageSize? {}

    extension GraphQLFragmentPath where UnderlyingType == Music.CoverArtArchiveImage {
        var fileId: Path<String> { .init() }

        var image: Path<String> { .init() }

        var thumbnails: FragmentPath<Music.CoverArtArchiveImageThumbnails> { .init() }

        var front: Path<Bool> { .init() }

        var back: Path<Bool> { .init() }

        var types: Path<[String?]> { .init() }

        var edit: Path<Int?> { .init() }

        var approved: Path<Bool?> { .init() }

        var comment: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.CoverArtArchiveImage? {
        var fileId: Path<String?> { .init() }

        var image: Path<String?> { .init() }

        var thumbnails: FragmentPath<Music.CoverArtArchiveImageThumbnails?> { .init() }

        var front: Path<Bool?> { .init() }

        var back: Path<Bool?> { .init() }

        var types: Path<[String?]?> { .init() }

        var edit: Path<Int?> { .init() }

        var approved: Path<Bool?> { .init() }

        var comment: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.CoverArtArchiveImageThumbnails {
        var small: Path<String?> { .init() }

        var large: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.CoverArtArchiveImageThumbnails? {
        var small: Path<String?> { .init() }

        var large: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.FanArtAlbum {
        var albumCovers: FragmentPath<[Music.FanArtImage?]?> { .init() }

        var discImages: FragmentPath<[Music.FanArtDiscImage?]?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.FanArtAlbum? {
        var albumCovers: FragmentPath<[Music.FanArtImage?]?> { .init() }

        var discImages: FragmentPath<[Music.FanArtDiscImage?]?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.FanArtImage {
        var imageId: Path<String?> { .init() }

        func url(size _: GraphQLArgument<Music.FanArtImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var url: Path<String?> { .init() }

        var likeCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.FanArtImage? {
        var imageId: Path<String?> { .init() }

        func url(size _: GraphQLArgument<Music.FanArtImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var url: Path<String?> { .init() }

        var likeCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.FanArtImageSize {}

    extension GraphQLFragmentPath where UnderlyingType == Music.FanArtImageSize? {}

    extension GraphQLFragmentPath where UnderlyingType == Music.FanArtDiscImage {
        var imageId: Path<String?> { .init() }

        func url(size _: GraphQLArgument<Music.FanArtImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var url: Path<String?> { .init() }

        var likeCount: Path<Int?> { .init() }

        var discNumber: Path<Int?> { .init() }

        var size: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.FanArtDiscImage? {
        var imageId: Path<String?> { .init() }

        func url(size _: GraphQLArgument<Music.FanArtImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var url: Path<String?> { .init() }

        var likeCount: Path<Int?> { .init() }

        var discNumber: Path<Int?> { .init() }

        var size: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDbAlbum {
        var albumId: Path<String?> { .init() }

        var artistId: Path<String?> { .init() }

        func description(lang _: GraphQLArgument<String?> = .argument) -> Path<String?> {
            return .init()
        }

        var description: Path<String?> { .init() }

        var review: Path<String?> { .init() }

        var salesCount: Path<Double?> { .init() }

        var score: Path<Double?> { .init() }

        var scoreVotes: Path<Double?> { .init() }

        func discImage(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var discImage: Path<String?> { .init() }

        func spineImage(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var spineImage: Path<String?> { .init() }

        func frontImage(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var frontImage: Path<String?> { .init() }

        func backImage(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var backImage: Path<String?> { .init() }

        var genre: Path<String?> { .init() }

        var mood: Path<String?> { .init() }

        var style: Path<String?> { .init() }

        var speed: Path<String?> { .init() }

        var theme: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDbAlbum? {
        var albumId: Path<String?> { .init() }

        var artistId: Path<String?> { .init() }

        func description(lang _: GraphQLArgument<String?> = .argument) -> Path<String?> {
            return .init()
        }

        var description: Path<String?> { .init() }

        var review: Path<String?> { .init() }

        var salesCount: Path<Double?> { .init() }

        var score: Path<Double?> { .init() }

        var scoreVotes: Path<Double?> { .init() }

        func discImage(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var discImage: Path<String?> { .init() }

        func spineImage(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var spineImage: Path<String?> { .init() }

        func frontImage(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var frontImage: Path<String?> { .init() }

        func backImage(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var backImage: Path<String?> { .init() }

        var genre: Path<String?> { .init() }

        var mood: Path<String?> { .init() }

        var style: Path<String?> { .init() }

        var speed: Path<String?> { .init() }

        var theme: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDbImageSize {}

    extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDbImageSize? {}

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsMaster {
        var masterId: Path<String> { .init() }

        var title: Path<String> { .init() }

        var url: Path<String> { .init() }

        var artistCredits: FragmentPath<[Music.DiscogsArtistCredit]> { .init() }

        var genres: Path<[String]> { .init() }

        var styles: Path<[String]> { .init() }

        var forSaleCount: Path<Int?> { .init() }

        func lowestPrice(currency _: GraphQLArgument<String?> = .argument) -> Path<Double?> {
            return .init()
        }

        var lowestPrice: Path<Double?> { .init() }

        var year: Path<Int?> { .init() }

        var mainRelease: FragmentPath<Music.DiscogsRelease?> { .init() }

        var images: FragmentPath<[Music.DiscogsImage]> { .init() }

        var videos: FragmentPath<[Music.DiscogsVideo]> { .init() }

        var dataQuality: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsMaster? {
        var masterId: Path<String?> { .init() }

        var title: Path<String?> { .init() }

        var url: Path<String?> { .init() }

        var artistCredits: FragmentPath<[Music.DiscogsArtistCredit]?> { .init() }

        var genres: Path<[String]?> { .init() }

        var styles: Path<[String]?> { .init() }

        var forSaleCount: Path<Int?> { .init() }

        func lowestPrice(currency _: GraphQLArgument<String?> = .argument) -> Path<Double?> {
            return .init()
        }

        var lowestPrice: Path<Double?> { .init() }

        var year: Path<Int?> { .init() }

        var mainRelease: FragmentPath<Music.DiscogsRelease?> { .init() }

        var images: FragmentPath<[Music.DiscogsImage]?> { .init() }

        var videos: FragmentPath<[Music.DiscogsVideo]?> { .init() }

        var dataQuality: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsArtistCredit {
        var name: Path<String?> { .init() }

        var nameVariation: Path<String?> { .init() }

        var joinPhrase: Path<String?> { .init() }

        var roles: Path<[String]> { .init() }

        var tracks: Path<[String]> { .init() }

        var artist: FragmentPath<Music.DiscogsArtist?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsArtistCredit? {
        var name: Path<String?> { .init() }

        var nameVariation: Path<String?> { .init() }

        var joinPhrase: Path<String?> { .init() }

        var roles: Path<[String]?> { .init() }

        var tracks: Path<[String]?> { .init() }

        var artist: FragmentPath<Music.DiscogsArtist?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsArtist {
        var artistId: Path<String> { .init() }

        var name: Path<String> { .init() }

        var nameVariations: Path<[String]> { .init() }

        var realName: Path<String?> { .init() }

        var aliases: FragmentPath<[Music.DiscogsArtist]> { .init() }

        var url: Path<String> { .init() }

        var urls: Path<[String]> { .init() }

        var profile: Path<String?> { .init() }

        var images: FragmentPath<[Music.DiscogsImage]> { .init() }

        var members: FragmentPath<[Music.DiscogsArtistMember]> { .init() }

        var dataQuality: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsArtist? {
        var artistId: Path<String?> { .init() }

        var name: Path<String?> { .init() }

        var nameVariations: Path<[String]?> { .init() }

        var realName: Path<String?> { .init() }

        var aliases: FragmentPath<[Music.DiscogsArtist]?> { .init() }

        var url: Path<String?> { .init() }

        var urls: Path<[String]?> { .init() }

        var profile: Path<String?> { .init() }

        var images: FragmentPath<[Music.DiscogsImage]?> { .init() }

        var members: FragmentPath<[Music.DiscogsArtistMember]?> { .init() }

        var dataQuality: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsImage {
        var url: Path<String> { .init() }

        var type: Path<Music.DiscogsImageType> { .init() }

        var width: Path<Int> { .init() }

        var height: Path<Int> { .init() }

        var thumbnail: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsImage? {
        var url: Path<String?> { .init() }

        var type: Path<Music.DiscogsImageType?> { .init() }

        var width: Path<Int?> { .init() }

        var height: Path<Int?> { .init() }

        var thumbnail: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsImageType {}

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsImageType? {}

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsArtistMember {
        var active: Path<Bool?> { .init() }

        var name: Path<String> { .init() }

        var artist: FragmentPath<Music.DiscogsArtist?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsArtistMember? {
        var active: Path<Bool?> { .init() }

        var name: Path<String?> { .init() }

        var artist: FragmentPath<Music.DiscogsArtist?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsRelease {
        var releaseId: Path<String> { .init() }

        var title: Path<String> { .init() }

        var url: Path<String> { .init() }

        var artistCredits: FragmentPath<[Music.DiscogsArtistCredit]> { .init() }

        var extraArtistCredits: FragmentPath<[Music.DiscogsArtistCredit]> { .init() }

        var genres: Path<[String]> { .init() }

        var styles: Path<[String]> { .init() }

        var forSaleCount: Path<Int?> { .init() }

        func lowestPrice(currency _: GraphQLArgument<String?> = .argument) -> Path<Double?> {
            return .init()
        }

        var lowestPrice: Path<Double?> { .init() }

        var year: Path<Int?> { .init() }

        var notes: Path<String?> { .init() }

        var country: Path<String?> { .init() }

        var master: FragmentPath<Music.DiscogsMaster?> { .init() }

        var thumbnail: Path<String?> { .init() }

        var images: FragmentPath<[Music.DiscogsImage]> { .init() }

        var videos: FragmentPath<[Music.DiscogsVideo]> { .init() }

        var community: FragmentPath<Music.DiscogsCommunity?> { .init() }

        var dataQuality: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsRelease? {
        var releaseId: Path<String?> { .init() }

        var title: Path<String?> { .init() }

        var url: Path<String?> { .init() }

        var artistCredits: FragmentPath<[Music.DiscogsArtistCredit]?> { .init() }

        var extraArtistCredits: FragmentPath<[Music.DiscogsArtistCredit]?> { .init() }

        var genres: Path<[String]?> { .init() }

        var styles: Path<[String]?> { .init() }

        var forSaleCount: Path<Int?> { .init() }

        func lowestPrice(currency _: GraphQLArgument<String?> = .argument) -> Path<Double?> {
            return .init()
        }

        var lowestPrice: Path<Double?> { .init() }

        var year: Path<Int?> { .init() }

        var notes: Path<String?> { .init() }

        var country: Path<String?> { .init() }

        var master: FragmentPath<Music.DiscogsMaster?> { .init() }

        var thumbnail: Path<String?> { .init() }

        var images: FragmentPath<[Music.DiscogsImage]?> { .init() }

        var videos: FragmentPath<[Music.DiscogsVideo]?> { .init() }

        var community: FragmentPath<Music.DiscogsCommunity?> { .init() }

        var dataQuality: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsVideo {
        var url: Path<String> { .init() }

        var title: Path<String?> { .init() }

        var description: Path<String?> { .init() }

        var duration: Path<String?> { .init() }

        var embed: Path<Bool?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsVideo? {
        var url: Path<String?> { .init() }

        var title: Path<String?> { .init() }

        var description: Path<String?> { .init() }

        var duration: Path<String?> { .init() }

        var embed: Path<Bool?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsCommunity {
        var status: Path<String?> { .init() }

        var rating: FragmentPath<Music.DiscogsRating?> { .init() }

        var haveCount: Path<Int?> { .init() }

        var wantCount: Path<Int?> { .init() }

        var contributors: FragmentPath<[Music.DiscogsUser]> { .init() }

        var submitter: FragmentPath<Music.DiscogsUser?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsCommunity? {
        var status: Path<String?> { .init() }

        var rating: FragmentPath<Music.DiscogsRating?> { .init() }

        var haveCount: Path<Int?> { .init() }

        var wantCount: Path<Int?> { .init() }

        var contributors: FragmentPath<[Music.DiscogsUser]?> { .init() }

        var submitter: FragmentPath<Music.DiscogsUser?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsRating {
        var voteCount: Path<Int> { .init() }

        var value: Path<Double?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsRating? {
        var voteCount: Path<Int?> { .init() }

        var value: Path<Double?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsUser {
        var username: Path<String> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsUser? {
        var username: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SeriesConnection {
        var pageInfo: FragmentPath<Music.PageInfo> { .init() }

        var edges: FragmentPath<[Music.SeriesEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Series?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SeriesConnection? {
        var pageInfo: FragmentPath<Music.PageInfo?> { .init() }

        var edges: FragmentPath<[Music.SeriesEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Series?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SeriesEdge {
        var node: FragmentPath<Music.Series?> { .init() }

        var cursor: Path<String> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SeriesEdge? {
        var node: FragmentPath<Music.Series?> { .init() }

        var cursor: Path<String?> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Series {
        var id: Path<String> { .init() }

        var mbid: Path<String> { .init() }

        var name: Path<String?> { .init() }

        var disambiguation: Path<String?> { .init() }

        var type: Path<String?> { .init() }

        var typeId: Path<String?> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        func collections(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        func tags(after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
            return .init()
        }

        var tags: FragmentPath<Music.TagConnection?> { .init() }

        var node: FragmentPath<Music.Node> { .init() }

        var entity: FragmentPath<Music.Entity> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Series? {
        var id: Path<String?> { .init() }

        var mbid: Path<String?> { .init() }

        var name: Path<String?> { .init() }

        var disambiguation: Path<String?> { .init() }

        var type: Path<String?> { .init() }

        var typeId: Path<String?> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        func collections(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        func tags(after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
            return .init()
        }

        var tags: FragmentPath<Music.TagConnection?> { .init() }

        var node: FragmentPath<Music.Node?> { .init() }

        var entity: FragmentPath<Music.Entity?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.WorkConnection {
        var pageInfo: FragmentPath<Music.PageInfo> { .init() }

        var edges: FragmentPath<[Music.WorkEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Work?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.WorkConnection? {
        var pageInfo: FragmentPath<Music.PageInfo?> { .init() }

        var edges: FragmentPath<[Music.WorkEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.Work?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.WorkEdge {
        var node: FragmentPath<Music.Work?> { .init() }

        var cursor: Path<String> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.WorkEdge? {
        var node: FragmentPath<Music.Work?> { .init() }

        var cursor: Path<String?> { .init() }

        var score: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Work {
        var id: Path<String> { .init() }

        var mbid: Path<String> { .init() }

        var title: Path<String?> { .init() }

        var disambiguation: Path<String?> { .init() }

        var aliases: FragmentPath<[Music.Alias?]?> { .init() }

        var iswcs: Path<[String?]?> { .init() }

        var language: Path<String?> { .init() }

        var type: Path<String?> { .init() }

        var typeId: Path<String?> { .init() }

        func artists(after _: GraphQLArgument<String?> = .argument,
                     first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
            return .init()
        }

        var artists: FragmentPath<Music.ArtistConnection?> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        func collections(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        var rating: FragmentPath<Music.Rating?> { .init() }

        func tags(after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
            return .init()
        }

        var tags: FragmentPath<Music.TagConnection?> { .init() }

        var node: FragmentPath<Music.Node> { .init() }

        var entity: FragmentPath<Music.Entity> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Work? {
        var id: Path<String?> { .init() }

        var mbid: Path<String?> { .init() }

        var title: Path<String?> { .init() }

        var disambiguation: Path<String?> { .init() }

        var aliases: FragmentPath<[Music.Alias?]?> { .init() }

        var iswcs: Path<[String?]?> { .init() }

        var language: Path<String?> { .init() }

        var type: Path<String?> { .init() }

        var typeId: Path<String?> { .init() }

        func artists(after _: GraphQLArgument<String?> = .argument,
                     first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
            return .init()
        }

        var artists: FragmentPath<Music.ArtistConnection?> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        func collections(after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        var rating: FragmentPath<Music.Rating?> { .init() }

        func tags(after _: GraphQLArgument<String?> = .argument,
                  first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.TagConnection?> {
            return .init()
        }

        var tags: FragmentPath<Music.TagConnection?> { .init() }

        var node: FragmentPath<Music.Node?> { .init() }

        var entity: FragmentPath<Music.Entity?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.FanArtLabel {
        var logos: FragmentPath<[Music.FanArtLabelImage?]?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.FanArtLabel? {
        var logos: FragmentPath<[Music.FanArtLabelImage?]?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.FanArtLabelImage {
        var imageId: Path<String?> { .init() }

        func url(size _: GraphQLArgument<Music.FanArtImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var url: Path<String?> { .init() }

        var likeCount: Path<Int?> { .init() }

        var color: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.FanArtLabelImage? {
        var imageId: Path<String?> { .init() }

        func url(size _: GraphQLArgument<Music.FanArtImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var url: Path<String?> { .init() }

        var likeCount: Path<Int?> { .init() }

        var color: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsLabel {
        var labelId: Path<String> { .init() }

        var name: Path<String> { .init() }

        var url: Path<String> { .init() }

        var profile: Path<String?> { .init() }

        var contactInfo: Path<String?> { .init() }

        var parentLabel: FragmentPath<Music.DiscogsLabel?> { .init() }

        var subLabels: FragmentPath<[Music.DiscogsLabel]> { .init() }

        var images: FragmentPath<[Music.DiscogsImage]> { .init() }

        var dataQuality: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsLabel? {
        var labelId: Path<String?> { .init() }

        var name: Path<String?> { .init() }

        var url: Path<String?> { .init() }

        var profile: Path<String?> { .init() }

        var contactInfo: Path<String?> { .init() }

        var parentLabel: FragmentPath<Music.DiscogsLabel?> { .init() }

        var subLabels: FragmentPath<[Music.DiscogsLabel]?> { .init() }

        var images: FragmentPath<[Music.DiscogsImage]?> { .init() }

        var dataQuality: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmAlbum {
        var mbid: Path<String?> { .init() }

        var title: Path<String?> { .init() }

        var url: Path<String> { .init() }

        func image(size _: GraphQLArgument<Music.LastFmImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var image: Path<String?> { .init() }

        var listenerCount: Path<Double?> { .init() }

        var playCount: Path<Double?> { .init() }

        func description(lang _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmWikiContent?> {
            return .init()
        }

        var description: FragmentPath<Music.LastFmWikiContent?> { .init() }

        var artist: FragmentPath<Music.LastFmArtist?> { .init() }

        func topTags(first _: GraphQLArgument<Int?> = .argument,
                     after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTagConnection?> {
            return .init()
        }

        var topTags: FragmentPath<Music.LastFmTagConnection?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmAlbum? {
        var mbid: Path<String?> { .init() }

        var title: Path<String?> { .init() }

        var url: Path<String?> { .init() }

        func image(size _: GraphQLArgument<Music.LastFmImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var image: Path<String?> { .init() }

        var listenerCount: Path<Double?> { .init() }

        var playCount: Path<Double?> { .init() }

        func description(lang _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmWikiContent?> {
            return .init()
        }

        var description: FragmentPath<Music.LastFmWikiContent?> { .init() }

        var artist: FragmentPath<Music.LastFmArtist?> { .init() }

        func topTags(first _: GraphQLArgument<Int?> = .argument,
                     after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTagConnection?> {
            return .init()
        }

        var topTags: FragmentPath<Music.LastFmTagConnection?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmImageSize {}

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmImageSize? {}

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmWikiContent {
        var summaryHtml: Path<String?> { .init() }

        var contentHtml: Path<String?> { .init() }

        var publishDate: Path<String?> { .init() }

        var publishTime: Path<String?> { .init() }

        var url: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmWikiContent? {
        var summaryHtml: Path<String?> { .init() }

        var contentHtml: Path<String?> { .init() }

        var publishDate: Path<String?> { .init() }

        var publishTime: Path<String?> { .init() }

        var url: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmArtist {
        var mbid: Path<String?> { .init() }

        var name: Path<String?> { .init() }

        var url: Path<String> { .init() }

        func image(size _: GraphQLArgument<Music.LastFmImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var image: Path<String?> { .init() }

        var listenerCount: Path<Double?> { .init() }

        var playCount: Path<Double?> { .init() }

        func similarArtists(first _: GraphQLArgument<Int?> = .argument,
                            after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmArtistConnection?> {
            return .init()
        }

        var similarArtists: FragmentPath<Music.LastFmArtistConnection?> { .init() }

        func topAlbums(first _: GraphQLArgument<Int?> = .argument,
                       after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmAlbumConnection?> {
            return .init()
        }

        var topAlbums: FragmentPath<Music.LastFmAlbumConnection?> { .init() }

        func topTags(first _: GraphQLArgument<Int?> = .argument,
                     after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTagConnection?> {
            return .init()
        }

        var topTags: FragmentPath<Music.LastFmTagConnection?> { .init() }

        func topTracks(first _: GraphQLArgument<Int?> = .argument,
                       after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTrackConnection?> {
            return .init()
        }

        var topTracks: FragmentPath<Music.LastFmTrackConnection?> { .init() }

        func biography(lang _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmWikiContent?> {
            return .init()
        }

        var biography: FragmentPath<Music.LastFmWikiContent?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmArtist? {
        var mbid: Path<String?> { .init() }

        var name: Path<String?> { .init() }

        var url: Path<String?> { .init() }

        func image(size _: GraphQLArgument<Music.LastFmImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var image: Path<String?> { .init() }

        var listenerCount: Path<Double?> { .init() }

        var playCount: Path<Double?> { .init() }

        func similarArtists(first _: GraphQLArgument<Int?> = .argument,
                            after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmArtistConnection?> {
            return .init()
        }

        var similarArtists: FragmentPath<Music.LastFmArtistConnection?> { .init() }

        func topAlbums(first _: GraphQLArgument<Int?> = .argument,
                       after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmAlbumConnection?> {
            return .init()
        }

        var topAlbums: FragmentPath<Music.LastFmAlbumConnection?> { .init() }

        func topTags(first _: GraphQLArgument<Int?> = .argument,
                     after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTagConnection?> {
            return .init()
        }

        var topTags: FragmentPath<Music.LastFmTagConnection?> { .init() }

        func topTracks(first _: GraphQLArgument<Int?> = .argument,
                       after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTrackConnection?> {
            return .init()
        }

        var topTracks: FragmentPath<Music.LastFmTrackConnection?> { .init() }

        func biography(lang _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmWikiContent?> {
            return .init()
        }

        var biography: FragmentPath<Music.LastFmWikiContent?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmArtistConnection {
        var pageInfo: FragmentPath<Music.PageInfo> { .init() }

        var edges: FragmentPath<[Music.LastFmArtistEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.LastFmArtist?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmArtistConnection? {
        var pageInfo: FragmentPath<Music.PageInfo?> { .init() }

        var edges: FragmentPath<[Music.LastFmArtistEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.LastFmArtist?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmArtistEdge {
        var node: FragmentPath<Music.LastFmArtist?> { .init() }

        var cursor: Path<String> { .init() }

        var matchScore: Path<Double?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmArtistEdge? {
        var node: FragmentPath<Music.LastFmArtist?> { .init() }

        var cursor: Path<String?> { .init() }

        var matchScore: Path<Double?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmAlbumConnection {
        var pageInfo: FragmentPath<Music.PageInfo> { .init() }

        var edges: FragmentPath<[Music.LastFmAlbumEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.LastFmAlbum?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmAlbumConnection? {
        var pageInfo: FragmentPath<Music.PageInfo?> { .init() }

        var edges: FragmentPath<[Music.LastFmAlbumEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.LastFmAlbum?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmAlbumEdge {
        var node: FragmentPath<Music.LastFmAlbum?> { .init() }

        var cursor: Path<String> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmAlbumEdge? {
        var node: FragmentPath<Music.LastFmAlbum?> { .init() }

        var cursor: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmTagConnection {
        var pageInfo: FragmentPath<Music.PageInfo> { .init() }

        var edges: FragmentPath<[Music.LastFmTagEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.LastFmTag?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmTagConnection? {
        var pageInfo: FragmentPath<Music.PageInfo?> { .init() }

        var edges: FragmentPath<[Music.LastFmTagEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.LastFmTag?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmTagEdge {
        var node: FragmentPath<Music.LastFmTag?> { .init() }

        var cursor: Path<String> { .init() }

        var tagCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmTagEdge? {
        var node: FragmentPath<Music.LastFmTag?> { .init() }

        var cursor: Path<String?> { .init() }

        var tagCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmTag {
        var name: Path<String> { .init() }

        var url: Path<String> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmTag? {
        var name: Path<String?> { .init() }

        var url: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmTrackConnection {
        var pageInfo: FragmentPath<Music.PageInfo> { .init() }

        var edges: FragmentPath<[Music.LastFmTrackEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.LastFmTrack?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmTrackConnection? {
        var pageInfo: FragmentPath<Music.PageInfo?> { .init() }

        var edges: FragmentPath<[Music.LastFmTrackEdge?]?> { .init() }

        var nodes: FragmentPath<[Music.LastFmTrack?]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmTrackEdge {
        var node: FragmentPath<Music.LastFmTrack?> { .init() }

        var cursor: Path<String> { .init() }

        var matchScore: Path<Double?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmTrackEdge? {
        var node: FragmentPath<Music.LastFmTrack?> { .init() }

        var cursor: Path<String?> { .init() }

        var matchScore: Path<Double?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmTrack {
        var mbid: Path<String?> { .init() }

        var title: Path<String?> { .init() }

        var url: Path<String> { .init() }

        var duration: Path<String?> { .init() }

        var listenerCount: Path<Double?> { .init() }

        var playCount: Path<Double?> { .init() }

        func description(lang _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmWikiContent?> {
            return .init()
        }

        var description: FragmentPath<Music.LastFmWikiContent?> { .init() }

        var artist: FragmentPath<Music.LastFmArtist?> { .init() }

        var album: FragmentPath<Music.LastFmAlbum?> { .init() }

        func similarTracks(first _: GraphQLArgument<Int?> = .argument,
                           after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTrackConnection?> {
            return .init()
        }

        var similarTracks: FragmentPath<Music.LastFmTrackConnection?> { .init() }

        func topTags(first _: GraphQLArgument<Int?> = .argument,
                     after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTagConnection?> {
            return .init()
        }

        var topTags: FragmentPath<Music.LastFmTagConnection?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmTrack? {
        var mbid: Path<String?> { .init() }

        var title: Path<String?> { .init() }

        var url: Path<String?> { .init() }

        var duration: Path<String?> { .init() }

        var listenerCount: Path<Double?> { .init() }

        var playCount: Path<Double?> { .init() }

        func description(lang _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmWikiContent?> {
            return .init()
        }

        var description: FragmentPath<Music.LastFmWikiContent?> { .init() }

        var artist: FragmentPath<Music.LastFmArtist?> { .init() }

        var album: FragmentPath<Music.LastFmAlbum?> { .init() }

        func similarTracks(first _: GraphQLArgument<Int?> = .argument,
                           after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTrackConnection?> {
            return .init()
        }

        var similarTracks: FragmentPath<Music.LastFmTrackConnection?> { .init() }

        func topTags(first _: GraphQLArgument<Int?> = .argument,
                     after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTagConnection?> {
            return .init()
        }

        var topTags: FragmentPath<Music.LastFmTagConnection?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyMatchStrategy {}

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyMatchStrategy? {}

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyAlbum {
        var albumId: Path<String> { .init() }

        var uri: Path<String> { .init() }

        var href: Path<String> { .init() }

        var title: Path<String?> { .init() }

        var albumType: Path<Music.ReleaseGroupType> { .init() }

        var artists: FragmentPath<[Music.SpotifyArtist]> { .init() }

        var availableMarkets: Path<[String]> { .init() }

        var copyrights: FragmentPath<[Music.SpotifyCopyright]> { .init() }

        var externalIDs: FragmentPath<[Music.SpotifyExternalId]> { .init() }

        var externalUrLs: FragmentPath<[Music.SpotifyExternalUrl]> { .init() }

        var genres: Path<[String]> { .init() }

        var images: FragmentPath<[Music.SpotifyImage]> { .init() }

        var label: Path<String?> { .init() }

        var popularity: Path<Int> { .init() }

        var releaseDate: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyAlbum? {
        var albumId: Path<String?> { .init() }

        var uri: Path<String?> { .init() }

        var href: Path<String?> { .init() }

        var title: Path<String?> { .init() }

        var albumType: Path<Music.ReleaseGroupType?> { .init() }

        var artists: FragmentPath<[Music.SpotifyArtist]?> { .init() }

        var availableMarkets: Path<[String]?> { .init() }

        var copyrights: FragmentPath<[Music.SpotifyCopyright]?> { .init() }

        var externalIDs: FragmentPath<[Music.SpotifyExternalId]?> { .init() }

        var externalUrLs: FragmentPath<[Music.SpotifyExternalUrl]?> { .init() }

        var genres: Path<[String]?> { .init() }

        var images: FragmentPath<[Music.SpotifyImage]?> { .init() }

        var label: Path<String?> { .init() }

        var popularity: Path<Int?> { .init() }

        var releaseDate: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyArtist {
        var artistId: Path<String> { .init() }

        var uri: Path<String> { .init() }

        var href: Path<String> { .init() }

        var name: Path<String> { .init() }

        var externalUrLs: FragmentPath<[Music.SpotifyExternalUrl]> { .init() }

        var genres: Path<[String]> { .init() }

        var popularity: Path<Int> { .init() }

        var images: FragmentPath<[Music.SpotifyImage]> { .init() }

        func topTracks(market _: GraphQLArgument<String> = .argument) -> FragmentPath<[Music.SpotifyTrack]> {
            return .init()
        }

        var topTracks: FragmentPath<[Music.SpotifyTrack]> { .init() }

        var relatedArtists: FragmentPath<[Music.SpotifyArtist]> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyArtist? {
        var artistId: Path<String?> { .init() }

        var uri: Path<String?> { .init() }

        var href: Path<String?> { .init() }

        var name: Path<String?> { .init() }

        var externalUrLs: FragmentPath<[Music.SpotifyExternalUrl]?> { .init() }

        var genres: Path<[String]?> { .init() }

        var popularity: Path<Int?> { .init() }

        var images: FragmentPath<[Music.SpotifyImage]?> { .init() }

        func topTracks(market _: GraphQLArgument<String> = .argument) -> FragmentPath<[Music.SpotifyTrack]?> {
            return .init()
        }

        var topTracks: FragmentPath<[Music.SpotifyTrack]?> { .init() }

        var relatedArtists: FragmentPath<[Music.SpotifyArtist]?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyExternalUrl {
        var type: Path<String> { .init() }

        var url: Path<String> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyExternalUrl? {
        var type: Path<String?> { .init() }

        var url: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyImage {
        var url: Path<String> { .init() }

        var width: Path<Int?> { .init() }

        var height: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyImage? {
        var url: Path<String?> { .init() }

        var width: Path<Int?> { .init() }

        var height: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyTrack {
        var trackId: Path<String> { .init() }

        var uri: Path<String> { .init() }

        var href: Path<String> { .init() }

        var title: Path<String> { .init() }

        var audioFeatures: FragmentPath<Music.SpotifyAudioFeatures?> { .init() }

        var album: FragmentPath<Music.SpotifyAlbum?> { .init() }

        var artists: FragmentPath<[Music.SpotifyArtist]> { .init() }

        var availableMarkets: Path<[String]> { .init() }

        var discNumber: Path<Int> { .init() }

        var duration: Path<String> { .init() }

        var explicit: Path<Bool?> { .init() }

        var externalIDs: FragmentPath<[Music.SpotifyExternalId]> { .init() }

        var externalUrLs: FragmentPath<[Music.SpotifyExternalUrl]> { .init() }

        var popularity: Path<Int> { .init() }

        var previewUrl: Path<String?> { .init() }

        var trackNumber: Path<Int> { .init() }

        func musicBrainz(strategy _: GraphQLArgument<[Music.SpotifyMatchStrategy]?> = .argument) -> FragmentPath<Music.Recording?> {
            return .init()
        }

        var musicBrainz: FragmentPath<Music.Recording?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyTrack? {
        var trackId: Path<String?> { .init() }

        var uri: Path<String?> { .init() }

        var href: Path<String?> { .init() }

        var title: Path<String?> { .init() }

        var audioFeatures: FragmentPath<Music.SpotifyAudioFeatures?> { .init() }

        var album: FragmentPath<Music.SpotifyAlbum?> { .init() }

        var artists: FragmentPath<[Music.SpotifyArtist]?> { .init() }

        var availableMarkets: Path<[String]?> { .init() }

        var discNumber: Path<Int?> { .init() }

        var duration: Path<String?> { .init() }

        var explicit: Path<Bool?> { .init() }

        var externalIDs: FragmentPath<[Music.SpotifyExternalId]?> { .init() }

        var externalUrLs: FragmentPath<[Music.SpotifyExternalUrl]?> { .init() }

        var popularity: Path<Int?> { .init() }

        var previewUrl: Path<String?> { .init() }

        var trackNumber: Path<Int?> { .init() }

        func musicBrainz(strategy _: GraphQLArgument<[Music.SpotifyMatchStrategy]?> = .argument) -> FragmentPath<Music.Recording?> {
            return .init()
        }

        var musicBrainz: FragmentPath<Music.Recording?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyAudioFeatures {
        var acousticness: Path<Double> { .init() }

        var danceability: Path<Double> { .init() }

        var duration: Path<String> { .init() }

        var energy: Path<Double> { .init() }

        var instrumentalness: Path<Double> { .init() }

        var key: Path<Int> { .init() }

        var keyName: Path<String> { .init() }

        var liveness: Path<Double> { .init() }

        var loudness: Path<Double> { .init() }

        var mode: Path<Music.SpotifyTrackMode> { .init() }

        var speechiness: Path<Double> { .init() }

        var tempo: Path<Double> { .init() }

        var timeSignature: Path<Double> { .init() }

        var valence: Path<Double> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyAudioFeatures? {
        var acousticness: Path<Double?> { .init() }

        var danceability: Path<Double?> { .init() }

        var duration: Path<String?> { .init() }

        var energy: Path<Double?> { .init() }

        var instrumentalness: Path<Double?> { .init() }

        var key: Path<Int?> { .init() }

        var keyName: Path<String?> { .init() }

        var liveness: Path<Double?> { .init() }

        var loudness: Path<Double?> { .init() }

        var mode: Path<Music.SpotifyTrackMode?> { .init() }

        var speechiness: Path<Double?> { .init() }

        var tempo: Path<Double?> { .init() }

        var timeSignature: Path<Double?> { .init() }

        var valence: Path<Double?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyTrackMode {}

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyTrackMode? {}

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyExternalId {
        var type: Path<String> { .init() }

        var id: Path<String> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyExternalId? {
        var type: Path<String?> { .init() }

        var id: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyCopyright {
        var text: Path<String> { .init() }

        var type: Path<Music.SpotifyCopyrightType> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyCopyright? {
        var text: Path<String?> { .init() }

        var type: Path<Music.SpotifyCopyrightType?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyCopyrightType {}

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyCopyrightType? {}

    extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDbTrack {
        var trackId: Path<String?> { .init() }

        var albumId: Path<String?> { .init() }

        var artistId: Path<String?> { .init() }

        func description(lang _: GraphQLArgument<String?> = .argument) -> Path<String?> {
            return .init()
        }

        var description: Path<String?> { .init() }

        func thumbnail(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var thumbnail: Path<String?> { .init() }

        var score: Path<Double?> { .init() }

        var scoreVotes: Path<Double?> { .init() }

        var trackNumber: Path<Int?> { .init() }

        var musicVideo: FragmentPath<Music.TheAudioDbMusicVideo?> { .init() }

        var genre: Path<String?> { .init() }

        var mood: Path<String?> { .init() }

        var style: Path<String?> { .init() }

        var theme: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDbTrack? {
        var trackId: Path<String?> { .init() }

        var albumId: Path<String?> { .init() }

        var artistId: Path<String?> { .init() }

        func description(lang _: GraphQLArgument<String?> = .argument) -> Path<String?> {
            return .init()
        }

        var description: Path<String?> { .init() }

        func thumbnail(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var thumbnail: Path<String?> { .init() }

        var score: Path<Double?> { .init() }

        var scoreVotes: Path<Double?> { .init() }

        var trackNumber: Path<Int?> { .init() }

        var musicVideo: FragmentPath<Music.TheAudioDbMusicVideo?> { .init() }

        var genre: Path<String?> { .init() }

        var mood: Path<String?> { .init() }

        var style: Path<String?> { .init() }

        var theme: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDbMusicVideo {
        var url: Path<String?> { .init() }

        var companyName: Path<String?> { .init() }

        var directorName: Path<String?> { .init() }

        func screenshots(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<[String?]> {
            return .init()
        }

        var screenshots: Path<[String?]> { .init() }

        var viewCount: Path<Double?> { .init() }

        var likeCount: Path<Double?> { .init() }

        var dislikeCount: Path<Double?> { .init() }

        var commentCount: Path<Double?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDbMusicVideo? {
        var url: Path<String?> { .init() }

        var companyName: Path<String?> { .init() }

        var directorName: Path<String?> { .init() }

        func screenshots(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<[String?]?> {
            return .init()
        }

        var screenshots: Path<[String?]?> { .init() }

        var viewCount: Path<Double?> { .init() }

        var likeCount: Path<Double?> { .init() }

        var dislikeCount: Path<Double?> { .init() }

        var commentCount: Path<Double?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.FanArtArtist {
        var backgrounds: FragmentPath<[Music.FanArtImage?]?> { .init() }

        var banners: FragmentPath<[Music.FanArtImage?]?> { .init() }

        var logos: FragmentPath<[Music.FanArtImage?]?> { .init() }

        var logosHd: FragmentPath<[Music.FanArtImage?]?> { .init() }

        var thumbnails: FragmentPath<[Music.FanArtImage?]?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.FanArtArtist? {
        var backgrounds: FragmentPath<[Music.FanArtImage?]?> { .init() }

        var banners: FragmentPath<[Music.FanArtImage?]?> { .init() }

        var logos: FragmentPath<[Music.FanArtImage?]?> { .init() }

        var logosHd: FragmentPath<[Music.FanArtImage?]?> { .init() }

        var thumbnails: FragmentPath<[Music.FanArtImage?]?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDbArtist {
        var artistId: Path<String?> { .init() }

        func biography(lang _: GraphQLArgument<String?> = .argument) -> Path<String?> {
            return .init()
        }

        var biography: Path<String?> { .init() }

        var memberCount: Path<Int?> { .init() }

        func banner(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var banner: Path<String?> { .init() }

        func fanArt(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<[String?]> {
            return .init()
        }

        var fanArt: Path<[String?]> { .init() }

        func logo(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var logo: Path<String?> { .init() }

        func thumbnail(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var thumbnail: Path<String?> { .init() }

        var genre: Path<String?> { .init() }

        var mood: Path<String?> { .init() }

        var style: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDbArtist? {
        var artistId: Path<String?> { .init() }

        func biography(lang _: GraphQLArgument<String?> = .argument) -> Path<String?> {
            return .init()
        }

        var biography: Path<String?> { .init() }

        var memberCount: Path<Int?> { .init() }

        func banner(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var banner: Path<String?> { .init() }

        func fanArt(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<[String?]?> {
            return .init()
        }

        var fanArt: Path<[String?]?> { .init() }

        func logo(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var logo: Path<String?> { .init() }

        func thumbnail(size _: GraphQLArgument<Music.TheAudioDbImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        var thumbnail: Path<String?> { .init() }

        var genre: Path<String?> { .init() }

        var mood: Path<String?> { .init() }

        var style: Path<String?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmCountry {
        func topArtists(first _: GraphQLArgument<Int?> = .argument,
                        after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmArtistConnection?> {
            return .init()
        }

        var topArtists: FragmentPath<Music.LastFmArtistConnection?> { .init() }

        func topTracks(first _: GraphQLArgument<Int?> = .argument,
                       after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTrackConnection?> {
            return .init()
        }

        var topTracks: FragmentPath<Music.LastFmTrackConnection?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmCountry? {
        func topArtists(first _: GraphQLArgument<Int?> = .argument,
                        after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmArtistConnection?> {
            return .init()
        }

        var topArtists: FragmentPath<Music.LastFmArtistConnection?> { .init() }

        func topTracks(first _: GraphQLArgument<Int?> = .argument,
                       after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTrackConnection?> {
            return .init()
        }

        var topTracks: FragmentPath<Music.LastFmTrackConnection?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Url {
        var id: Path<String> { .init() }

        var mbid: Path<String> { .init() }

        var resource: Path<String> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        var node: FragmentPath<Music.Node> { .init() }

        var entity: FragmentPath<Music.Entity> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.Url? {
        var id: Path<String?> { .init() }

        var mbid: Path<String?> { .init() }

        var resource: Path<String?> { .init() }

        var relationships: FragmentPath<Music.Relationships?> { .init() }

        var node: FragmentPath<Music.Node?> { .init() }

        var entity: FragmentPath<Music.Entity?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.BrowseQuery {
        func areas(collection _: GraphQLArgument<String?> = .argument,
                   after _: GraphQLArgument<String?> = .argument,
                   first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.AreaConnection?> {
            return .init()
        }

        var areas: FragmentPath<Music.AreaConnection?> { .init() }

        func artists(area _: GraphQLArgument<String?> = .argument,
                     collection _: GraphQLArgument<String?> = .argument,
                     recording _: GraphQLArgument<String?> = .argument,
                     release _: GraphQLArgument<String?> = .argument,
                     releaseGroup _: GraphQLArgument<String?> = .argument,
                     work _: GraphQLArgument<String?> = .argument,
                     after _: GraphQLArgument<String?> = .argument,
                     first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
            return .init()
        }

        var artists: FragmentPath<Music.ArtistConnection?> { .init() }

        func collections(area _: GraphQLArgument<String?> = .argument,
                         artist _: GraphQLArgument<String?> = .argument,
                         editor _: GraphQLArgument<String?> = .argument,
                         event _: GraphQLArgument<String?> = .argument,
                         label _: GraphQLArgument<String?> = .argument,
                         place _: GraphQLArgument<String?> = .argument,
                         recording _: GraphQLArgument<String?> = .argument,
                         release _: GraphQLArgument<String?> = .argument,
                         releaseGroup _: GraphQLArgument<String?> = .argument,
                         work _: GraphQLArgument<String?> = .argument,
                         after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        func events(area _: GraphQLArgument<String?> = .argument,
                    artist _: GraphQLArgument<String?> = .argument,
                    collection _: GraphQLArgument<String?> = .argument,
                    place _: GraphQLArgument<String?> = .argument,
                    after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.EventConnection?> {
            return .init()
        }

        var events: FragmentPath<Music.EventConnection?> { .init() }

        func labels(area _: GraphQLArgument<String?> = .argument,
                    collection _: GraphQLArgument<String?> = .argument,
                    release _: GraphQLArgument<String?> = .argument,
                    after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.LabelConnection?> {
            return .init()
        }

        var labels: FragmentPath<Music.LabelConnection?> { .init() }

        func places(area _: GraphQLArgument<String?> = .argument,
                    collection _: GraphQLArgument<String?> = .argument,
                    after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.PlaceConnection?> {
            return .init()
        }

        var places: FragmentPath<Music.PlaceConnection?> { .init() }

        func recordings(artist _: GraphQLArgument<String?> = .argument,
                        collection _: GraphQLArgument<String?> = .argument,
                        isrc _: GraphQLArgument<String?> = .argument,
                        release _: GraphQLArgument<String?> = .argument,
                        after _: GraphQLArgument<String?> = .argument,
                        first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RecordingConnection?> {
            return .init()
        }

        var recordings: FragmentPath<Music.RecordingConnection?> { .init() }

        func releases(area _: GraphQLArgument<String?> = .argument,
                      artist _: GraphQLArgument<String?> = .argument,
                      collection _: GraphQLArgument<String?> = .argument,
                      discID _: GraphQLArgument<String?> = .argument,
                      label _: GraphQLArgument<String?> = .argument,
                      recording _: GraphQLArgument<String?> = .argument,
                      releaseGroup _: GraphQLArgument<String?> = .argument,
                      track _: GraphQLArgument<String?> = .argument,
                      trackArtist _: GraphQLArgument<String?> = .argument,
                      type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                      status _: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument,
                      after _: GraphQLArgument<String?> = .argument,
                      first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
            return .init()
        }

        var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

        func releaseGroups(artist _: GraphQLArgument<String?> = .argument,
                           collection _: GraphQLArgument<String?> = .argument,
                           release _: GraphQLArgument<String?> = .argument,
                           type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                           after _: GraphQLArgument<String?> = .argument,
                           first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseGroupConnection?> {
            return .init()
        }

        var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }

        func works(artist _: GraphQLArgument<String?> = .argument,
                   collection _: GraphQLArgument<String?> = .argument,
                   iswc _: GraphQLArgument<String?> = .argument,
                   after _: GraphQLArgument<String?> = .argument,
                   first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.WorkConnection?> {
            return .init()
        }

        var works: FragmentPath<Music.WorkConnection?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.BrowseQuery? {
        func areas(collection _: GraphQLArgument<String?> = .argument,
                   after _: GraphQLArgument<String?> = .argument,
                   first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.AreaConnection?> {
            return .init()
        }

        var areas: FragmentPath<Music.AreaConnection?> { .init() }

        func artists(area _: GraphQLArgument<String?> = .argument,
                     collection _: GraphQLArgument<String?> = .argument,
                     recording _: GraphQLArgument<String?> = .argument,
                     release _: GraphQLArgument<String?> = .argument,
                     releaseGroup _: GraphQLArgument<String?> = .argument,
                     work _: GraphQLArgument<String?> = .argument,
                     after _: GraphQLArgument<String?> = .argument,
                     first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
            return .init()
        }

        var artists: FragmentPath<Music.ArtistConnection?> { .init() }

        func collections(area _: GraphQLArgument<String?> = .argument,
                         artist _: GraphQLArgument<String?> = .argument,
                         editor _: GraphQLArgument<String?> = .argument,
                         event _: GraphQLArgument<String?> = .argument,
                         label _: GraphQLArgument<String?> = .argument,
                         place _: GraphQLArgument<String?> = .argument,
                         recording _: GraphQLArgument<String?> = .argument,
                         release _: GraphQLArgument<String?> = .argument,
                         releaseGroup _: GraphQLArgument<String?> = .argument,
                         work _: GraphQLArgument<String?> = .argument,
                         after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.CollectionConnection?> {
            return .init()
        }

        var collections: FragmentPath<Music.CollectionConnection?> { .init() }

        func events(area _: GraphQLArgument<String?> = .argument,
                    artist _: GraphQLArgument<String?> = .argument,
                    collection _: GraphQLArgument<String?> = .argument,
                    place _: GraphQLArgument<String?> = .argument,
                    after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.EventConnection?> {
            return .init()
        }

        var events: FragmentPath<Music.EventConnection?> { .init() }

        func labels(area _: GraphQLArgument<String?> = .argument,
                    collection _: GraphQLArgument<String?> = .argument,
                    release _: GraphQLArgument<String?> = .argument,
                    after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.LabelConnection?> {
            return .init()
        }

        var labels: FragmentPath<Music.LabelConnection?> { .init() }

        func places(area _: GraphQLArgument<String?> = .argument,
                    collection _: GraphQLArgument<String?> = .argument,
                    after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.PlaceConnection?> {
            return .init()
        }

        var places: FragmentPath<Music.PlaceConnection?> { .init() }

        func recordings(artist _: GraphQLArgument<String?> = .argument,
                        collection _: GraphQLArgument<String?> = .argument,
                        isrc _: GraphQLArgument<String?> = .argument,
                        release _: GraphQLArgument<String?> = .argument,
                        after _: GraphQLArgument<String?> = .argument,
                        first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RecordingConnection?> {
            return .init()
        }

        var recordings: FragmentPath<Music.RecordingConnection?> { .init() }

        func releases(area _: GraphQLArgument<String?> = .argument,
                      artist _: GraphQLArgument<String?> = .argument,
                      collection _: GraphQLArgument<String?> = .argument,
                      discID _: GraphQLArgument<String?> = .argument,
                      label _: GraphQLArgument<String?> = .argument,
                      recording _: GraphQLArgument<String?> = .argument,
                      releaseGroup _: GraphQLArgument<String?> = .argument,
                      track _: GraphQLArgument<String?> = .argument,
                      trackArtist _: GraphQLArgument<String?> = .argument,
                      type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                      status _: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument,
                      after _: GraphQLArgument<String?> = .argument,
                      first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
            return .init()
        }

        var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

        func releaseGroups(artist _: GraphQLArgument<String?> = .argument,
                           collection _: GraphQLArgument<String?> = .argument,
                           release _: GraphQLArgument<String?> = .argument,
                           type _: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument,
                           after _: GraphQLArgument<String?> = .argument,
                           first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseGroupConnection?> {
            return .init()
        }

        var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }

        func works(artist _: GraphQLArgument<String?> = .argument,
                   collection _: GraphQLArgument<String?> = .argument,
                   iswc _: GraphQLArgument<String?> = .argument,
                   after _: GraphQLArgument<String?> = .argument,
                   first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.WorkConnection?> {
            return .init()
        }

        var works: FragmentPath<Music.WorkConnection?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SearchQuery {
        func areas(query _: GraphQLArgument<String> = .argument,
                   after _: GraphQLArgument<String?> = .argument,
                   first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.AreaConnection?> {
            return .init()
        }

        var areas: FragmentPath<Music.AreaConnection?> { .init() }

        func artists(query _: GraphQLArgument<String> = .argument,
                     after _: GraphQLArgument<String?> = .argument,
                     first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
            return .init()
        }

        var artists: FragmentPath<Music.ArtistConnection?> { .init() }

        func events(query _: GraphQLArgument<String> = .argument,
                    after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.EventConnection?> {
            return .init()
        }

        var events: FragmentPath<Music.EventConnection?> { .init() }

        func instruments(query _: GraphQLArgument<String> = .argument,
                         after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.InstrumentConnection?> {
            return .init()
        }

        var instruments: FragmentPath<Music.InstrumentConnection?> { .init() }

        func labels(query _: GraphQLArgument<String> = .argument,
                    after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.LabelConnection?> {
            return .init()
        }

        var labels: FragmentPath<Music.LabelConnection?> { .init() }

        func places(query _: GraphQLArgument<String> = .argument,
                    after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.PlaceConnection?> {
            return .init()
        }

        var places: FragmentPath<Music.PlaceConnection?> { .init() }

        func recordings(query _: GraphQLArgument<String> = .argument,
                        after _: GraphQLArgument<String?> = .argument,
                        first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RecordingConnection?> {
            return .init()
        }

        var recordings: FragmentPath<Music.RecordingConnection?> { .init() }

        func releases(query _: GraphQLArgument<String> = .argument,
                      after _: GraphQLArgument<String?> = .argument,
                      first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
            return .init()
        }

        var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

        func releaseGroups(query _: GraphQLArgument<String> = .argument,
                           after _: GraphQLArgument<String?> = .argument,
                           first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseGroupConnection?> {
            return .init()
        }

        var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }

        func series(query _: GraphQLArgument<String> = .argument,
                    after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.SeriesConnection?> {
            return .init()
        }

        var series: FragmentPath<Music.SeriesConnection?> { .init() }

        func works(query _: GraphQLArgument<String> = .argument,
                   after _: GraphQLArgument<String?> = .argument,
                   first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.WorkConnection?> {
            return .init()
        }

        var works: FragmentPath<Music.WorkConnection?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SearchQuery? {
        func areas(query _: GraphQLArgument<String> = .argument,
                   after _: GraphQLArgument<String?> = .argument,
                   first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.AreaConnection?> {
            return .init()
        }

        var areas: FragmentPath<Music.AreaConnection?> { .init() }

        func artists(query _: GraphQLArgument<String> = .argument,
                     after _: GraphQLArgument<String?> = .argument,
                     first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ArtistConnection?> {
            return .init()
        }

        var artists: FragmentPath<Music.ArtistConnection?> { .init() }

        func events(query _: GraphQLArgument<String> = .argument,
                    after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.EventConnection?> {
            return .init()
        }

        var events: FragmentPath<Music.EventConnection?> { .init() }

        func instruments(query _: GraphQLArgument<String> = .argument,
                         after _: GraphQLArgument<String?> = .argument,
                         first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.InstrumentConnection?> {
            return .init()
        }

        var instruments: FragmentPath<Music.InstrumentConnection?> { .init() }

        func labels(query _: GraphQLArgument<String> = .argument,
                    after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.LabelConnection?> {
            return .init()
        }

        var labels: FragmentPath<Music.LabelConnection?> { .init() }

        func places(query _: GraphQLArgument<String> = .argument,
                    after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.PlaceConnection?> {
            return .init()
        }

        var places: FragmentPath<Music.PlaceConnection?> { .init() }

        func recordings(query _: GraphQLArgument<String> = .argument,
                        after _: GraphQLArgument<String?> = .argument,
                        first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.RecordingConnection?> {
            return .init()
        }

        var recordings: FragmentPath<Music.RecordingConnection?> { .init() }

        func releases(query _: GraphQLArgument<String> = .argument,
                      after _: GraphQLArgument<String?> = .argument,
                      first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseConnection?> {
            return .init()
        }

        var releases: FragmentPath<Music.ReleaseConnection?> { .init() }

        func releaseGroups(query _: GraphQLArgument<String> = .argument,
                           after _: GraphQLArgument<String?> = .argument,
                           first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.ReleaseGroupConnection?> {
            return .init()
        }

        var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }

        func series(query _: GraphQLArgument<String> = .argument,
                    after _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.SeriesConnection?> {
            return .init()
        }

        var series: FragmentPath<Music.SeriesConnection?> { .init() }

        func works(query _: GraphQLArgument<String> = .argument,
                   after _: GraphQLArgument<String?> = .argument,
                   first _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.WorkConnection?> {
            return .init()
        }

        var works: FragmentPath<Music.WorkConnection?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmQuery {
        var chart: FragmentPath<Music.LastFmChartQuery> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmQuery? {
        var chart: FragmentPath<Music.LastFmChartQuery?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmChartQuery {
        func topArtists(country _: GraphQLArgument<String?> = .argument,
                        first _: GraphQLArgument<Int?> = .argument,
                        after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmArtistConnection?> {
            return .init()
        }

        var topArtists: FragmentPath<Music.LastFmArtistConnection?> { .init() }

        func topTags(first _: GraphQLArgument<Int?> = .argument,
                     after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTagConnection?> {
            return .init()
        }

        var topTags: FragmentPath<Music.LastFmTagConnection?> { .init() }

        func topTracks(country _: GraphQLArgument<String?> = .argument,
                       first _: GraphQLArgument<Int?> = .argument,
                       after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTrackConnection?> {
            return .init()
        }

        var topTracks: FragmentPath<Music.LastFmTrackConnection?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.LastFmChartQuery? {
        func topArtists(country _: GraphQLArgument<String?> = .argument,
                        first _: GraphQLArgument<Int?> = .argument,
                        after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmArtistConnection?> {
            return .init()
        }

        var topArtists: FragmentPath<Music.LastFmArtistConnection?> { .init() }

        func topTags(first _: GraphQLArgument<Int?> = .argument,
                     after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTagConnection?> {
            return .init()
        }

        var topTags: FragmentPath<Music.LastFmTagConnection?> { .init() }

        func topTracks(country _: GraphQLArgument<String?> = .argument,
                       first _: GraphQLArgument<Int?> = .argument,
                       after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFmTrackConnection?> {
            return .init()
        }

        var topTracks: FragmentPath<Music.LastFmTrackConnection?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyQuery {
        func recommendations(seedArtists _: GraphQLArgument<[String]?> = .argument,
                             seedGenres _: GraphQLArgument<[String]?> = .argument,
                             seedTracks _: GraphQLArgument<[String]?> = .argument,
                             limit _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.SpotifyRecommendations> {
            return .init()
        }

        var recommendations: FragmentPath<Music.SpotifyRecommendations> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyQuery? {
        func recommendations(seedArtists _: GraphQLArgument<[String]?> = .argument,
                             seedGenres _: GraphQLArgument<[String]?> = .argument,
                             seedTracks _: GraphQLArgument<[String]?> = .argument,
                             limit _: GraphQLArgument<Int?> = .argument) -> FragmentPath<Music.SpotifyRecommendations?> {
            return .init()
        }

        var recommendations: FragmentPath<Music.SpotifyRecommendations?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyRecommendations {
        var tracks: FragmentPath<[Music.SpotifyTrack]> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyRecommendations? {
        var tracks: FragmentPath<[Music.SpotifyTrack]?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsReleaseConnection {
        var pageInfo: FragmentPath<Music.PageInfo> { .init() }

        var edges: FragmentPath<[Music.DiscogsReleaseEdge]> { .init() }

        var nodes: FragmentPath<[Music.DiscogsRelease]> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsReleaseConnection? {
        var pageInfo: FragmentPath<Music.PageInfo?> { .init() }

        var edges: FragmentPath<[Music.DiscogsReleaseEdge]?> { .init() }

        var nodes: FragmentPath<[Music.DiscogsRelease]?> { .init() }

        var totalCount: Path<Int?> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsReleaseEdge {
        var node: FragmentPath<Music.DiscogsRelease> { .init() }
    }

    extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsReleaseEdge? {
        var node: FragmentPath<Music.DiscogsRelease?> { .init() }
    }

#endif




// MARK: - AlbumArtistCreditButton

#if GRAPHAELLO_MUSIC_TARGET

    extension ApolloMusic.AlbumArtistCreditButtonArtist: Fragment {
        typealias UnderlyingType = Music.Artist
    }

    extension AlbumArtistCreditButton {
        typealias Artist = ApolloMusic.AlbumArtistCreditButtonArtist

        init(api: Music,
             artist: Artist) {
            self.init(api: api,
                      id: GraphQL(artist.mbid),
                      name: GraphQL(artist.name))
        }

        @ViewBuilder
        static func placeholderView(api: Music) -> some View {
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                Self(api: api,
                     artist: .placeholder).disabled(true).redacted(reason: .placeholder)
            } else {
                BasicLoadingView()
            }
        }
    }

    extension ApolloMusic.AlbumArtistCreditButtonArtist {
        private static let placeholderMap: ResultMap = ["__typename": "Artist", "mbid": "__GRAPHAELLO_PLACEHOLDER__", "name": "__GRAPHAELLO_PLACEHOLDER__"]

        static let placeholder = ApolloMusic.AlbumArtistCreditButtonArtist(
            unsafeResultMap: ApolloMusic.AlbumArtistCreditButtonArtist.placeholderMap
        )
    }

#endif


// MARK: - AlbumTrackCellCredit

#if GRAPHAELLO_MUSIC_TARGET

    extension ApolloMusic.AlbumTrackCellCreditArtistCredit: Fragment {
        typealias UnderlyingType = Music.ArtistCredit
    }

    extension AlbumTrackCellCredit {
        typealias ArtistCredit = ApolloMusic.AlbumTrackCellCreditArtistCredit

        init(artistCredit: ArtistCredit) {
            self.init(name: GraphQL(artistCredit.name),
                      joinPhrase: GraphQL(artistCredit.joinPhrase))
        }
    }

    extension AlbumTrackCellCredit: Fragment {
        typealias UnderlyingType = Music.ArtistCredit

        static let placeholder = Self(artistCredit: .placeholder)
    }

    extension ApolloMusic.AlbumTrackCellCreditArtistCredit {
        func referencedSingleFragmentStruct() -> AlbumTrackCellCredit {
            return AlbumTrackCellCredit(artistCredit: self)
        }
    }

    extension ApolloMusic.AlbumTrackCellCreditArtistCredit {
        private static let placeholderMap: ResultMap = ["__typename": "ArtistCredit", "joinPhrase": "__GRAPHAELLO_PLACEHOLDER__", "name": "__GRAPHAELLO_PLACEHOLDER__"]

        static let placeholder = ApolloMusic.AlbumTrackCellCreditArtistCredit(
            unsafeResultMap: ApolloMusic.AlbumTrackCellCreditArtistCredit.placeholderMap
        )
    }

#endif


// MARK: - ArtistAlbumCell

#if GRAPHAELLO_MUSIC_TARGET

    extension ApolloMusic.ArtistAlbumCellReleaseGroup: Fragment {
        typealias UnderlyingType = Music.ReleaseGroup
    }

    extension ArtistAlbumCell {
        typealias ReleaseGroup = ApolloMusic.ArtistAlbumCellReleaseGroup

        init(api: Music,
             releaseGroup: ReleaseGroup) {
            self.init(api: api,
                      title: GraphQL(releaseGroup.title),
                      cover: GraphQL(releaseGroup.theAudioDb?.frontImage),
                      discImage: GraphQL(releaseGroup.theAudioDb?.frontImage),
                      releaseIds: GraphQL(releaseGroup.releases?.nodes?.map { $0?.mbid }))
        }

        @ViewBuilder
        static func placeholderView(api: Music) -> some View {
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                Self(api: api,
                     releaseGroup: .placeholder).disabled(true).redacted(reason: .placeholder)
            } else {
                BasicLoadingView()
            }
        }
    }

    extension ApolloMusic.ArtistAlbumCellReleaseGroup {
        private static let placeholderMap: ResultMap = ["__typename": "ReleaseGroup", "releases": ["__typename": "ReleaseConnection", "nodes": Array(repeating: ["__typename": "Release", "mbid": "__GRAPHAELLO_PLACEHOLDER__"], count: 5) as [ResultMap]], "theAudioDB": ["__typename": "TheAudioDBAlbum", "frontImage": "__GRAPHAELLO_PLACEHOLDER__"], "title": "__GRAPHAELLO_PLACEHOLDER__"]

        static let placeholder = ApolloMusic.ArtistAlbumCellReleaseGroup(
            unsafeResultMap: ApolloMusic.ArtistAlbumCellReleaseGroup.placeholderMap
        )
    }

#endif


// MARK: - TrendingArtistCell

#if GRAPHAELLO_MUSIC_TARGET

    extension ApolloMusic.TrendingArtistCellLastFmArtist: Fragment {
        typealias UnderlyingType = Music.LastFmArtist
    }

    extension TrendingArtistCell {
        typealias LastFmArtist = ApolloMusic.TrendingArtistCellLastFmArtist

        init(api: Music,
             lastFmArtist: LastFmArtist) {
            self.init(api: api,
                      id: GraphQL(lastFmArtist.mbid),
                      name: GraphQL(lastFmArtist.name),
                      tags: GraphQL(lastFmArtist.topTags?.nodes?.map { $0?.name }),
                      images: GraphQL(lastFmArtist.topAlbums?.nodes?.map { $0?.image }),
                      mostFamousSongs: GraphQL(lastFmArtist.topTracks?.nodes?.map { $0?.title }))
        }

        @ViewBuilder
        static func placeholderView(api: Music) -> some View {
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                Self(api: api,
                     lastFmArtist: .placeholder).disabled(true).redacted(reason: .placeholder)
            } else {
                BasicLoadingView()
            }
        }
    }

    extension ApolloMusic.TrendingArtistCellLastFmArtist {
        private static let placeholderMap: ResultMap = ["__typename": "LastFMArtist", "mbid": "__GRAPHAELLO_PLACEHOLDER__", "name": "__GRAPHAELLO_PLACEHOLDER__", "topAlbums": ["__typename": "LastFMAlbumConnection", "nodes": Array(repeating: ["__typename": "LastFMAlbum", "image": "__GRAPHAELLO_PLACEHOLDER__"], count: 5) as [ResultMap]], "topTags": ["__typename": "LastFMTagConnection", "nodes": Array(repeating: ["__typename": "LastFMTag", "name": "__GRAPHAELLO_PLACEHOLDER__"], count: 5) as [ResultMap]], "topTracks": ["__typename": "LastFMTrackConnection", "nodes": Array(repeating: ["__typename": "LastFMTrack", "title": "__GRAPHAELLO_PLACEHOLDER__"], count: 5) as [ResultMap]]]

        static let placeholder = ApolloMusic.TrendingArtistCellLastFmArtist(
            unsafeResultMap: ApolloMusic.TrendingArtistCellLastFmArtist.placeholderMap
        )
    }

#endif


// MARK: - TrendingTrackCell

#if GRAPHAELLO_MUSIC_TARGET

    extension ApolloMusic.TrendingTrackCellLastFmTrack: Fragment {
        typealias UnderlyingType = Music.LastFmTrack
    }

    extension TrendingTrackCell {
        typealias LastFmTrack = ApolloMusic.TrendingTrackCellLastFmTrack

        init(api: Music,
             lastFmTrack: LastFmTrack) {
            self.init(api: api,
                      title: GraphQL(lastFmTrack.title),
                      artist: GraphQL(lastFmTrack.artist?.name),
                      image: GraphQL(lastFmTrack.album?.image),
                      albumId: GraphQL(lastFmTrack.album?.mbid))
        }

        @ViewBuilder
        static func placeholderView(api: Music) -> some View {
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                Self(api: api,
                     lastFmTrack: .placeholder).disabled(true).redacted(reason: .placeholder)
            } else {
                BasicLoadingView()
            }
        }
    }

    extension ApolloMusic.TrendingTrackCellLastFmTrack {
        private static let placeholderMap: ResultMap = ["__typename": "LastFMTrack", "album": ["__typename": "LastFMAlbum", "image": "__GRAPHAELLO_PLACEHOLDER__", "mbid": "__GRAPHAELLO_PLACEHOLDER__"], "artist": ["__typename": "LastFMArtist", "name": "__GRAPHAELLO_PLACEHOLDER__"], "title": "__GRAPHAELLO_PLACEHOLDER__"]

        static let placeholder = ApolloMusic.TrendingTrackCellLastFmTrack(
            unsafeResultMap: ApolloMusic.TrendingTrackCellLastFmTrack.placeholderMap
        )
    }

#endif


// MARK: - TrendingArtistsList

#if GRAPHAELLO_MUSIC_TARGET

    extension TrendingArtistsList {
        typealias Data = ApolloMusic.TrendingArtistsListQuery.Data

        init(api: Music,
             artists: Paging<TrendingArtistCell.LastFmArtist>?,
             tracks: Paging<TrendingTrackCell.LastFmTrack>?,
             data _: Data) {
            self.init(api: api,
                      artists: GraphQL(artists),
                      tracks: GraphQL(tracks))
        }

        @ViewBuilder
        static func placeholderView(api: Music,
                                    artists: Paging<TrendingArtistCell.LastFmArtist>?,
                                    tracks: Paging<TrendingTrackCell.LastFmTrack>?) -> some View {
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                Self(api: api,
                     artists: artists,
                     tracks: tracks,
                     data: .placeholder).disabled(true).redacted(reason: .placeholder)
            } else {
                BasicLoadingView()
            }
        }
    }

    extension Music {
        func trendingArtistsList<Loading: View, Error: View>(country: String? = nil,
                                                             first: Int? = 25,
                                                             after: String? = nil,
                                                             size: Music.LastFmImageSize? = nil,
                                                             
                                                             @ViewBuilder loading: () -> Loading,
                                                             @ViewBuilder error: @escaping (QueryError) -> Error) -> some View {
            return QueryRenderer(client: client,
                                 query: ApolloMusic.TrendingArtistsListQuery(country: country,
                                                                             first: first,
                                                                             after: after,
                                                                             LastFMTagConnection_first: 3,
                                                                             LastFMAlbumConnection_first: 4,
                                                                             size: size,
                                                                             LastFMTrackConnection_first: 1),
                                 loading: loading(),
                                 error: error) { (data: ApolloMusic.TrendingArtistsListQuery.Data) -> TrendingArtistsList in

                TrendingArtistsList(api: self,
                                    artists: data.lastFm?.chart.topArtists?.fragments.lastFmArtistConnectionTrendingArtistCellLastFmArtist.paging { _cursor, _pageSize, _completion in
                                        self.client.fetch(query: ApolloMusic.TrendingArtistsListArtistsLastFmArtistConnectionTrendingArtistCellLastFmArtistQuery(country: country,
                                                                                                                                                                 first: _pageSize ?? first,
                                                                                                                                                                 after: _cursor,
                                                                                                                                                                 LastFMTagConnection_first: 3,
                                                                                                                                                                 LastFMAlbumConnection_first: 4,
                                                                                                                                                                 size: size,
                                                                                                                                                                 LastFMTrackConnection_first: 1)) { result in
                                            _completion(result.map { $0.data?.lastFm?.chart.topArtists?.fragments.lastFmArtistConnectionTrendingArtistCellLastFmArtist })
                                        }
                                    },
                                    
                                    tracks: data.lastFm?.chart.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack.paging { _cursor, _pageSize, _completion in
                                        self.client.fetch(query: ApolloMusic.TrendingArtistsListTracksLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery(country: country,
                                                                                                                                                             first: _pageSize ?? first,
                                                                                                                                                             after: _cursor,
                                                                                                                                                             size: size)) { result in
                                            _completion(result.map { $0.data?.lastFm?.chart.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack })
                                        }
                                    },
                                    
                                    data: data)
            }
        }

        func trendingArtistsList<Loading: View>(country: String? = nil,
                                                first: Int? = 25,
                                                after: String? = nil,
                                                size: Music.LastFmImageSize? = nil,
                                                
                                                @ViewBuilder loading: () -> Loading) -> some View {
            return QueryRenderer(client: client,
                                 query: ApolloMusic.TrendingArtistsListQuery(country: country,
                                                                             first: first,
                                                                             after: after,
                                                                             LastFMTagConnection_first: 3,
                                                                             LastFMAlbumConnection_first: 4,
                                                                             size: size,
                                                                             LastFMTrackConnection_first: 1),
                                 loading: loading(),
                                 error: { BasicErrorView(error: $0) }) { (data: ApolloMusic.TrendingArtistsListQuery.Data) -> TrendingArtistsList in

                TrendingArtistsList(api: self,
                                    artists: data.lastFm?.chart.topArtists?.fragments.lastFmArtistConnectionTrendingArtistCellLastFmArtist.paging { _cursor, _pageSize, _completion in
                                        self.client.fetch(query: ApolloMusic.TrendingArtistsListArtistsLastFmArtistConnectionTrendingArtistCellLastFmArtistQuery(country: country,
                                                                                                                                                                 first: _pageSize ?? first,
                                                                                                                                                                 after: _cursor,
                                                                                                                                                                 LastFMTagConnection_first: 3,
                                                                                                                                                                 LastFMAlbumConnection_first: 4,
                                                                                                                                                                 size: size,
                                                                                                                                                                 LastFMTrackConnection_first: 1)) { result in
                                            _completion(result.map { $0.data?.lastFm?.chart.topArtists?.fragments.lastFmArtistConnectionTrendingArtistCellLastFmArtist })
                                        }
                                    },
                                    
                                    tracks: data.lastFm?.chart.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack.paging { _cursor, _pageSize, _completion in
                                        self.client.fetch(query: ApolloMusic.TrendingArtistsListTracksLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery(country: country,
                                                                                                                                                             first: _pageSize ?? first,
                                                                                                                                                             after: _cursor,
                                                                                                                                                             size: size)) { result in
                                            _completion(result.map { $0.data?.lastFm?.chart.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack })
                                        }
                                    },
                                    
                                    data: data)
            }
        }

        func trendingArtistsList<Error: View>(country: String? = nil,
                                              first: Int? = 25,
                                              after: String? = nil,
                                              size: Music.LastFmImageSize? = nil,
                                              
                                              @ViewBuilder error: @escaping (QueryError) -> Error) -> some View {
            return QueryRenderer(client: client,
                                 query: ApolloMusic.TrendingArtistsListQuery(country: country,
                                                                             first: first,
                                                                             after: after,
                                                                             LastFMTagConnection_first: 3,
                                                                             LastFMAlbumConnection_first: 4,
                                                                             size: size,
                                                                             LastFMTrackConnection_first: 1),
                                 loading: TrendingArtistsList.placeholderView(api: self,
                                                                              artists: ApolloMusic.TrendingArtistsListQuery.Data.placeholder.lastFm?.chart.topArtists?.fragments.lastFmArtistConnectionTrendingArtistCellLastFmArtist.paging { _, _, _ in
                                                                                  // no-op
                                                                              },
                                                                              
                                                                              tracks: ApolloMusic.TrendingArtistsListQuery.Data.placeholder.lastFm?.chart.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack.paging { _, _, _ in
                                                                                  // no-op
                                 }),
                                 error: error) { (data: ApolloMusic.TrendingArtistsListQuery.Data) -> TrendingArtistsList in

                TrendingArtistsList(api: self,
                                    artists: data.lastFm?.chart.topArtists?.fragments.lastFmArtistConnectionTrendingArtistCellLastFmArtist.paging { _cursor, _pageSize, _completion in
                                        self.client.fetch(query: ApolloMusic.TrendingArtistsListArtistsLastFmArtistConnectionTrendingArtistCellLastFmArtistQuery(country: country,
                                                                                                                                                                 first: _pageSize ?? first,
                                                                                                                                                                 after: _cursor,
                                                                                                                                                                 LastFMTagConnection_first: 3,
                                                                                                                                                                 LastFMAlbumConnection_first: 4,
                                                                                                                                                                 size: size,
                                                                                                                                                                 LastFMTrackConnection_first: 1)) { result in
                                            _completion(result.map { $0.data?.lastFm?.chart.topArtists?.fragments.lastFmArtistConnectionTrendingArtistCellLastFmArtist })
                                        }
                                    },
                                    
                                    tracks: data.lastFm?.chart.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack.paging { _cursor, _pageSize, _completion in
                                        self.client.fetch(query: ApolloMusic.TrendingArtistsListTracksLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery(country: country,
                                                                                                                                                             first: _pageSize ?? first,
                                                                                                                                                             after: _cursor,
                                                                                                                                                             size: size)) { result in
                                            _completion(result.map { $0.data?.lastFm?.chart.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack })
                                        }
                                    },
                                    
                                    data: data)
            }
        }

        func trendingArtistsList(country: String? = nil,
                                 first: Int? = 25,
                                 after: String? = nil,
                                 size: Music.LastFmImageSize? = nil) -> some View {
            return QueryRenderer(client: client,
                                 query: ApolloMusic.TrendingArtistsListQuery(country: country,
                                                                             first: first,
                                                                             after: after,
                                                                             LastFMTagConnection_first: 3,
                                                                             LastFMAlbumConnection_first: 4,
                                                                             size: size,
                                                                             LastFMTrackConnection_first: 1),
                                 loading: TrendingArtistsList.placeholderView(api: self,
                                                                              artists: ApolloMusic.TrendingArtistsListQuery.Data.placeholder.lastFm?.chart.topArtists?.fragments.lastFmArtistConnectionTrendingArtistCellLastFmArtist.paging { _, _, _ in
                                                                                  // no-op
                                                                              },
                                                                              
                                                                              tracks: ApolloMusic.TrendingArtistsListQuery.Data.placeholder.lastFm?.chart.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack.paging { _, _, _ in
                                                                                  // no-op
                                 }),
                                 error: { BasicErrorView(error: $0) }) { (data: ApolloMusic.TrendingArtistsListQuery.Data) -> TrendingArtistsList in

                TrendingArtistsList(api: self,
                                    artists: data.lastFm?.chart.topArtists?.fragments.lastFmArtistConnectionTrendingArtistCellLastFmArtist.paging { _cursor, _pageSize, _completion in
                                        self.client.fetch(query: ApolloMusic.TrendingArtistsListArtistsLastFmArtistConnectionTrendingArtistCellLastFmArtistQuery(country: country,
                                                                                                                                                                 first: _pageSize ?? first,
                                                                                                                                                                 after: _cursor,
                                                                                                                                                                 LastFMTagConnection_first: 3,
                                                                                                                                                                 LastFMAlbumConnection_first: 4,
                                                                                                                                                                 size: size,
                                                                                                                                                                 LastFMTrackConnection_first: 1)) { result in
                                            _completion(result.map { $0.data?.lastFm?.chart.topArtists?.fragments.lastFmArtistConnectionTrendingArtistCellLastFmArtist })
                                        }
                                    },
                                    
                                    tracks: data.lastFm?.chart.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack.paging { _cursor, _pageSize, _completion in
                                        self.client.fetch(query: ApolloMusic.TrendingArtistsListTracksLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery(country: country,
                                                                                                                                                             first: _pageSize ?? first,
                                                                                                                                                             after: _cursor,
                                                                                                                                                             size: size)) { result in
                                            _completion(result.map { $0.data?.lastFm?.chart.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack })
                                        }
                                    },
                                    
                                    data: data)
            }
        }
    }

    extension ApolloMusic.TrendingArtistsListQuery.Data {
        private static let placeholderMap: ResultMap = ["lastFM": ["__typename": "LastFMQuery", "chart": ["__typename": "LastFMChartQuery", "topArtists": ["__typename": "LastFMArtistConnection", "edges": Array(repeating: ["__typename": "LastFMArtistEdge", "node": ["__typename": "LastFMArtist", "mbid": "__GRAPHAELLO_PLACEHOLDER__", "name": "__GRAPHAELLO_PLACEHOLDER__", "topAlbums": ["__typename": "LastFMAlbumConnection", "nodes": Array(repeating: ["__typename": "LastFMAlbum", "image": "__GRAPHAELLO_PLACEHOLDER__"], count: 5) as [ResultMap]], "topTags": ["__typename": "LastFMTagConnection", "nodes": Array(repeating: ["__typename": "LastFMTag", "name": "__GRAPHAELLO_PLACEHOLDER__"], count: 5) as [ResultMap]], "topTracks": ["__typename": "LastFMTrackConnection", "nodes": Array(repeating: ["__typename": "LastFMTrack", "title": "__GRAPHAELLO_PLACEHOLDER__"], count: 5) as [ResultMap]]]], count: 5) as [ResultMap], "pageInfo": ["__typename": "PageInfo", "endCursor": "__GRAPHAELLO_PLACEHOLDER__", "hasNextPage": true]], "topTracks": ["__typename": "LastFMTrackConnection", "edges": Array(repeating: ["__typename": "LastFMTrackEdge", "node": ["__typename": "LastFMTrack", "album": ["__typename": "LastFMAlbum", "image": "__GRAPHAELLO_PLACEHOLDER__", "mbid": "__GRAPHAELLO_PLACEHOLDER__"], "artist": ["__typename": "LastFMArtist", "name": "__GRAPHAELLO_PLACEHOLDER__"], "title": "__GRAPHAELLO_PLACEHOLDER__"]], count: 5) as [ResultMap], "pageInfo": ["__typename": "PageInfo", "endCursor": "__GRAPHAELLO_PLACEHOLDER__", "hasNextPage": true]]]]]

        static let placeholder = ApolloMusic.TrendingArtistsListQuery.Data(
            unsafeResultMap: ApolloMusic.TrendingArtistsListQuery.Data.placeholderMap
        )
    }

    extension ApolloMusic.TrendingArtistsListQuery.Data.LastFm.Chart.TopArtist {
        public struct Fragments {
            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
            }
        }

        public var fragments: Fragments {
            get {
                return Fragments(unsafeResultMap: resultMap)
            }
            set {
                resultMap += newValue.resultMap
            }
        }
    }

    extension ApolloMusic.TrendingArtistsListQuery.Data.LastFm.Chart.TopTrack {
        public struct Fragments {
            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
            }
        }

        public var fragments: Fragments {
            get {
                return Fragments(unsafeResultMap: resultMap)
            }
            set {
                resultMap += newValue.resultMap
            }
        }
    }

    extension ApolloMusic.TrendingArtistsListArtistsLastFmArtistConnectionTrendingArtistCellLastFmArtistQuery.Data.LastFm.Chart.TopArtist {
        public struct Fragments {
            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
            }
        }

        public var fragments: Fragments {
            get {
                return Fragments(unsafeResultMap: resultMap)
            }
            set {
                resultMap += newValue.resultMap
            }
        }
    }

    extension ApolloMusic.TrendingArtistsListTracksLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery.Data.LastFm.Chart.TopTrack {
        public struct Fragments {
            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
            }
        }

        public var fragments: Fragments {
            get {
                return Fragments(unsafeResultMap: resultMap)
            }
            set {
                resultMap += newValue.resultMap
            }
        }
    }

    extension ApolloMusic.TrendingArtistsListQuery.Data.LastFm.Chart.TopArtist.Fragments {
        public var lastFmArtistConnectionTrendingArtistCellLastFmArtist: ApolloMusic.LastFmArtistConnectionTrendingArtistCellLastFmArtist {
            get {
                return ApolloMusic.LastFmArtistConnectionTrendingArtistCellLastFmArtist(unsafeResultMap: resultMap)
            }
            set {
                resultMap += newValue.resultMap
            }
        }
    }

    extension ApolloMusic.TrendingArtistsListQuery.Data.LastFm.Chart.TopTrack.Fragments {
        public var lastFmTrackConnectionTrendingTrackCellLastFmTrack: ApolloMusic.LastFmTrackConnectionTrendingTrackCellLastFmTrack {
            get {
                return ApolloMusic.LastFmTrackConnectionTrendingTrackCellLastFmTrack(unsafeResultMap: resultMap)
            }
            set {
                resultMap += newValue.resultMap
            }
        }
    }

    extension ApolloMusic.TrendingArtistsListArtistsLastFmArtistConnectionTrendingArtistCellLastFmArtistQuery.Data.LastFm.Chart.TopArtist.Fragments {
        public var lastFmArtistConnectionTrendingArtistCellLastFmArtist: ApolloMusic.LastFmArtistConnectionTrendingArtistCellLastFmArtist {
            get {
                return ApolloMusic.LastFmArtistConnectionTrendingArtistCellLastFmArtist(unsafeResultMap: resultMap)
            }
            set {
                resultMap += newValue.resultMap
            }
        }
    }

    extension ApolloMusic.TrendingArtistsListTracksLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery.Data.LastFm.Chart.TopTrack.Fragments {
        public var lastFmTrackConnectionTrendingTrackCellLastFmTrack: ApolloMusic.LastFmTrackConnectionTrendingTrackCellLastFmTrack {
            get {
                return ApolloMusic.LastFmTrackConnectionTrendingTrackCellLastFmTrack(unsafeResultMap: resultMap)
            }
            set {
                resultMap += newValue.resultMap
            }
        }
    }

#endif


// MARK: - AlbumTrackCell

#if GRAPHAELLO_MUSIC_TARGET

    extension ApolloMusic.AlbumTrackCellTrack: Fragment {
        typealias UnderlyingType = Music.Track
    }

    extension AlbumTrackCell {
        typealias Track = ApolloMusic.AlbumTrackCellTrack

        init(albumTrackCount: Int,
             playCountForAlbum: Double?,
             track: Track) {
            self.init(albumTrackCount: albumTrackCount,
                      playCountForAlbum: playCountForAlbum,
                      position: GraphQL(track.position),
                      title: GraphQL(track.title),
                      credits: GraphQL(track.recording?.artistCredits?.map { $0?.fragments.albumTrackCellCreditArtistCredit }),
                      playCount: GraphQL(track.recording?.lastFm?.playCount))
        }

        @ViewBuilder
        static func placeholderView(albumTrackCount: Int,
                                    playCountForAlbum: Double?) -> some View {
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                Self(albumTrackCount: albumTrackCount,
                     playCountForAlbum: playCountForAlbum,
                     track: .placeholder).disabled(true).redacted(reason: .placeholder)
            } else {
                BasicLoadingView()
            }
        }
    }

    extension ApolloMusic.AlbumTrackCellTrack {
        private static let placeholderMap: ResultMap = ["__typename": "Track", "position": 42, "recording": ["__typename": "Recording", "artistCredits": Array(repeating: ["__typename": "ArtistCredit", "joinPhrase": "__GRAPHAELLO_PLACEHOLDER__", "name": "__GRAPHAELLO_PLACEHOLDER__"], count: 5) as [ResultMap], "lastFM": ["__typename": "LastFMTrack", "playCount": 42.0]], "title": "__GRAPHAELLO_PLACEHOLDER__"]

        static let placeholder = ApolloMusic.AlbumTrackCellTrack(
            unsafeResultMap: ApolloMusic.AlbumTrackCellTrack.placeholderMap
        )
    }

#endif


// MARK: - ArtistDetailView

#if GRAPHAELLO_MUSIC_TARGET

    extension ArtistDetailView {
        typealias Data = ApolloMusic.ArtistDetailViewQuery.Data

        init(api: Music,
             topSongs: Paging<TrendingTrackCell.LastFmTrack>?,
             albums: Paging<ArtistAlbumCell.ReleaseGroup>?,
             singles: Paging<ArtistAlbumCell.ReleaseGroup>?,
             data: Data) {
            self.init(api: api,
                      name: GraphQL(data.lookup?.artist?.name),
                      image: GraphQL(data.lookup?.artist?.theAudioDb?.thumbnail),
                      topSongs: GraphQL(topSongs),
                      albums: GraphQL(albums),
                      singles: GraphQL(singles),
                      bio: GraphQL(data.lookup?.artist?.theAudioDb?.biography),
                      area: GraphQL(data.lookup?.artist?.area?.name),
                      type: GraphQL(data.lookup?.artist?.type),
                      formed: GraphQL(data.lookup?.artist?.lifeSpan?.begin),
                      genre: GraphQL(data.lookup?.artist?.theAudioDb?.style),
                      mood: GraphQL(data.lookup?.artist?.theAudioDb?.mood))
        }

        @ViewBuilder
        static func placeholderView(api: Music,
                                    topSongs: Paging<TrendingTrackCell.LastFmTrack>?,
                                    albums: Paging<ArtistAlbumCell.ReleaseGroup>?,
                                    singles: Paging<ArtistAlbumCell.ReleaseGroup>?) -> some View {
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                Self(api: api,
                     topSongs: topSongs,
                     albums: albums,
                     singles: singles,
                     data: .placeholder).disabled(true).redacted(reason: .placeholder)
            } else {
                BasicLoadingView()
            }
        }
    }

    extension Music {
        func artistDetailView<Loading: View, Error: View>(mbid: String,
                                                          size: Music.TheAudioDbImageSize? = Music.TheAudioDbImageSize.full,
                                                          after: String? = nil,
                                                          urlStringSize: Music.LastFmImageSize? = nil,
                                                          releaseConnectionFirst: Int? = nil,
                                                          lang: String? = "en",
                                                          
                                                          @ViewBuilder loading: () -> Loading,
                                                          @ViewBuilder error: @escaping (QueryError) -> Error) -> some View {
            return QueryRenderer(client: client,
                                 query: ApolloMusic.ArtistDetailViewQuery(mbid: mbid,
                                                                          size: size,
                                                                          first: 5,
                                                                          after: after,
                                                                          URLString_size: urlStringSize,
                                                                          type: [.album],
                                                                          status: [.official],
                                                                          ReleaseConnection_first: releaseConnectionFirst,
                                                                          ReleaseGroupConnection_type: [.single],
                                                                          lang: lang),
                                 loading: loading(),
                                 error: error) { (data: ApolloMusic.ArtistDetailViewQuery.Data) -> ArtistDetailView in

                ArtistDetailView(api: self,
                                 topSongs: data.lookup?.artist?.lastFm?.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack.paging { _cursor, _pageSize, _completion in
                                     self.client.fetch(query: ApolloMusic.ArtistDetailViewTopSongsLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery(mbid: mbid,
                                                                                                                                                         first: _pageSize ?? 5,
                                                                                                                                                         after: _cursor,
                                                                                                                                                         URLString_size: urlStringSize)) { result in
                                         _completion(result.map { $0.data?.lookup?.artist?.lastFm?.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack })
                                     }
                                 },
                                 
                                 albums: data.lookup?.artist?.releaseGroups?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup.paging { _cursor, _pageSize, _completion in
                                     self.client.fetch(query: ApolloMusic.ArtistDetailViewAlbumsReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery(mbid: mbid,
                                                                                                                                                       type: [.album],
                                                                                                                                                       after: _cursor,
                                                                                                                                                       first: _pageSize ?? 5,
                                                                                                                                                       size: size,
                                                                                                                                                       status: [.official],
                                                                                                                                                       ReleaseConnection_first: releaseConnectionFirst)) { result in
                                         _completion(result.map { $0.data?.lookup?.artist?.releaseGroups?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup })
                                     }
                                 },
                                 
                                 singles: data.lookup?.artist?.releaseGroups1?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup.paging { _cursor, _pageSize, _completion in
                                     self.client.fetch(query: ApolloMusic.ArtistDetailViewSinglesReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery(mbid: mbid,
                                                                                                                                                        ReleaseGroupConnection_type: [.single],
                                                                                                                                                        after: _cursor,
                                                                                                                                                        first: _pageSize ?? 5,
                                                                                                                                                        size: size,
                                                                                                                                                        type: [.album],
                                                                                                                                                        status: [.official],
                                                                                                                                                        ReleaseConnection_first: releaseConnectionFirst)) { result in
                                         _completion(result.map { $0.data?.lookup?.artist?.releaseGroups1?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup })
                                     }
                                 },
                                 
                                 data: data)
            }
        }

        func artistDetailView<Loading: View>(mbid: String,
                                             size: Music.TheAudioDbImageSize? = Music.TheAudioDbImageSize.full,
                                             after: String? = nil,
                                             urlStringSize: Music.LastFmImageSize? = nil,
                                             releaseConnectionFirst: Int? = nil,
                                             lang: String? = "en",
                                             
                                             @ViewBuilder loading: () -> Loading) -> some View {
            return QueryRenderer(client: client,
                                 query: ApolloMusic.ArtistDetailViewQuery(mbid: mbid,
                                                                          size: size,
                                                                          first: 5,
                                                                          after: after,
                                                                          URLString_size: urlStringSize,
                                                                          type: [.album],
                                                                          status: [.official],
                                                                          ReleaseConnection_first: releaseConnectionFirst,
                                                                          ReleaseGroupConnection_type: [.single],
                                                                          lang: lang),
                                 loading: loading(),
                                 error: { BasicErrorView(error: $0) }) { (data: ApolloMusic.ArtistDetailViewQuery.Data) -> ArtistDetailView in

                ArtistDetailView(api: self,
                                 topSongs: data.lookup?.artist?.lastFm?.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack.paging { _cursor, _pageSize, _completion in
                                     self.client.fetch(query: ApolloMusic.ArtistDetailViewTopSongsLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery(mbid: mbid,
                                                                                                                                                         first: _pageSize ?? 5,
                                                                                                                                                         after: _cursor,
                                                                                                                                                         URLString_size: urlStringSize)) { result in
                                         _completion(result.map { $0.data?.lookup?.artist?.lastFm?.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack })
                                     }
                                 },
                                 
                                 albums: data.lookup?.artist?.releaseGroups?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup.paging { _cursor, _pageSize, _completion in
                                     self.client.fetch(query: ApolloMusic.ArtistDetailViewAlbumsReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery(mbid: mbid,
                                                                                                                                                       type: [.album],
                                                                                                                                                       after: _cursor,
                                                                                                                                                       first: _pageSize ?? 5,
                                                                                                                                                       size: size,
                                                                                                                                                       status: [.official],
                                                                                                                                                       ReleaseConnection_first: releaseConnectionFirst)) { result in
                                         _completion(result.map { $0.data?.lookup?.artist?.releaseGroups?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup })
                                     }
                                 },
                                 
                                 singles: data.lookup?.artist?.releaseGroups1?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup.paging { _cursor, _pageSize, _completion in
                                     self.client.fetch(query: ApolloMusic.ArtistDetailViewSinglesReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery(mbid: mbid,
                                                                                                                                                        ReleaseGroupConnection_type: [.single],
                                                                                                                                                        after: _cursor,
                                                                                                                                                        first: _pageSize ?? 5,
                                                                                                                                                        size: size,
                                                                                                                                                        type: [.album],
                                                                                                                                                        status: [.official],
                                                                                                                                                        ReleaseConnection_first: releaseConnectionFirst)) { result in
                                         _completion(result.map { $0.data?.lookup?.artist?.releaseGroups1?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup })
                                     }
                                 },
                                 
                                 data: data)
            }
        }

        func artistDetailView<Error: View>(mbid: String,
                                           size: Music.TheAudioDbImageSize? = Music.TheAudioDbImageSize.full,
                                           after: String? = nil,
                                           urlStringSize: Music.LastFmImageSize? = nil,
                                           releaseConnectionFirst: Int? = nil,
                                           lang: String? = "en",
                                           
                                           @ViewBuilder error: @escaping (QueryError) -> Error) -> some View {
            return QueryRenderer(client: client,
                                 query: ApolloMusic.ArtistDetailViewQuery(mbid: mbid,
                                                                          size: size,
                                                                          first: 5,
                                                                          after: after,
                                                                          URLString_size: urlStringSize,
                                                                          type: [.album],
                                                                          status: [.official],
                                                                          ReleaseConnection_first: releaseConnectionFirst,
                                                                          ReleaseGroupConnection_type: [.single],
                                                                          lang: lang),
                                 loading: ArtistDetailView.placeholderView(api: self,
                                                                           topSongs: ApolloMusic.ArtistDetailViewQuery.Data.placeholder.lookup?.artist?.lastFm?.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack.paging { _, _, _ in
                                                                               // no-op
                                                                           },
                                                                           
                                                                           albums: ApolloMusic.ArtistDetailViewQuery.Data.placeholder.lookup?.artist?.releaseGroups?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup.paging { _, _, _ in
                                                                               // no-op
                                                                           },
                                                                           
                                                                           singles: ApolloMusic.ArtistDetailViewQuery.Data.placeholder.lookup?.artist?.releaseGroups1?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup.paging { _, _, _ in
                                                                               // no-op
                                 }),
                                 error: error) { (data: ApolloMusic.ArtistDetailViewQuery.Data) -> ArtistDetailView in

                ArtistDetailView(api: self,
                                 topSongs: data.lookup?.artist?.lastFm?.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack.paging { _cursor, _pageSize, _completion in
                                     self.client.fetch(query: ApolloMusic.ArtistDetailViewTopSongsLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery(mbid: mbid,
                                                                                                                                                         first: _pageSize ?? 5,
                                                                                                                                                         after: _cursor,
                                                                                                                                                         URLString_size: urlStringSize)) { result in
                                         _completion(result.map { $0.data?.lookup?.artist?.lastFm?.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack })
                                     }
                                 },
                                 
                                 albums: data.lookup?.artist?.releaseGroups?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup.paging { _cursor, _pageSize, _completion in
                                     self.client.fetch(query: ApolloMusic.ArtistDetailViewAlbumsReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery(mbid: mbid,
                                                                                                                                                       type: [.album],
                                                                                                                                                       after: _cursor,
                                                                                                                                                       first: _pageSize ?? 5,
                                                                                                                                                       size: size,
                                                                                                                                                       status: [.official],
                                                                                                                                                       ReleaseConnection_first: releaseConnectionFirst)) { result in
                                         _completion(result.map { $0.data?.lookup?.artist?.releaseGroups?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup })
                                     }
                                 },
                                 
                                 singles: data.lookup?.artist?.releaseGroups1?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup.paging { _cursor, _pageSize, _completion in
                                     self.client.fetch(query: ApolloMusic.ArtistDetailViewSinglesReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery(mbid: mbid,
                                                                                                                                                        ReleaseGroupConnection_type: [.single],
                                                                                                                                                        after: _cursor,
                                                                                                                                                        first: _pageSize ?? 5,
                                                                                                                                                        size: size,
                                                                                                                                                        type: [.album],
                                                                                                                                                        status: [.official],
                                                                                                                                                        ReleaseConnection_first: releaseConnectionFirst)) { result in
                                         _completion(result.map { $0.data?.lookup?.artist?.releaseGroups1?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup })
                                     }
                                 },
                                 
                                 data: data)
            }
        }

        func artistDetailView(mbid: String,
                              size: Music.TheAudioDbImageSize? = Music.TheAudioDbImageSize.full,
                              after: String? = nil,
                              urlStringSize: Music.LastFmImageSize? = nil,
                              releaseConnectionFirst: Int? = nil,
                              lang: String? = "en") -> some View {
            return QueryRenderer(client: client,
                                 query: ApolloMusic.ArtistDetailViewQuery(mbid: mbid,
                                                                          size: size,
                                                                          first: 5,
                                                                          after: after,
                                                                          URLString_size: urlStringSize,
                                                                          type: [.album],
                                                                          status: [.official],
                                                                          ReleaseConnection_first: releaseConnectionFirst,
                                                                          ReleaseGroupConnection_type: [.single],
                                                                          lang: lang),
                                 loading: ArtistDetailView.placeholderView(api: self,
                                                                           topSongs: ApolloMusic.ArtistDetailViewQuery.Data.placeholder.lookup?.artist?.lastFm?.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack.paging { _, _, _ in
                                                                               // no-op
                                                                           },
                                                                           
                                                                           albums: ApolloMusic.ArtistDetailViewQuery.Data.placeholder.lookup?.artist?.releaseGroups?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup.paging { _, _, _ in
                                                                               // no-op
                                                                           },
                                                                           
                                                                           singles: ApolloMusic.ArtistDetailViewQuery.Data.placeholder.lookup?.artist?.releaseGroups1?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup.paging { _, _, _ in
                                                                               // no-op
                                 }),
                                 error: { BasicErrorView(error: $0) }) { (data: ApolloMusic.ArtistDetailViewQuery.Data) -> ArtistDetailView in

                ArtistDetailView(api: self,
                                 topSongs: data.lookup?.artist?.lastFm?.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack.paging { _cursor, _pageSize, _completion in
                                     self.client.fetch(query: ApolloMusic.ArtistDetailViewTopSongsLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery(mbid: mbid,
                                                                                                                                                         first: _pageSize ?? 5,
                                                                                                                                                         after: _cursor,
                                                                                                                                                         URLString_size: urlStringSize)) { result in
                                         _completion(result.map { $0.data?.lookup?.artist?.lastFm?.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack })
                                     }
                                 },
                                 
                                 albums: data.lookup?.artist?.releaseGroups?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup.paging { _cursor, _pageSize, _completion in
                                     self.client.fetch(query: ApolloMusic.ArtistDetailViewAlbumsReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery(mbid: mbid,
                                                                                                                                                       type: [.album],
                                                                                                                                                       after: _cursor,
                                                                                                                                                       first: _pageSize ?? 5,
                                                                                                                                                       size: size,
                                                                                                                                                       status: [.official],
                                                                                                                                                       ReleaseConnection_first: releaseConnectionFirst)) { result in
                                         _completion(result.map { $0.data?.lookup?.artist?.releaseGroups?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup })
                                     }
                                 },
                                 
                                 singles: data.lookup?.artist?.releaseGroups1?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup.paging { _cursor, _pageSize, _completion in
                                     self.client.fetch(query: ApolloMusic.ArtistDetailViewSinglesReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery(mbid: mbid,
                                                                                                                                                        ReleaseGroupConnection_type: [.single],
                                                                                                                                                        after: _cursor,
                                                                                                                                                        first: _pageSize ?? 5,
                                                                                                                                                        size: size,
                                                                                                                                                        type: [.album],
                                                                                                                                                        status: [.official],
                                                                                                                                                        ReleaseConnection_first: releaseConnectionFirst)) { result in
                                         _completion(result.map { $0.data?.lookup?.artist?.releaseGroups1?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup })
                                     }
                                 },
                                 
                                 data: data)
            }
        }
    }

    extension ApolloMusic.ArtistDetailViewQuery.Data {
        private static let placeholderMap: ResultMap = ["lookup": ["__typename": "LookupQuery", "artist": ["__typename": "Artist", "area": ["__typename": "Area", "name": "__GRAPHAELLO_PLACEHOLDER__"], "lastFM": ["__typename": "LastFMArtist", "topTracks": ["__typename": "LastFMTrackConnection", "edges": Array(repeating: ["__typename": "LastFMTrackEdge", "node": ["__typename": "LastFMTrack", "album": ["__typename": "LastFMAlbum", "image": "__GRAPHAELLO_PLACEHOLDER__", "mbid": "__GRAPHAELLO_PLACEHOLDER__"], "artist": ["__typename": "LastFMArtist", "name": "__GRAPHAELLO_PLACEHOLDER__"], "title": "__GRAPHAELLO_PLACEHOLDER__"]], count: 5) as [ResultMap], "pageInfo": ["__typename": "PageInfo", "endCursor": "__GRAPHAELLO_PLACEHOLDER__", "hasNextPage": true]]], "lifeSpan": ["__typename": "LifeSpan", "begin": "__GRAPHAELLO_PLACEHOLDER__"], "name": "__GRAPHAELLO_PLACEHOLDER__", "releaseGroups": ["__typename": "ReleaseGroupConnection", "edges": Array(repeating: ["__typename": "ReleaseGroupEdge", "node": ["__typename": "ReleaseGroup", "releases": ["__typename": "ReleaseConnection", "nodes": Array(repeating: ["__typename": "Release", "mbid": "__GRAPHAELLO_PLACEHOLDER__"], count: 5) as [ResultMap]], "theAudioDB": ["__typename": "TheAudioDBAlbum", "frontImage": "__GRAPHAELLO_PLACEHOLDER__"], "title": "__GRAPHAELLO_PLACEHOLDER__"]], count: 5) as [ResultMap], "pageInfo": ["__typename": "PageInfo", "endCursor": "__GRAPHAELLO_PLACEHOLDER__", "hasNextPage": true]], "releaseGroups1": ["__typename": "ReleaseGroupConnection", "edges": Array(repeating: ["__typename": "ReleaseGroupEdge", "node": ["__typename": "ReleaseGroup", "releases": ["__typename": "ReleaseConnection", "nodes": Array(repeating: ["__typename": "Release", "mbid": "__GRAPHAELLO_PLACEHOLDER__"], count: 5) as [ResultMap]], "theAudioDB": ["__typename": "TheAudioDBAlbum", "frontImage": "__GRAPHAELLO_PLACEHOLDER__"], "title": "__GRAPHAELLO_PLACEHOLDER__"]], count: 5) as [ResultMap], "pageInfo": ["__typename": "PageInfo", "endCursor": "__GRAPHAELLO_PLACEHOLDER__", "hasNextPage": true]], "theAudioDB": ["__typename": "TheAudioDBArtist", "biography": "__GRAPHAELLO_PLACEHOLDER__", "mood": "__GRAPHAELLO_PLACEHOLDER__", "style": "__GRAPHAELLO_PLACEHOLDER__", "thumbnail": "__GRAPHAELLO_PLACEHOLDER__"], "type": "__GRAPHAELLO_PLACEHOLDER__"]]]

        static let placeholder = ApolloMusic.ArtistDetailViewQuery.Data(
            unsafeResultMap: ApolloMusic.ArtistDetailViewQuery.Data.placeholderMap
        )
    }

    extension ApolloMusic.ArtistDetailViewQuery.Data.Lookup.Artist.LastFm.TopTrack {
        public struct Fragments {
            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
            }
        }

        public var fragments: Fragments {
            get {
                return Fragments(unsafeResultMap: resultMap)
            }
            set {
                resultMap += newValue.resultMap
            }
        }
    }

    extension ApolloMusic.ArtistDetailViewQuery.Data.Lookup.Artist.ReleaseGroup {
        public struct Fragments {
            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
            }
        }

        public var fragments: Fragments {
            get {
                return Fragments(unsafeResultMap: resultMap)
            }
            set {
                resultMap += newValue.resultMap
            }
        }
    }

    extension ApolloMusic.ArtistDetailViewQuery.Data.Lookup.Artist.ReleaseGroups1 {
        public struct Fragments {
            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
            }
        }

        public var fragments: Fragments {
            get {
                return Fragments(unsafeResultMap: resultMap)
            }
            set {
                resultMap += newValue.resultMap
            }
        }
    }

    extension ApolloMusic.ArtistDetailViewTopSongsLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery.Data.Lookup.Artist.LastFm.TopTrack {
        public struct Fragments {
            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
            }
        }

        public var fragments: Fragments {
            get {
                return Fragments(unsafeResultMap: resultMap)
            }
            set {
                resultMap += newValue.resultMap
            }
        }
    }

    extension ApolloMusic.ArtistDetailViewAlbumsReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery.Data.Lookup.Artist.ReleaseGroup {
        public struct Fragments {
            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
            }
        }

        public var fragments: Fragments {
            get {
                return Fragments(unsafeResultMap: resultMap)
            }
            set {
                resultMap += newValue.resultMap
            }
        }
    }

    extension ApolloMusic.ArtistDetailViewSinglesReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery.Data.Lookup.Artist.ReleaseGroups1 {
        public struct Fragments {
            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
            }
        }

        public var fragments: Fragments {
            get {
                return Fragments(unsafeResultMap: resultMap)
            }
            set {
                resultMap += newValue.resultMap
            }
        }
    }

    extension ApolloMusic.ArtistDetailViewQuery.Data.Lookup.Artist.LastFm.TopTrack.Fragments {
        public var lastFmTrackConnectionTrendingTrackCellLastFmTrack: ApolloMusic.LastFmTrackConnectionTrendingTrackCellLastFmTrack {
            get {
                return ApolloMusic.LastFmTrackConnectionTrendingTrackCellLastFmTrack(unsafeResultMap: resultMap)
            }
            set {
                resultMap += newValue.resultMap
            }
        }
    }

    extension ApolloMusic.ArtistDetailViewQuery.Data.Lookup.Artist.ReleaseGroup.Fragments {
        public var releaseGroupConnectionArtistAlbumCellReleaseGroup: ApolloMusic.ReleaseGroupConnectionArtistAlbumCellReleaseGroup {
            get {
                return ApolloMusic.ReleaseGroupConnectionArtistAlbumCellReleaseGroup(unsafeResultMap: resultMap)
            }
            set {
                resultMap += newValue.resultMap
            }
        }
    }

    extension ApolloMusic.ArtistDetailViewQuery.Data.Lookup.Artist.ReleaseGroups1.Fragments {
        public var releaseGroupConnectionArtistAlbumCellReleaseGroup: ApolloMusic.ReleaseGroupConnectionArtistAlbumCellReleaseGroup {
            get {
                return ApolloMusic.ReleaseGroupConnectionArtistAlbumCellReleaseGroup(unsafeResultMap: resultMap)
            }
            set {
                resultMap += newValue.resultMap
            }
        }
    }

    extension ApolloMusic.ArtistDetailViewTopSongsLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery.Data.Lookup.Artist.LastFm.TopTrack.Fragments {
        public var lastFmTrackConnectionTrendingTrackCellLastFmTrack: ApolloMusic.LastFmTrackConnectionTrendingTrackCellLastFmTrack {
            get {
                return ApolloMusic.LastFmTrackConnectionTrendingTrackCellLastFmTrack(unsafeResultMap: resultMap)
            }
            set {
                resultMap += newValue.resultMap
            }
        }
    }

    extension ApolloMusic.ArtistDetailViewAlbumsReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery.Data.Lookup.Artist.ReleaseGroup.Fragments {
        public var releaseGroupConnectionArtistAlbumCellReleaseGroup: ApolloMusic.ReleaseGroupConnectionArtistAlbumCellReleaseGroup {
            get {
                return ApolloMusic.ReleaseGroupConnectionArtistAlbumCellReleaseGroup(unsafeResultMap: resultMap)
            }
            set {
                resultMap += newValue.resultMap
            }
        }
    }

    extension ApolloMusic.ArtistDetailViewSinglesReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery.Data.Lookup.Artist.ReleaseGroups1.Fragments {
        public var releaseGroupConnectionArtistAlbumCellReleaseGroup: ApolloMusic.ReleaseGroupConnectionArtistAlbumCellReleaseGroup {
            get {
                return ApolloMusic.ReleaseGroupConnectionArtistAlbumCellReleaseGroup(unsafeResultMap: resultMap)
            }
            set {
                resultMap += newValue.resultMap
            }
        }
    }

#endif


// MARK: - AlbumDetailView

#if GRAPHAELLO_MUSIC_TARGET

    extension AlbumDetailView {
        typealias Data = ApolloMusic.AlbumDetailViewQuery.Data

        init(api: Music,
             data: Data) {
            self.init(api: api,
                      title: GraphQL(data.lookup?.release?.title),
                      cover: GraphQL(data.lookup?.release?.coverArtArchive?.front),
                      artists: GraphQL(data.lookup?.release?.artistCredits?.map { $0?.artist?.fragments.albumArtistCreditButtonArtist }),
                      genres: GraphQL(data.lookup?.release?.discogs?.genres),
                      date: GraphQL(data.lookup?.release?.date),
                      media: GraphQL(data.lookup?.release?.media?.map { $0?.tracks?.map { $0?.fragments.albumTrackCellTrack } }),
                      playCount: GraphQL(data.lookup?.release?.lastFm?.playCount))
        }

        @ViewBuilder
        static func placeholderView(api: Music) -> some View {
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                Self(api: api,
                     data: .placeholder).disabled(true).redacted(reason: .placeholder)
            } else {
                BasicLoadingView()
            }
        }
    }

    extension Music {
        func albumDetailView<Loading: View, Error: View>(mbid: String,
                                                         
                                                         @ViewBuilder loading: () -> Loading,
                                                         @ViewBuilder error: @escaping (QueryError) -> Error) -> some View {
            return QueryRenderer(client: client,
                                 query: ApolloMusic.AlbumDetailViewQuery(mbid: mbid,
                                                                         size: .small),
                                 loading: loading(),
                                 error: error) { (data: ApolloMusic.AlbumDetailViewQuery.Data) -> AlbumDetailView in

                AlbumDetailView(api: self,
                                data: data)
            }
        }

        func albumDetailView<Loading: View>(mbid: String,
                                            
                                            @ViewBuilder loading: () -> Loading) -> some View {
            return QueryRenderer(client: client,
                                 query: ApolloMusic.AlbumDetailViewQuery(mbid: mbid,
                                                                         size: .small),
                                 loading: loading(),
                                 error: { BasicErrorView(error: $0) }) { (data: ApolloMusic.AlbumDetailViewQuery.Data) -> AlbumDetailView in

                AlbumDetailView(api: self,
                                data: data)
            }
        }

        func albumDetailView<Error: View>(mbid: String,
                                          
                                          @ViewBuilder error: @escaping (QueryError) -> Error) -> some View {
            return QueryRenderer(client: client,
                                 query: ApolloMusic.AlbumDetailViewQuery(mbid: mbid,
                                                                         size: .small),
                                 loading: AlbumDetailView.placeholderView(api: self),
                                 error: error) { (data: ApolloMusic.AlbumDetailViewQuery.Data) -> AlbumDetailView in

                AlbumDetailView(api: self,
                                data: data)
            }
        }

        func albumDetailView(mbid: String) -> some View {
            return QueryRenderer(client: client,
                                 query: ApolloMusic.AlbumDetailViewQuery(mbid: mbid,
                                                                         size: .small),
                                 loading: AlbumDetailView.placeholderView(api: self),
                                 error: { BasicErrorView(error: $0) }) { (data: ApolloMusic.AlbumDetailViewQuery.Data) -> AlbumDetailView in

                AlbumDetailView(api: self,
                                data: data)
            }
        }
    }

    extension ApolloMusic.AlbumDetailViewQuery.Data {
        private static let placeholderMap: ResultMap = ["lookup": ["__typename": "LookupQuery", "release": ["__typename": "Release", "artistCredits": Array(repeating: ["__typename": "ArtistCredit", "artist": ["__typename": "Artist", "mbid": "__GRAPHAELLO_PLACEHOLDER__", "name": "__GRAPHAELLO_PLACEHOLDER__"]], count: 5) as [ResultMap], "coverArtArchive": ["__typename": "CoverArtArchiveRelease", "front": "__GRAPHAELLO_PLACEHOLDER__"], "date": "__GRAPHAELLO_PLACEHOLDER__", "discogs": ["__typename": "DiscogsRelease", "genres": Array(repeating: "__GRAPHAELLO_PLACEHOLDER__", count: 5) as [String]], "lastFM": ["__typename": "LastFMAlbum", "playCount": 42.0], "media": Array(repeating: ["__typename": "Medium", "tracks": Array(repeating: ["__typename": "Track", "position": 42, "recording": ["__typename": "Recording", "artistCredits": Array(repeating: ["__typename": "ArtistCredit", "joinPhrase": "__GRAPHAELLO_PLACEHOLDER__", "name": "__GRAPHAELLO_PLACEHOLDER__"], count: 5) as [ResultMap], "lastFM": ["__typename": "LastFMTrack", "playCount": 42.0]], "title": "__GRAPHAELLO_PLACEHOLDER__"], count: 5) as [ResultMap]], count: 5) as [ResultMap], "title": "__GRAPHAELLO_PLACEHOLDER__"]]]

        static let placeholder = ApolloMusic.AlbumDetailViewQuery.Data(
            unsafeResultMap: ApolloMusic.AlbumDetailViewQuery.Data.placeholderMap
        )
    }

#endif




extension ApolloMusic.LastFmArtistConnectionTrendingArtistCellLastFmArtist {
    typealias Completion = (Result<ApolloMusic.LastFmArtistConnectionTrendingArtistCellLastFmArtist?, Error>) -> Void
    typealias Loader = (String, Int?, @escaping Completion) -> Void

    private var response: Paging<ApolloMusic.TrendingArtistCellLastFmArtist>.Response {
        return Paging.Response(values: edges?.compactMap { $0?.node?.fragments.trendingArtistCellLastFmArtist } ?? [],
                               cursor: pageInfo.endCursor,
                               hasMore: pageInfo.hasNextPage)
    }

    fileprivate func paging(loader: @escaping Loader) -> Paging<ApolloMusic.TrendingArtistCellLastFmArtist> {
        return Paging(response) { cursor, pageSize, completion in
            loader(cursor, pageSize) { result in
                completion(result.map { $0?.response ?? .empty })
            }
        }
    }
}

extension ApolloMusic.LastFmArtistConnectionTrendingArtistCellLastFmArtist.Edge.Node {
    public struct Fragments {
        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
            resultMap = unsafeResultMap
        }
    }

    public var fragments: Fragments {
        get {
            return Fragments(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }
}

extension ApolloMusic.LastFmArtistConnectionTrendingArtistCellLastFmArtist.Edge.Node.Fragments {
    public var trendingArtistCellLastFmArtist: ApolloMusic.TrendingArtistCellLastFmArtist {
        get {
            return ApolloMusic.TrendingArtistCellLastFmArtist(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }
}


extension ApolloMusic.LastFmTrackConnectionTrendingTrackCellLastFmTrack {
    typealias Completion = (Result<ApolloMusic.LastFmTrackConnectionTrendingTrackCellLastFmTrack?, Error>) -> Void
    typealias Loader = (String, Int?, @escaping Completion) -> Void

    private var response: Paging<ApolloMusic.TrendingTrackCellLastFmTrack>.Response {
        return Paging.Response(values: edges?.compactMap { $0?.node?.fragments.trendingTrackCellLastFmTrack } ?? [],
                               cursor: pageInfo.endCursor,
                               hasMore: pageInfo.hasNextPage)
    }

    fileprivate func paging(loader: @escaping Loader) -> Paging<ApolloMusic.TrendingTrackCellLastFmTrack> {
        return Paging(response) { cursor, pageSize, completion in
            loader(cursor, pageSize) { result in
                completion(result.map { $0?.response ?? .empty })
            }
        }
    }
}

extension ApolloMusic.LastFmTrackConnectionTrendingTrackCellLastFmTrack.Edge.Node {
    public struct Fragments {
        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
            resultMap = unsafeResultMap
        }
    }

    public var fragments: Fragments {
        get {
            return Fragments(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }
}

extension ApolloMusic.LastFmTrackConnectionTrendingTrackCellLastFmTrack.Edge.Node.Fragments {
    public var trendingTrackCellLastFmTrack: ApolloMusic.TrendingTrackCellLastFmTrack {
        get {
            return ApolloMusic.TrendingTrackCellLastFmTrack(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }
}


extension ApolloMusic.ReleaseGroupConnectionArtistAlbumCellReleaseGroup {
    typealias Completion = (Result<ApolloMusic.ReleaseGroupConnectionArtistAlbumCellReleaseGroup?, Error>) -> Void
    typealias Loader = (String, Int?, @escaping Completion) -> Void

    private var response: Paging<ApolloMusic.ArtistAlbumCellReleaseGroup>.Response {
        return Paging.Response(values: edges?.compactMap { $0?.node?.fragments.artistAlbumCellReleaseGroup } ?? [],
                               cursor: pageInfo.endCursor,
                               hasMore: pageInfo.hasNextPage)
    }

    fileprivate func paging(loader: @escaping Loader) -> Paging<ApolloMusic.ArtistAlbumCellReleaseGroup> {
        return Paging(response) { cursor, pageSize, completion in
            loader(cursor, pageSize) { result in
                completion(result.map { $0?.response ?? .empty })
            }
        }
    }
}

extension ApolloMusic.ReleaseGroupConnectionArtistAlbumCellReleaseGroup.Edge.Node {
    public struct Fragments {
        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
            resultMap = unsafeResultMap
        }
    }

    public var fragments: Fragments {
        get {
            return Fragments(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }
}

extension ApolloMusic.ReleaseGroupConnectionArtistAlbumCellReleaseGroup.Edge.Node.Fragments {
    public var artistAlbumCellReleaseGroup: ApolloMusic.ArtistAlbumCellReleaseGroup {
        get {
            return ApolloMusic.ArtistAlbumCellReleaseGroup(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }
}




// @generated
//  This file was automatically generated and should not be edited.

import Apollo
import Foundation

/// ApolloMusic namespace
public enum ApolloMusic {
  /// The image sizes that may be requested at [Last.fm](https://www.last.fm/).
  public enum LastFMImageSize: RawRepresentable, Equatable, Hashable, CaseIterable, Apollo.JSONDecodable, Apollo.JSONEncodable {
    public typealias RawValue = String
    /// A maximum dimension of 34px.
    case small
    /// A maximum dimension of 64px.
    case medium
    /// A maximum dimension of 174px.
    case large
    /// A maximum dimension of 300px.
    case extralarge
    /// A maximum dimension of 300px.
    case mega
    /// Auto generated constant for unknown enum values
    case __unknown(RawValue)

    public init?(rawValue: RawValue) {
      switch rawValue {
        case "SMALL": self = .small
        case "MEDIUM": self = .medium
        case "LARGE": self = .large
        case "EXTRALARGE": self = .extralarge
        case "MEGA": self = .mega
        default: self = .__unknown(rawValue)
      }
    }

    public var rawValue: RawValue {
      switch self {
        case .small: return "SMALL"
        case .medium: return "MEDIUM"
        case .large: return "LARGE"
        case .extralarge: return "EXTRALARGE"
        case .mega: return "MEGA"
        case .__unknown(let value): return value
      }
    }

    public static func == (lhs: LastFMImageSize, rhs: LastFMImageSize) -> Bool {
      switch (lhs, rhs) {
        case (.small, .small): return true
        case (.medium, .medium): return true
        case (.large, .large): return true
        case (.extralarge, .extralarge): return true
        case (.mega, .mega): return true
        case (.__unknown(let lhsValue), .__unknown(let rhsValue)): return lhsValue == rhsValue
        default: return false
      }
    }

    public static var allCases: [LastFMImageSize] {
      return [
        .small,
        .medium,
        .large,
        .extralarge,
        .mega,
      ]
    }
  }

  /// A type used to describe release groups, e.g. album, single, EP,
  /// etc.
  public enum ReleaseGroupType: RawRepresentable, Equatable, Hashable, CaseIterable, Apollo.JSONDecodable, Apollo.JSONEncodable {
    public typealias RawValue = String
    /// An album, perhaps better defined as a “Long Play” (LP)
    /// release, generally consists of previously unreleased material (unless this type
    /// is combined with secondary types which change that, such as “Compilation”). This
    /// includes album re-issues, with or without bonus tracks.
    case album
    /// A single typically has one main song and possibly a handful
    /// of additional tracks or remixes of the main track. A single is usually named
    /// after its main song.
    case single
    /// An EP is a so-called “Extended Play” release and often
    /// contains the letters EP in the title. Generally an EP will be shorter than a
    /// full length release (an LP or “Long Play”) and the tracks are usually exclusive
    /// to the EP, in other words the tracks don’t come from a previously issued
    /// release. EP is fairly difficult to define; usually it should only be assumed
    /// that a release is an EP if the artist defines it as such.
    case ep
    /// Any release that does not fit any of the other categories.
    case other
    /// An episodic release that was originally broadcast via radio,
    /// television, or the Internet, including podcasts.
    case broadcast
    /// A compilation is a collection of previously released tracks
    /// by one or more artists.
    case compilation
    /// A soundtrack is the musical score to a movie, TV series,
    /// stage show, computer game, etc.
    case soundtrack
    /// A non-music spoken word release.
    case spokenword
    /// An interview release contains an interview, generally with
    /// an artist.
    case interview
    /// An audiobook is a book read by a narrator without music.
    case audiobook
    /// A release that was recorded live.
    case live
    /// A release that was (re)mixed from previously released
    /// material.
    case remix
    /// A DJ-mix is a sequence of several recordings played one
    /// after the other, each one modified so that they blend together into a continuous
    /// flow of music. A DJ mix release requires that the recordings be modified in some
    /// manner, and the DJ who does this modification is usually (although not always)
    /// credited in a fairly prominent way.
    case djmix
    /// Promotional in nature (but not necessarily free), mixtapes
    /// and street albums are often released by artists to promote new artists, or
    /// upcoming studio albums by prominent artists. They are also sometimes used to
    /// keep fans’ attention between studio releases and are most common in rap & hip
    /// hop genres. They are often not sanctioned by the artist’s label, may lack proper
    /// sample or song clearances and vary widely in production and recording quality.
    /// While mixtapes are generally DJ-mixed, they are distinct from commercial DJ
    /// mixes (which are usually deemed compilations) and are defined by having a
    /// significant proportion of new material, including original production or
    /// original vocals over top of other artists’ instrumentals. They are distinct from
    /// demos in that they are designed for release directly to the public and fans, not
    /// to labels.
    case mixtape
    /// A release that was recorded for limited circulation or
    /// reference use rather than for general public release.
    case demo
    /// A non-album track (special case).
    case nat
    /// Auto generated constant for unknown enum values
    case __unknown(RawValue)

    public init?(rawValue: RawValue) {
      switch rawValue {
        case "ALBUM": self = .album
        case "SINGLE": self = .single
        case "EP": self = .ep
        case "OTHER": self = .other
        case "BROADCAST": self = .broadcast
        case "COMPILATION": self = .compilation
        case "SOUNDTRACK": self = .soundtrack
        case "SPOKENWORD": self = .spokenword
        case "INTERVIEW": self = .interview
        case "AUDIOBOOK": self = .audiobook
        case "LIVE": self = .live
        case "REMIX": self = .remix
        case "DJMIX": self = .djmix
        case "MIXTAPE": self = .mixtape
        case "DEMO": self = .demo
        case "NAT": self = .nat
        default: self = .__unknown(rawValue)
      }
    }

    public var rawValue: RawValue {
      switch self {
        case .album: return "ALBUM"
        case .single: return "SINGLE"
        case .ep: return "EP"
        case .other: return "OTHER"
        case .broadcast: return "BROADCAST"
        case .compilation: return "COMPILATION"
        case .soundtrack: return "SOUNDTRACK"
        case .spokenword: return "SPOKENWORD"
        case .interview: return "INTERVIEW"
        case .audiobook: return "AUDIOBOOK"
        case .live: return "LIVE"
        case .remix: return "REMIX"
        case .djmix: return "DJMIX"
        case .mixtape: return "MIXTAPE"
        case .demo: return "DEMO"
        case .nat: return "NAT"
        case .__unknown(let value): return value
      }
    }

    public static func == (lhs: ReleaseGroupType, rhs: ReleaseGroupType) -> Bool {
      switch (lhs, rhs) {
        case (.album, .album): return true
        case (.single, .single): return true
        case (.ep, .ep): return true
        case (.other, .other): return true
        case (.broadcast, .broadcast): return true
        case (.compilation, .compilation): return true
        case (.soundtrack, .soundtrack): return true
        case (.spokenword, .spokenword): return true
        case (.interview, .interview): return true
        case (.audiobook, .audiobook): return true
        case (.live, .live): return true
        case (.remix, .remix): return true
        case (.djmix, .djmix): return true
        case (.mixtape, .mixtape): return true
        case (.demo, .demo): return true
        case (.nat, .nat): return true
        case (.__unknown(let lhsValue), .__unknown(let rhsValue)): return lhsValue == rhsValue
        default: return false
      }
    }

    public static var allCases: [ReleaseGroupType] {
      return [
        .album,
        .single,
        .ep,
        .other,
        .broadcast,
        .compilation,
        .soundtrack,
        .spokenword,
        .interview,
        .audiobook,
        .live,
        .remix,
        .djmix,
        .mixtape,
        .demo,
        .nat,
      ]
    }
  }

  /// The image sizes that may be requested at [TheAudioDB](http://www.theaudiodb.com/).
  public enum TheAudioDBImageSize: RawRepresentable, Equatable, Hashable, CaseIterable, Apollo.JSONDecodable, Apollo.JSONEncodable {
    public typealias RawValue = String
    /// The image’s full original dimensions.
    case full
    /// A maximum dimension of 200px.
    case preview
    /// Auto generated constant for unknown enum values
    case __unknown(RawValue)

    public init?(rawValue: RawValue) {
      switch rawValue {
        case "FULL": self = .full
        case "PREVIEW": self = .preview
        default: self = .__unknown(rawValue)
      }
    }

    public var rawValue: RawValue {
      switch self {
        case .full: return "FULL"
        case .preview: return "PREVIEW"
        case .__unknown(let value): return value
      }
    }

    public static func == (lhs: TheAudioDBImageSize, rhs: TheAudioDBImageSize) -> Bool {
      switch (lhs, rhs) {
        case (.full, .full): return true
        case (.preview, .preview): return true
        case (.__unknown(let lhsValue), .__unknown(let rhsValue)): return lhsValue == rhsValue
        default: return false
      }
    }

    public static var allCases: [TheAudioDBImageSize] {
      return [
        .full,
        .preview,
      ]
    }
  }

  /// A type used to describe the status of releases, e.g. official,
  /// bootleg, etc.
  public enum ReleaseStatus: RawRepresentable, Equatable, Hashable, CaseIterable, Apollo.JSONDecodable, Apollo.JSONEncodable {
    public typealias RawValue = String
    /// Any release officially sanctioned by the artist and/or their
    /// record company. (Most releases will fit into this category.)
    case official
    /// A giveaway release or a release intended to promote an
    /// upcoming official release, e.g. prerelease albums or releases included with a
    /// magazine.
    case promotion
    /// An unofficial/underground release that was not sanctioned by
    /// the artist and/or the record company.
    case bootleg
    /// A pseudo-release is a duplicate release for
    /// translation/transliteration purposes.
    case pseudorelease
    /// Auto generated constant for unknown enum values
    case __unknown(RawValue)

    public init?(rawValue: RawValue) {
      switch rawValue {
        case "OFFICIAL": self = .official
        case "PROMOTION": self = .promotion
        case "BOOTLEG": self = .bootleg
        case "PSEUDORELEASE": self = .pseudorelease
        default: self = .__unknown(rawValue)
      }
    }

    public var rawValue: RawValue {
      switch self {
        case .official: return "OFFICIAL"
        case .promotion: return "PROMOTION"
        case .bootleg: return "BOOTLEG"
        case .pseudorelease: return "PSEUDORELEASE"
        case .__unknown(let value): return value
      }
    }

    public static func == (lhs: ReleaseStatus, rhs: ReleaseStatus) -> Bool {
      switch (lhs, rhs) {
        case (.official, .official): return true
        case (.promotion, .promotion): return true
        case (.bootleg, .bootleg): return true
        case (.pseudorelease, .pseudorelease): return true
        case (.__unknown(let lhsValue), .__unknown(let rhsValue)): return lhsValue == rhsValue
        default: return false
      }
    }

    public static var allCases: [ReleaseStatus] {
      return [
        .official,
        .promotion,
        .bootleg,
        .pseudorelease,
      ]
    }
  }

  /// The image sizes that may be requested at the [Cover Art Archive](https://musicbrainz.org/doc/Cover_Art_Archive).
  public enum CoverArtArchiveImageSize: RawRepresentable, Equatable, Hashable, CaseIterable, Apollo.JSONDecodable, Apollo.JSONEncodable {
    public typealias RawValue = String
    /// A maximum dimension of 250px.
    case small
    /// A maximum dimension of 500px.
    case large
    /// The image’s original dimensions, with no maximum.
    case full
    /// Auto generated constant for unknown enum values
    case __unknown(RawValue)

    public init?(rawValue: RawValue) {
      switch rawValue {
        case "SMALL": self = .small
        case "LARGE": self = .large
        case "FULL": self = .full
        default: self = .__unknown(rawValue)
      }
    }

    public var rawValue: RawValue {
      switch self {
        case .small: return "SMALL"
        case .large: return "LARGE"
        case .full: return "FULL"
        case .__unknown(let value): return value
      }
    }

    public static func == (lhs: CoverArtArchiveImageSize, rhs: CoverArtArchiveImageSize) -> Bool {
      switch (lhs, rhs) {
        case (.small, .small): return true
        case (.large, .large): return true
        case (.full, .full): return true
        case (.__unknown(let lhsValue), .__unknown(let rhsValue)): return lhsValue == rhsValue
        default: return false
      }
    }

    public static var allCases: [CoverArtArchiveImageSize] {
      return [
        .small,
        .large,
        .full,
      ]
    }
  }

  public final class TrendingArtistsListArtistsLastFmArtistConnectionTrendingArtistCellLastFmArtistQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      query TrendingArtistsListArtistsLastFMArtistConnectionTrendingArtistCellLastFMArtist($country: String, $first: Int, $after: String, $LastFMTagConnection_first: Int, $LastFMAlbumConnection_first: Int, $size: LastFMImageSize, $LastFMTrackConnection_first: Int) {
        lastFM {
          __typename
          chart {
            __typename
            topArtists(after: $after, country: $country, first: $first) {
              __typename
              edges {
                __typename
                node {
                  __typename
                  mbid
                  name
                  topAlbums(after: $after, first: $LastFMAlbumConnection_first) {
                    __typename
                    nodes {
                      __typename
                      image(size: $size)
                    }
                  }
                  topTags(after: $after, first: $LastFMTagConnection_first) {
                    __typename
                    nodes {
                      __typename
                      name
                    }
                  }
                  topTracks(after: $after, first: $LastFMTrackConnection_first) {
                    __typename
                    nodes {
                      __typename
                      title
                    }
                  }
                }
              }
              pageInfo {
                __typename
                endCursor
                hasNextPage
              }
            }
          }
        }
      }
      """

    public let operationName: String = "TrendingArtistsListArtistsLastFMArtistConnectionTrendingArtistCellLastFMArtist"

    public var country: String?
    public var first: Int?
    public var after: String?
    public var LastFMTagConnection_first: Int?
    public var LastFMAlbumConnection_first: Int?
    public var size: LastFMImageSize?
    public var LastFMTrackConnection_first: Int?

    public init(country: String? = nil, first: Int? = nil, after: String? = nil, LastFMTagConnection_first: Int? = nil, LastFMAlbumConnection_first: Int? = nil, size: LastFMImageSize? = nil, LastFMTrackConnection_first: Int? = nil) {
      self.country = country
      self.first = first
      self.after = after
      self.LastFMTagConnection_first = LastFMTagConnection_first
      self.LastFMAlbumConnection_first = LastFMAlbumConnection_first
      self.size = size
      self.LastFMTrackConnection_first = LastFMTrackConnection_first
    }

    public var variables: GraphQLMap? {
      return ["country": country, "first": first, "after": after, "LastFMTagConnection_first": LastFMTagConnection_first, "LastFMAlbumConnection_first": LastFMAlbumConnection_first, "size": size, "LastFMTrackConnection_first": LastFMTrackConnection_first]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Query"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("lastFM", type: .object(LastFm.selections)),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(lastFm: LastFm? = nil) {
        self.init(unsafeResultMap: ["__typename": "Query", "lastFM": lastFm.flatMap { (value: LastFm) -> ResultMap in value.resultMap }])
      }

      /// A query for data on [Last.fm](https://www.last.fm/) that is not connected
      /// to any particular MusicBrainz entity. This field is provided by the
      /// Last.fm extension.
      public var lastFm: LastFm? {
        get {
          return (resultMap["lastFM"] as? ResultMap).flatMap { LastFm(unsafeResultMap: $0) }
        }
        set {
          resultMap.updateValue(newValue?.resultMap, forKey: "lastFM")
        }
      }

      public struct LastFm: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["LastFMQuery"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("chart", type: .nonNull(.object(Chart.selections))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(chart: Chart) {
          self.init(unsafeResultMap: ["__typename": "LastFMQuery", "chart": chart.resultMap])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        /// A query for chart data.
        public var chart: Chart {
          get {
            return Chart(unsafeResultMap: resultMap["chart"]! as! ResultMap)
          }
          set {
            resultMap.updateValue(newValue.resultMap, forKey: "chart")
          }
        }

        public struct Chart: GraphQLSelectionSet {
          public static let possibleTypes: [String] = ["LastFMChartQuery"]

          public static var selections: [GraphQLSelection] {
            return [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("topArtists", arguments: ["after": GraphQLVariable("after"), "country": GraphQLVariable("country"), "first": GraphQLVariable("first")], type: .object(TopArtist.selections)),
            ]
          }

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(topArtists: TopArtist? = nil) {
            self.init(unsafeResultMap: ["__typename": "LastFMChartQuery", "topArtists": topArtists.flatMap { (value: TopArtist) -> ResultMap in value.resultMap }])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          /// The most popular artists, ordered by popularity. If a country code is
          /// given, retrieve the most popular artists in that country.
          public var topArtists: TopArtist? {
            get {
              return (resultMap["topArtists"] as? ResultMap).flatMap { TopArtist(unsafeResultMap: $0) }
            }
            set {
              resultMap.updateValue(newValue?.resultMap, forKey: "topArtists")
            }
          }

          public struct TopArtist: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["LastFMArtistConnection"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("edges", type: .list(.object(Edge.selections))),
                GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(edges: [Edge?]? = nil, pageInfo: PageInfo) {
              self.init(unsafeResultMap: ["__typename": "LastFMArtistConnection", "edges": edges.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, "pageInfo": pageInfo.resultMap])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            /// A list of edges.
            public var edges: [Edge?]? {
              get {
                return (resultMap["edges"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Edge?] in value.map { (value: ResultMap?) -> Edge? in value.flatMap { (value: ResultMap) -> Edge in Edge(unsafeResultMap: value) } } }
              }
              set {
                resultMap.updateValue(newValue.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, forKey: "edges")
              }
            }

            /// Information to aid in pagination.
            public var pageInfo: PageInfo {
              get {
                return PageInfo(unsafeResultMap: resultMap["pageInfo"]! as! ResultMap)
              }
              set {
                resultMap.updateValue(newValue.resultMap, forKey: "pageInfo")
              }
            }

            public struct Edge: GraphQLSelectionSet {
              public static let possibleTypes: [String] = ["LastFMArtistEdge"]

              public static var selections: [GraphQLSelection] {
                return [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("node", type: .object(Node.selections)),
                ]
              }

              public private(set) var resultMap: ResultMap

              public init(unsafeResultMap: ResultMap) {
                self.resultMap = unsafeResultMap
              }

              public init(node: Node? = nil) {
                self.init(unsafeResultMap: ["__typename": "LastFMArtistEdge", "node": node.flatMap { (value: Node) -> ResultMap in value.resultMap }])
              }

              public var __typename: String {
                get {
                  return resultMap["__typename"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "__typename")
                }
              }

              /// The item at the end of the edge.
              public var node: Node? {
                get {
                  return (resultMap["node"] as? ResultMap).flatMap { Node(unsafeResultMap: $0) }
                }
                set {
                  resultMap.updateValue(newValue?.resultMap, forKey: "node")
                }
              }

              public struct Node: GraphQLSelectionSet {
                public static let possibleTypes: [String] = ["LastFMArtist"]

                public static var selections: [GraphQLSelection] {
                  return [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("mbid", type: .scalar(String.self)),
                    GraphQLField("name", type: .scalar(String.self)),
                    GraphQLField("topAlbums", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("LastFMAlbumConnection_first")], type: .object(TopAlbum.selections)),
                    GraphQLField("topTags", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("LastFMTagConnection_first")], type: .object(TopTag.selections)),
                    GraphQLField("topTracks", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("LastFMTrackConnection_first")], type: .object(TopTrack.selections)),
                  ]
                }

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                  self.resultMap = unsafeResultMap
                }

                public init(mbid: String? = nil, name: String? = nil, topAlbums: TopAlbum? = nil, topTags: TopTag? = nil, topTracks: TopTrack? = nil) {
                  self.init(unsafeResultMap: ["__typename": "LastFMArtist", "mbid": mbid, "name": name, "topAlbums": topAlbums.flatMap { (value: TopAlbum) -> ResultMap in value.resultMap }, "topTags": topTags.flatMap { (value: TopTag) -> ResultMap in value.resultMap }, "topTracks": topTracks.flatMap { (value: TopTrack) -> ResultMap in value.resultMap }])
                }

                public var __typename: String {
                  get {
                    return resultMap["__typename"]! as! String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "__typename")
                  }
                }

                /// The MBID of the corresponding MusicBrainz artist.
                public var mbid: String? {
                  get {
                    return resultMap["mbid"] as? String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "mbid")
                  }
                }

                /// The name of the artist according to [Last.fm](https://www.last.fm/).
                public var name: String? {
                  get {
                    return resultMap["name"] as? String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "name")
                  }
                }

                /// A list of the artist’s most popular albums.
                public var topAlbums: TopAlbum? {
                  get {
                    return (resultMap["topAlbums"] as? ResultMap).flatMap { TopAlbum(unsafeResultMap: $0) }
                  }
                  set {
                    resultMap.updateValue(newValue?.resultMap, forKey: "topAlbums")
                  }
                }

                /// A list of tags applied to the artist by users, ordered by popularity.
                public var topTags: TopTag? {
                  get {
                    return (resultMap["topTags"] as? ResultMap).flatMap { TopTag(unsafeResultMap: $0) }
                  }
                  set {
                    resultMap.updateValue(newValue?.resultMap, forKey: "topTags")
                  }
                }

                /// A list of the artist’s most popular tracks.
                public var topTracks: TopTrack? {
                  get {
                    return (resultMap["topTracks"] as? ResultMap).flatMap { TopTrack(unsafeResultMap: $0) }
                  }
                  set {
                    resultMap.updateValue(newValue?.resultMap, forKey: "topTracks")
                  }
                }

                public struct TopAlbum: GraphQLSelectionSet {
                  public static let possibleTypes: [String] = ["LastFMAlbumConnection"]

                  public static var selections: [GraphQLSelection] {
                    return [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("nodes", type: .list(.object(Node.selections))),
                    ]
                  }

                  public private(set) var resultMap: ResultMap

                  public init(unsafeResultMap: ResultMap) {
                    self.resultMap = unsafeResultMap
                  }

                  public init(nodes: [Node?]? = nil) {
                    self.init(unsafeResultMap: ["__typename": "LastFMAlbumConnection", "nodes": nodes.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }])
                  }

                  public var __typename: String {
                    get {
                      return resultMap["__typename"]! as! String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "__typename")
                    }
                  }

                  /// A list of nodes in the connection (without going through the `edges` field).
                  public var nodes: [Node?]? {
                    get {
                      return (resultMap["nodes"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Node?] in value.map { (value: ResultMap?) -> Node? in value.flatMap { (value: ResultMap) -> Node in Node(unsafeResultMap: value) } } }
                    }
                    set {
                      resultMap.updateValue(newValue.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }, forKey: "nodes")
                    }
                  }

                  public struct Node: GraphQLSelectionSet {
                    public static let possibleTypes: [String] = ["LastFMAlbum"]

                    public static var selections: [GraphQLSelection] {
                      return [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("image", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                      ]
                    }

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                      self.resultMap = unsafeResultMap
                    }

                    public init(image: String? = nil) {
                      self.init(unsafeResultMap: ["__typename": "LastFMAlbum", "image": image])
                    }

                    public var __typename: String {
                      get {
                        return resultMap["__typename"]! as! String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "__typename")
                      }
                    }

                    /// An image of the cover artwork of the release.
                    public var image: String? {
                      get {
                        return resultMap["image"] as? String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "image")
                      }
                    }
                  }
                }

                public struct TopTag: GraphQLSelectionSet {
                  public static let possibleTypes: [String] = ["LastFMTagConnection"]

                  public static var selections: [GraphQLSelection] {
                    return [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("nodes", type: .list(.object(Node.selections))),
                    ]
                  }

                  public private(set) var resultMap: ResultMap

                  public init(unsafeResultMap: ResultMap) {
                    self.resultMap = unsafeResultMap
                  }

                  public init(nodes: [Node?]? = nil) {
                    self.init(unsafeResultMap: ["__typename": "LastFMTagConnection", "nodes": nodes.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }])
                  }

                  public var __typename: String {
                    get {
                      return resultMap["__typename"]! as! String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "__typename")
                    }
                  }

                  /// A list of nodes in the connection (without going through the `edges` field).
                  public var nodes: [Node?]? {
                    get {
                      return (resultMap["nodes"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Node?] in value.map { (value: ResultMap?) -> Node? in value.flatMap { (value: ResultMap) -> Node in Node(unsafeResultMap: value) } } }
                    }
                    set {
                      resultMap.updateValue(newValue.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }, forKey: "nodes")
                    }
                  }

                  public struct Node: GraphQLSelectionSet {
                    public static let possibleTypes: [String] = ["LastFMTag"]

                    public static var selections: [GraphQLSelection] {
                      return [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("name", type: .nonNull(.scalar(String.self))),
                      ]
                    }

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                      self.resultMap = unsafeResultMap
                    }

                    public init(name: String) {
                      self.init(unsafeResultMap: ["__typename": "LastFMTag", "name": name])
                    }

                    public var __typename: String {
                      get {
                        return resultMap["__typename"]! as! String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "__typename")
                      }
                    }

                    /// The tag name.
                    public var name: String {
                      get {
                        return resultMap["name"]! as! String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "name")
                      }
                    }
                  }
                }

                public struct TopTrack: GraphQLSelectionSet {
                  public static let possibleTypes: [String] = ["LastFMTrackConnection"]

                  public static var selections: [GraphQLSelection] {
                    return [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("nodes", type: .list(.object(Node.selections))),
                    ]
                  }

                  public private(set) var resultMap: ResultMap

                  public init(unsafeResultMap: ResultMap) {
                    self.resultMap = unsafeResultMap
                  }

                  public init(nodes: [Node?]? = nil) {
                    self.init(unsafeResultMap: ["__typename": "LastFMTrackConnection", "nodes": nodes.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }])
                  }

                  public var __typename: String {
                    get {
                      return resultMap["__typename"]! as! String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "__typename")
                    }
                  }

                  /// A list of nodes in the connection (without going through the `edges` field).
                  public var nodes: [Node?]? {
                    get {
                      return (resultMap["nodes"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Node?] in value.map { (value: ResultMap?) -> Node? in value.flatMap { (value: ResultMap) -> Node in Node(unsafeResultMap: value) } } }
                    }
                    set {
                      resultMap.updateValue(newValue.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }, forKey: "nodes")
                    }
                  }

                  public struct Node: GraphQLSelectionSet {
                    public static let possibleTypes: [String] = ["LastFMTrack"]

                    public static var selections: [GraphQLSelection] {
                      return [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("title", type: .scalar(String.self)),
                      ]
                    }

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                      self.resultMap = unsafeResultMap
                    }

                    public init(title: String? = nil) {
                      self.init(unsafeResultMap: ["__typename": "LastFMTrack", "title": title])
                    }

                    public var __typename: String {
                      get {
                        return resultMap["__typename"]! as! String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "__typename")
                      }
                    }

                    /// The title of the track according to [Last.fm](https://www.last.fm/).
                    public var title: String? {
                      get {
                        return resultMap["title"] as? String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "title")
                      }
                    }
                  }
                }
              }
            }

            public struct PageInfo: GraphQLSelectionSet {
              public static let possibleTypes: [String] = ["PageInfo"]

              public static var selections: [GraphQLSelection] {
                return [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("endCursor", type: .scalar(String.self)),
                  GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                ]
              }

              public private(set) var resultMap: ResultMap

              public init(unsafeResultMap: ResultMap) {
                self.resultMap = unsafeResultMap
              }

              public init(endCursor: String? = nil, hasNextPage: Bool) {
                self.init(unsafeResultMap: ["__typename": "PageInfo", "endCursor": endCursor, "hasNextPage": hasNextPage])
              }

              public var __typename: String {
                get {
                  return resultMap["__typename"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "__typename")
                }
              }

              /// When paginating forwards, the cursor to continue.
              public var endCursor: String? {
                get {
                  return resultMap["endCursor"] as? String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "endCursor")
                }
              }

              /// When paginating forwards, are there more items?
              public var hasNextPage: Bool {
                get {
                  return resultMap["hasNextPage"]! as! Bool
                }
                set {
                  resultMap.updateValue(newValue, forKey: "hasNextPage")
                }
              }
            }
          }
        }
      }
    }
  }

  public final class TrendingArtistsListTracksLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      query TrendingArtistsListTracksLastFMTrackConnectionTrendingTrackCellLastFMTrack($country: String, $first: Int, $after: String, $size: LastFMImageSize) {
        lastFM {
          __typename
          chart {
            __typename
            topTracks(after: $after, country: $country, first: $first) {
              __typename
              edges {
                __typename
                node {
                  __typename
                  album {
                    __typename
                    image(size: $size)
                    mbid
                  }
                  artist {
                    __typename
                    name
                  }
                  title
                }
              }
              pageInfo {
                __typename
                endCursor
                hasNextPage
              }
            }
          }
        }
      }
      """

    public let operationName: String = "TrendingArtistsListTracksLastFMTrackConnectionTrendingTrackCellLastFMTrack"

    public var country: String?
    public var first: Int?
    public var after: String?
    public var size: LastFMImageSize?

    public init(country: String? = nil, first: Int? = nil, after: String? = nil, size: LastFMImageSize? = nil) {
      self.country = country
      self.first = first
      self.after = after
      self.size = size
    }

    public var variables: GraphQLMap? {
      return ["country": country, "first": first, "after": after, "size": size]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Query"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("lastFM", type: .object(LastFm.selections)),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(lastFm: LastFm? = nil) {
        self.init(unsafeResultMap: ["__typename": "Query", "lastFM": lastFm.flatMap { (value: LastFm) -> ResultMap in value.resultMap }])
      }

      /// A query for data on [Last.fm](https://www.last.fm/) that is not connected
      /// to any particular MusicBrainz entity. This field is provided by the
      /// Last.fm extension.
      public var lastFm: LastFm? {
        get {
          return (resultMap["lastFM"] as? ResultMap).flatMap { LastFm(unsafeResultMap: $0) }
        }
        set {
          resultMap.updateValue(newValue?.resultMap, forKey: "lastFM")
        }
      }

      public struct LastFm: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["LastFMQuery"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("chart", type: .nonNull(.object(Chart.selections))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(chart: Chart) {
          self.init(unsafeResultMap: ["__typename": "LastFMQuery", "chart": chart.resultMap])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        /// A query for chart data.
        public var chart: Chart {
          get {
            return Chart(unsafeResultMap: resultMap["chart"]! as! ResultMap)
          }
          set {
            resultMap.updateValue(newValue.resultMap, forKey: "chart")
          }
        }

        public struct Chart: GraphQLSelectionSet {
          public static let possibleTypes: [String] = ["LastFMChartQuery"]

          public static var selections: [GraphQLSelection] {
            return [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("topTracks", arguments: ["after": GraphQLVariable("after"), "country": GraphQLVariable("country"), "first": GraphQLVariable("first")], type: .object(TopTrack.selections)),
            ]
          }

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(topTracks: TopTrack? = nil) {
            self.init(unsafeResultMap: ["__typename": "LastFMChartQuery", "topTracks": topTracks.flatMap { (value: TopTrack) -> ResultMap in value.resultMap }])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          /// The most popular tracks, ordered by popularity. If a country code is
          /// given, retrieve the most popular tracks in that country.
          public var topTracks: TopTrack? {
            get {
              return (resultMap["topTracks"] as? ResultMap).flatMap { TopTrack(unsafeResultMap: $0) }
            }
            set {
              resultMap.updateValue(newValue?.resultMap, forKey: "topTracks")
            }
          }

          public struct TopTrack: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["LastFMTrackConnection"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("edges", type: .list(.object(Edge.selections))),
                GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(edges: [Edge?]? = nil, pageInfo: PageInfo) {
              self.init(unsafeResultMap: ["__typename": "LastFMTrackConnection", "edges": edges.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, "pageInfo": pageInfo.resultMap])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            /// A list of edges.
            public var edges: [Edge?]? {
              get {
                return (resultMap["edges"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Edge?] in value.map { (value: ResultMap?) -> Edge? in value.flatMap { (value: ResultMap) -> Edge in Edge(unsafeResultMap: value) } } }
              }
              set {
                resultMap.updateValue(newValue.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, forKey: "edges")
              }
            }

            /// Information to aid in pagination.
            public var pageInfo: PageInfo {
              get {
                return PageInfo(unsafeResultMap: resultMap["pageInfo"]! as! ResultMap)
              }
              set {
                resultMap.updateValue(newValue.resultMap, forKey: "pageInfo")
              }
            }

            public struct Edge: GraphQLSelectionSet {
              public static let possibleTypes: [String] = ["LastFMTrackEdge"]

              public static var selections: [GraphQLSelection] {
                return [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("node", type: .object(Node.selections)),
                ]
              }

              public private(set) var resultMap: ResultMap

              public init(unsafeResultMap: ResultMap) {
                self.resultMap = unsafeResultMap
              }

              public init(node: Node? = nil) {
                self.init(unsafeResultMap: ["__typename": "LastFMTrackEdge", "node": node.flatMap { (value: Node) -> ResultMap in value.resultMap }])
              }

              public var __typename: String {
                get {
                  return resultMap["__typename"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "__typename")
                }
              }

              /// The item at the end of the edge.
              public var node: Node? {
                get {
                  return (resultMap["node"] as? ResultMap).flatMap { Node(unsafeResultMap: $0) }
                }
                set {
                  resultMap.updateValue(newValue?.resultMap, forKey: "node")
                }
              }

              public struct Node: GraphQLSelectionSet {
                public static let possibleTypes: [String] = ["LastFMTrack"]

                public static var selections: [GraphQLSelection] {
                  return [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("album", type: .object(Album.selections)),
                    GraphQLField("artist", type: .object(Artist.selections)),
                    GraphQLField("title", type: .scalar(String.self)),
                  ]
                }

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                  self.resultMap = unsafeResultMap
                }

                public init(album: Album? = nil, artist: Artist? = nil, title: String? = nil) {
                  self.init(unsafeResultMap: ["__typename": "LastFMTrack", "album": album.flatMap { (value: Album) -> ResultMap in value.resultMap }, "artist": artist.flatMap { (value: Artist) -> ResultMap in value.resultMap }, "title": title])
                }

                public var __typename: String {
                  get {
                    return resultMap["__typename"]! as! String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "__typename")
                  }
                }

                /// The album on which the track appears. This returns the Last.fm album info,
                /// not the MusicBrainz release.
                public var album: Album? {
                  get {
                    return (resultMap["album"] as? ResultMap).flatMap { Album(unsafeResultMap: $0) }
                  }
                  set {
                    resultMap.updateValue(newValue?.resultMap, forKey: "album")
                  }
                }

                /// The artist who released the track. This returns the Last.fm artist info,
                /// not the MusicBrainz artist.
                public var artist: Artist? {
                  get {
                    return (resultMap["artist"] as? ResultMap).flatMap { Artist(unsafeResultMap: $0) }
                  }
                  set {
                    resultMap.updateValue(newValue?.resultMap, forKey: "artist")
                  }
                }

                /// The title of the track according to [Last.fm](https://www.last.fm/).
                public var title: String? {
                  get {
                    return resultMap["title"] as? String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "title")
                  }
                }

                public struct Album: GraphQLSelectionSet {
                  public static let possibleTypes: [String] = ["LastFMAlbum"]

                  public static var selections: [GraphQLSelection] {
                    return [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("image", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                      GraphQLField("mbid", type: .scalar(String.self)),
                    ]
                  }

                  public private(set) var resultMap: ResultMap

                  public init(unsafeResultMap: ResultMap) {
                    self.resultMap = unsafeResultMap
                  }

                  public init(image: String? = nil, mbid: String? = nil) {
                    self.init(unsafeResultMap: ["__typename": "LastFMAlbum", "image": image, "mbid": mbid])
                  }

                  public var __typename: String {
                    get {
                      return resultMap["__typename"]! as! String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "__typename")
                    }
                  }

                  /// An image of the cover artwork of the release.
                  public var image: String? {
                    get {
                      return resultMap["image"] as? String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "image")
                    }
                  }

                  /// The MBID of the corresponding MusicBrainz release.
                  public var mbid: String? {
                    get {
                      return resultMap["mbid"] as? String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "mbid")
                    }
                  }
                }

                public struct Artist: GraphQLSelectionSet {
                  public static let possibleTypes: [String] = ["LastFMArtist"]

                  public static var selections: [GraphQLSelection] {
                    return [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("name", type: .scalar(String.self)),
                    ]
                  }

                  public private(set) var resultMap: ResultMap

                  public init(unsafeResultMap: ResultMap) {
                    self.resultMap = unsafeResultMap
                  }

                  public init(name: String? = nil) {
                    self.init(unsafeResultMap: ["__typename": "LastFMArtist", "name": name])
                  }

                  public var __typename: String {
                    get {
                      return resultMap["__typename"]! as! String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "__typename")
                    }
                  }

                  /// The name of the artist according to [Last.fm](https://www.last.fm/).
                  public var name: String? {
                    get {
                      return resultMap["name"] as? String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "name")
                    }
                  }
                }
              }
            }

            public struct PageInfo: GraphQLSelectionSet {
              public static let possibleTypes: [String] = ["PageInfo"]

              public static var selections: [GraphQLSelection] {
                return [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("endCursor", type: .scalar(String.self)),
                  GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                ]
              }

              public private(set) var resultMap: ResultMap

              public init(unsafeResultMap: ResultMap) {
                self.resultMap = unsafeResultMap
              }

              public init(endCursor: String? = nil, hasNextPage: Bool) {
                self.init(unsafeResultMap: ["__typename": "PageInfo", "endCursor": endCursor, "hasNextPage": hasNextPage])
              }

              public var __typename: String {
                get {
                  return resultMap["__typename"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "__typename")
                }
              }

              /// When paginating forwards, the cursor to continue.
              public var endCursor: String? {
                get {
                  return resultMap["endCursor"] as? String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "endCursor")
                }
              }

              /// When paginating forwards, are there more items?
              public var hasNextPage: Bool {
                get {
                  return resultMap["hasNextPage"]! as! Bool
                }
                set {
                  resultMap.updateValue(newValue, forKey: "hasNextPage")
                }
              }
            }
          }
        }
      }
    }
  }

  public final class ArtistDetailViewTopSongsLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      query ArtistDetailViewTopSongsLastFMTrackConnectionTrendingTrackCellLastFMTrack($mbid: MBID!, $first: Int, $after: String, $URLString_size: LastFMImageSize) {
        lookup {
          __typename
          artist(mbid: $mbid) {
            __typename
            lastFM {
              __typename
              topTracks(after: $after, first: $first) {
                __typename
                edges {
                  __typename
                  node {
                    __typename
                    album {
                      __typename
                      image(size: $URLString_size)
                      mbid
                    }
                    artist {
                      __typename
                      name
                    }
                    title
                  }
                }
                pageInfo {
                  __typename
                  endCursor
                  hasNextPage
                }
              }
            }
          }
        }
      }
      """

    public let operationName: String = "ArtistDetailViewTopSongsLastFMTrackConnectionTrendingTrackCellLastFMTrack"

    public var mbid: String
    public var first: Int?
    public var after: String?
    public var URLString_size: LastFMImageSize?

    public init(mbid: String, first: Int? = nil, after: String? = nil, URLString_size: LastFMImageSize? = nil) {
      self.mbid = mbid
      self.first = first
      self.after = after
      self.URLString_size = URLString_size
    }

    public var variables: GraphQLMap? {
      return ["mbid": mbid, "first": first, "after": after, "URLString_size": URLString_size]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Query"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("lookup", type: .object(Lookup.selections)),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(lookup: Lookup? = nil) {
        self.init(unsafeResultMap: ["__typename": "Query", "lookup": lookup.flatMap { (value: Lookup) -> ResultMap in value.resultMap }])
      }

      /// Perform a lookup of a MusicBrainz entity by its MBID.
      public var lookup: Lookup? {
        get {
          return (resultMap["lookup"] as? ResultMap).flatMap { Lookup(unsafeResultMap: $0) }
        }
        set {
          resultMap.updateValue(newValue?.resultMap, forKey: "lookup")
        }
      }

      public struct Lookup: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["LookupQuery"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("artist", arguments: ["mbid": GraphQLVariable("mbid")], type: .object(Artist.selections)),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(artist: Artist? = nil) {
          self.init(unsafeResultMap: ["__typename": "LookupQuery", "artist": artist.flatMap { (value: Artist) -> ResultMap in value.resultMap }])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        /// Look up a specific artist by its MBID.
        public var artist: Artist? {
          get {
            return (resultMap["artist"] as? ResultMap).flatMap { Artist(unsafeResultMap: $0) }
          }
          set {
            resultMap.updateValue(newValue?.resultMap, forKey: "artist")
          }
        }

        public struct Artist: GraphQLSelectionSet {
          public static let possibleTypes: [String] = ["Artist"]

          public static var selections: [GraphQLSelection] {
            return [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("lastFM", type: .object(LastFm.selections)),
            ]
          }

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(lastFm: LastFm? = nil) {
            self.init(unsafeResultMap: ["__typename": "Artist", "lastFM": lastFm.flatMap { (value: LastFm) -> ResultMap in value.resultMap }])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          /// Data about the artist from [Last.fm](https://www.last.fm/), a good source
          /// for measuring popularity via listener and play counts. This field is
          /// provided by the Last.fm extension.
          public var lastFm: LastFm? {
            get {
              return (resultMap["lastFM"] as? ResultMap).flatMap { LastFm(unsafeResultMap: $0) }
            }
            set {
              resultMap.updateValue(newValue?.resultMap, forKey: "lastFM")
            }
          }

          public struct LastFm: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["LastFMArtist"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("topTracks", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first")], type: .object(TopTrack.selections)),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(topTracks: TopTrack? = nil) {
              self.init(unsafeResultMap: ["__typename": "LastFMArtist", "topTracks": topTracks.flatMap { (value: TopTrack) -> ResultMap in value.resultMap }])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            /// A list of the artist’s most popular tracks.
            public var topTracks: TopTrack? {
              get {
                return (resultMap["topTracks"] as? ResultMap).flatMap { TopTrack(unsafeResultMap: $0) }
              }
              set {
                resultMap.updateValue(newValue?.resultMap, forKey: "topTracks")
              }
            }

            public struct TopTrack: GraphQLSelectionSet {
              public static let possibleTypes: [String] = ["LastFMTrackConnection"]

              public static var selections: [GraphQLSelection] {
                return [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("edges", type: .list(.object(Edge.selections))),
                  GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
                ]
              }

              public private(set) var resultMap: ResultMap

              public init(unsafeResultMap: ResultMap) {
                self.resultMap = unsafeResultMap
              }

              public init(edges: [Edge?]? = nil, pageInfo: PageInfo) {
                self.init(unsafeResultMap: ["__typename": "LastFMTrackConnection", "edges": edges.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, "pageInfo": pageInfo.resultMap])
              }

              public var __typename: String {
                get {
                  return resultMap["__typename"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "__typename")
                }
              }

              /// A list of edges.
              public var edges: [Edge?]? {
                get {
                  return (resultMap["edges"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Edge?] in value.map { (value: ResultMap?) -> Edge? in value.flatMap { (value: ResultMap) -> Edge in Edge(unsafeResultMap: value) } } }
                }
                set {
                  resultMap.updateValue(newValue.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, forKey: "edges")
                }
              }

              /// Information to aid in pagination.
              public var pageInfo: PageInfo {
                get {
                  return PageInfo(unsafeResultMap: resultMap["pageInfo"]! as! ResultMap)
                }
                set {
                  resultMap.updateValue(newValue.resultMap, forKey: "pageInfo")
                }
              }

              public struct Edge: GraphQLSelectionSet {
                public static let possibleTypes: [String] = ["LastFMTrackEdge"]

                public static var selections: [GraphQLSelection] {
                  return [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("node", type: .object(Node.selections)),
                  ]
                }

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                  self.resultMap = unsafeResultMap
                }

                public init(node: Node? = nil) {
                  self.init(unsafeResultMap: ["__typename": "LastFMTrackEdge", "node": node.flatMap { (value: Node) -> ResultMap in value.resultMap }])
                }

                public var __typename: String {
                  get {
                    return resultMap["__typename"]! as! String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "__typename")
                  }
                }

                /// The item at the end of the edge.
                public var node: Node? {
                  get {
                    return (resultMap["node"] as? ResultMap).flatMap { Node(unsafeResultMap: $0) }
                  }
                  set {
                    resultMap.updateValue(newValue?.resultMap, forKey: "node")
                  }
                }

                public struct Node: GraphQLSelectionSet {
                  public static let possibleTypes: [String] = ["LastFMTrack"]

                  public static var selections: [GraphQLSelection] {
                    return [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("album", type: .object(Album.selections)),
                      GraphQLField("artist", type: .object(Artist.selections)),
                      GraphQLField("title", type: .scalar(String.self)),
                    ]
                  }

                  public private(set) var resultMap: ResultMap

                  public init(unsafeResultMap: ResultMap) {
                    self.resultMap = unsafeResultMap
                  }

                  public init(album: Album? = nil, artist: Artist? = nil, title: String? = nil) {
                    self.init(unsafeResultMap: ["__typename": "LastFMTrack", "album": album.flatMap { (value: Album) -> ResultMap in value.resultMap }, "artist": artist.flatMap { (value: Artist) -> ResultMap in value.resultMap }, "title": title])
                  }

                  public var __typename: String {
                    get {
                      return resultMap["__typename"]! as! String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "__typename")
                    }
                  }

                  /// The album on which the track appears. This returns the Last.fm album info,
                  /// not the MusicBrainz release.
                  public var album: Album? {
                    get {
                      return (resultMap["album"] as? ResultMap).flatMap { Album(unsafeResultMap: $0) }
                    }
                    set {
                      resultMap.updateValue(newValue?.resultMap, forKey: "album")
                    }
                  }

                  /// The artist who released the track. This returns the Last.fm artist info,
                  /// not the MusicBrainz artist.
                  public var artist: Artist? {
                    get {
                      return (resultMap["artist"] as? ResultMap).flatMap { Artist(unsafeResultMap: $0) }
                    }
                    set {
                      resultMap.updateValue(newValue?.resultMap, forKey: "artist")
                    }
                  }

                  /// The title of the track according to [Last.fm](https://www.last.fm/).
                  public var title: String? {
                    get {
                      return resultMap["title"] as? String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "title")
                    }
                  }

                  public struct Album: GraphQLSelectionSet {
                    public static let possibleTypes: [String] = ["LastFMAlbum"]

                    public static var selections: [GraphQLSelection] {
                      return [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("image", arguments: ["size": GraphQLVariable("URLString_size")], type: .scalar(String.self)),
                        GraphQLField("mbid", type: .scalar(String.self)),
                      ]
                    }

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                      self.resultMap = unsafeResultMap
                    }

                    public init(image: String? = nil, mbid: String? = nil) {
                      self.init(unsafeResultMap: ["__typename": "LastFMAlbum", "image": image, "mbid": mbid])
                    }

                    public var __typename: String {
                      get {
                        return resultMap["__typename"]! as! String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "__typename")
                      }
                    }

                    /// An image of the cover artwork of the release.
                    public var image: String? {
                      get {
                        return resultMap["image"] as? String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "image")
                      }
                    }

                    /// The MBID of the corresponding MusicBrainz release.
                    public var mbid: String? {
                      get {
                        return resultMap["mbid"] as? String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "mbid")
                      }
                    }
                  }

                  public struct Artist: GraphQLSelectionSet {
                    public static let possibleTypes: [String] = ["LastFMArtist"]

                    public static var selections: [GraphQLSelection] {
                      return [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("name", type: .scalar(String.self)),
                      ]
                    }

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                      self.resultMap = unsafeResultMap
                    }

                    public init(name: String? = nil) {
                      self.init(unsafeResultMap: ["__typename": "LastFMArtist", "name": name])
                    }

                    public var __typename: String {
                      get {
                        return resultMap["__typename"]! as! String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "__typename")
                      }
                    }

                    /// The name of the artist according to [Last.fm](https://www.last.fm/).
                    public var name: String? {
                      get {
                        return resultMap["name"] as? String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "name")
                      }
                    }
                  }
                }
              }

              public struct PageInfo: GraphQLSelectionSet {
                public static let possibleTypes: [String] = ["PageInfo"]

                public static var selections: [GraphQLSelection] {
                  return [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("endCursor", type: .scalar(String.self)),
                    GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                  ]
                }

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                  self.resultMap = unsafeResultMap
                }

                public init(endCursor: String? = nil, hasNextPage: Bool) {
                  self.init(unsafeResultMap: ["__typename": "PageInfo", "endCursor": endCursor, "hasNextPage": hasNextPage])
                }

                public var __typename: String {
                  get {
                    return resultMap["__typename"]! as! String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "__typename")
                  }
                }

                /// When paginating forwards, the cursor to continue.
                public var endCursor: String? {
                  get {
                    return resultMap["endCursor"] as? String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "endCursor")
                  }
                }

                /// When paginating forwards, are there more items?
                public var hasNextPage: Bool {
                  get {
                    return resultMap["hasNextPage"]! as! Bool
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "hasNextPage")
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  public final class ArtistDetailViewAlbumsReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      query ArtistDetailViewAlbumsReleaseGroupConnectionArtistAlbumCellReleaseGroup($mbid: MBID!, $type: [ReleaseGroupType], $after: String, $first: Int, $size: TheAudioDBImageSize, $status: [ReleaseStatus], $ReleaseConnection_first: Int) {
        lookup {
          __typename
          artist(mbid: $mbid) {
            __typename
            releaseGroups(after: $after, first: $first, type: $type) {
              __typename
              edges {
                __typename
                node {
                  __typename
                  releases(after: $after, first: $ReleaseConnection_first, status: $status, type: $type) {
                    __typename
                    nodes {
                      __typename
                      mbid
                    }
                  }
                  theAudioDB {
                    __typename
                    frontImage(size: $size)
                  }
                  title
                }
              }
              pageInfo {
                __typename
                endCursor
                hasNextPage
              }
            }
          }
        }
      }
      """

    public let operationName: String = "ArtistDetailViewAlbumsReleaseGroupConnectionArtistAlbumCellReleaseGroup"

    public var mbid: String
    public var type: [ReleaseGroupType?]?
    public var after: String?
    public var first: Int?
    public var size: TheAudioDBImageSize?
    public var status: [ReleaseStatus?]?
    public var ReleaseConnection_first: Int?

    public init(mbid: String, type: [ReleaseGroupType?]? = nil, after: String? = nil, first: Int? = nil, size: TheAudioDBImageSize? = nil, status: [ReleaseStatus?]? = nil, ReleaseConnection_first: Int? = nil) {
      self.mbid = mbid
      self.type = type
      self.after = after
      self.first = first
      self.size = size
      self.status = status
      self.ReleaseConnection_first = ReleaseConnection_first
    }

    public var variables: GraphQLMap? {
      return ["mbid": mbid, "type": type, "after": after, "first": first, "size": size, "status": status, "ReleaseConnection_first": ReleaseConnection_first]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Query"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("lookup", type: .object(Lookup.selections)),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(lookup: Lookup? = nil) {
        self.init(unsafeResultMap: ["__typename": "Query", "lookup": lookup.flatMap { (value: Lookup) -> ResultMap in value.resultMap }])
      }

      /// Perform a lookup of a MusicBrainz entity by its MBID.
      public var lookup: Lookup? {
        get {
          return (resultMap["lookup"] as? ResultMap).flatMap { Lookup(unsafeResultMap: $0) }
        }
        set {
          resultMap.updateValue(newValue?.resultMap, forKey: "lookup")
        }
      }

      public struct Lookup: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["LookupQuery"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("artist", arguments: ["mbid": GraphQLVariable("mbid")], type: .object(Artist.selections)),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(artist: Artist? = nil) {
          self.init(unsafeResultMap: ["__typename": "LookupQuery", "artist": artist.flatMap { (value: Artist) -> ResultMap in value.resultMap }])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        /// Look up a specific artist by its MBID.
        public var artist: Artist? {
          get {
            return (resultMap["artist"] as? ResultMap).flatMap { Artist(unsafeResultMap: $0) }
          }
          set {
            resultMap.updateValue(newValue?.resultMap, forKey: "artist")
          }
        }

        public struct Artist: GraphQLSelectionSet {
          public static let possibleTypes: [String] = ["Artist"]

          public static var selections: [GraphQLSelection] {
            return [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("releaseGroups", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first"), "type": GraphQLVariable("type")], type: .object(ReleaseGroup.selections)),
            ]
          }

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(releaseGroups: ReleaseGroup? = nil) {
            self.init(unsafeResultMap: ["__typename": "Artist", "releaseGroups": releaseGroups.flatMap { (value: ReleaseGroup) -> ResultMap in value.resultMap }])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          /// A list of release groups linked to this entity.
          public var releaseGroups: ReleaseGroup? {
            get {
              return (resultMap["releaseGroups"] as? ResultMap).flatMap { ReleaseGroup(unsafeResultMap: $0) }
            }
            set {
              resultMap.updateValue(newValue?.resultMap, forKey: "releaseGroups")
            }
          }

          public struct ReleaseGroup: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["ReleaseGroupConnection"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("edges", type: .list(.object(Edge.selections))),
                GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(edges: [Edge?]? = nil, pageInfo: PageInfo) {
              self.init(unsafeResultMap: ["__typename": "ReleaseGroupConnection", "edges": edges.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, "pageInfo": pageInfo.resultMap])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            /// A list of edges.
            public var edges: [Edge?]? {
              get {
                return (resultMap["edges"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Edge?] in value.map { (value: ResultMap?) -> Edge? in value.flatMap { (value: ResultMap) -> Edge in Edge(unsafeResultMap: value) } } }
              }
              set {
                resultMap.updateValue(newValue.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, forKey: "edges")
              }
            }

            /// Information to aid in pagination.
            public var pageInfo: PageInfo {
              get {
                return PageInfo(unsafeResultMap: resultMap["pageInfo"]! as! ResultMap)
              }
              set {
                resultMap.updateValue(newValue.resultMap, forKey: "pageInfo")
              }
            }

            public struct Edge: GraphQLSelectionSet {
              public static let possibleTypes: [String] = ["ReleaseGroupEdge"]

              public static var selections: [GraphQLSelection] {
                return [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("node", type: .object(Node.selections)),
                ]
              }

              public private(set) var resultMap: ResultMap

              public init(unsafeResultMap: ResultMap) {
                self.resultMap = unsafeResultMap
              }

              public init(node: Node? = nil) {
                self.init(unsafeResultMap: ["__typename": "ReleaseGroupEdge", "node": node.flatMap { (value: Node) -> ResultMap in value.resultMap }])
              }

              public var __typename: String {
                get {
                  return resultMap["__typename"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "__typename")
                }
              }

              /// The item at the end of the edge
              public var node: Node? {
                get {
                  return (resultMap["node"] as? ResultMap).flatMap { Node(unsafeResultMap: $0) }
                }
                set {
                  resultMap.updateValue(newValue?.resultMap, forKey: "node")
                }
              }

              public struct Node: GraphQLSelectionSet {
                public static let possibleTypes: [String] = ["ReleaseGroup"]

                public static var selections: [GraphQLSelection] {
                  return [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("releases", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("ReleaseConnection_first"), "status": GraphQLVariable("status"), "type": GraphQLVariable("type")], type: .object(Release.selections)),
                    GraphQLField("theAudioDB", type: .object(TheAudioDb.selections)),
                    GraphQLField("title", type: .scalar(String.self)),
                  ]
                }

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                  self.resultMap = unsafeResultMap
                }

                public init(releases: Release? = nil, theAudioDb: TheAudioDb? = nil, title: String? = nil) {
                  self.init(unsafeResultMap: ["__typename": "ReleaseGroup", "releases": releases.flatMap { (value: Release) -> ResultMap in value.resultMap }, "theAudioDB": theAudioDb.flatMap { (value: TheAudioDb) -> ResultMap in value.resultMap }, "title": title])
                }

                public var __typename: String {
                  get {
                    return resultMap["__typename"]! as! String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "__typename")
                  }
                }

                /// A list of releases linked to this entity.
                public var releases: Release? {
                  get {
                    return (resultMap["releases"] as? ResultMap).flatMap { Release(unsafeResultMap: $0) }
                  }
                  set {
                    resultMap.updateValue(newValue?.resultMap, forKey: "releases")
                  }
                }

                /// Data about the release group from [TheAudioDB](http://www.theaudiodb.com/),
                /// a good source of descriptive information, reviews, and images.
                /// This field is provided by TheAudioDB extension.
                public var theAudioDb: TheAudioDb? {
                  get {
                    return (resultMap["theAudioDB"] as? ResultMap).flatMap { TheAudioDb(unsafeResultMap: $0) }
                  }
                  set {
                    resultMap.updateValue(newValue?.resultMap, forKey: "theAudioDB")
                  }
                }

                /// The official title of the entity.
                public var title: String? {
                  get {
                    return resultMap["title"] as? String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "title")
                  }
                }

                public struct Release: GraphQLSelectionSet {
                  public static let possibleTypes: [String] = ["ReleaseConnection"]

                  public static var selections: [GraphQLSelection] {
                    return [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("nodes", type: .list(.object(Node.selections))),
                    ]
                  }

                  public private(set) var resultMap: ResultMap

                  public init(unsafeResultMap: ResultMap) {
                    self.resultMap = unsafeResultMap
                  }

                  public init(nodes: [Node?]? = nil) {
                    self.init(unsafeResultMap: ["__typename": "ReleaseConnection", "nodes": nodes.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }])
                  }

                  public var __typename: String {
                    get {
                      return resultMap["__typename"]! as! String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "__typename")
                    }
                  }

                  /// A list of nodes in the connection (without going through the
                  /// `edges` field).
                  public var nodes: [Node?]? {
                    get {
                      return (resultMap["nodes"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Node?] in value.map { (value: ResultMap?) -> Node? in value.flatMap { (value: ResultMap) -> Node in Node(unsafeResultMap: value) } } }
                    }
                    set {
                      resultMap.updateValue(newValue.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }, forKey: "nodes")
                    }
                  }

                  public struct Node: GraphQLSelectionSet {
                    public static let possibleTypes: [String] = ["Release"]

                    public static var selections: [GraphQLSelection] {
                      return [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("mbid", type: .nonNull(.scalar(String.self))),
                      ]
                    }

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                      self.resultMap = unsafeResultMap
                    }

                    public init(mbid: String) {
                      self.init(unsafeResultMap: ["__typename": "Release", "mbid": mbid])
                    }

                    public var __typename: String {
                      get {
                        return resultMap["__typename"]! as! String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "__typename")
                      }
                    }

                    /// The MBID of the entity.
                    public var mbid: String {
                      get {
                        return resultMap["mbid"]! as! String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "mbid")
                      }
                    }
                  }
                }

                public struct TheAudioDb: GraphQLSelectionSet {
                  public static let possibleTypes: [String] = ["TheAudioDBAlbum"]

                  public static var selections: [GraphQLSelection] {
                    return [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("frontImage", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                    ]
                  }

                  public private(set) var resultMap: ResultMap

                  public init(unsafeResultMap: ResultMap) {
                    self.resultMap = unsafeResultMap
                  }

                  public init(frontImage: String? = nil) {
                    self.init(unsafeResultMap: ["__typename": "TheAudioDBAlbum", "frontImage": frontImage])
                  }

                  public var __typename: String {
                    get {
                      return resultMap["__typename"]! as! String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "__typename")
                    }
                  }

                  /// An image of the front of the album packaging.
                  public var frontImage: String? {
                    get {
                      return resultMap["frontImage"] as? String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "frontImage")
                    }
                  }
                }
              }
            }

            public struct PageInfo: GraphQLSelectionSet {
              public static let possibleTypes: [String] = ["PageInfo"]

              public static var selections: [GraphQLSelection] {
                return [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("endCursor", type: .scalar(String.self)),
                  GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                ]
              }

              public private(set) var resultMap: ResultMap

              public init(unsafeResultMap: ResultMap) {
                self.resultMap = unsafeResultMap
              }

              public init(endCursor: String? = nil, hasNextPage: Bool) {
                self.init(unsafeResultMap: ["__typename": "PageInfo", "endCursor": endCursor, "hasNextPage": hasNextPage])
              }

              public var __typename: String {
                get {
                  return resultMap["__typename"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "__typename")
                }
              }

              /// When paginating forwards, the cursor to continue.
              public var endCursor: String? {
                get {
                  return resultMap["endCursor"] as? String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "endCursor")
                }
              }

              /// When paginating forwards, are there more items?
              public var hasNextPage: Bool {
                get {
                  return resultMap["hasNextPage"]! as! Bool
                }
                set {
                  resultMap.updateValue(newValue, forKey: "hasNextPage")
                }
              }
            }
          }
        }
      }
    }
  }

  public final class ArtistDetailViewSinglesReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      query ArtistDetailViewSinglesReleaseGroupConnectionArtistAlbumCellReleaseGroup($mbid: MBID!, $ReleaseGroupConnection_type: [ReleaseGroupType], $after: String, $first: Int, $size: TheAudioDBImageSize, $type: [ReleaseGroupType], $status: [ReleaseStatus], $ReleaseConnection_first: Int) {
        lookup {
          __typename
          artist(mbid: $mbid) {
            __typename
            releaseGroups1: releaseGroups(after: $after, first: $first, type: $ReleaseGroupConnection_type) {
              __typename
              edges {
                __typename
                node {
                  __typename
                  releases(after: $after, first: $ReleaseConnection_first, status: $status, type: $type) {
                    __typename
                    nodes {
                      __typename
                      mbid
                    }
                  }
                  theAudioDB {
                    __typename
                    frontImage(size: $size)
                  }
                  title
                }
              }
              pageInfo {
                __typename
                endCursor
                hasNextPage
              }
            }
          }
        }
      }
      """

    public let operationName: String = "ArtistDetailViewSinglesReleaseGroupConnectionArtistAlbumCellReleaseGroup"

    public var mbid: String
    public var ReleaseGroupConnection_type: [ReleaseGroupType?]?
    public var after: String?
    public var first: Int?
    public var size: TheAudioDBImageSize?
    public var type: [ReleaseGroupType?]?
    public var status: [ReleaseStatus?]?
    public var ReleaseConnection_first: Int?

    public init(mbid: String, ReleaseGroupConnection_type: [ReleaseGroupType?]? = nil, after: String? = nil, first: Int? = nil, size: TheAudioDBImageSize? = nil, type: [ReleaseGroupType?]? = nil, status: [ReleaseStatus?]? = nil, ReleaseConnection_first: Int? = nil) {
      self.mbid = mbid
      self.ReleaseGroupConnection_type = ReleaseGroupConnection_type
      self.after = after
      self.first = first
      self.size = size
      self.type = type
      self.status = status
      self.ReleaseConnection_first = ReleaseConnection_first
    }

    public var variables: GraphQLMap? {
      return ["mbid": mbid, "ReleaseGroupConnection_type": ReleaseGroupConnection_type, "after": after, "first": first, "size": size, "type": type, "status": status, "ReleaseConnection_first": ReleaseConnection_first]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Query"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("lookup", type: .object(Lookup.selections)),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(lookup: Lookup? = nil) {
        self.init(unsafeResultMap: ["__typename": "Query", "lookup": lookup.flatMap { (value: Lookup) -> ResultMap in value.resultMap }])
      }

      /// Perform a lookup of a MusicBrainz entity by its MBID.
      public var lookup: Lookup? {
        get {
          return (resultMap["lookup"] as? ResultMap).flatMap { Lookup(unsafeResultMap: $0) }
        }
        set {
          resultMap.updateValue(newValue?.resultMap, forKey: "lookup")
        }
      }

      public struct Lookup: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["LookupQuery"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("artist", arguments: ["mbid": GraphQLVariable("mbid")], type: .object(Artist.selections)),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(artist: Artist? = nil) {
          self.init(unsafeResultMap: ["__typename": "LookupQuery", "artist": artist.flatMap { (value: Artist) -> ResultMap in value.resultMap }])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        /// Look up a specific artist by its MBID.
        public var artist: Artist? {
          get {
            return (resultMap["artist"] as? ResultMap).flatMap { Artist(unsafeResultMap: $0) }
          }
          set {
            resultMap.updateValue(newValue?.resultMap, forKey: "artist")
          }
        }

        public struct Artist: GraphQLSelectionSet {
          public static let possibleTypes: [String] = ["Artist"]

          public static var selections: [GraphQLSelection] {
            return [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("releaseGroups", alias: "releaseGroups1", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first"), "type": GraphQLVariable("ReleaseGroupConnection_type")], type: .object(ReleaseGroups1.selections)),
            ]
          }

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(releaseGroups1: ReleaseGroups1? = nil) {
            self.init(unsafeResultMap: ["__typename": "Artist", "releaseGroups1": releaseGroups1.flatMap { (value: ReleaseGroups1) -> ResultMap in value.resultMap }])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          /// A list of release groups linked to this entity.
          public var releaseGroups1: ReleaseGroups1? {
            get {
              return (resultMap["releaseGroups1"] as? ResultMap).flatMap { ReleaseGroups1(unsafeResultMap: $0) }
            }
            set {
              resultMap.updateValue(newValue?.resultMap, forKey: "releaseGroups1")
            }
          }

          public struct ReleaseGroups1: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["ReleaseGroupConnection"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("edges", type: .list(.object(Edge.selections))),
                GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(edges: [Edge?]? = nil, pageInfo: PageInfo) {
              self.init(unsafeResultMap: ["__typename": "ReleaseGroupConnection", "edges": edges.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, "pageInfo": pageInfo.resultMap])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            /// A list of edges.
            public var edges: [Edge?]? {
              get {
                return (resultMap["edges"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Edge?] in value.map { (value: ResultMap?) -> Edge? in value.flatMap { (value: ResultMap) -> Edge in Edge(unsafeResultMap: value) } } }
              }
              set {
                resultMap.updateValue(newValue.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, forKey: "edges")
              }
            }

            /// Information to aid in pagination.
            public var pageInfo: PageInfo {
              get {
                return PageInfo(unsafeResultMap: resultMap["pageInfo"]! as! ResultMap)
              }
              set {
                resultMap.updateValue(newValue.resultMap, forKey: "pageInfo")
              }
            }

            public struct Edge: GraphQLSelectionSet {
              public static let possibleTypes: [String] = ["ReleaseGroupEdge"]

              public static var selections: [GraphQLSelection] {
                return [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("node", type: .object(Node.selections)),
                ]
              }

              public private(set) var resultMap: ResultMap

              public init(unsafeResultMap: ResultMap) {
                self.resultMap = unsafeResultMap
              }

              public init(node: Node? = nil) {
                self.init(unsafeResultMap: ["__typename": "ReleaseGroupEdge", "node": node.flatMap { (value: Node) -> ResultMap in value.resultMap }])
              }

              public var __typename: String {
                get {
                  return resultMap["__typename"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "__typename")
                }
              }

              /// The item at the end of the edge
              public var node: Node? {
                get {
                  return (resultMap["node"] as? ResultMap).flatMap { Node(unsafeResultMap: $0) }
                }
                set {
                  resultMap.updateValue(newValue?.resultMap, forKey: "node")
                }
              }

              public struct Node: GraphQLSelectionSet {
                public static let possibleTypes: [String] = ["ReleaseGroup"]

                public static var selections: [GraphQLSelection] {
                  return [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("releases", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("ReleaseConnection_first"), "status": GraphQLVariable("status"), "type": GraphQLVariable("type")], type: .object(Release.selections)),
                    GraphQLField("theAudioDB", type: .object(TheAudioDb.selections)),
                    GraphQLField("title", type: .scalar(String.self)),
                  ]
                }

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                  self.resultMap = unsafeResultMap
                }

                public init(releases: Release? = nil, theAudioDb: TheAudioDb? = nil, title: String? = nil) {
                  self.init(unsafeResultMap: ["__typename": "ReleaseGroup", "releases": releases.flatMap { (value: Release) -> ResultMap in value.resultMap }, "theAudioDB": theAudioDb.flatMap { (value: TheAudioDb) -> ResultMap in value.resultMap }, "title": title])
                }

                public var __typename: String {
                  get {
                    return resultMap["__typename"]! as! String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "__typename")
                  }
                }

                /// A list of releases linked to this entity.
                public var releases: Release? {
                  get {
                    return (resultMap["releases"] as? ResultMap).flatMap { Release(unsafeResultMap: $0) }
                  }
                  set {
                    resultMap.updateValue(newValue?.resultMap, forKey: "releases")
                  }
                }

                /// Data about the release group from [TheAudioDB](http://www.theaudiodb.com/),
                /// a good source of descriptive information, reviews, and images.
                /// This field is provided by TheAudioDB extension.
                public var theAudioDb: TheAudioDb? {
                  get {
                    return (resultMap["theAudioDB"] as? ResultMap).flatMap { TheAudioDb(unsafeResultMap: $0) }
                  }
                  set {
                    resultMap.updateValue(newValue?.resultMap, forKey: "theAudioDB")
                  }
                }

                /// The official title of the entity.
                public var title: String? {
                  get {
                    return resultMap["title"] as? String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "title")
                  }
                }

                public struct Release: GraphQLSelectionSet {
                  public static let possibleTypes: [String] = ["ReleaseConnection"]

                  public static var selections: [GraphQLSelection] {
                    return [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("nodes", type: .list(.object(Node.selections))),
                    ]
                  }

                  public private(set) var resultMap: ResultMap

                  public init(unsafeResultMap: ResultMap) {
                    self.resultMap = unsafeResultMap
                  }

                  public init(nodes: [Node?]? = nil) {
                    self.init(unsafeResultMap: ["__typename": "ReleaseConnection", "nodes": nodes.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }])
                  }

                  public var __typename: String {
                    get {
                      return resultMap["__typename"]! as! String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "__typename")
                    }
                  }

                  /// A list of nodes in the connection (without going through the
                  /// `edges` field).
                  public var nodes: [Node?]? {
                    get {
                      return (resultMap["nodes"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Node?] in value.map { (value: ResultMap?) -> Node? in value.flatMap { (value: ResultMap) -> Node in Node(unsafeResultMap: value) } } }
                    }
                    set {
                      resultMap.updateValue(newValue.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }, forKey: "nodes")
                    }
                  }

                  public struct Node: GraphQLSelectionSet {
                    public static let possibleTypes: [String] = ["Release"]

                    public static var selections: [GraphQLSelection] {
                      return [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("mbid", type: .nonNull(.scalar(String.self))),
                      ]
                    }

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                      self.resultMap = unsafeResultMap
                    }

                    public init(mbid: String) {
                      self.init(unsafeResultMap: ["__typename": "Release", "mbid": mbid])
                    }

                    public var __typename: String {
                      get {
                        return resultMap["__typename"]! as! String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "__typename")
                      }
                    }

                    /// The MBID of the entity.
                    public var mbid: String {
                      get {
                        return resultMap["mbid"]! as! String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "mbid")
                      }
                    }
                  }
                }

                public struct TheAudioDb: GraphQLSelectionSet {
                  public static let possibleTypes: [String] = ["TheAudioDBAlbum"]

                  public static var selections: [GraphQLSelection] {
                    return [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("frontImage", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                    ]
                  }

                  public private(set) var resultMap: ResultMap

                  public init(unsafeResultMap: ResultMap) {
                    self.resultMap = unsafeResultMap
                  }

                  public init(frontImage: String? = nil) {
                    self.init(unsafeResultMap: ["__typename": "TheAudioDBAlbum", "frontImage": frontImage])
                  }

                  public var __typename: String {
                    get {
                      return resultMap["__typename"]! as! String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "__typename")
                    }
                  }

                  /// An image of the front of the album packaging.
                  public var frontImage: String? {
                    get {
                      return resultMap["frontImage"] as? String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "frontImage")
                    }
                  }
                }
              }
            }

            public struct PageInfo: GraphQLSelectionSet {
              public static let possibleTypes: [String] = ["PageInfo"]

              public static var selections: [GraphQLSelection] {
                return [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("endCursor", type: .scalar(String.self)),
                  GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                ]
              }

              public private(set) var resultMap: ResultMap

              public init(unsafeResultMap: ResultMap) {
                self.resultMap = unsafeResultMap
              }

              public init(endCursor: String? = nil, hasNextPage: Bool) {
                self.init(unsafeResultMap: ["__typename": "PageInfo", "endCursor": endCursor, "hasNextPage": hasNextPage])
              }

              public var __typename: String {
                get {
                  return resultMap["__typename"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "__typename")
                }
              }

              /// When paginating forwards, the cursor to continue.
              public var endCursor: String? {
                get {
                  return resultMap["endCursor"] as? String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "endCursor")
                }
              }

              /// When paginating forwards, are there more items?
              public var hasNextPage: Bool {
                get {
                  return resultMap["hasNextPage"]! as! Bool
                }
                set {
                  resultMap.updateValue(newValue, forKey: "hasNextPage")
                }
              }
            }
          }
        }
      }
    }
  }

  public final class TrendingArtistsListQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      query TrendingArtistsList($country: String, $first: Int, $after: String, $LastFMTagConnection_first: Int, $LastFMAlbumConnection_first: Int, $size: LastFMImageSize, $LastFMTrackConnection_first: Int) {
        lastFM {
          __typename
          chart {
            __typename
            topArtists(after: $after, country: $country, first: $first) {
              __typename
              edges {
                __typename
                node {
                  __typename
                  mbid
                  name
                  topAlbums(after: $after, first: $LastFMAlbumConnection_first) {
                    __typename
                    nodes {
                      __typename
                      image(size: $size)
                    }
                  }
                  topTags(after: $after, first: $LastFMTagConnection_first) {
                    __typename
                    nodes {
                      __typename
                      name
                    }
                  }
                  topTracks(after: $after, first: $LastFMTrackConnection_first) {
                    __typename
                    nodes {
                      __typename
                      title
                    }
                  }
                }
              }
              pageInfo {
                __typename
                endCursor
                hasNextPage
              }
            }
            topTracks(after: $after, country: $country, first: $first) {
              __typename
              edges {
                __typename
                node {
                  __typename
                  album {
                    __typename
                    image(size: $size)
                    mbid
                  }
                  artist {
                    __typename
                    name
                  }
                  title
                }
              }
              pageInfo {
                __typename
                endCursor
                hasNextPage
              }
            }
          }
        }
      }
      """

    public let operationName: String = "TrendingArtistsList"

    public var country: String?
    public var first: Int?
    public var after: String?
    public var LastFMTagConnection_first: Int?
    public var LastFMAlbumConnection_first: Int?
    public var size: LastFMImageSize?
    public var LastFMTrackConnection_first: Int?

    public init(country: String? = nil, first: Int? = nil, after: String? = nil, LastFMTagConnection_first: Int? = nil, LastFMAlbumConnection_first: Int? = nil, size: LastFMImageSize? = nil, LastFMTrackConnection_first: Int? = nil) {
      self.country = country
      self.first = first
      self.after = after
      self.LastFMTagConnection_first = LastFMTagConnection_first
      self.LastFMAlbumConnection_first = LastFMAlbumConnection_first
      self.size = size
      self.LastFMTrackConnection_first = LastFMTrackConnection_first
    }

    public var variables: GraphQLMap? {
      return ["country": country, "first": first, "after": after, "LastFMTagConnection_first": LastFMTagConnection_first, "LastFMAlbumConnection_first": LastFMAlbumConnection_first, "size": size, "LastFMTrackConnection_first": LastFMTrackConnection_first]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Query"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("lastFM", type: .object(LastFm.selections)),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(lastFm: LastFm? = nil) {
        self.init(unsafeResultMap: ["__typename": "Query", "lastFM": lastFm.flatMap { (value: LastFm) -> ResultMap in value.resultMap }])
      }

      /// A query for data on [Last.fm](https://www.last.fm/) that is not connected
      /// to any particular MusicBrainz entity. This field is provided by the
      /// Last.fm extension.
      public var lastFm: LastFm? {
        get {
          return (resultMap["lastFM"] as? ResultMap).flatMap { LastFm(unsafeResultMap: $0) }
        }
        set {
          resultMap.updateValue(newValue?.resultMap, forKey: "lastFM")
        }
      }

      public struct LastFm: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["LastFMQuery"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("chart", type: .nonNull(.object(Chart.selections))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(chart: Chart) {
          self.init(unsafeResultMap: ["__typename": "LastFMQuery", "chart": chart.resultMap])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        /// A query for chart data.
        public var chart: Chart {
          get {
            return Chart(unsafeResultMap: resultMap["chart"]! as! ResultMap)
          }
          set {
            resultMap.updateValue(newValue.resultMap, forKey: "chart")
          }
        }

        public struct Chart: GraphQLSelectionSet {
          public static let possibleTypes: [String] = ["LastFMChartQuery"]

          public static var selections: [GraphQLSelection] {
            return [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("topArtists", arguments: ["after": GraphQLVariable("after"), "country": GraphQLVariable("country"), "first": GraphQLVariable("first")], type: .object(TopArtist.selections)),
              GraphQLField("topTracks", arguments: ["after": GraphQLVariable("after"), "country": GraphQLVariable("country"), "first": GraphQLVariable("first")], type: .object(TopTrack.selections)),
            ]
          }

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(topArtists: TopArtist? = nil, topTracks: TopTrack? = nil) {
            self.init(unsafeResultMap: ["__typename": "LastFMChartQuery", "topArtists": topArtists.flatMap { (value: TopArtist) -> ResultMap in value.resultMap }, "topTracks": topTracks.flatMap { (value: TopTrack) -> ResultMap in value.resultMap }])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          /// The most popular artists, ordered by popularity. If a country code is
          /// given, retrieve the most popular artists in that country.
          public var topArtists: TopArtist? {
            get {
              return (resultMap["topArtists"] as? ResultMap).flatMap { TopArtist(unsafeResultMap: $0) }
            }
            set {
              resultMap.updateValue(newValue?.resultMap, forKey: "topArtists")
            }
          }

          /// The most popular tracks, ordered by popularity. If a country code is
          /// given, retrieve the most popular tracks in that country.
          public var topTracks: TopTrack? {
            get {
              return (resultMap["topTracks"] as? ResultMap).flatMap { TopTrack(unsafeResultMap: $0) }
            }
            set {
              resultMap.updateValue(newValue?.resultMap, forKey: "topTracks")
            }
          }

          public struct TopArtist: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["LastFMArtistConnection"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("edges", type: .list(.object(Edge.selections))),
                GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(edges: [Edge?]? = nil, pageInfo: PageInfo) {
              self.init(unsafeResultMap: ["__typename": "LastFMArtistConnection", "edges": edges.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, "pageInfo": pageInfo.resultMap])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            /// A list of edges.
            public var edges: [Edge?]? {
              get {
                return (resultMap["edges"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Edge?] in value.map { (value: ResultMap?) -> Edge? in value.flatMap { (value: ResultMap) -> Edge in Edge(unsafeResultMap: value) } } }
              }
              set {
                resultMap.updateValue(newValue.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, forKey: "edges")
              }
            }

            /// Information to aid in pagination.
            public var pageInfo: PageInfo {
              get {
                return PageInfo(unsafeResultMap: resultMap["pageInfo"]! as! ResultMap)
              }
              set {
                resultMap.updateValue(newValue.resultMap, forKey: "pageInfo")
              }
            }

            public struct Edge: GraphQLSelectionSet {
              public static let possibleTypes: [String] = ["LastFMArtistEdge"]

              public static var selections: [GraphQLSelection] {
                return [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("node", type: .object(Node.selections)),
                ]
              }

              public private(set) var resultMap: ResultMap

              public init(unsafeResultMap: ResultMap) {
                self.resultMap = unsafeResultMap
              }

              public init(node: Node? = nil) {
                self.init(unsafeResultMap: ["__typename": "LastFMArtistEdge", "node": node.flatMap { (value: Node) -> ResultMap in value.resultMap }])
              }

              public var __typename: String {
                get {
                  return resultMap["__typename"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "__typename")
                }
              }

              /// The item at the end of the edge.
              public var node: Node? {
                get {
                  return (resultMap["node"] as? ResultMap).flatMap { Node(unsafeResultMap: $0) }
                }
                set {
                  resultMap.updateValue(newValue?.resultMap, forKey: "node")
                }
              }

              public struct Node: GraphQLSelectionSet {
                public static let possibleTypes: [String] = ["LastFMArtist"]

                public static var selections: [GraphQLSelection] {
                  return [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("mbid", type: .scalar(String.self)),
                    GraphQLField("name", type: .scalar(String.self)),
                    GraphQLField("topAlbums", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("LastFMAlbumConnection_first")], type: .object(TopAlbum.selections)),
                    GraphQLField("topTags", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("LastFMTagConnection_first")], type: .object(TopTag.selections)),
                    GraphQLField("topTracks", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("LastFMTrackConnection_first")], type: .object(TopTrack.selections)),
                  ]
                }

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                  self.resultMap = unsafeResultMap
                }

                public init(mbid: String? = nil, name: String? = nil, topAlbums: TopAlbum? = nil, topTags: TopTag? = nil, topTracks: TopTrack? = nil) {
                  self.init(unsafeResultMap: ["__typename": "LastFMArtist", "mbid": mbid, "name": name, "topAlbums": topAlbums.flatMap { (value: TopAlbum) -> ResultMap in value.resultMap }, "topTags": topTags.flatMap { (value: TopTag) -> ResultMap in value.resultMap }, "topTracks": topTracks.flatMap { (value: TopTrack) -> ResultMap in value.resultMap }])
                }

                public var __typename: String {
                  get {
                    return resultMap["__typename"]! as! String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "__typename")
                  }
                }

                /// The MBID of the corresponding MusicBrainz artist.
                public var mbid: String? {
                  get {
                    return resultMap["mbid"] as? String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "mbid")
                  }
                }

                /// The name of the artist according to [Last.fm](https://www.last.fm/).
                public var name: String? {
                  get {
                    return resultMap["name"] as? String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "name")
                  }
                }

                /// A list of the artist’s most popular albums.
                public var topAlbums: TopAlbum? {
                  get {
                    return (resultMap["topAlbums"] as? ResultMap).flatMap { TopAlbum(unsafeResultMap: $0) }
                  }
                  set {
                    resultMap.updateValue(newValue?.resultMap, forKey: "topAlbums")
                  }
                }

                /// A list of tags applied to the artist by users, ordered by popularity.
                public var topTags: TopTag? {
                  get {
                    return (resultMap["topTags"] as? ResultMap).flatMap { TopTag(unsafeResultMap: $0) }
                  }
                  set {
                    resultMap.updateValue(newValue?.resultMap, forKey: "topTags")
                  }
                }

                /// A list of the artist’s most popular tracks.
                public var topTracks: TopTrack? {
                  get {
                    return (resultMap["topTracks"] as? ResultMap).flatMap { TopTrack(unsafeResultMap: $0) }
                  }
                  set {
                    resultMap.updateValue(newValue?.resultMap, forKey: "topTracks")
                  }
                }

                public struct TopAlbum: GraphQLSelectionSet {
                  public static let possibleTypes: [String] = ["LastFMAlbumConnection"]

                  public static var selections: [GraphQLSelection] {
                    return [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("nodes", type: .list(.object(Node.selections))),
                    ]
                  }

                  public private(set) var resultMap: ResultMap

                  public init(unsafeResultMap: ResultMap) {
                    self.resultMap = unsafeResultMap
                  }

                  public init(nodes: [Node?]? = nil) {
                    self.init(unsafeResultMap: ["__typename": "LastFMAlbumConnection", "nodes": nodes.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }])
                  }

                  public var __typename: String {
                    get {
                      return resultMap["__typename"]! as! String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "__typename")
                    }
                  }

                  /// A list of nodes in the connection (without going through the `edges` field).
                  public var nodes: [Node?]? {
                    get {
                      return (resultMap["nodes"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Node?] in value.map { (value: ResultMap?) -> Node? in value.flatMap { (value: ResultMap) -> Node in Node(unsafeResultMap: value) } } }
                    }
                    set {
                      resultMap.updateValue(newValue.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }, forKey: "nodes")
                    }
                  }

                  public struct Node: GraphQLSelectionSet {
                    public static let possibleTypes: [String] = ["LastFMAlbum"]

                    public static var selections: [GraphQLSelection] {
                      return [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("image", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                      ]
                    }

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                      self.resultMap = unsafeResultMap
                    }

                    public init(image: String? = nil) {
                      self.init(unsafeResultMap: ["__typename": "LastFMAlbum", "image": image])
                    }

                    public var __typename: String {
                      get {
                        return resultMap["__typename"]! as! String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "__typename")
                      }
                    }

                    /// An image of the cover artwork of the release.
                    public var image: String? {
                      get {
                        return resultMap["image"] as? String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "image")
                      }
                    }
                  }
                }

                public struct TopTag: GraphQLSelectionSet {
                  public static let possibleTypes: [String] = ["LastFMTagConnection"]

                  public static var selections: [GraphQLSelection] {
                    return [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("nodes", type: .list(.object(Node.selections))),
                    ]
                  }

                  public private(set) var resultMap: ResultMap

                  public init(unsafeResultMap: ResultMap) {
                    self.resultMap = unsafeResultMap
                  }

                  public init(nodes: [Node?]? = nil) {
                    self.init(unsafeResultMap: ["__typename": "LastFMTagConnection", "nodes": nodes.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }])
                  }

                  public var __typename: String {
                    get {
                      return resultMap["__typename"]! as! String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "__typename")
                    }
                  }

                  /// A list of nodes in the connection (without going through the `edges` field).
                  public var nodes: [Node?]? {
                    get {
                      return (resultMap["nodes"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Node?] in value.map { (value: ResultMap?) -> Node? in value.flatMap { (value: ResultMap) -> Node in Node(unsafeResultMap: value) } } }
                    }
                    set {
                      resultMap.updateValue(newValue.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }, forKey: "nodes")
                    }
                  }

                  public struct Node: GraphQLSelectionSet {
                    public static let possibleTypes: [String] = ["LastFMTag"]

                    public static var selections: [GraphQLSelection] {
                      return [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("name", type: .nonNull(.scalar(String.self))),
                      ]
                    }

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                      self.resultMap = unsafeResultMap
                    }

                    public init(name: String) {
                      self.init(unsafeResultMap: ["__typename": "LastFMTag", "name": name])
                    }

                    public var __typename: String {
                      get {
                        return resultMap["__typename"]! as! String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "__typename")
                      }
                    }

                    /// The tag name.
                    public var name: String {
                      get {
                        return resultMap["name"]! as! String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "name")
                      }
                    }
                  }
                }

                public struct TopTrack: GraphQLSelectionSet {
                  public static let possibleTypes: [String] = ["LastFMTrackConnection"]

                  public static var selections: [GraphQLSelection] {
                    return [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("nodes", type: .list(.object(Node.selections))),
                    ]
                  }

                  public private(set) var resultMap: ResultMap

                  public init(unsafeResultMap: ResultMap) {
                    self.resultMap = unsafeResultMap
                  }

                  public init(nodes: [Node?]? = nil) {
                    self.init(unsafeResultMap: ["__typename": "LastFMTrackConnection", "nodes": nodes.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }])
                  }

                  public var __typename: String {
                    get {
                      return resultMap["__typename"]! as! String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "__typename")
                    }
                  }

                  /// A list of nodes in the connection (without going through the `edges` field).
                  public var nodes: [Node?]? {
                    get {
                      return (resultMap["nodes"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Node?] in value.map { (value: ResultMap?) -> Node? in value.flatMap { (value: ResultMap) -> Node in Node(unsafeResultMap: value) } } }
                    }
                    set {
                      resultMap.updateValue(newValue.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }, forKey: "nodes")
                    }
                  }

                  public struct Node: GraphQLSelectionSet {
                    public static let possibleTypes: [String] = ["LastFMTrack"]

                    public static var selections: [GraphQLSelection] {
                      return [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("title", type: .scalar(String.self)),
                      ]
                    }

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                      self.resultMap = unsafeResultMap
                    }

                    public init(title: String? = nil) {
                      self.init(unsafeResultMap: ["__typename": "LastFMTrack", "title": title])
                    }

                    public var __typename: String {
                      get {
                        return resultMap["__typename"]! as! String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "__typename")
                      }
                    }

                    /// The title of the track according to [Last.fm](https://www.last.fm/).
                    public var title: String? {
                      get {
                        return resultMap["title"] as? String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "title")
                      }
                    }
                  }
                }
              }
            }

            public struct PageInfo: GraphQLSelectionSet {
              public static let possibleTypes: [String] = ["PageInfo"]

              public static var selections: [GraphQLSelection] {
                return [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("endCursor", type: .scalar(String.self)),
                  GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                ]
              }

              public private(set) var resultMap: ResultMap

              public init(unsafeResultMap: ResultMap) {
                self.resultMap = unsafeResultMap
              }

              public init(endCursor: String? = nil, hasNextPage: Bool) {
                self.init(unsafeResultMap: ["__typename": "PageInfo", "endCursor": endCursor, "hasNextPage": hasNextPage])
              }

              public var __typename: String {
                get {
                  return resultMap["__typename"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "__typename")
                }
              }

              /// When paginating forwards, the cursor to continue.
              public var endCursor: String? {
                get {
                  return resultMap["endCursor"] as? String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "endCursor")
                }
              }

              /// When paginating forwards, are there more items?
              public var hasNextPage: Bool {
                get {
                  return resultMap["hasNextPage"]! as! Bool
                }
                set {
                  resultMap.updateValue(newValue, forKey: "hasNextPage")
                }
              }
            }
          }

          public struct TopTrack: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["LastFMTrackConnection"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("edges", type: .list(.object(Edge.selections))),
                GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(edges: [Edge?]? = nil, pageInfo: PageInfo) {
              self.init(unsafeResultMap: ["__typename": "LastFMTrackConnection", "edges": edges.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, "pageInfo": pageInfo.resultMap])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            /// A list of edges.
            public var edges: [Edge?]? {
              get {
                return (resultMap["edges"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Edge?] in value.map { (value: ResultMap?) -> Edge? in value.flatMap { (value: ResultMap) -> Edge in Edge(unsafeResultMap: value) } } }
              }
              set {
                resultMap.updateValue(newValue.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, forKey: "edges")
              }
            }

            /// Information to aid in pagination.
            public var pageInfo: PageInfo {
              get {
                return PageInfo(unsafeResultMap: resultMap["pageInfo"]! as! ResultMap)
              }
              set {
                resultMap.updateValue(newValue.resultMap, forKey: "pageInfo")
              }
            }

            public struct Edge: GraphQLSelectionSet {
              public static let possibleTypes: [String] = ["LastFMTrackEdge"]

              public static var selections: [GraphQLSelection] {
                return [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("node", type: .object(Node.selections)),
                ]
              }

              public private(set) var resultMap: ResultMap

              public init(unsafeResultMap: ResultMap) {
                self.resultMap = unsafeResultMap
              }

              public init(node: Node? = nil) {
                self.init(unsafeResultMap: ["__typename": "LastFMTrackEdge", "node": node.flatMap { (value: Node) -> ResultMap in value.resultMap }])
              }

              public var __typename: String {
                get {
                  return resultMap["__typename"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "__typename")
                }
              }

              /// The item at the end of the edge.
              public var node: Node? {
                get {
                  return (resultMap["node"] as? ResultMap).flatMap { Node(unsafeResultMap: $0) }
                }
                set {
                  resultMap.updateValue(newValue?.resultMap, forKey: "node")
                }
              }

              public struct Node: GraphQLSelectionSet {
                public static let possibleTypes: [String] = ["LastFMTrack"]

                public static var selections: [GraphQLSelection] {
                  return [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("album", type: .object(Album.selections)),
                    GraphQLField("artist", type: .object(Artist.selections)),
                    GraphQLField("title", type: .scalar(String.self)),
                  ]
                }

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                  self.resultMap = unsafeResultMap
                }

                public init(album: Album? = nil, artist: Artist? = nil, title: String? = nil) {
                  self.init(unsafeResultMap: ["__typename": "LastFMTrack", "album": album.flatMap { (value: Album) -> ResultMap in value.resultMap }, "artist": artist.flatMap { (value: Artist) -> ResultMap in value.resultMap }, "title": title])
                }

                public var __typename: String {
                  get {
                    return resultMap["__typename"]! as! String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "__typename")
                  }
                }

                /// The album on which the track appears. This returns the Last.fm album info,
                /// not the MusicBrainz release.
                public var album: Album? {
                  get {
                    return (resultMap["album"] as? ResultMap).flatMap { Album(unsafeResultMap: $0) }
                  }
                  set {
                    resultMap.updateValue(newValue?.resultMap, forKey: "album")
                  }
                }

                /// The artist who released the track. This returns the Last.fm artist info,
                /// not the MusicBrainz artist.
                public var artist: Artist? {
                  get {
                    return (resultMap["artist"] as? ResultMap).flatMap { Artist(unsafeResultMap: $0) }
                  }
                  set {
                    resultMap.updateValue(newValue?.resultMap, forKey: "artist")
                  }
                }

                /// The title of the track according to [Last.fm](https://www.last.fm/).
                public var title: String? {
                  get {
                    return resultMap["title"] as? String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "title")
                  }
                }

                public struct Album: GraphQLSelectionSet {
                  public static let possibleTypes: [String] = ["LastFMAlbum"]

                  public static var selections: [GraphQLSelection] {
                    return [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("image", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                      GraphQLField("mbid", type: .scalar(String.self)),
                    ]
                  }

                  public private(set) var resultMap: ResultMap

                  public init(unsafeResultMap: ResultMap) {
                    self.resultMap = unsafeResultMap
                  }

                  public init(image: String? = nil, mbid: String? = nil) {
                    self.init(unsafeResultMap: ["__typename": "LastFMAlbum", "image": image, "mbid": mbid])
                  }

                  public var __typename: String {
                    get {
                      return resultMap["__typename"]! as! String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "__typename")
                    }
                  }

                  /// An image of the cover artwork of the release.
                  public var image: String? {
                    get {
                      return resultMap["image"] as? String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "image")
                    }
                  }

                  /// The MBID of the corresponding MusicBrainz release.
                  public var mbid: String? {
                    get {
                      return resultMap["mbid"] as? String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "mbid")
                    }
                  }
                }

                public struct Artist: GraphQLSelectionSet {
                  public static let possibleTypes: [String] = ["LastFMArtist"]

                  public static var selections: [GraphQLSelection] {
                    return [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("name", type: .scalar(String.self)),
                    ]
                  }

                  public private(set) var resultMap: ResultMap

                  public init(unsafeResultMap: ResultMap) {
                    self.resultMap = unsafeResultMap
                  }

                  public init(name: String? = nil) {
                    self.init(unsafeResultMap: ["__typename": "LastFMArtist", "name": name])
                  }

                  public var __typename: String {
                    get {
                      return resultMap["__typename"]! as! String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "__typename")
                    }
                  }

                  /// The name of the artist according to [Last.fm](https://www.last.fm/).
                  public var name: String? {
                    get {
                      return resultMap["name"] as? String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "name")
                    }
                  }
                }
              }
            }

            public struct PageInfo: GraphQLSelectionSet {
              public static let possibleTypes: [String] = ["PageInfo"]

              public static var selections: [GraphQLSelection] {
                return [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("endCursor", type: .scalar(String.self)),
                  GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                ]
              }

              public private(set) var resultMap: ResultMap

              public init(unsafeResultMap: ResultMap) {
                self.resultMap = unsafeResultMap
              }

              public init(endCursor: String? = nil, hasNextPage: Bool) {
                self.init(unsafeResultMap: ["__typename": "PageInfo", "endCursor": endCursor, "hasNextPage": hasNextPage])
              }

              public var __typename: String {
                get {
                  return resultMap["__typename"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "__typename")
                }
              }

              /// When paginating forwards, the cursor to continue.
              public var endCursor: String? {
                get {
                  return resultMap["endCursor"] as? String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "endCursor")
                }
              }

              /// When paginating forwards, are there more items?
              public var hasNextPage: Bool {
                get {
                  return resultMap["hasNextPage"]! as! Bool
                }
                set {
                  resultMap.updateValue(newValue, forKey: "hasNextPage")
                }
              }
            }
          }
        }
      }
    }
  }

  public final class ArtistDetailViewQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      query ArtistDetailView($mbid: MBID!, $size: TheAudioDBImageSize, $first: Int, $after: String, $URLString_size: LastFMImageSize, $type: [ReleaseGroupType], $status: [ReleaseStatus], $ReleaseConnection_first: Int, $ReleaseGroupConnection_type: [ReleaseGroupType], $lang: String) {
        lookup {
          __typename
          artist(mbid: $mbid) {
            __typename
            area {
              __typename
              name
            }
            lastFM {
              __typename
              topTracks(after: $after, first: $first) {
                __typename
                edges {
                  __typename
                  node {
                    __typename
                    album {
                      __typename
                      image(size: $URLString_size)
                      mbid
                    }
                    artist {
                      __typename
                      name
                    }
                    title
                  }
                }
                pageInfo {
                  __typename
                  endCursor
                  hasNextPage
                }
              }
            }
            lifeSpan {
              __typename
              begin
            }
            name
            releaseGroups(after: $after, first: $first, type: $type) {
              __typename
              edges {
                __typename
                node {
                  __typename
                  releases(after: $after, first: $ReleaseConnection_first, status: $status, type: $type) {
                    __typename
                    nodes {
                      __typename
                      mbid
                    }
                  }
                  theAudioDB {
                    __typename
                    frontImage(size: $size)
                  }
                  title
                }
              }
              pageInfo {
                __typename
                endCursor
                hasNextPage
              }
            }
            releaseGroups1: releaseGroups(after: $after, first: $first, type: $ReleaseGroupConnection_type) {
              __typename
              edges {
                __typename
                node {
                  __typename
                  releases(after: $after, first: $ReleaseConnection_first, status: $status, type: $type) {
                    __typename
                    nodes {
                      __typename
                      mbid
                    }
                  }
                  theAudioDB {
                    __typename
                    frontImage(size: $size)
                  }
                  title
                }
              }
              pageInfo {
                __typename
                endCursor
                hasNextPage
              }
            }
            theAudioDB {
              __typename
              biography(lang: $lang)
              mood
              style
              thumbnail(size: $size)
            }
            type
          }
        }
      }
      """

    public let operationName: String = "ArtistDetailView"

    public var mbid: String
    public var size: TheAudioDBImageSize?
    public var first: Int?
    public var after: String?
    public var URLString_size: LastFMImageSize?
    public var type: [ReleaseGroupType?]?
    public var status: [ReleaseStatus?]?
    public var ReleaseConnection_first: Int?
    public var ReleaseGroupConnection_type: [ReleaseGroupType?]?
    public var lang: String?

    public init(mbid: String, size: TheAudioDBImageSize? = nil, first: Int? = nil, after: String? = nil, URLString_size: LastFMImageSize? = nil, type: [ReleaseGroupType?]? = nil, status: [ReleaseStatus?]? = nil, ReleaseConnection_first: Int? = nil, ReleaseGroupConnection_type: [ReleaseGroupType?]? = nil, lang: String? = nil) {
      self.mbid = mbid
      self.size = size
      self.first = first
      self.after = after
      self.URLString_size = URLString_size
      self.type = type
      self.status = status
      self.ReleaseConnection_first = ReleaseConnection_first
      self.ReleaseGroupConnection_type = ReleaseGroupConnection_type
      self.lang = lang
    }

    public var variables: GraphQLMap? {
      return ["mbid": mbid, "size": size, "first": first, "after": after, "URLString_size": URLString_size, "type": type, "status": status, "ReleaseConnection_first": ReleaseConnection_first, "ReleaseGroupConnection_type": ReleaseGroupConnection_type, "lang": lang]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Query"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("lookup", type: .object(Lookup.selections)),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(lookup: Lookup? = nil) {
        self.init(unsafeResultMap: ["__typename": "Query", "lookup": lookup.flatMap { (value: Lookup) -> ResultMap in value.resultMap }])
      }

      /// Perform a lookup of a MusicBrainz entity by its MBID.
      public var lookup: Lookup? {
        get {
          return (resultMap["lookup"] as? ResultMap).flatMap { Lookup(unsafeResultMap: $0) }
        }
        set {
          resultMap.updateValue(newValue?.resultMap, forKey: "lookup")
        }
      }

      public struct Lookup: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["LookupQuery"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("artist", arguments: ["mbid": GraphQLVariable("mbid")], type: .object(Artist.selections)),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(artist: Artist? = nil) {
          self.init(unsafeResultMap: ["__typename": "LookupQuery", "artist": artist.flatMap { (value: Artist) -> ResultMap in value.resultMap }])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        /// Look up a specific artist by its MBID.
        public var artist: Artist? {
          get {
            return (resultMap["artist"] as? ResultMap).flatMap { Artist(unsafeResultMap: $0) }
          }
          set {
            resultMap.updateValue(newValue?.resultMap, forKey: "artist")
          }
        }

        public struct Artist: GraphQLSelectionSet {
          public static let possibleTypes: [String] = ["Artist"]

          public static var selections: [GraphQLSelection] {
            return [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("area", type: .object(Area.selections)),
              GraphQLField("lastFM", type: .object(LastFm.selections)),
              GraphQLField("lifeSpan", type: .object(LifeSpan.selections)),
              GraphQLField("name", type: .scalar(String.self)),
              GraphQLField("releaseGroups", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first"), "type": GraphQLVariable("type")], type: .object(ReleaseGroup.selections)),
              GraphQLField("releaseGroups", alias: "releaseGroups1", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first"), "type": GraphQLVariable("ReleaseGroupConnection_type")], type: .object(ReleaseGroups1.selections)),
              GraphQLField("theAudioDB", type: .object(TheAudioDb.selections)),
              GraphQLField("type", type: .scalar(String.self)),
            ]
          }

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(area: Area? = nil, lastFm: LastFm? = nil, lifeSpan: LifeSpan? = nil, name: String? = nil, releaseGroups: ReleaseGroup? = nil, releaseGroups1: ReleaseGroups1? = nil, theAudioDb: TheAudioDb? = nil, type: String? = nil) {
            self.init(unsafeResultMap: ["__typename": "Artist", "area": area.flatMap { (value: Area) -> ResultMap in value.resultMap }, "lastFM": lastFm.flatMap { (value: LastFm) -> ResultMap in value.resultMap }, "lifeSpan": lifeSpan.flatMap { (value: LifeSpan) -> ResultMap in value.resultMap }, "name": name, "releaseGroups": releaseGroups.flatMap { (value: ReleaseGroup) -> ResultMap in value.resultMap }, "releaseGroups1": releaseGroups1.flatMap { (value: ReleaseGroups1) -> ResultMap in value.resultMap }, "theAudioDB": theAudioDb.flatMap { (value: TheAudioDb) -> ResultMap in value.resultMap }, "type": type])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          /// The area with which an artist is primarily identified. It
          /// is often, but not always, its birth/formation country.
          public var area: Area? {
            get {
              return (resultMap["area"] as? ResultMap).flatMap { Area(unsafeResultMap: $0) }
            }
            set {
              resultMap.updateValue(newValue?.resultMap, forKey: "area")
            }
          }

          /// Data about the artist from [Last.fm](https://www.last.fm/), a good source
          /// for measuring popularity via listener and play counts. This field is
          /// provided by the Last.fm extension.
          public var lastFm: LastFm? {
            get {
              return (resultMap["lastFM"] as? ResultMap).flatMap { LastFm(unsafeResultMap: $0) }
            }
            set {
              resultMap.updateValue(newValue?.resultMap, forKey: "lastFM")
            }
          }

          /// The begin and end dates of the entity’s existence. Its exact
          /// meaning depends on the type of entity.
          public var lifeSpan: LifeSpan? {
            get {
              return (resultMap["lifeSpan"] as? ResultMap).flatMap { LifeSpan(unsafeResultMap: $0) }
            }
            set {
              resultMap.updateValue(newValue?.resultMap, forKey: "lifeSpan")
            }
          }

          /// The official name of the entity.
          public var name: String? {
            get {
              return resultMap["name"] as? String
            }
            set {
              resultMap.updateValue(newValue, forKey: "name")
            }
          }

          /// A list of release groups linked to this entity.
          public var releaseGroups: ReleaseGroup? {
            get {
              return (resultMap["releaseGroups"] as? ResultMap).flatMap { ReleaseGroup(unsafeResultMap: $0) }
            }
            set {
              resultMap.updateValue(newValue?.resultMap, forKey: "releaseGroups")
            }
          }

          /// A list of release groups linked to this entity.
          public var releaseGroups1: ReleaseGroups1? {
            get {
              return (resultMap["releaseGroups1"] as? ResultMap).flatMap { ReleaseGroups1(unsafeResultMap: $0) }
            }
            set {
              resultMap.updateValue(newValue?.resultMap, forKey: "releaseGroups1")
            }
          }

          /// Data about the artist from [TheAudioDB](http://www.theaudiodb.com/), a good
          /// source of biographical information and images.
          /// This field is provided by TheAudioDB extension.
          public var theAudioDb: TheAudioDb? {
            get {
              return (resultMap["theAudioDB"] as? ResultMap).flatMap { TheAudioDb(unsafeResultMap: $0) }
            }
            set {
              resultMap.updateValue(newValue?.resultMap, forKey: "theAudioDB")
            }
          }

          /// Whether an artist is a person, a group, or something else.
          public var type: String? {
            get {
              return resultMap["type"] as? String
            }
            set {
              resultMap.updateValue(newValue, forKey: "type")
            }
          }

          public struct Area: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["Area"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("name", type: .scalar(String.self)),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(name: String? = nil) {
              self.init(unsafeResultMap: ["__typename": "Area", "name": name])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            /// The official name of the entity.
            public var name: String? {
              get {
                return resultMap["name"] as? String
              }
              set {
                resultMap.updateValue(newValue, forKey: "name")
              }
            }
          }

          public struct LastFm: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["LastFMArtist"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("topTracks", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first")], type: .object(TopTrack.selections)),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(topTracks: TopTrack? = nil) {
              self.init(unsafeResultMap: ["__typename": "LastFMArtist", "topTracks": topTracks.flatMap { (value: TopTrack) -> ResultMap in value.resultMap }])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            /// A list of the artist’s most popular tracks.
            public var topTracks: TopTrack? {
              get {
                return (resultMap["topTracks"] as? ResultMap).flatMap { TopTrack(unsafeResultMap: $0) }
              }
              set {
                resultMap.updateValue(newValue?.resultMap, forKey: "topTracks")
              }
            }

            public struct TopTrack: GraphQLSelectionSet {
              public static let possibleTypes: [String] = ["LastFMTrackConnection"]

              public static var selections: [GraphQLSelection] {
                return [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("edges", type: .list(.object(Edge.selections))),
                  GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
                ]
              }

              public private(set) var resultMap: ResultMap

              public init(unsafeResultMap: ResultMap) {
                self.resultMap = unsafeResultMap
              }

              public init(edges: [Edge?]? = nil, pageInfo: PageInfo) {
                self.init(unsafeResultMap: ["__typename": "LastFMTrackConnection", "edges": edges.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, "pageInfo": pageInfo.resultMap])
              }

              public var __typename: String {
                get {
                  return resultMap["__typename"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "__typename")
                }
              }

              /// A list of edges.
              public var edges: [Edge?]? {
                get {
                  return (resultMap["edges"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Edge?] in value.map { (value: ResultMap?) -> Edge? in value.flatMap { (value: ResultMap) -> Edge in Edge(unsafeResultMap: value) } } }
                }
                set {
                  resultMap.updateValue(newValue.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, forKey: "edges")
                }
              }

              /// Information to aid in pagination.
              public var pageInfo: PageInfo {
                get {
                  return PageInfo(unsafeResultMap: resultMap["pageInfo"]! as! ResultMap)
                }
                set {
                  resultMap.updateValue(newValue.resultMap, forKey: "pageInfo")
                }
              }

              public struct Edge: GraphQLSelectionSet {
                public static let possibleTypes: [String] = ["LastFMTrackEdge"]

                public static var selections: [GraphQLSelection] {
                  return [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("node", type: .object(Node.selections)),
                  ]
                }

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                  self.resultMap = unsafeResultMap
                }

                public init(node: Node? = nil) {
                  self.init(unsafeResultMap: ["__typename": "LastFMTrackEdge", "node": node.flatMap { (value: Node) -> ResultMap in value.resultMap }])
                }

                public var __typename: String {
                  get {
                    return resultMap["__typename"]! as! String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "__typename")
                  }
                }

                /// The item at the end of the edge.
                public var node: Node? {
                  get {
                    return (resultMap["node"] as? ResultMap).flatMap { Node(unsafeResultMap: $0) }
                  }
                  set {
                    resultMap.updateValue(newValue?.resultMap, forKey: "node")
                  }
                }

                public struct Node: GraphQLSelectionSet {
                  public static let possibleTypes: [String] = ["LastFMTrack"]

                  public static var selections: [GraphQLSelection] {
                    return [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("album", type: .object(Album.selections)),
                      GraphQLField("artist", type: .object(Artist.selections)),
                      GraphQLField("title", type: .scalar(String.self)),
                    ]
                  }

                  public private(set) var resultMap: ResultMap

                  public init(unsafeResultMap: ResultMap) {
                    self.resultMap = unsafeResultMap
                  }

                  public init(album: Album? = nil, artist: Artist? = nil, title: String? = nil) {
                    self.init(unsafeResultMap: ["__typename": "LastFMTrack", "album": album.flatMap { (value: Album) -> ResultMap in value.resultMap }, "artist": artist.flatMap { (value: Artist) -> ResultMap in value.resultMap }, "title": title])
                  }

                  public var __typename: String {
                    get {
                      return resultMap["__typename"]! as! String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "__typename")
                    }
                  }

                  /// The album on which the track appears. This returns the Last.fm album info,
                  /// not the MusicBrainz release.
                  public var album: Album? {
                    get {
                      return (resultMap["album"] as? ResultMap).flatMap { Album(unsafeResultMap: $0) }
                    }
                    set {
                      resultMap.updateValue(newValue?.resultMap, forKey: "album")
                    }
                  }

                  /// The artist who released the track. This returns the Last.fm artist info,
                  /// not the MusicBrainz artist.
                  public var artist: Artist? {
                    get {
                      return (resultMap["artist"] as? ResultMap).flatMap { Artist(unsafeResultMap: $0) }
                    }
                    set {
                      resultMap.updateValue(newValue?.resultMap, forKey: "artist")
                    }
                  }

                  /// The title of the track according to [Last.fm](https://www.last.fm/).
                  public var title: String? {
                    get {
                      return resultMap["title"] as? String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "title")
                    }
                  }

                  public struct Album: GraphQLSelectionSet {
                    public static let possibleTypes: [String] = ["LastFMAlbum"]

                    public static var selections: [GraphQLSelection] {
                      return [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("image", arguments: ["size": GraphQLVariable("URLString_size")], type: .scalar(String.self)),
                        GraphQLField("mbid", type: .scalar(String.self)),
                      ]
                    }

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                      self.resultMap = unsafeResultMap
                    }

                    public init(image: String? = nil, mbid: String? = nil) {
                      self.init(unsafeResultMap: ["__typename": "LastFMAlbum", "image": image, "mbid": mbid])
                    }

                    public var __typename: String {
                      get {
                        return resultMap["__typename"]! as! String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "__typename")
                      }
                    }

                    /// An image of the cover artwork of the release.
                    public var image: String? {
                      get {
                        return resultMap["image"] as? String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "image")
                      }
                    }

                    /// The MBID of the corresponding MusicBrainz release.
                    public var mbid: String? {
                      get {
                        return resultMap["mbid"] as? String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "mbid")
                      }
                    }
                  }

                  public struct Artist: GraphQLSelectionSet {
                    public static let possibleTypes: [String] = ["LastFMArtist"]

                    public static var selections: [GraphQLSelection] {
                      return [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("name", type: .scalar(String.self)),
                      ]
                    }

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                      self.resultMap = unsafeResultMap
                    }

                    public init(name: String? = nil) {
                      self.init(unsafeResultMap: ["__typename": "LastFMArtist", "name": name])
                    }

                    public var __typename: String {
                      get {
                        return resultMap["__typename"]! as! String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "__typename")
                      }
                    }

                    /// The name of the artist according to [Last.fm](https://www.last.fm/).
                    public var name: String? {
                      get {
                        return resultMap["name"] as? String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "name")
                      }
                    }
                  }
                }
              }

              public struct PageInfo: GraphQLSelectionSet {
                public static let possibleTypes: [String] = ["PageInfo"]

                public static var selections: [GraphQLSelection] {
                  return [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("endCursor", type: .scalar(String.self)),
                    GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                  ]
                }

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                  self.resultMap = unsafeResultMap
                }

                public init(endCursor: String? = nil, hasNextPage: Bool) {
                  self.init(unsafeResultMap: ["__typename": "PageInfo", "endCursor": endCursor, "hasNextPage": hasNextPage])
                }

                public var __typename: String {
                  get {
                    return resultMap["__typename"]! as! String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "__typename")
                  }
                }

                /// When paginating forwards, the cursor to continue.
                public var endCursor: String? {
                  get {
                    return resultMap["endCursor"] as? String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "endCursor")
                  }
                }

                /// When paginating forwards, are there more items?
                public var hasNextPage: Bool {
                  get {
                    return resultMap["hasNextPage"]! as! Bool
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "hasNextPage")
                  }
                }
              }
            }
          }

          public struct LifeSpan: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["LifeSpan"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("begin", type: .scalar(String.self)),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(begin: String? = nil) {
              self.init(unsafeResultMap: ["__typename": "LifeSpan", "begin": begin])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            /// The start date of the entity’s life span.
            public var begin: String? {
              get {
                return resultMap["begin"] as? String
              }
              set {
                resultMap.updateValue(newValue, forKey: "begin")
              }
            }
          }

          public struct ReleaseGroup: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["ReleaseGroupConnection"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("edges", type: .list(.object(Edge.selections))),
                GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(edges: [Edge?]? = nil, pageInfo: PageInfo) {
              self.init(unsafeResultMap: ["__typename": "ReleaseGroupConnection", "edges": edges.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, "pageInfo": pageInfo.resultMap])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            /// A list of edges.
            public var edges: [Edge?]? {
              get {
                return (resultMap["edges"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Edge?] in value.map { (value: ResultMap?) -> Edge? in value.flatMap { (value: ResultMap) -> Edge in Edge(unsafeResultMap: value) } } }
              }
              set {
                resultMap.updateValue(newValue.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, forKey: "edges")
              }
            }

            /// Information to aid in pagination.
            public var pageInfo: PageInfo {
              get {
                return PageInfo(unsafeResultMap: resultMap["pageInfo"]! as! ResultMap)
              }
              set {
                resultMap.updateValue(newValue.resultMap, forKey: "pageInfo")
              }
            }

            public struct Edge: GraphQLSelectionSet {
              public static let possibleTypes: [String] = ["ReleaseGroupEdge"]

              public static var selections: [GraphQLSelection] {
                return [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("node", type: .object(Node.selections)),
                ]
              }

              public private(set) var resultMap: ResultMap

              public init(unsafeResultMap: ResultMap) {
                self.resultMap = unsafeResultMap
              }

              public init(node: Node? = nil) {
                self.init(unsafeResultMap: ["__typename": "ReleaseGroupEdge", "node": node.flatMap { (value: Node) -> ResultMap in value.resultMap }])
              }

              public var __typename: String {
                get {
                  return resultMap["__typename"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "__typename")
                }
              }

              /// The item at the end of the edge
              public var node: Node? {
                get {
                  return (resultMap["node"] as? ResultMap).flatMap { Node(unsafeResultMap: $0) }
                }
                set {
                  resultMap.updateValue(newValue?.resultMap, forKey: "node")
                }
              }

              public struct Node: GraphQLSelectionSet {
                public static let possibleTypes: [String] = ["ReleaseGroup"]

                public static var selections: [GraphQLSelection] {
                  return [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("releases", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("ReleaseConnection_first"), "status": GraphQLVariable("status"), "type": GraphQLVariable("type")], type: .object(Release.selections)),
                    GraphQLField("theAudioDB", type: .object(TheAudioDb.selections)),
                    GraphQLField("title", type: .scalar(String.self)),
                  ]
                }

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                  self.resultMap = unsafeResultMap
                }

                public init(releases: Release? = nil, theAudioDb: TheAudioDb? = nil, title: String? = nil) {
                  self.init(unsafeResultMap: ["__typename": "ReleaseGroup", "releases": releases.flatMap { (value: Release) -> ResultMap in value.resultMap }, "theAudioDB": theAudioDb.flatMap { (value: TheAudioDb) -> ResultMap in value.resultMap }, "title": title])
                }

                public var __typename: String {
                  get {
                    return resultMap["__typename"]! as! String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "__typename")
                  }
                }

                /// A list of releases linked to this entity.
                public var releases: Release? {
                  get {
                    return (resultMap["releases"] as? ResultMap).flatMap { Release(unsafeResultMap: $0) }
                  }
                  set {
                    resultMap.updateValue(newValue?.resultMap, forKey: "releases")
                  }
                }

                /// Data about the release group from [TheAudioDB](http://www.theaudiodb.com/),
                /// a good source of descriptive information, reviews, and images.
                /// This field is provided by TheAudioDB extension.
                public var theAudioDb: TheAudioDb? {
                  get {
                    return (resultMap["theAudioDB"] as? ResultMap).flatMap { TheAudioDb(unsafeResultMap: $0) }
                  }
                  set {
                    resultMap.updateValue(newValue?.resultMap, forKey: "theAudioDB")
                  }
                }

                /// The official title of the entity.
                public var title: String? {
                  get {
                    return resultMap["title"] as? String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "title")
                  }
                }

                public struct Release: GraphQLSelectionSet {
                  public static let possibleTypes: [String] = ["ReleaseConnection"]

                  public static var selections: [GraphQLSelection] {
                    return [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("nodes", type: .list(.object(Node.selections))),
                    ]
                  }

                  public private(set) var resultMap: ResultMap

                  public init(unsafeResultMap: ResultMap) {
                    self.resultMap = unsafeResultMap
                  }

                  public init(nodes: [Node?]? = nil) {
                    self.init(unsafeResultMap: ["__typename": "ReleaseConnection", "nodes": nodes.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }])
                  }

                  public var __typename: String {
                    get {
                      return resultMap["__typename"]! as! String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "__typename")
                    }
                  }

                  /// A list of nodes in the connection (without going through the
                  /// `edges` field).
                  public var nodes: [Node?]? {
                    get {
                      return (resultMap["nodes"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Node?] in value.map { (value: ResultMap?) -> Node? in value.flatMap { (value: ResultMap) -> Node in Node(unsafeResultMap: value) } } }
                    }
                    set {
                      resultMap.updateValue(newValue.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }, forKey: "nodes")
                    }
                  }

                  public struct Node: GraphQLSelectionSet {
                    public static let possibleTypes: [String] = ["Release"]

                    public static var selections: [GraphQLSelection] {
                      return [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("mbid", type: .nonNull(.scalar(String.self))),
                      ]
                    }

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                      self.resultMap = unsafeResultMap
                    }

                    public init(mbid: String) {
                      self.init(unsafeResultMap: ["__typename": "Release", "mbid": mbid])
                    }

                    public var __typename: String {
                      get {
                        return resultMap["__typename"]! as! String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "__typename")
                      }
                    }

                    /// The MBID of the entity.
                    public var mbid: String {
                      get {
                        return resultMap["mbid"]! as! String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "mbid")
                      }
                    }
                  }
                }

                public struct TheAudioDb: GraphQLSelectionSet {
                  public static let possibleTypes: [String] = ["TheAudioDBAlbum"]

                  public static var selections: [GraphQLSelection] {
                    return [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("frontImage", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                    ]
                  }

                  public private(set) var resultMap: ResultMap

                  public init(unsafeResultMap: ResultMap) {
                    self.resultMap = unsafeResultMap
                  }

                  public init(frontImage: String? = nil) {
                    self.init(unsafeResultMap: ["__typename": "TheAudioDBAlbum", "frontImage": frontImage])
                  }

                  public var __typename: String {
                    get {
                      return resultMap["__typename"]! as! String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "__typename")
                    }
                  }

                  /// An image of the front of the album packaging.
                  public var frontImage: String? {
                    get {
                      return resultMap["frontImage"] as? String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "frontImage")
                    }
                  }
                }
              }
            }

            public struct PageInfo: GraphQLSelectionSet {
              public static let possibleTypes: [String] = ["PageInfo"]

              public static var selections: [GraphQLSelection] {
                return [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("endCursor", type: .scalar(String.self)),
                  GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                ]
              }

              public private(set) var resultMap: ResultMap

              public init(unsafeResultMap: ResultMap) {
                self.resultMap = unsafeResultMap
              }

              public init(endCursor: String? = nil, hasNextPage: Bool) {
                self.init(unsafeResultMap: ["__typename": "PageInfo", "endCursor": endCursor, "hasNextPage": hasNextPage])
              }

              public var __typename: String {
                get {
                  return resultMap["__typename"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "__typename")
                }
              }

              /// When paginating forwards, the cursor to continue.
              public var endCursor: String? {
                get {
                  return resultMap["endCursor"] as? String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "endCursor")
                }
              }

              /// When paginating forwards, are there more items?
              public var hasNextPage: Bool {
                get {
                  return resultMap["hasNextPage"]! as! Bool
                }
                set {
                  resultMap.updateValue(newValue, forKey: "hasNextPage")
                }
              }
            }
          }

          public struct ReleaseGroups1: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["ReleaseGroupConnection"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("edges", type: .list(.object(Edge.selections))),
                GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(edges: [Edge?]? = nil, pageInfo: PageInfo) {
              self.init(unsafeResultMap: ["__typename": "ReleaseGroupConnection", "edges": edges.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, "pageInfo": pageInfo.resultMap])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            /// A list of edges.
            public var edges: [Edge?]? {
              get {
                return (resultMap["edges"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Edge?] in value.map { (value: ResultMap?) -> Edge? in value.flatMap { (value: ResultMap) -> Edge in Edge(unsafeResultMap: value) } } }
              }
              set {
                resultMap.updateValue(newValue.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, forKey: "edges")
              }
            }

            /// Information to aid in pagination.
            public var pageInfo: PageInfo {
              get {
                return PageInfo(unsafeResultMap: resultMap["pageInfo"]! as! ResultMap)
              }
              set {
                resultMap.updateValue(newValue.resultMap, forKey: "pageInfo")
              }
            }

            public struct Edge: GraphQLSelectionSet {
              public static let possibleTypes: [String] = ["ReleaseGroupEdge"]

              public static var selections: [GraphQLSelection] {
                return [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("node", type: .object(Node.selections)),
                ]
              }

              public private(set) var resultMap: ResultMap

              public init(unsafeResultMap: ResultMap) {
                self.resultMap = unsafeResultMap
              }

              public init(node: Node? = nil) {
                self.init(unsafeResultMap: ["__typename": "ReleaseGroupEdge", "node": node.flatMap { (value: Node) -> ResultMap in value.resultMap }])
              }

              public var __typename: String {
                get {
                  return resultMap["__typename"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "__typename")
                }
              }

              /// The item at the end of the edge
              public var node: Node? {
                get {
                  return (resultMap["node"] as? ResultMap).flatMap { Node(unsafeResultMap: $0) }
                }
                set {
                  resultMap.updateValue(newValue?.resultMap, forKey: "node")
                }
              }

              public struct Node: GraphQLSelectionSet {
                public static let possibleTypes: [String] = ["ReleaseGroup"]

                public static var selections: [GraphQLSelection] {
                  return [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("releases", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("ReleaseConnection_first"), "status": GraphQLVariable("status"), "type": GraphQLVariable("type")], type: .object(Release.selections)),
                    GraphQLField("theAudioDB", type: .object(TheAudioDb.selections)),
                    GraphQLField("title", type: .scalar(String.self)),
                  ]
                }

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                  self.resultMap = unsafeResultMap
                }

                public init(releases: Release? = nil, theAudioDb: TheAudioDb? = nil, title: String? = nil) {
                  self.init(unsafeResultMap: ["__typename": "ReleaseGroup", "releases": releases.flatMap { (value: Release) -> ResultMap in value.resultMap }, "theAudioDB": theAudioDb.flatMap { (value: TheAudioDb) -> ResultMap in value.resultMap }, "title": title])
                }

                public var __typename: String {
                  get {
                    return resultMap["__typename"]! as! String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "__typename")
                  }
                }

                /// A list of releases linked to this entity.
                public var releases: Release? {
                  get {
                    return (resultMap["releases"] as? ResultMap).flatMap { Release(unsafeResultMap: $0) }
                  }
                  set {
                    resultMap.updateValue(newValue?.resultMap, forKey: "releases")
                  }
                }

                /// Data about the release group from [TheAudioDB](http://www.theaudiodb.com/),
                /// a good source of descriptive information, reviews, and images.
                /// This field is provided by TheAudioDB extension.
                public var theAudioDb: TheAudioDb? {
                  get {
                    return (resultMap["theAudioDB"] as? ResultMap).flatMap { TheAudioDb(unsafeResultMap: $0) }
                  }
                  set {
                    resultMap.updateValue(newValue?.resultMap, forKey: "theAudioDB")
                  }
                }

                /// The official title of the entity.
                public var title: String? {
                  get {
                    return resultMap["title"] as? String
                  }
                  set {
                    resultMap.updateValue(newValue, forKey: "title")
                  }
                }

                public struct Release: GraphQLSelectionSet {
                  public static let possibleTypes: [String] = ["ReleaseConnection"]

                  public static var selections: [GraphQLSelection] {
                    return [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("nodes", type: .list(.object(Node.selections))),
                    ]
                  }

                  public private(set) var resultMap: ResultMap

                  public init(unsafeResultMap: ResultMap) {
                    self.resultMap = unsafeResultMap
                  }

                  public init(nodes: [Node?]? = nil) {
                    self.init(unsafeResultMap: ["__typename": "ReleaseConnection", "nodes": nodes.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }])
                  }

                  public var __typename: String {
                    get {
                      return resultMap["__typename"]! as! String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "__typename")
                    }
                  }

                  /// A list of nodes in the connection (without going through the
                  /// `edges` field).
                  public var nodes: [Node?]? {
                    get {
                      return (resultMap["nodes"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Node?] in value.map { (value: ResultMap?) -> Node? in value.flatMap { (value: ResultMap) -> Node in Node(unsafeResultMap: value) } } }
                    }
                    set {
                      resultMap.updateValue(newValue.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }, forKey: "nodes")
                    }
                  }

                  public struct Node: GraphQLSelectionSet {
                    public static let possibleTypes: [String] = ["Release"]

                    public static var selections: [GraphQLSelection] {
                      return [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("mbid", type: .nonNull(.scalar(String.self))),
                      ]
                    }

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                      self.resultMap = unsafeResultMap
                    }

                    public init(mbid: String) {
                      self.init(unsafeResultMap: ["__typename": "Release", "mbid": mbid])
                    }

                    public var __typename: String {
                      get {
                        return resultMap["__typename"]! as! String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "__typename")
                      }
                    }

                    /// The MBID of the entity.
                    public var mbid: String {
                      get {
                        return resultMap["mbid"]! as! String
                      }
                      set {
                        resultMap.updateValue(newValue, forKey: "mbid")
                      }
                    }
                  }
                }

                public struct TheAudioDb: GraphQLSelectionSet {
                  public static let possibleTypes: [String] = ["TheAudioDBAlbum"]

                  public static var selections: [GraphQLSelection] {
                    return [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("frontImage", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                    ]
                  }

                  public private(set) var resultMap: ResultMap

                  public init(unsafeResultMap: ResultMap) {
                    self.resultMap = unsafeResultMap
                  }

                  public init(frontImage: String? = nil) {
                    self.init(unsafeResultMap: ["__typename": "TheAudioDBAlbum", "frontImage": frontImage])
                  }

                  public var __typename: String {
                    get {
                      return resultMap["__typename"]! as! String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "__typename")
                    }
                  }

                  /// An image of the front of the album packaging.
                  public var frontImage: String? {
                    get {
                      return resultMap["frontImage"] as? String
                    }
                    set {
                      resultMap.updateValue(newValue, forKey: "frontImage")
                    }
                  }
                }
              }
            }

            public struct PageInfo: GraphQLSelectionSet {
              public static let possibleTypes: [String] = ["PageInfo"]

              public static var selections: [GraphQLSelection] {
                return [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("endCursor", type: .scalar(String.self)),
                  GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                ]
              }

              public private(set) var resultMap: ResultMap

              public init(unsafeResultMap: ResultMap) {
                self.resultMap = unsafeResultMap
              }

              public init(endCursor: String? = nil, hasNextPage: Bool) {
                self.init(unsafeResultMap: ["__typename": "PageInfo", "endCursor": endCursor, "hasNextPage": hasNextPage])
              }

              public var __typename: String {
                get {
                  return resultMap["__typename"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "__typename")
                }
              }

              /// When paginating forwards, the cursor to continue.
              public var endCursor: String? {
                get {
                  return resultMap["endCursor"] as? String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "endCursor")
                }
              }

              /// When paginating forwards, are there more items?
              public var hasNextPage: Bool {
                get {
                  return resultMap["hasNextPage"]! as! Bool
                }
                set {
                  resultMap.updateValue(newValue, forKey: "hasNextPage")
                }
              }
            }
          }

          public struct TheAudioDb: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["TheAudioDBArtist"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("biography", arguments: ["lang": GraphQLVariable("lang")], type: .scalar(String.self)),
                GraphQLField("mood", type: .scalar(String.self)),
                GraphQLField("style", type: .scalar(String.self)),
                GraphQLField("thumbnail", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(biography: String? = nil, mood: String? = nil, style: String? = nil, thumbnail: String? = nil) {
              self.init(unsafeResultMap: ["__typename": "TheAudioDBArtist", "biography": biography, "mood": mood, "style": style, "thumbnail": thumbnail])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            /// A biography of the artist, often available in several languages.
            public var biography: String? {
              get {
                return resultMap["biography"] as? String
              }
              set {
                resultMap.updateValue(newValue, forKey: "biography")
              }
            }

            /// The primary musical mood of the artist (e.g. “Sad”).
            public var mood: String? {
              get {
                return resultMap["mood"] as? String
              }
              set {
                resultMap.updateValue(newValue, forKey: "mood")
              }
            }

            /// The primary musical style of the artist (e.g. “Rock/Pop”).
            public var style: String? {
              get {
                return resultMap["style"] as? String
              }
              set {
                resultMap.updateValue(newValue, forKey: "style")
              }
            }

            /// A 1000x1000 JPG thumbnail image picturing the artist (usually containing
            /// every member of a band).
            public var thumbnail: String? {
              get {
                return resultMap["thumbnail"] as? String
              }
              set {
                resultMap.updateValue(newValue, forKey: "thumbnail")
              }
            }
          }
        }
      }
    }
  }

  public final class AlbumDetailViewQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      query AlbumDetailView($mbid: MBID!, $size: CoverArtArchiveImageSize) {
        lookup {
          __typename
          release(mbid: $mbid) {
            __typename
            artistCredits {
              __typename
              artist {
                __typename
                ...AlbumArtistCreditButtonArtist
              }
            }
            coverArtArchive {
              __typename
              front(size: $size)
            }
            date
            discogs {
              __typename
              genres
            }
            lastFM {
              __typename
              playCount
            }
            media {
              __typename
              tracks {
                __typename
                ...AlbumTrackCellTrack
              }
            }
            title
          }
        }
      }
      """

    public let operationName: String = "AlbumDetailView"

    public var queryDocument: String { return operationDefinition.appending(AlbumArtistCreditButtonArtist.fragmentDefinition).appending(AlbumTrackCellTrack.fragmentDefinition).appending(AlbumTrackCellCreditArtistCredit.fragmentDefinition) }

    public var mbid: String
    public var size: CoverArtArchiveImageSize?

    public init(mbid: String, size: CoverArtArchiveImageSize? = nil) {
      self.mbid = mbid
      self.size = size
    }

    public var variables: GraphQLMap? {
      return ["mbid": mbid, "size": size]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Query"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("lookup", type: .object(Lookup.selections)),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(lookup: Lookup? = nil) {
        self.init(unsafeResultMap: ["__typename": "Query", "lookup": lookup.flatMap { (value: Lookup) -> ResultMap in value.resultMap }])
      }

      /// Perform a lookup of a MusicBrainz entity by its MBID.
      public var lookup: Lookup? {
        get {
          return (resultMap["lookup"] as? ResultMap).flatMap { Lookup(unsafeResultMap: $0) }
        }
        set {
          resultMap.updateValue(newValue?.resultMap, forKey: "lookup")
        }
      }

      public struct Lookup: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["LookupQuery"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("release", arguments: ["mbid": GraphQLVariable("mbid")], type: .object(Release.selections)),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(release: Release? = nil) {
          self.init(unsafeResultMap: ["__typename": "LookupQuery", "release": release.flatMap { (value: Release) -> ResultMap in value.resultMap }])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        /// Look up a specific release by its MBID.
        public var release: Release? {
          get {
            return (resultMap["release"] as? ResultMap).flatMap { Release(unsafeResultMap: $0) }
          }
          set {
            resultMap.updateValue(newValue?.resultMap, forKey: "release")
          }
        }

        public struct Release: GraphQLSelectionSet {
          public static let possibleTypes: [String] = ["Release"]

          public static var selections: [GraphQLSelection] {
            return [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("artistCredits", type: .list(.object(ArtistCredit.selections))),
              GraphQLField("coverArtArchive", type: .object(CoverArtArchive.selections)),
              GraphQLField("date", type: .scalar(String.self)),
              GraphQLField("discogs", type: .object(Discog.selections)),
              GraphQLField("lastFM", type: .object(LastFm.selections)),
              GraphQLField("media", type: .list(.object(Medium.selections))),
              GraphQLField("title", type: .scalar(String.self)),
            ]
          }

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(artistCredits: [ArtistCredit?]? = nil, coverArtArchive: CoverArtArchive? = nil, date: String? = nil, discogs: Discog? = nil, lastFm: LastFm? = nil, media: [Medium?]? = nil, title: String? = nil) {
            self.init(unsafeResultMap: ["__typename": "Release", "artistCredits": artistCredits.flatMap { (value: [ArtistCredit?]) -> [ResultMap?] in value.map { (value: ArtistCredit?) -> ResultMap? in value.flatMap { (value: ArtistCredit) -> ResultMap in value.resultMap } } }, "coverArtArchive": coverArtArchive.flatMap { (value: CoverArtArchive) -> ResultMap in value.resultMap }, "date": date, "discogs": discogs.flatMap { (value: Discog) -> ResultMap in value.resultMap }, "lastFM": lastFm.flatMap { (value: LastFm) -> ResultMap in value.resultMap }, "media": media.flatMap { (value: [Medium?]) -> [ResultMap?] in value.map { (value: Medium?) -> ResultMap? in value.flatMap { (value: Medium) -> ResultMap in value.resultMap } } }, "title": title])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          /// The main credited artist(s).
          public var artistCredits: [ArtistCredit?]? {
            get {
              return (resultMap["artistCredits"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [ArtistCredit?] in value.map { (value: ResultMap?) -> ArtistCredit? in value.flatMap { (value: ResultMap) -> ArtistCredit in ArtistCredit(unsafeResultMap: value) } } }
            }
            set {
              resultMap.updateValue(newValue.flatMap { (value: [ArtistCredit?]) -> [ResultMap?] in value.map { (value: ArtistCredit?) -> ResultMap? in value.flatMap { (value: ArtistCredit) -> ResultMap in value.resultMap } } }, forKey: "artistCredits")
            }
          }

          /// An object containing a list and summary of the cover art images that are
          /// present for this release from the [Cover Art Archive](https://musicbrainz.org/doc/Cover_Art_Archive).
          /// This field is provided by the Cover Art Archive extension.
          public var coverArtArchive: CoverArtArchive? {
            get {
              return (resultMap["coverArtArchive"] as? ResultMap).flatMap { CoverArtArchive(unsafeResultMap: $0) }
            }
            set {
              resultMap.updateValue(newValue?.resultMap, forKey: "coverArtArchive")
            }
          }

          /// The [release date](https://musicbrainz.org/doc/Release/Date)
          /// is the date in which a release was made available through some sort of
          /// distribution mechanism.
          public var date: String? {
            get {
              return resultMap["date"] as? String
            }
            set {
              resultMap.updateValue(newValue, forKey: "date")
            }
          }

          /// Information about the release on Discogs.
          public var discogs: Discog? {
            get {
              return (resultMap["discogs"] as? ResultMap).flatMap { Discog(unsafeResultMap: $0) }
            }
            set {
              resultMap.updateValue(newValue?.resultMap, forKey: "discogs")
            }
          }

          /// Data about the release from [Last.fm](https://www.last.fm/), a good source
          /// for measuring popularity via listener and play counts. This field is
          /// provided by the Last.fm extension.
          public var lastFm: LastFm? {
            get {
              return (resultMap["lastFM"] as? ResultMap).flatMap { LastFm(unsafeResultMap: $0) }
            }
            set {
              resultMap.updateValue(newValue?.resultMap, forKey: "lastFM")
            }
          }

          /// The media on which the release was distributed.
          public var media: [Medium?]? {
            get {
              return (resultMap["media"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Medium?] in value.map { (value: ResultMap?) -> Medium? in value.flatMap { (value: ResultMap) -> Medium in Medium(unsafeResultMap: value) } } }
            }
            set {
              resultMap.updateValue(newValue.flatMap { (value: [Medium?]) -> [ResultMap?] in value.map { (value: Medium?) -> ResultMap? in value.flatMap { (value: Medium) -> ResultMap in value.resultMap } } }, forKey: "media")
            }
          }

          /// The official title of the entity.
          public var title: String? {
            get {
              return resultMap["title"] as? String
            }
            set {
              resultMap.updateValue(newValue, forKey: "title")
            }
          }

          public struct ArtistCredit: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["ArtistCredit"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("artist", type: .object(Artist.selections)),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(artist: Artist? = nil) {
              self.init(unsafeResultMap: ["__typename": "ArtistCredit", "artist": artist.flatMap { (value: Artist) -> ResultMap in value.resultMap }])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            /// The entity representing the artist referenced in the
            /// credits.
            public var artist: Artist? {
              get {
                return (resultMap["artist"] as? ResultMap).flatMap { Artist(unsafeResultMap: $0) }
              }
              set {
                resultMap.updateValue(newValue?.resultMap, forKey: "artist")
              }
            }

            public struct Artist: GraphQLSelectionSet {
              public static let possibleTypes: [String] = ["Artist"]

              public static var selections: [GraphQLSelection] {
                return [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLFragmentSpread(AlbumArtistCreditButtonArtist.self),
                ]
              }

              public private(set) var resultMap: ResultMap

              public init(unsafeResultMap: ResultMap) {
                self.resultMap = unsafeResultMap
              }

              public init(mbid: String, name: String? = nil) {
                self.init(unsafeResultMap: ["__typename": "Artist", "mbid": mbid, "name": name])
              }

              public var __typename: String {
                get {
                  return resultMap["__typename"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "__typename")
                }
              }

              public var fragments: Fragments {
                get {
                  return Fragments(unsafeResultMap: resultMap)
                }
                set {
                  resultMap += newValue.resultMap
                }
              }

              public struct Fragments {
                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                  self.resultMap = unsafeResultMap
                }

                public var albumArtistCreditButtonArtist: AlbumArtistCreditButtonArtist {
                  get {
                    return AlbumArtistCreditButtonArtist(unsafeResultMap: resultMap)
                  }
                  set {
                    resultMap += newValue.resultMap
                  }
                }
              }
            }
          }

          public struct CoverArtArchive: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["CoverArtArchiveRelease"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("front", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(front: String? = nil) {
              self.init(unsafeResultMap: ["__typename": "CoverArtArchiveRelease", "front": front])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            /// The URL of an image depicting the album cover or “main front” of the release,
            /// i.e. the front of the packaging of the audio recording (or in the case of a
            /// digital release, the image associated with it in a digital media store).
            /// 
            /// In the MusicBrainz schema, this field is a Boolean value indicating the
            /// presence of a front image, whereas here the value is the URL for the image
            /// itself if one exists. You can check for null if you just want to determine
            /// the presence of an image.
            public var front: String? {
              get {
                return resultMap["front"] as? String
              }
              set {
                resultMap.updateValue(newValue, forKey: "front")
              }
            }
          }

          public struct Discog: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["DiscogsRelease"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("genres", type: .nonNull(.list(.nonNull(.scalar(String.self))))),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(genres: [String]) {
              self.init(unsafeResultMap: ["__typename": "DiscogsRelease", "genres": genres])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            /// The primary musical genres of the release (e.g. “Electronic”).
            public var genres: [String] {
              get {
                return resultMap["genres"]! as! [String]
              }
              set {
                resultMap.updateValue(newValue, forKey: "genres")
              }
            }
          }

          public struct LastFm: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["LastFMAlbum"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("playCount", type: .scalar(Double.self)),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(playCount: Double? = nil) {
              self.init(unsafeResultMap: ["__typename": "LastFMAlbum", "playCount": playCount])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            /// The number of plays recorded for the album.
            public var playCount: Double? {
              get {
                return resultMap["playCount"] as? Double
              }
              set {
                resultMap.updateValue(newValue, forKey: "playCount")
              }
            }
          }

          public struct Medium: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["Medium"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("tracks", type: .list(.object(Track.selections))),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(tracks: [Track?]? = nil) {
              self.init(unsafeResultMap: ["__typename": "Medium", "tracks": tracks.flatMap { (value: [Track?]) -> [ResultMap?] in value.map { (value: Track?) -> ResultMap? in value.flatMap { (value: Track) -> ResultMap in value.resultMap } } }])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            /// The list of tracks on the given media.
            public var tracks: [Track?]? {
              get {
                return (resultMap["tracks"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Track?] in value.map { (value: ResultMap?) -> Track? in value.flatMap { (value: ResultMap) -> Track in Track(unsafeResultMap: value) } } }
              }
              set {
                resultMap.updateValue(newValue.flatMap { (value: [Track?]) -> [ResultMap?] in value.map { (value: Track?) -> ResultMap? in value.flatMap { (value: Track) -> ResultMap in value.resultMap } } }, forKey: "tracks")
              }
            }

            public struct Track: GraphQLSelectionSet {
              public static let possibleTypes: [String] = ["Track"]

              public static var selections: [GraphQLSelection] {
                return [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLFragmentSpread(AlbumTrackCellTrack.self),
                ]
              }

              public private(set) var resultMap: ResultMap

              public init(unsafeResultMap: ResultMap) {
                self.resultMap = unsafeResultMap
              }

              public var __typename: String {
                get {
                  return resultMap["__typename"]! as! String
                }
                set {
                  resultMap.updateValue(newValue, forKey: "__typename")
                }
              }

              public var fragments: Fragments {
                get {
                  return Fragments(unsafeResultMap: resultMap)
                }
                set {
                  resultMap += newValue.resultMap
                }
              }

              public struct Fragments {
                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                  self.resultMap = unsafeResultMap
                }

                public var albumTrackCellTrack: AlbumTrackCellTrack {
                  get {
                    return AlbumTrackCellTrack(unsafeResultMap: resultMap)
                  }
                  set {
                    resultMap += newValue.resultMap
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  public struct LastFmArtistConnectionTrendingArtistCellLastFmArtist: GraphQLFragment {
    /// The raw GraphQL definition of this fragment.
    public static let fragmentDefinition: String =
      """
      fragment LastFMArtistConnectionTrendingArtistCellLastFMArtist on LastFMArtistConnection {
        __typename
        edges {
          __typename
          node {
            __typename
            mbid
            name
            topAlbums {
              __typename
              nodes {
                __typename
                image
              }
            }
            topTags {
              __typename
              nodes {
                __typename
                name
              }
            }
            topTracks {
              __typename
              nodes {
                __typename
                title
              }
            }
          }
        }
        pageInfo {
          __typename
          endCursor
          hasNextPage
        }
      }
      """

    public static let possibleTypes: [String] = ["LastFMArtistConnection"]

    public static var selections: [GraphQLSelection] {
      return [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("edges", type: .list(.object(Edge.selections))),
        GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
      ]
    }

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(edges: [Edge?]? = nil, pageInfo: PageInfo) {
      self.init(unsafeResultMap: ["__typename": "LastFMArtistConnection", "edges": edges.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, "pageInfo": pageInfo.resultMap])
    }

    public var __typename: String {
      get {
        return resultMap["__typename"]! as! String
      }
      set {
        resultMap.updateValue(newValue, forKey: "__typename")
      }
    }

    /// A list of edges.
    public var edges: [Edge?]? {
      get {
        return (resultMap["edges"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Edge?] in value.map { (value: ResultMap?) -> Edge? in value.flatMap { (value: ResultMap) -> Edge in Edge(unsafeResultMap: value) } } }
      }
      set {
        resultMap.updateValue(newValue.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, forKey: "edges")
      }
    }

    /// Information to aid in pagination.
    public var pageInfo: PageInfo {
      get {
        return PageInfo(unsafeResultMap: resultMap["pageInfo"]! as! ResultMap)
      }
      set {
        resultMap.updateValue(newValue.resultMap, forKey: "pageInfo")
      }
    }

    public struct Edge: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["LastFMArtistEdge"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("node", type: .object(Node.selections)),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(node: Node? = nil) {
        self.init(unsafeResultMap: ["__typename": "LastFMArtistEdge", "node": node.flatMap { (value: Node) -> ResultMap in value.resultMap }])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      /// The item at the end of the edge.
      public var node: Node? {
        get {
          return (resultMap["node"] as? ResultMap).flatMap { Node(unsafeResultMap: $0) }
        }
        set {
          resultMap.updateValue(newValue?.resultMap, forKey: "node")
        }
      }

      public struct Node: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["LastFMArtist"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("mbid", type: .scalar(String.self)),
            GraphQLField("name", type: .scalar(String.self)),
            GraphQLField("topAlbums", type: .object(TopAlbum.selections)),
            GraphQLField("topTags", type: .object(TopTag.selections)),
            GraphQLField("topTracks", type: .object(TopTrack.selections)),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(mbid: String? = nil, name: String? = nil, topAlbums: TopAlbum? = nil, topTags: TopTag? = nil, topTracks: TopTrack? = nil) {
          self.init(unsafeResultMap: ["__typename": "LastFMArtist", "mbid": mbid, "name": name, "topAlbums": topAlbums.flatMap { (value: TopAlbum) -> ResultMap in value.resultMap }, "topTags": topTags.flatMap { (value: TopTag) -> ResultMap in value.resultMap }, "topTracks": topTracks.flatMap { (value: TopTrack) -> ResultMap in value.resultMap }])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        /// The MBID of the corresponding MusicBrainz artist.
        public var mbid: String? {
          get {
            return resultMap["mbid"] as? String
          }
          set {
            resultMap.updateValue(newValue, forKey: "mbid")
          }
        }

        /// The name of the artist according to [Last.fm](https://www.last.fm/).
        public var name: String? {
          get {
            return resultMap["name"] as? String
          }
          set {
            resultMap.updateValue(newValue, forKey: "name")
          }
        }

        /// A list of the artist’s most popular albums.
        public var topAlbums: TopAlbum? {
          get {
            return (resultMap["topAlbums"] as? ResultMap).flatMap { TopAlbum(unsafeResultMap: $0) }
          }
          set {
            resultMap.updateValue(newValue?.resultMap, forKey: "topAlbums")
          }
        }

        /// A list of tags applied to the artist by users, ordered by popularity.
        public var topTags: TopTag? {
          get {
            return (resultMap["topTags"] as? ResultMap).flatMap { TopTag(unsafeResultMap: $0) }
          }
          set {
            resultMap.updateValue(newValue?.resultMap, forKey: "topTags")
          }
        }

        /// A list of the artist’s most popular tracks.
        public var topTracks: TopTrack? {
          get {
            return (resultMap["topTracks"] as? ResultMap).flatMap { TopTrack(unsafeResultMap: $0) }
          }
          set {
            resultMap.updateValue(newValue?.resultMap, forKey: "topTracks")
          }
        }

        public struct TopAlbum: GraphQLSelectionSet {
          public static let possibleTypes: [String] = ["LastFMAlbumConnection"]

          public static var selections: [GraphQLSelection] {
            return [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("nodes", type: .list(.object(Node.selections))),
            ]
          }

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(nodes: [Node?]? = nil) {
            self.init(unsafeResultMap: ["__typename": "LastFMAlbumConnection", "nodes": nodes.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          /// A list of nodes in the connection (without going through the `edges` field).
          public var nodes: [Node?]? {
            get {
              return (resultMap["nodes"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Node?] in value.map { (value: ResultMap?) -> Node? in value.flatMap { (value: ResultMap) -> Node in Node(unsafeResultMap: value) } } }
            }
            set {
              resultMap.updateValue(newValue.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }, forKey: "nodes")
            }
          }

          public struct Node: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["LastFMAlbum"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("image", type: .scalar(String.self)),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(image: String? = nil) {
              self.init(unsafeResultMap: ["__typename": "LastFMAlbum", "image": image])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            /// An image of the cover artwork of the release.
            public var image: String? {
              get {
                return resultMap["image"] as? String
              }
              set {
                resultMap.updateValue(newValue, forKey: "image")
              }
            }
          }
        }

        public struct TopTag: GraphQLSelectionSet {
          public static let possibleTypes: [String] = ["LastFMTagConnection"]

          public static var selections: [GraphQLSelection] {
            return [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("nodes", type: .list(.object(Node.selections))),
            ]
          }

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(nodes: [Node?]? = nil) {
            self.init(unsafeResultMap: ["__typename": "LastFMTagConnection", "nodes": nodes.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          /// A list of nodes in the connection (without going through the `edges` field).
          public var nodes: [Node?]? {
            get {
              return (resultMap["nodes"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Node?] in value.map { (value: ResultMap?) -> Node? in value.flatMap { (value: ResultMap) -> Node in Node(unsafeResultMap: value) } } }
            }
            set {
              resultMap.updateValue(newValue.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }, forKey: "nodes")
            }
          }

          public struct Node: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["LastFMTag"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("name", type: .nonNull(.scalar(String.self))),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(name: String) {
              self.init(unsafeResultMap: ["__typename": "LastFMTag", "name": name])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            /// The tag name.
            public var name: String {
              get {
                return resultMap["name"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "name")
              }
            }
          }
        }

        public struct TopTrack: GraphQLSelectionSet {
          public static let possibleTypes: [String] = ["LastFMTrackConnection"]

          public static var selections: [GraphQLSelection] {
            return [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("nodes", type: .list(.object(Node.selections))),
            ]
          }

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(nodes: [Node?]? = nil) {
            self.init(unsafeResultMap: ["__typename": "LastFMTrackConnection", "nodes": nodes.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          /// A list of nodes in the connection (without going through the `edges` field).
          public var nodes: [Node?]? {
            get {
              return (resultMap["nodes"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Node?] in value.map { (value: ResultMap?) -> Node? in value.flatMap { (value: ResultMap) -> Node in Node(unsafeResultMap: value) } } }
            }
            set {
              resultMap.updateValue(newValue.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }, forKey: "nodes")
            }
          }

          public struct Node: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["LastFMTrack"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("title", type: .scalar(String.self)),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(title: String? = nil) {
              self.init(unsafeResultMap: ["__typename": "LastFMTrack", "title": title])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            /// The title of the track according to [Last.fm](https://www.last.fm/).
            public var title: String? {
              get {
                return resultMap["title"] as? String
              }
              set {
                resultMap.updateValue(newValue, forKey: "title")
              }
            }
          }
        }
      }
    }

    public struct PageInfo: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["PageInfo"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("endCursor", type: .scalar(String.self)),
          GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(endCursor: String? = nil, hasNextPage: Bool) {
        self.init(unsafeResultMap: ["__typename": "PageInfo", "endCursor": endCursor, "hasNextPage": hasNextPage])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      /// When paginating forwards, the cursor to continue.
      public var endCursor: String? {
        get {
          return resultMap["endCursor"] as? String
        }
        set {
          resultMap.updateValue(newValue, forKey: "endCursor")
        }
      }

      /// When paginating forwards, are there more items?
      public var hasNextPage: Bool {
        get {
          return resultMap["hasNextPage"]! as! Bool
        }
        set {
          resultMap.updateValue(newValue, forKey: "hasNextPage")
        }
      }
    }
  }

  public struct LastFmTrackConnectionTrendingTrackCellLastFmTrack: GraphQLFragment {
    /// The raw GraphQL definition of this fragment.
    public static let fragmentDefinition: String =
      """
      fragment LastFMTrackConnectionTrendingTrackCellLastFMTrack on LastFMTrackConnection {
        __typename
        edges {
          __typename
          node {
            __typename
            album {
              __typename
              image
              mbid
            }
            artist {
              __typename
              name
            }
            title
          }
        }
        pageInfo {
          __typename
          endCursor
          hasNextPage
        }
      }
      """

    public static let possibleTypes: [String] = ["LastFMTrackConnection"]

    public static var selections: [GraphQLSelection] {
      return [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("edges", type: .list(.object(Edge.selections))),
        GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
      ]
    }

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(edges: [Edge?]? = nil, pageInfo: PageInfo) {
      self.init(unsafeResultMap: ["__typename": "LastFMTrackConnection", "edges": edges.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, "pageInfo": pageInfo.resultMap])
    }

    public var __typename: String {
      get {
        return resultMap["__typename"]! as! String
      }
      set {
        resultMap.updateValue(newValue, forKey: "__typename")
      }
    }

    /// A list of edges.
    public var edges: [Edge?]? {
      get {
        return (resultMap["edges"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Edge?] in value.map { (value: ResultMap?) -> Edge? in value.flatMap { (value: ResultMap) -> Edge in Edge(unsafeResultMap: value) } } }
      }
      set {
        resultMap.updateValue(newValue.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, forKey: "edges")
      }
    }

    /// Information to aid in pagination.
    public var pageInfo: PageInfo {
      get {
        return PageInfo(unsafeResultMap: resultMap["pageInfo"]! as! ResultMap)
      }
      set {
        resultMap.updateValue(newValue.resultMap, forKey: "pageInfo")
      }
    }

    public struct Edge: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["LastFMTrackEdge"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("node", type: .object(Node.selections)),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(node: Node? = nil) {
        self.init(unsafeResultMap: ["__typename": "LastFMTrackEdge", "node": node.flatMap { (value: Node) -> ResultMap in value.resultMap }])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      /// The item at the end of the edge.
      public var node: Node? {
        get {
          return (resultMap["node"] as? ResultMap).flatMap { Node(unsafeResultMap: $0) }
        }
        set {
          resultMap.updateValue(newValue?.resultMap, forKey: "node")
        }
      }

      public struct Node: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["LastFMTrack"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("album", type: .object(Album.selections)),
            GraphQLField("artist", type: .object(Artist.selections)),
            GraphQLField("title", type: .scalar(String.self)),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(album: Album? = nil, artist: Artist? = nil, title: String? = nil) {
          self.init(unsafeResultMap: ["__typename": "LastFMTrack", "album": album.flatMap { (value: Album) -> ResultMap in value.resultMap }, "artist": artist.flatMap { (value: Artist) -> ResultMap in value.resultMap }, "title": title])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        /// The album on which the track appears. This returns the Last.fm album info,
        /// not the MusicBrainz release.
        public var album: Album? {
          get {
            return (resultMap["album"] as? ResultMap).flatMap { Album(unsafeResultMap: $0) }
          }
          set {
            resultMap.updateValue(newValue?.resultMap, forKey: "album")
          }
        }

        /// The artist who released the track. This returns the Last.fm artist info,
        /// not the MusicBrainz artist.
        public var artist: Artist? {
          get {
            return (resultMap["artist"] as? ResultMap).flatMap { Artist(unsafeResultMap: $0) }
          }
          set {
            resultMap.updateValue(newValue?.resultMap, forKey: "artist")
          }
        }

        /// The title of the track according to [Last.fm](https://www.last.fm/).
        public var title: String? {
          get {
            return resultMap["title"] as? String
          }
          set {
            resultMap.updateValue(newValue, forKey: "title")
          }
        }

        public struct Album: GraphQLSelectionSet {
          public static let possibleTypes: [String] = ["LastFMAlbum"]

          public static var selections: [GraphQLSelection] {
            return [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("image", type: .scalar(String.self)),
              GraphQLField("mbid", type: .scalar(String.self)),
            ]
          }

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(image: String? = nil, mbid: String? = nil) {
            self.init(unsafeResultMap: ["__typename": "LastFMAlbum", "image": image, "mbid": mbid])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          /// An image of the cover artwork of the release.
          public var image: String? {
            get {
              return resultMap["image"] as? String
            }
            set {
              resultMap.updateValue(newValue, forKey: "image")
            }
          }

          /// The MBID of the corresponding MusicBrainz release.
          public var mbid: String? {
            get {
              return resultMap["mbid"] as? String
            }
            set {
              resultMap.updateValue(newValue, forKey: "mbid")
            }
          }
        }

        public struct Artist: GraphQLSelectionSet {
          public static let possibleTypes: [String] = ["LastFMArtist"]

          public static var selections: [GraphQLSelection] {
            return [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("name", type: .scalar(String.self)),
            ]
          }

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(name: String? = nil) {
            self.init(unsafeResultMap: ["__typename": "LastFMArtist", "name": name])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          /// The name of the artist according to [Last.fm](https://www.last.fm/).
          public var name: String? {
            get {
              return resultMap["name"] as? String
            }
            set {
              resultMap.updateValue(newValue, forKey: "name")
            }
          }
        }
      }
    }

    public struct PageInfo: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["PageInfo"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("endCursor", type: .scalar(String.self)),
          GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(endCursor: String? = nil, hasNextPage: Bool) {
        self.init(unsafeResultMap: ["__typename": "PageInfo", "endCursor": endCursor, "hasNextPage": hasNextPage])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      /// When paginating forwards, the cursor to continue.
      public var endCursor: String? {
        get {
          return resultMap["endCursor"] as? String
        }
        set {
          resultMap.updateValue(newValue, forKey: "endCursor")
        }
      }

      /// When paginating forwards, are there more items?
      public var hasNextPage: Bool {
        get {
          return resultMap["hasNextPage"]! as! Bool
        }
        set {
          resultMap.updateValue(newValue, forKey: "hasNextPage")
        }
      }
    }
  }

  public struct ReleaseGroupConnectionArtistAlbumCellReleaseGroup: GraphQLFragment {
    /// The raw GraphQL definition of this fragment.
    public static let fragmentDefinition: String =
      """
      fragment ReleaseGroupConnectionArtistAlbumCellReleaseGroup on ReleaseGroupConnection {
        __typename
        edges {
          __typename
          node {
            __typename
            releases {
              __typename
              nodes {
                __typename
                mbid
              }
            }
            theAudioDB {
              __typename
              frontImage
            }
            title
          }
        }
        pageInfo {
          __typename
          endCursor
          hasNextPage
        }
      }
      """

    public static let possibleTypes: [String] = ["ReleaseGroupConnection"]

    public static var selections: [GraphQLSelection] {
      return [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("edges", type: .list(.object(Edge.selections))),
        GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
      ]
    }

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(edges: [Edge?]? = nil, pageInfo: PageInfo) {
      self.init(unsafeResultMap: ["__typename": "ReleaseGroupConnection", "edges": edges.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, "pageInfo": pageInfo.resultMap])
    }

    public var __typename: String {
      get {
        return resultMap["__typename"]! as! String
      }
      set {
        resultMap.updateValue(newValue, forKey: "__typename")
      }
    }

    /// A list of edges.
    public var edges: [Edge?]? {
      get {
        return (resultMap["edges"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Edge?] in value.map { (value: ResultMap?) -> Edge? in value.flatMap { (value: ResultMap) -> Edge in Edge(unsafeResultMap: value) } } }
      }
      set {
        resultMap.updateValue(newValue.flatMap { (value: [Edge?]) -> [ResultMap?] in value.map { (value: Edge?) -> ResultMap? in value.flatMap { (value: Edge) -> ResultMap in value.resultMap } } }, forKey: "edges")
      }
    }

    /// Information to aid in pagination.
    public var pageInfo: PageInfo {
      get {
        return PageInfo(unsafeResultMap: resultMap["pageInfo"]! as! ResultMap)
      }
      set {
        resultMap.updateValue(newValue.resultMap, forKey: "pageInfo")
      }
    }

    public struct Edge: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["ReleaseGroupEdge"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("node", type: .object(Node.selections)),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(node: Node? = nil) {
        self.init(unsafeResultMap: ["__typename": "ReleaseGroupEdge", "node": node.flatMap { (value: Node) -> ResultMap in value.resultMap }])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      /// The item at the end of the edge
      public var node: Node? {
        get {
          return (resultMap["node"] as? ResultMap).flatMap { Node(unsafeResultMap: $0) }
        }
        set {
          resultMap.updateValue(newValue?.resultMap, forKey: "node")
        }
      }

      public struct Node: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["ReleaseGroup"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("releases", type: .object(Release.selections)),
            GraphQLField("theAudioDB", type: .object(TheAudioDb.selections)),
            GraphQLField("title", type: .scalar(String.self)),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(releases: Release? = nil, theAudioDb: TheAudioDb? = nil, title: String? = nil) {
          self.init(unsafeResultMap: ["__typename": "ReleaseGroup", "releases": releases.flatMap { (value: Release) -> ResultMap in value.resultMap }, "theAudioDB": theAudioDb.flatMap { (value: TheAudioDb) -> ResultMap in value.resultMap }, "title": title])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        /// A list of releases linked to this entity.
        public var releases: Release? {
          get {
            return (resultMap["releases"] as? ResultMap).flatMap { Release(unsafeResultMap: $0) }
          }
          set {
            resultMap.updateValue(newValue?.resultMap, forKey: "releases")
          }
        }

        /// Data about the release group from [TheAudioDB](http://www.theaudiodb.com/),
        /// a good source of descriptive information, reviews, and images.
        /// This field is provided by TheAudioDB extension.
        public var theAudioDb: TheAudioDb? {
          get {
            return (resultMap["theAudioDB"] as? ResultMap).flatMap { TheAudioDb(unsafeResultMap: $0) }
          }
          set {
            resultMap.updateValue(newValue?.resultMap, forKey: "theAudioDB")
          }
        }

        /// The official title of the entity.
        public var title: String? {
          get {
            return resultMap["title"] as? String
          }
          set {
            resultMap.updateValue(newValue, forKey: "title")
          }
        }

        public struct Release: GraphQLSelectionSet {
          public static let possibleTypes: [String] = ["ReleaseConnection"]

          public static var selections: [GraphQLSelection] {
            return [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("nodes", type: .list(.object(Node.selections))),
            ]
          }

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(nodes: [Node?]? = nil) {
            self.init(unsafeResultMap: ["__typename": "ReleaseConnection", "nodes": nodes.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          /// A list of nodes in the connection (without going through the
          /// `edges` field).
          public var nodes: [Node?]? {
            get {
              return (resultMap["nodes"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Node?] in value.map { (value: ResultMap?) -> Node? in value.flatMap { (value: ResultMap) -> Node in Node(unsafeResultMap: value) } } }
            }
            set {
              resultMap.updateValue(newValue.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }, forKey: "nodes")
            }
          }

          public struct Node: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["Release"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("mbid", type: .nonNull(.scalar(String.self))),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(mbid: String) {
              self.init(unsafeResultMap: ["__typename": "Release", "mbid": mbid])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            /// The MBID of the entity.
            public var mbid: String {
              get {
                return resultMap["mbid"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "mbid")
              }
            }
          }
        }

        public struct TheAudioDb: GraphQLSelectionSet {
          public static let possibleTypes: [String] = ["TheAudioDBAlbum"]

          public static var selections: [GraphQLSelection] {
            return [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("frontImage", type: .scalar(String.self)),
            ]
          }

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(frontImage: String? = nil) {
            self.init(unsafeResultMap: ["__typename": "TheAudioDBAlbum", "frontImage": frontImage])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          /// An image of the front of the album packaging.
          public var frontImage: String? {
            get {
              return resultMap["frontImage"] as? String
            }
            set {
              resultMap.updateValue(newValue, forKey: "frontImage")
            }
          }
        }
      }
    }

    public struct PageInfo: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["PageInfo"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("endCursor", type: .scalar(String.self)),
          GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(endCursor: String? = nil, hasNextPage: Bool) {
        self.init(unsafeResultMap: ["__typename": "PageInfo", "endCursor": endCursor, "hasNextPage": hasNextPage])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      /// When paginating forwards, the cursor to continue.
      public var endCursor: String? {
        get {
          return resultMap["endCursor"] as? String
        }
        set {
          resultMap.updateValue(newValue, forKey: "endCursor")
        }
      }

      /// When paginating forwards, are there more items?
      public var hasNextPage: Bool {
        get {
          return resultMap["hasNextPage"]! as! Bool
        }
        set {
          resultMap.updateValue(newValue, forKey: "hasNextPage")
        }
      }
    }
  }

  public struct AlbumArtistCreditButtonArtist: GraphQLFragment {
    /// The raw GraphQL definition of this fragment.
    public static let fragmentDefinition: String =
      """
      fragment AlbumArtistCreditButtonArtist on Artist {
        __typename
        mbid
        name
      }
      """

    public static let possibleTypes: [String] = ["Artist"]

    public static var selections: [GraphQLSelection] {
      return [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("mbid", type: .nonNull(.scalar(String.self))),
        GraphQLField("name", type: .scalar(String.self)),
      ]
    }

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(mbid: String, name: String? = nil) {
      self.init(unsafeResultMap: ["__typename": "Artist", "mbid": mbid, "name": name])
    }

    public var __typename: String {
      get {
        return resultMap["__typename"]! as! String
      }
      set {
        resultMap.updateValue(newValue, forKey: "__typename")
      }
    }

    /// The MBID of the entity.
    public var mbid: String {
      get {
        return resultMap["mbid"]! as! String
      }
      set {
        resultMap.updateValue(newValue, forKey: "mbid")
      }
    }

    /// The official name of the entity.
    public var name: String? {
      get {
        return resultMap["name"] as? String
      }
      set {
        resultMap.updateValue(newValue, forKey: "name")
      }
    }
  }

  public struct AlbumTrackCellCreditArtistCredit: GraphQLFragment {
    /// The raw GraphQL definition of this fragment.
    public static let fragmentDefinition: String =
      """
      fragment AlbumTrackCellCreditArtistCredit on ArtistCredit {
        __typename
        joinPhrase
        name
      }
      """

    public static let possibleTypes: [String] = ["ArtistCredit"]

    public static var selections: [GraphQLSelection] {
      return [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("joinPhrase", type: .scalar(String.self)),
        GraphQLField("name", type: .scalar(String.self)),
      ]
    }

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(joinPhrase: String? = nil, name: String? = nil) {
      self.init(unsafeResultMap: ["__typename": "ArtistCredit", "joinPhrase": joinPhrase, "name": name])
    }

    public var __typename: String {
      get {
        return resultMap["__typename"]! as! String
      }
      set {
        resultMap.updateValue(newValue, forKey: "__typename")
      }
    }

    /// Join phrases might include words and/or punctuation to
    /// separate artist names as they appear on the release, track, etc.
    public var joinPhrase: String? {
      get {
        return resultMap["joinPhrase"] as? String
      }
      set {
        resultMap.updateValue(newValue, forKey: "joinPhrase")
      }
    }

    /// The name of the artist as credited in the specific release,
    /// track, etc.
    public var name: String? {
      get {
        return resultMap["name"] as? String
      }
      set {
        resultMap.updateValue(newValue, forKey: "name")
      }
    }
  }

  public struct ArtistAlbumCellReleaseGroup: GraphQLFragment {
    /// The raw GraphQL definition of this fragment.
    public static let fragmentDefinition: String =
      """
      fragment ArtistAlbumCellReleaseGroup on ReleaseGroup {
        __typename
        releases {
          __typename
          nodes {
            __typename
            mbid
          }
        }
        theAudioDB {
          __typename
          frontImage
        }
        title
      }
      """

    public static let possibleTypes: [String] = ["ReleaseGroup"]

    public static var selections: [GraphQLSelection] {
      return [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("releases", type: .object(Release.selections)),
        GraphQLField("theAudioDB", type: .object(TheAudioDb.selections)),
        GraphQLField("title", type: .scalar(String.self)),
      ]
    }

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(releases: Release? = nil, theAudioDb: TheAudioDb? = nil, title: String? = nil) {
      self.init(unsafeResultMap: ["__typename": "ReleaseGroup", "releases": releases.flatMap { (value: Release) -> ResultMap in value.resultMap }, "theAudioDB": theAudioDb.flatMap { (value: TheAudioDb) -> ResultMap in value.resultMap }, "title": title])
    }

    public var __typename: String {
      get {
        return resultMap["__typename"]! as! String
      }
      set {
        resultMap.updateValue(newValue, forKey: "__typename")
      }
    }

    /// A list of releases linked to this entity.
    public var releases: Release? {
      get {
        return (resultMap["releases"] as? ResultMap).flatMap { Release(unsafeResultMap: $0) }
      }
      set {
        resultMap.updateValue(newValue?.resultMap, forKey: "releases")
      }
    }

    /// Data about the release group from [TheAudioDB](http://www.theaudiodb.com/),
    /// a good source of descriptive information, reviews, and images.
    /// This field is provided by TheAudioDB extension.
    public var theAudioDb: TheAudioDb? {
      get {
        return (resultMap["theAudioDB"] as? ResultMap).flatMap { TheAudioDb(unsafeResultMap: $0) }
      }
      set {
        resultMap.updateValue(newValue?.resultMap, forKey: "theAudioDB")
      }
    }

    /// The official title of the entity.
    public var title: String? {
      get {
        return resultMap["title"] as? String
      }
      set {
        resultMap.updateValue(newValue, forKey: "title")
      }
    }

    public struct Release: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["ReleaseConnection"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nodes", type: .list(.object(Node.selections))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(nodes: [Node?]? = nil) {
        self.init(unsafeResultMap: ["__typename": "ReleaseConnection", "nodes": nodes.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      /// A list of nodes in the connection (without going through the
      /// `edges` field).
      public var nodes: [Node?]? {
        get {
          return (resultMap["nodes"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Node?] in value.map { (value: ResultMap?) -> Node? in value.flatMap { (value: ResultMap) -> Node in Node(unsafeResultMap: value) } } }
        }
        set {
          resultMap.updateValue(newValue.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }, forKey: "nodes")
        }
      }

      public struct Node: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["Release"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("mbid", type: .nonNull(.scalar(String.self))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(mbid: String) {
          self.init(unsafeResultMap: ["__typename": "Release", "mbid": mbid])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        /// The MBID of the entity.
        public var mbid: String {
          get {
            return resultMap["mbid"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "mbid")
          }
        }
      }
    }

    public struct TheAudioDb: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["TheAudioDBAlbum"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("frontImage", type: .scalar(String.self)),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(frontImage: String? = nil) {
        self.init(unsafeResultMap: ["__typename": "TheAudioDBAlbum", "frontImage": frontImage])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      /// An image of the front of the album packaging.
      public var frontImage: String? {
        get {
          return resultMap["frontImage"] as? String
        }
        set {
          resultMap.updateValue(newValue, forKey: "frontImage")
        }
      }
    }
  }

  public struct TrendingArtistCellLastFmArtist: GraphQLFragment {
    /// The raw GraphQL definition of this fragment.
    public static let fragmentDefinition: String =
      """
      fragment TrendingArtistCellLastFMArtist on LastFMArtist {
        __typename
        mbid
        name
        topAlbums {
          __typename
          nodes {
            __typename
            image
          }
        }
        topTags {
          __typename
          nodes {
            __typename
            name
          }
        }
        topTracks {
          __typename
          nodes {
            __typename
            title
          }
        }
      }
      """

    public static let possibleTypes: [String] = ["LastFMArtist"]

    public static var selections: [GraphQLSelection] {
      return [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("mbid", type: .scalar(String.self)),
        GraphQLField("name", type: .scalar(String.self)),
        GraphQLField("topAlbums", type: .object(TopAlbum.selections)),
        GraphQLField("topTags", type: .object(TopTag.selections)),
        GraphQLField("topTracks", type: .object(TopTrack.selections)),
      ]
    }

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(mbid: String? = nil, name: String? = nil, topAlbums: TopAlbum? = nil, topTags: TopTag? = nil, topTracks: TopTrack? = nil) {
      self.init(unsafeResultMap: ["__typename": "LastFMArtist", "mbid": mbid, "name": name, "topAlbums": topAlbums.flatMap { (value: TopAlbum) -> ResultMap in value.resultMap }, "topTags": topTags.flatMap { (value: TopTag) -> ResultMap in value.resultMap }, "topTracks": topTracks.flatMap { (value: TopTrack) -> ResultMap in value.resultMap }])
    }

    public var __typename: String {
      get {
        return resultMap["__typename"]! as! String
      }
      set {
        resultMap.updateValue(newValue, forKey: "__typename")
      }
    }

    /// The MBID of the corresponding MusicBrainz artist.
    public var mbid: String? {
      get {
        return resultMap["mbid"] as? String
      }
      set {
        resultMap.updateValue(newValue, forKey: "mbid")
      }
    }

    /// The name of the artist according to [Last.fm](https://www.last.fm/).
    public var name: String? {
      get {
        return resultMap["name"] as? String
      }
      set {
        resultMap.updateValue(newValue, forKey: "name")
      }
    }

    /// A list of the artist’s most popular albums.
    public var topAlbums: TopAlbum? {
      get {
        return (resultMap["topAlbums"] as? ResultMap).flatMap { TopAlbum(unsafeResultMap: $0) }
      }
      set {
        resultMap.updateValue(newValue?.resultMap, forKey: "topAlbums")
      }
    }

    /// A list of tags applied to the artist by users, ordered by popularity.
    public var topTags: TopTag? {
      get {
        return (resultMap["topTags"] as? ResultMap).flatMap { TopTag(unsafeResultMap: $0) }
      }
      set {
        resultMap.updateValue(newValue?.resultMap, forKey: "topTags")
      }
    }

    /// A list of the artist’s most popular tracks.
    public var topTracks: TopTrack? {
      get {
        return (resultMap["topTracks"] as? ResultMap).flatMap { TopTrack(unsafeResultMap: $0) }
      }
      set {
        resultMap.updateValue(newValue?.resultMap, forKey: "topTracks")
      }
    }

    public struct TopAlbum: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["LastFMAlbumConnection"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nodes", type: .list(.object(Node.selections))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(nodes: [Node?]? = nil) {
        self.init(unsafeResultMap: ["__typename": "LastFMAlbumConnection", "nodes": nodes.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      /// A list of nodes in the connection (without going through the `edges` field).
      public var nodes: [Node?]? {
        get {
          return (resultMap["nodes"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Node?] in value.map { (value: ResultMap?) -> Node? in value.flatMap { (value: ResultMap) -> Node in Node(unsafeResultMap: value) } } }
        }
        set {
          resultMap.updateValue(newValue.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }, forKey: "nodes")
        }
      }

      public struct Node: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["LastFMAlbum"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("image", type: .scalar(String.self)),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(image: String? = nil) {
          self.init(unsafeResultMap: ["__typename": "LastFMAlbum", "image": image])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        /// An image of the cover artwork of the release.
        public var image: String? {
          get {
            return resultMap["image"] as? String
          }
          set {
            resultMap.updateValue(newValue, forKey: "image")
          }
        }
      }
    }

    public struct TopTag: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["LastFMTagConnection"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nodes", type: .list(.object(Node.selections))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(nodes: [Node?]? = nil) {
        self.init(unsafeResultMap: ["__typename": "LastFMTagConnection", "nodes": nodes.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      /// A list of nodes in the connection (without going through the `edges` field).
      public var nodes: [Node?]? {
        get {
          return (resultMap["nodes"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Node?] in value.map { (value: ResultMap?) -> Node? in value.flatMap { (value: ResultMap) -> Node in Node(unsafeResultMap: value) } } }
        }
        set {
          resultMap.updateValue(newValue.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }, forKey: "nodes")
        }
      }

      public struct Node: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["LastFMTag"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("name", type: .nonNull(.scalar(String.self))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(name: String) {
          self.init(unsafeResultMap: ["__typename": "LastFMTag", "name": name])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        /// The tag name.
        public var name: String {
          get {
            return resultMap["name"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "name")
          }
        }
      }
    }

    public struct TopTrack: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["LastFMTrackConnection"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nodes", type: .list(.object(Node.selections))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(nodes: [Node?]? = nil) {
        self.init(unsafeResultMap: ["__typename": "LastFMTrackConnection", "nodes": nodes.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      /// A list of nodes in the connection (without going through the `edges` field).
      public var nodes: [Node?]? {
        get {
          return (resultMap["nodes"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [Node?] in value.map { (value: ResultMap?) -> Node? in value.flatMap { (value: ResultMap) -> Node in Node(unsafeResultMap: value) } } }
        }
        set {
          resultMap.updateValue(newValue.flatMap { (value: [Node?]) -> [ResultMap?] in value.map { (value: Node?) -> ResultMap? in value.flatMap { (value: Node) -> ResultMap in value.resultMap } } }, forKey: "nodes")
        }
      }

      public struct Node: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["LastFMTrack"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("title", type: .scalar(String.self)),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(title: String? = nil) {
          self.init(unsafeResultMap: ["__typename": "LastFMTrack", "title": title])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        /// The title of the track according to [Last.fm](https://www.last.fm/).
        public var title: String? {
          get {
            return resultMap["title"] as? String
          }
          set {
            resultMap.updateValue(newValue, forKey: "title")
          }
        }
      }
    }
  }

  public struct TrendingTrackCellLastFmTrack: GraphQLFragment {
    /// The raw GraphQL definition of this fragment.
    public static let fragmentDefinition: String =
      """
      fragment TrendingTrackCellLastFMTrack on LastFMTrack {
        __typename
        album {
          __typename
          image
          mbid
        }
        artist {
          __typename
          name
        }
        title
      }
      """

    public static let possibleTypes: [String] = ["LastFMTrack"]

    public static var selections: [GraphQLSelection] {
      return [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("album", type: .object(Album.selections)),
        GraphQLField("artist", type: .object(Artist.selections)),
        GraphQLField("title", type: .scalar(String.self)),
      ]
    }

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(album: Album? = nil, artist: Artist? = nil, title: String? = nil) {
      self.init(unsafeResultMap: ["__typename": "LastFMTrack", "album": album.flatMap { (value: Album) -> ResultMap in value.resultMap }, "artist": artist.flatMap { (value: Artist) -> ResultMap in value.resultMap }, "title": title])
    }

    public var __typename: String {
      get {
        return resultMap["__typename"]! as! String
      }
      set {
        resultMap.updateValue(newValue, forKey: "__typename")
      }
    }

    /// The album on which the track appears. This returns the Last.fm album info,
    /// not the MusicBrainz release.
    public var album: Album? {
      get {
        return (resultMap["album"] as? ResultMap).flatMap { Album(unsafeResultMap: $0) }
      }
      set {
        resultMap.updateValue(newValue?.resultMap, forKey: "album")
      }
    }

    /// The artist who released the track. This returns the Last.fm artist info,
    /// not the MusicBrainz artist.
    public var artist: Artist? {
      get {
        return (resultMap["artist"] as? ResultMap).flatMap { Artist(unsafeResultMap: $0) }
      }
      set {
        resultMap.updateValue(newValue?.resultMap, forKey: "artist")
      }
    }

    /// The title of the track according to [Last.fm](https://www.last.fm/).
    public var title: String? {
      get {
        return resultMap["title"] as? String
      }
      set {
        resultMap.updateValue(newValue, forKey: "title")
      }
    }

    public struct Album: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["LastFMAlbum"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("image", type: .scalar(String.self)),
          GraphQLField("mbid", type: .scalar(String.self)),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(image: String? = nil, mbid: String? = nil) {
        self.init(unsafeResultMap: ["__typename": "LastFMAlbum", "image": image, "mbid": mbid])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      /// An image of the cover artwork of the release.
      public var image: String? {
        get {
          return resultMap["image"] as? String
        }
        set {
          resultMap.updateValue(newValue, forKey: "image")
        }
      }

      /// The MBID of the corresponding MusicBrainz release.
      public var mbid: String? {
        get {
          return resultMap["mbid"] as? String
        }
        set {
          resultMap.updateValue(newValue, forKey: "mbid")
        }
      }
    }

    public struct Artist: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["LastFMArtist"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .scalar(String.self)),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(name: String? = nil) {
        self.init(unsafeResultMap: ["__typename": "LastFMArtist", "name": name])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      /// The name of the artist according to [Last.fm](https://www.last.fm/).
      public var name: String? {
        get {
          return resultMap["name"] as? String
        }
        set {
          resultMap.updateValue(newValue, forKey: "name")
        }
      }
    }
  }

  public struct AlbumTrackCellTrack: GraphQLFragment {
    /// The raw GraphQL definition of this fragment.
    public static let fragmentDefinition: String =
      """
      fragment AlbumTrackCellTrack on Track {
        __typename
        position
        recording {
          __typename
          artistCredits {
            __typename
            ...AlbumTrackCellCreditArtistCredit
          }
          lastFM {
            __typename
            playCount
          }
        }
        title
      }
      """

    public static let possibleTypes: [String] = ["Track"]

    public static var selections: [GraphQLSelection] {
      return [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("position", type: .scalar(Int.self)),
        GraphQLField("recording", type: .object(Recording.selections)),
        GraphQLField("title", type: .scalar(String.self)),
      ]
    }

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(position: Int? = nil, recording: Recording? = nil, title: String? = nil) {
      self.init(unsafeResultMap: ["__typename": "Track", "position": position, "recording": recording.flatMap { (value: Recording) -> ResultMap in value.resultMap }, "title": title])
    }

    public var __typename: String {
      get {
        return resultMap["__typename"]! as! String
      }
      set {
        resultMap.updateValue(newValue, forKey: "__typename")
      }
    }

    /// The track’s position on the overall release (including all
    /// tracks from all discs).
    public var position: Int? {
      get {
        return resultMap["position"] as? Int
      }
      set {
        resultMap.updateValue(newValue, forKey: "position")
      }
    }

    /// The recording that appears on the track.
    public var recording: Recording? {
      get {
        return (resultMap["recording"] as? ResultMap).flatMap { Recording(unsafeResultMap: $0) }
      }
      set {
        resultMap.updateValue(newValue?.resultMap, forKey: "recording")
      }
    }

    /// The official title of the entity.
    public var title: String? {
      get {
        return resultMap["title"] as? String
      }
      set {
        resultMap.updateValue(newValue, forKey: "title")
      }
    }

    public struct Recording: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Recording"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("artistCredits", type: .list(.object(ArtistCredit.selections))),
          GraphQLField("lastFM", type: .object(LastFm.selections)),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(artistCredits: [ArtistCredit?]? = nil, lastFm: LastFm? = nil) {
        self.init(unsafeResultMap: ["__typename": "Recording", "artistCredits": artistCredits.flatMap { (value: [ArtistCredit?]) -> [ResultMap?] in value.map { (value: ArtistCredit?) -> ResultMap? in value.flatMap { (value: ArtistCredit) -> ResultMap in value.resultMap } } }, "lastFM": lastFm.flatMap { (value: LastFm) -> ResultMap in value.resultMap }])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      /// The main credited artist(s).
      public var artistCredits: [ArtistCredit?]? {
        get {
          return (resultMap["artistCredits"] as? [ResultMap?]).flatMap { (value: [ResultMap?]) -> [ArtistCredit?] in value.map { (value: ResultMap?) -> ArtistCredit? in value.flatMap { (value: ResultMap) -> ArtistCredit in ArtistCredit(unsafeResultMap: value) } } }
        }
        set {
          resultMap.updateValue(newValue.flatMap { (value: [ArtistCredit?]) -> [ResultMap?] in value.map { (value: ArtistCredit?) -> ResultMap? in value.flatMap { (value: ArtistCredit) -> ResultMap in value.resultMap } } }, forKey: "artistCredits")
        }
      }

      /// Data about the recording from [Last.fm](https://www.last.fm/), a good
      /// source for measuring popularity via listener and play counts. This field
      /// is provided by the Last.fm extension.
      public var lastFm: LastFm? {
        get {
          return (resultMap["lastFM"] as? ResultMap).flatMap { LastFm(unsafeResultMap: $0) }
        }
        set {
          resultMap.updateValue(newValue?.resultMap, forKey: "lastFM")
        }
      }

      public struct ArtistCredit: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["ArtistCredit"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLFragmentSpread(AlbumTrackCellCreditArtistCredit.self),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(joinPhrase: String? = nil, name: String? = nil) {
          self.init(unsafeResultMap: ["__typename": "ArtistCredit", "joinPhrase": joinPhrase, "name": name])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var fragments: Fragments {
          get {
            return Fragments(unsafeResultMap: resultMap)
          }
          set {
            resultMap += newValue.resultMap
          }
        }

        public struct Fragments {
          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public var albumTrackCellCreditArtistCredit: AlbumTrackCellCreditArtistCredit {
            get {
              return AlbumTrackCellCreditArtistCredit(unsafeResultMap: resultMap)
            }
            set {
              resultMap += newValue.resultMap
            }
          }
        }
      }

      public struct LastFm: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["LastFMTrack"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("playCount", type: .scalar(Double.self)),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(playCount: Double? = nil) {
          self.init(unsafeResultMap: ["__typename": "LastFMTrack", "playCount": playCount])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        /// The number of plays recorded for the track.
        public var playCount: Double? {
          get {
            return resultMap["playCount"] as? Double
          }
          set {
            resultMap.updateValue(newValue, forKey: "playCount")
          }
        }
      }
    }
  }
}



