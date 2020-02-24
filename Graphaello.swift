// swiftlint:disable all
// This file was automatically generated and should not be edited.

import Apollo
import Foundation
import SwiftUI

// MARK: Basic API

private struct QueryRenderer<Query: GraphQLQuery, Content: View>: View {
    typealias ContentFactory = (Query.Data) -> Content

    private final class ViewModel: ObservableObject {
        @Published var isLoading: Bool = false
        @Published var value: Query.Data? = nil
        @Published var error: String? = nil
        private var cancellable: Cancellable?

        deinit {
            cancel()
        }

        func load(client: ApolloClient, query: Query) {
            guard value == nil, !isLoading else { return }
            cancellable = client.fetch(query: query) { [weak self] result in
                defer {
                    self?.cancellable = nil
                    self?.isLoading = false
                }
                switch result {
                case let .success(result):
                    self?.value = result.data
                    self?.error = result.errors?.map { $0.description }.joined(separator: ", ")
                case let .failure(error):
                    self?.error = error.localizedDescription
                }
            }
            isLoading = true
        }

        func cancel() {
            cancellable?.cancel()
        }
    }

    let client: ApolloClient
    let query: Query
    let factory: ContentFactory

    @ObservedObject private var viewModel = ViewModel()

    var body: some View {
        VStack {
            viewModel.error.map { Text("Error: \($0)") }
            viewModel.value.map(factory)
            viewModel.isLoading ? Text("Loading") : nil
        }
        .onAppear {
            self.viewModel.load(client: self.client, query: self.query)
        }
        .onDisappear {
            self.viewModel.cancel()
        }
    }
}

protocol Fragment {
    associatedtype UnderlyingType
}

protocol Target {}

protocol API: Target {}

protocol Connection: Target {
    associatedtype Node
}

extension Array: Fragment where Element: Fragment {
    typealias UnderlyingType = [Element.UnderlyingType]
}

extension Optional: Fragment where Wrapped: Fragment {
    typealias UnderlyingType = Wrapped.UnderlyingType?
}

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

struct PagingView<Value: Fragment>: View {
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
    private let pageSize: Int?
    private var loader: (Data) -> AnyView

    init(_ paging: Paging<Value>, pageSize: Int?, loader: @escaping (Data) -> AnyView) {
        self.paging = paging
        self.pageSize = pageSize
        self.loader = loader
    }

    var body: some View {
        ForEach((paging.values.enumerated().map { Data.item($0.element, $0.offset) } +
                    [paging.isLoading ? Data.loading : nil, paging.error.map(Data.error)].compactMap { $0 }),
        id: \.id) { data in

            self.loader(data).onAppear { self.onAppear(data: data) }
        }
    }

    private func onAppear(data: Data) {
        guard !paging.isLoading,
            paging.hasMore,
            case let .item(_, index) = data,
            index > paging.values.count - 2 else { return }

        paging.loadMore(pageSize: pageSize)
    }
}

extension PagingView {
    init<Loading: View, Error: View, Data: View>(_ paging: Paging<Value>,
                                                 pageSize: Int? = nil,
                                                 loading loadingView: @escaping () -> Loading,
                                                 error errorView: @escaping (Swift.Error) -> Error,
                                                 item itemView: @escaping (Value) -> Data) {
        self.init(paging, pageSize: pageSize) { data in
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
                                  pageSize: Int? = nil,
                                  error errorView: @escaping (Swift.Error) -> Error,
                                  item itemView: @escaping (Value) -> Data) {
        self.init(paging,
                  pageSize: pageSize,
                  loading: { Text("Loading") },
                  error: errorView,
                  item: itemView)
    }

    init<Loading: View, Data: View>(_ paging: Paging<Value>,
                                    pageSize: Int? = nil,
                                    loading loadingView: @escaping () -> Loading,
                                    item itemView: @escaping (Value) -> Data) {
        self.init(paging,
                  pageSize: pageSize,
                  loading: loadingView,
                  error: { Text("Error: \($0.localizedDescription)") },
                  item: itemView)
    }

    init<Data: View>(_ paging: Paging<Value>,
                     pageSize: Int? = nil,
                     item itemView: @escaping (Value) -> Data) {
        self.init(paging,
                  pageSize: pageSize,
                  loading: { Text("Loading") },
                  error: { Text("Error: \($0.localizedDescription)") },
                  item: itemView)
    }
}

protocol GraphQLValueDecoder {
    associatedtype Encoded
    associatedtype Decoded

    static func decode(encoded: Encoded) throws -> Decoded
}

extension Array: GraphQLValueDecoder where Element: GraphQLValueDecoder {
    static func decode(encoded: [Element.Encoded]) throws -> [Element.Decoded] {
        return try encoded.map { try Element.decode(encoded: $0) }
    }
}

extension Optional: GraphQLValueDecoder where Wrapped: GraphQLValueDecoder {
    static func decode(encoded: Wrapped.Encoded?) throws -> Wrapped.Decoded? {
        return try encoded.map { try Wrapped.decode(encoded: $0) }
    }
}

enum NoOpDecoder<T>: GraphQLValueDecoder {
    static func decode(encoded: T) throws -> T {
        return encoded
    }
}

@propertyWrapper
struct GraphQL<Decoder: GraphQLValueDecoder> {
    var wrappedValue: Decoder.Decoded

    init<T: Target>(_: @autoclosure () -> GraphQLPath<T, Decoder.Encoded>) {
        fatalError("Initializer with path only should never be used")
    }

    init<T: Target, Value>(_: @autoclosure () -> GraphQLPath<T, Value>) where Decoder == NoOpDecoder<Value> {
        fatalError("Initializer with path only should never be used")
    }

    fileprivate init(_ wrappedValue: Decoder.Encoded) {
        self.wrappedValue = try! Decoder.decode(encoded: wrappedValue)
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

extension RawRepresentable {
    fileprivate init<Other: RawRepresentable>(_ other: Other) where Other.RawValue == RawValue {
        guard let value = Self(rawValue: other.rawValue) else { fatalError() }
        self = value
    }
}

extension Optional where Wrapped: RawRepresentable {
    fileprivate init<Other: RawRepresentable>(_ other: Other?) where Other.RawValue == Wrapped.RawValue {
        self = other.map { .init($0) }
    }
}

extension Array where Element: RawRepresentable {
    fileprivate init<Other: RawRepresentable>(_ other: [Other]) where Other.RawValue == Element.RawValue {
        self = other.map { .init($0) }
    }
}

extension Optional {
    fileprivate init<Raw: RawRepresentable, Other: RawRepresentable>(_ other: [Other]?) where Wrapped == [Raw], Other.RawValue == Raw.RawValue {
        self = other.map { .init($0) }
    }
}

extension Array {
    fileprivate init<Raw: RawRepresentable, Other: RawRepresentable>(_ other: [Other?]) where Element == Raw?, Other.RawValue == Raw.RawValue {
        self = other.map { .init($0) }
    }
}

extension Optional {
    fileprivate init<Raw: RawRepresentable, Other: RawRepresentable>(_ other: [Other?]?) where Wrapped == [Raw?], Other.RawValue == Raw.RawValue {
        self = other.map { .init($0) }
    }
}

// MARK: - Music

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

    static var lastFm: FragmentPath<Music.LastFMQuery?> { .init() }

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
                        resource _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.URL?> {
            return .init()
        }

        static var url: FragmentPath<Music.URL?> { .init() }

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

        static var lastFm: FragmentPath<Music.LastFMCountry?> { .init() }

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

        static var url: FragmentPath<URL?> { .init() }

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

        static var url: FragmentPath<URL?> { .init() }

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

        static var theAudioDb: FragmentPath<Music.TheAudioDBArtist?> { .init() }

        static var discogs: FragmentPath<Music.DiscogsArtist?> { .init() }

        static var lastFm: FragmentPath<Music.LastFMArtist?> { .init() }

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

        static var theAudioDb: FragmentPath<Music.TheAudioDBTrack?> { .init() }

        static var lastFm: FragmentPath<Music.LastFMTrack?> { .init() }

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

    enum ReleaseGroupType: String, Target {
        typealias Path<V> = GraphQLPath<ReleaseGroupType, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<ReleaseGroupType, V>

        case album = "ALBUM"

        case single = "SINGLE"

        case ep = "EP"

        case other = "OTHER"

        case broadcast = "BROADCAST"

        case compilation = "COMPILATION"

        case soundtrack = "SOUNDTRACK"

        case spokenword = "SPOKENWORD"

        case interview = "INTERVIEW"

        case audiobook = "AUDIOBOOK"

        case live = "LIVE"

        case remix = "REMIX"

        case djmix = "DJMIX"

        case mixtape = "MIXTAPE"

        case demo = "DEMO"

        case nat = "NAT"

        static var _fragment: FragmentPath<ReleaseGroupType> { .init() }
    }

    enum ReleaseStatus: String, Target {
        typealias Path<V> = GraphQLPath<ReleaseStatus, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<ReleaseStatus, V>

        case official = "OFFICIAL"

        case promotion = "PROMOTION"

        case bootleg = "BOOTLEG"

        case pseudorelease = "PSEUDORELEASE"

        static var _fragment: FragmentPath<ReleaseStatus> { .init() }
    }

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

        static var status: FragmentPath<Music.ReleaseStatus?> { .init() }

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

        static var lastFm: FragmentPath<Music.LastFMAlbum?> { .init() }

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

        static var primaryType: FragmentPath<Music.ReleaseGroupType?> { .init() }

        static var primaryTypeId: Path<String?> { .init() }

        static var secondaryTypes: FragmentPath<[Music.ReleaseGroupType?]?> { .init() }

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

        static var theAudioDb: FragmentPath<Music.TheAudioDBAlbum?> { .init() }

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

    enum CoverArtArchiveImageSize: String, Target {
        typealias Path<V> = GraphQLPath<CoverArtArchiveImageSize, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<CoverArtArchiveImageSize, V>

        case small = "SMALL"

        case large = "LARGE"

        case full = "FULL"

        static var _fragment: FragmentPath<CoverArtArchiveImageSize> { .init() }
    }

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

    enum TheAudioDBAlbum: Target {
        typealias Path<V> = GraphQLPath<TheAudioDBAlbum, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<TheAudioDBAlbum, V>

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

        static func discImage(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        static var discImage: Path<String?> { .init() }

        static func spineImage(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        static var spineImage: Path<String?> { .init() }

        static func frontImage(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        static var frontImage: Path<String?> { .init() }

        static func backImage(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        static var backImage: Path<String?> { .init() }

        static var genre: Path<String?> { .init() }

        static var mood: Path<String?> { .init() }

        static var style: Path<String?> { .init() }

        static var speed: Path<String?> { .init() }

        static var theme: Path<String?> { .init() }

        static var _fragment: FragmentPath<TheAudioDBAlbum> { .init() }
    }

    enum TheAudioDBImageSize: String, Target {
        typealias Path<V> = GraphQLPath<TheAudioDBImageSize, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<TheAudioDBImageSize, V>

        case full = "FULL"

        case preview = "PREVIEW"

        static var _fragment: FragmentPath<TheAudioDBImageSize> { .init() }
    }

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

        static var type: FragmentPath<Music.DiscogsImageType> { .init() }

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

    enum LastFMAlbum: Target {
        typealias Path<V> = GraphQLPath<LastFMAlbum, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<LastFMAlbum, V>

        static var mbid: Path<String?> { .init() }

        static var title: Path<String?> { .init() }

        static var url: Path<String> { .init() }

        static func image(size _: GraphQLArgument<Music.LastFMImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        static var image: Path<String?> { .init() }

        static var listenerCount: Path<Double?> { .init() }

        static var playCount: Path<Double?> { .init() }

        static func description(lang _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMWikiContent?> {
            return .init()
        }

        static var description: FragmentPath<Music.LastFMWikiContent?> { .init() }

        static var artist: FragmentPath<Music.LastFMArtist?> { .init() }

        static func topTags(first _: GraphQLArgument<Int?> = .argument,
                            after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTagConnection?> {
            return .init()
        }

        static var topTags: FragmentPath<Music.LastFMTagConnection?> { .init() }

        static var _fragment: FragmentPath<LastFMAlbum> { .init() }
    }

    enum LastFMImageSize: String, Target {
        typealias Path<V> = GraphQLPath<LastFMImageSize, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<LastFMImageSize, V>

        case small = "SMALL"

        case medium = "MEDIUM"

        case large = "LARGE"

        case extralarge = "EXTRALARGE"

        case mega = "MEGA"

        static var _fragment: FragmentPath<LastFMImageSize> { .init() }
    }

    enum LastFMWikiContent: Target {
        typealias Path<V> = GraphQLPath<LastFMWikiContent, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<LastFMWikiContent, V>

        static var summaryHtml: Path<String?> { .init() }

        static var contentHtml: Path<String?> { .init() }

        static var publishDate: Path<String?> { .init() }

        static var publishTime: Path<String?> { .init() }

        static var url: Path<String?> { .init() }

        static var _fragment: FragmentPath<LastFMWikiContent> { .init() }
    }

    enum LastFMArtist: Target {
        typealias Path<V> = GraphQLPath<LastFMArtist, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<LastFMArtist, V>

        static var mbid: Path<String?> { .init() }

        static var name: Path<String?> { .init() }

        static var url: Path<String> { .init() }

        static func image(size _: GraphQLArgument<Music.LastFMImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        static var image: Path<String?> { .init() }

        static var listenerCount: Path<Double?> { .init() }

        static var playCount: Path<Double?> { .init() }

        static func similarArtists(first _: GraphQLArgument<Int?> = .argument,
                                   after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMArtistConnection?> {
            return .init()
        }

        static var similarArtists: FragmentPath<Music.LastFMArtistConnection?> { .init() }

        static func topAlbums(first _: GraphQLArgument<Int?> = .argument,
                              after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMAlbumConnection?> {
            return .init()
        }

        static var topAlbums: FragmentPath<Music.LastFMAlbumConnection?> { .init() }

        static func topTags(first _: GraphQLArgument<Int?> = .argument,
                            after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTagConnection?> {
            return .init()
        }

        static var topTags: FragmentPath<Music.LastFMTagConnection?> { .init() }

        static func topTracks(first _: GraphQLArgument<Int?> = .argument,
                              after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTrackConnection?> {
            return .init()
        }

        static var topTracks: FragmentPath<Music.LastFMTrackConnection?> { .init() }

        static func biography(lang _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMWikiContent?> {
            return .init()
        }

        static var biography: FragmentPath<Music.LastFMWikiContent?> { .init() }

        static var _fragment: FragmentPath<LastFMArtist> { .init() }
    }

    enum LastFMArtistConnection: Target, Connection {
        typealias Node = Music.LastFMArtist
        typealias Path<V> = GraphQLPath<LastFMArtistConnection, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<LastFMArtistConnection, V>

        static var pageInfo: FragmentPath<Music.PageInfo> { .init() }

        static var edges: FragmentPath<[Music.LastFMArtistEdge?]?> { .init() }

        static var nodes: FragmentPath<[Music.LastFMArtist?]?> { .init() }

        static var totalCount: Path<Int?> { .init() }

        static var _fragment: FragmentPath<LastFMArtistConnection> { .init() }
    }

    enum LastFMArtistEdge: Target {
        typealias Path<V> = GraphQLPath<LastFMArtistEdge, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<LastFMArtistEdge, V>

        static var node: FragmentPath<Music.LastFMArtist?> { .init() }

        static var cursor: Path<String> { .init() }

        static var matchScore: Path<Double?> { .init() }

        static var _fragment: FragmentPath<LastFMArtistEdge> { .init() }
    }

    enum LastFMAlbumConnection: Target, Connection {
        typealias Node = Music.LastFMAlbum
        typealias Path<V> = GraphQLPath<LastFMAlbumConnection, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<LastFMAlbumConnection, V>

        static var pageInfo: FragmentPath<Music.PageInfo> { .init() }

        static var edges: FragmentPath<[Music.LastFMAlbumEdge?]?> { .init() }

        static var nodes: FragmentPath<[Music.LastFMAlbum?]?> { .init() }

        static var totalCount: Path<Int?> { .init() }

        static var _fragment: FragmentPath<LastFMAlbumConnection> { .init() }
    }

    enum LastFMAlbumEdge: Target {
        typealias Path<V> = GraphQLPath<LastFMAlbumEdge, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<LastFMAlbumEdge, V>

        static var node: FragmentPath<Music.LastFMAlbum?> { .init() }

        static var cursor: Path<String> { .init() }

        static var _fragment: FragmentPath<LastFMAlbumEdge> { .init() }
    }

    enum LastFMTagConnection: Target, Connection {
        typealias Node = Music.LastFMTag
        typealias Path<V> = GraphQLPath<LastFMTagConnection, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<LastFMTagConnection, V>

        static var pageInfo: FragmentPath<Music.PageInfo> { .init() }

        static var edges: FragmentPath<[Music.LastFMTagEdge?]?> { .init() }

        static var nodes: FragmentPath<[Music.LastFMTag?]?> { .init() }

        static var totalCount: Path<Int?> { .init() }

        static var _fragment: FragmentPath<LastFMTagConnection> { .init() }
    }

    enum LastFMTagEdge: Target {
        typealias Path<V> = GraphQLPath<LastFMTagEdge, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<LastFMTagEdge, V>

        static var node: FragmentPath<Music.LastFMTag?> { .init() }

        static var cursor: Path<String> { .init() }

        static var tagCount: Path<Int?> { .init() }

        static var _fragment: FragmentPath<LastFMTagEdge> { .init() }
    }

    enum LastFMTag: Target {
        typealias Path<V> = GraphQLPath<LastFMTag, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<LastFMTag, V>

        static var name: Path<String> { .init() }

        static var url: Path<String> { .init() }

        static var _fragment: FragmentPath<LastFMTag> { .init() }
    }

    enum LastFMTrackConnection: Target, Connection {
        typealias Node = Music.LastFMTrack
        typealias Path<V> = GraphQLPath<LastFMTrackConnection, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<LastFMTrackConnection, V>

        static var pageInfo: FragmentPath<Music.PageInfo> { .init() }

        static var edges: FragmentPath<[Music.LastFMTrackEdge?]?> { .init() }

        static var nodes: FragmentPath<[Music.LastFMTrack?]?> { .init() }

        static var totalCount: Path<Int?> { .init() }

        static var _fragment: FragmentPath<LastFMTrackConnection> { .init() }
    }

    enum LastFMTrackEdge: Target {
        typealias Path<V> = GraphQLPath<LastFMTrackEdge, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<LastFMTrackEdge, V>

        static var node: FragmentPath<Music.LastFMTrack?> { .init() }

        static var cursor: Path<String> { .init() }

        static var matchScore: Path<Double?> { .init() }

        static var _fragment: FragmentPath<LastFMTrackEdge> { .init() }
    }

    enum LastFMTrack: Target {
        typealias Path<V> = GraphQLPath<LastFMTrack, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<LastFMTrack, V>

        static var mbid: Path<String?> { .init() }

        static var title: Path<String?> { .init() }

        static var url: Path<String> { .init() }

        static var duration: Path<String?> { .init() }

        static var listenerCount: Path<Double?> { .init() }

        static var playCount: Path<Double?> { .init() }

        static func description(lang _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMWikiContent?> {
            return .init()
        }

        static var description: FragmentPath<Music.LastFMWikiContent?> { .init() }

        static var artist: FragmentPath<Music.LastFMArtist?> { .init() }

        static var album: FragmentPath<Music.LastFMAlbum?> { .init() }

        static func similarTracks(first _: GraphQLArgument<Int?> = .argument,
                                  after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTrackConnection?> {
            return .init()
        }

        static var similarTracks: FragmentPath<Music.LastFMTrackConnection?> { .init() }

        static func topTags(first _: GraphQLArgument<Int?> = .argument,
                            after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTagConnection?> {
            return .init()
        }

        static var topTags: FragmentPath<Music.LastFMTagConnection?> { .init() }

        static var _fragment: FragmentPath<LastFMTrack> { .init() }
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

        static var albumType: FragmentPath<Music.ReleaseGroupType> { .init() }

        static var artists: FragmentPath<[Music.SpotifyArtist]> { .init() }

        static var availableMarkets: Path<[String]> { .init() }

        static var copyrights: FragmentPath<[Music.SpotifyCopyright]> { .init() }

        static var externalIDs: FragmentPath<[Music.SpotifyExternalID]> { .init() }

        static var externalUrLs: FragmentPath<[Music.SpotifyExternalURL]> { .init() }

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

        static var externalUrLs: FragmentPath<[Music.SpotifyExternalURL]> { .init() }

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

    enum SpotifyExternalURL: Target {
        typealias Path<V> = GraphQLPath<SpotifyExternalURL, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<SpotifyExternalURL, V>

        static var type: Path<String> { .init() }

        static var url: Path<String> { .init() }

        static var _fragment: FragmentPath<SpotifyExternalURL> { .init() }
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

        static var externalIDs: FragmentPath<[Music.SpotifyExternalID]> { .init() }

        static var externalUrLs: FragmentPath<[Music.SpotifyExternalURL]> { .init() }

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

        static var mode: FragmentPath<Music.SpotifyTrackMode> { .init() }

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

    enum SpotifyExternalID: Target {
        typealias Path<V> = GraphQLPath<SpotifyExternalID, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<SpotifyExternalID, V>

        static var type: Path<String> { .init() }

        static var id: Path<String> { .init() }

        static var _fragment: FragmentPath<SpotifyExternalID> { .init() }
    }

    enum SpotifyCopyright: Target {
        typealias Path<V> = GraphQLPath<SpotifyCopyright, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<SpotifyCopyright, V>

        static var text: Path<String> { .init() }

        static var type: FragmentPath<Music.SpotifyCopyrightType> { .init() }

        static var _fragment: FragmentPath<SpotifyCopyright> { .init() }
    }

    enum SpotifyCopyrightType: String, Target {
        typealias Path<V> = GraphQLPath<SpotifyCopyrightType, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<SpotifyCopyrightType, V>

        case copyright = "COPYRIGHT"

        case performance = "PERFORMANCE"

        static var _fragment: FragmentPath<SpotifyCopyrightType> { .init() }
    }

    enum TheAudioDBTrack: Target {
        typealias Path<V> = GraphQLPath<TheAudioDBTrack, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<TheAudioDBTrack, V>

        static var trackId: Path<String?> { .init() }

        static var albumId: Path<String?> { .init() }

        static var artistId: Path<String?> { .init() }

        static func description(lang _: GraphQLArgument<String?> = .argument) -> Path<String?> {
            return .init()
        }

        static var description: Path<String?> { .init() }

        static func thumbnail(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        static var thumbnail: Path<String?> { .init() }

        static var score: Path<Double?> { .init() }

        static var scoreVotes: Path<Double?> { .init() }

        static var trackNumber: Path<Int?> { .init() }

        static var musicVideo: FragmentPath<Music.TheAudioDBMusicVideo?> { .init() }

        static var genre: Path<String?> { .init() }

        static var mood: Path<String?> { .init() }

        static var style: Path<String?> { .init() }

        static var theme: Path<String?> { .init() }

        static var _fragment: FragmentPath<TheAudioDBTrack> { .init() }
    }

    enum TheAudioDBMusicVideo: Target {
        typealias Path<V> = GraphQLPath<TheAudioDBMusicVideo, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<TheAudioDBMusicVideo, V>

        static var url: Path<String?> { .init() }

        static var companyName: Path<String?> { .init() }

        static var directorName: Path<String?> { .init() }

        static func screenshots(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<[String?]> {
            return .init()
        }

        static var screenshots: Path<[String?]> { .init() }

        static var viewCount: Path<Double?> { .init() }

        static var likeCount: Path<Double?> { .init() }

        static var dislikeCount: Path<Double?> { .init() }

        static var commentCount: Path<Double?> { .init() }

        static var _fragment: FragmentPath<TheAudioDBMusicVideo> { .init() }
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

    enum TheAudioDBArtist: Target {
        typealias Path<V> = GraphQLPath<TheAudioDBArtist, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<TheAudioDBArtist, V>

        static var artistId: Path<String?> { .init() }

        static func biography(lang _: GraphQLArgument<String?> = .argument) -> Path<String?> {
            return .init()
        }

        static var biography: Path<String?> { .init() }

        static var memberCount: Path<Int?> { .init() }

        static func banner(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        static var banner: Path<String?> { .init() }

        static func fanArt(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<[String?]> {
            return .init()
        }

        static var fanArt: Path<[String?]> { .init() }

        static func logo(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        static var logo: Path<String?> { .init() }

        static func thumbnail(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
            return .init()
        }

        static var thumbnail: Path<String?> { .init() }

        static var genre: Path<String?> { .init() }

        static var mood: Path<String?> { .init() }

        static var style: Path<String?> { .init() }

        static var _fragment: FragmentPath<TheAudioDBArtist> { .init() }
    }

    enum LastFMCountry: Target {
        typealias Path<V> = GraphQLPath<LastFMCountry, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<LastFMCountry, V>

        static func topArtists(first _: GraphQLArgument<Int?> = .argument,
                               after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMArtistConnection?> {
            return .init()
        }

        static var topArtists: FragmentPath<Music.LastFMArtistConnection?> { .init() }

        static func topTracks(first _: GraphQLArgument<Int?> = .argument,
                              after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTrackConnection?> {
            return .init()
        }

        static var topTracks: FragmentPath<Music.LastFMTrackConnection?> { .init() }

        static var _fragment: FragmentPath<LastFMCountry> { .init() }
    }

    enum URL: Target {
        typealias Path<V> = GraphQLPath<URL, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<URL, V>

        static var id: Path<String> { .init() }

        static var mbid: Path<String> { .init() }

        static var resource: Path<String> { .init() }

        static var relationships: FragmentPath<Music.Relationships?> { .init() }

        static var node: FragmentPath<Node> { .init() }

        static var entity: FragmentPath<Entity> { .init() }

        static var _fragment: FragmentPath<URL> { .init() }
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

    enum LastFMQuery: Target {
        typealias Path<V> = GraphQLPath<LastFMQuery, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<LastFMQuery, V>

        static var chart: FragmentPath<Music.LastFMChartQuery> { .init() }

        static var _fragment: FragmentPath<LastFMQuery> { .init() }
    }

    enum LastFMChartQuery: Target {
        typealias Path<V> = GraphQLPath<LastFMChartQuery, V>
        typealias FragmentPath<V> = GraphQLFragmentPath<LastFMChartQuery, V>

        static func topArtists(country _: GraphQLArgument<String?> = .argument,
                               first _: GraphQLArgument<Int?> = .argument,
                               after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMArtistConnection?> {
            return .init()
        }

        static var topArtists: FragmentPath<Music.LastFMArtistConnection?> { .init() }

        static func topTags(first _: GraphQLArgument<Int?> = .argument,
                            after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTagConnection?> {
            return .init()
        }

        static var topTags: FragmentPath<Music.LastFMTagConnection?> { .init() }

        static func topTracks(country _: GraphQLArgument<String?> = .argument,
                              first _: GraphQLArgument<Int?> = .argument,
                              after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTrackConnection?> {
            return .init()
        }

        static var topTracks: FragmentPath<Music.LastFMTrackConnection?> { .init() }

        static var _fragment: FragmentPath<LastFMChartQuery> { .init() }
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
             resource _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.URL?> {
        return .init()
    }

    var url: FragmentPath<Music.URL?> { .init() }

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
             resource _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.URL?> {
        return .init()
    }

    var url: FragmentPath<Music.URL?> { .init() }

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

    var lastFm: FragmentPath<Music.LastFMCountry?> { .init() }

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

    var lastFm: FragmentPath<Music.LastFMCountry?> { .init() }

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

    var url: FragmentPath<Music.URL?> { .init() }
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

    var url: FragmentPath<Music.URL?> { .init() }
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

    var url: FragmentPath<Music.URL?> { .init() }
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

    var url: FragmentPath<Music.URL?> { .init() }
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

    var theAudioDb: FragmentPath<Music.TheAudioDBArtist?> { .init() }

    var discogs: FragmentPath<Music.DiscogsArtist?> { .init() }

    var lastFm: FragmentPath<Music.LastFMArtist?> { .init() }

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

    var theAudioDb: FragmentPath<Music.TheAudioDBArtist?> { .init() }

    var discogs: FragmentPath<Music.DiscogsArtist?> { .init() }

    var lastFm: FragmentPath<Music.LastFMArtist?> { .init() }

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

    var theAudioDb: FragmentPath<Music.TheAudioDBTrack?> { .init() }

    var lastFm: FragmentPath<Music.LastFMTrack?> { .init() }

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

    var theAudioDb: FragmentPath<Music.TheAudioDBTrack?> { .init() }

    var lastFm: FragmentPath<Music.LastFMTrack?> { .init() }

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

    var status: FragmentPath<Music.ReleaseStatus?> { .init() }

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

    var lastFm: FragmentPath<Music.LastFMAlbum?> { .init() }

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

    var status: FragmentPath<Music.ReleaseStatus?> { .init() }

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

    var lastFm: FragmentPath<Music.LastFMAlbum?> { .init() }

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

    var primaryType: FragmentPath<Music.ReleaseGroupType?> { .init() }

    var primaryTypeId: Path<String?> { .init() }

    var secondaryTypes: FragmentPath<[Music.ReleaseGroupType?]?> { .init() }

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

    var theAudioDb: FragmentPath<Music.TheAudioDBAlbum?> { .init() }

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

    var primaryType: FragmentPath<Music.ReleaseGroupType?> { .init() }

    var primaryTypeId: Path<String?> { .init() }

    var secondaryTypes: FragmentPath<[Music.ReleaseGroupType?]?> { .init() }

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

    var theAudioDb: FragmentPath<Music.TheAudioDBAlbum?> { .init() }

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

extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDBAlbum {
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

    func discImage(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
        return .init()
    }

    var discImage: Path<String?> { .init() }

    func spineImage(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
        return .init()
    }

    var spineImage: Path<String?> { .init() }

    func frontImage(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
        return .init()
    }

    var frontImage: Path<String?> { .init() }

    func backImage(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
        return .init()
    }

    var backImage: Path<String?> { .init() }

    var genre: Path<String?> { .init() }

    var mood: Path<String?> { .init() }

    var style: Path<String?> { .init() }

    var speed: Path<String?> { .init() }

    var theme: Path<String?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDBAlbum? {
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

    func discImage(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
        return .init()
    }

    var discImage: Path<String?> { .init() }

    func spineImage(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
        return .init()
    }

    var spineImage: Path<String?> { .init() }

    func frontImage(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
        return .init()
    }

    var frontImage: Path<String?> { .init() }

    func backImage(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
        return .init()
    }

    var backImage: Path<String?> { .init() }

    var genre: Path<String?> { .init() }

    var mood: Path<String?> { .init() }

    var style: Path<String?> { .init() }

    var speed: Path<String?> { .init() }

    var theme: Path<String?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDBImageSize {}

extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDBImageSize? {}

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

    var type: FragmentPath<Music.DiscogsImageType> { .init() }

    var width: Path<Int> { .init() }

    var height: Path<Int> { .init() }

    var thumbnail: Path<String?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsImage? {
    var url: Path<String?> { .init() }

    var type: FragmentPath<Music.DiscogsImageType?> { .init() }

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

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMAlbum {
    var mbid: Path<String?> { .init() }

    var title: Path<String?> { .init() }

    var url: Path<String> { .init() }

    func image(size _: GraphQLArgument<Music.LastFMImageSize?> = .argument) -> Path<String?> {
        return .init()
    }

    var image: Path<String?> { .init() }

    var listenerCount: Path<Double?> { .init() }

    var playCount: Path<Double?> { .init() }

    func description(lang _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMWikiContent?> {
        return .init()
    }

    var description: FragmentPath<Music.LastFMWikiContent?> { .init() }

    var artist: FragmentPath<Music.LastFMArtist?> { .init() }

    func topTags(first _: GraphQLArgument<Int?> = .argument,
                 after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTagConnection?> {
        return .init()
    }

    var topTags: FragmentPath<Music.LastFMTagConnection?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMAlbum? {
    var mbid: Path<String?> { .init() }

    var title: Path<String?> { .init() }

    var url: Path<String?> { .init() }

    func image(size _: GraphQLArgument<Music.LastFMImageSize?> = .argument) -> Path<String?> {
        return .init()
    }

    var image: Path<String?> { .init() }

    var listenerCount: Path<Double?> { .init() }

    var playCount: Path<Double?> { .init() }

    func description(lang _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMWikiContent?> {
        return .init()
    }

    var description: FragmentPath<Music.LastFMWikiContent?> { .init() }

    var artist: FragmentPath<Music.LastFMArtist?> { .init() }

    func topTags(first _: GraphQLArgument<Int?> = .argument,
                 after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTagConnection?> {
        return .init()
    }

    var topTags: FragmentPath<Music.LastFMTagConnection?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMImageSize {}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMImageSize? {}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMWikiContent {
    var summaryHtml: Path<String?> { .init() }

    var contentHtml: Path<String?> { .init() }

    var publishDate: Path<String?> { .init() }

    var publishTime: Path<String?> { .init() }

    var url: Path<String?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMWikiContent? {
    var summaryHtml: Path<String?> { .init() }

    var contentHtml: Path<String?> { .init() }

    var publishDate: Path<String?> { .init() }

    var publishTime: Path<String?> { .init() }

    var url: Path<String?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMArtist {
    var mbid: Path<String?> { .init() }

    var name: Path<String?> { .init() }

    var url: Path<String> { .init() }

    func image(size _: GraphQLArgument<Music.LastFMImageSize?> = .argument) -> Path<String?> {
        return .init()
    }

    var image: Path<String?> { .init() }

    var listenerCount: Path<Double?> { .init() }

    var playCount: Path<Double?> { .init() }

    func similarArtists(first _: GraphQLArgument<Int?> = .argument,
                        after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMArtistConnection?> {
        return .init()
    }

    var similarArtists: FragmentPath<Music.LastFMArtistConnection?> { .init() }

    func topAlbums(first _: GraphQLArgument<Int?> = .argument,
                   after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMAlbumConnection?> {
        return .init()
    }

    var topAlbums: FragmentPath<Music.LastFMAlbumConnection?> { .init() }

    func topTags(first _: GraphQLArgument<Int?> = .argument,
                 after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTagConnection?> {
        return .init()
    }

    var topTags: FragmentPath<Music.LastFMTagConnection?> { .init() }

    func topTracks(first _: GraphQLArgument<Int?> = .argument,
                   after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTrackConnection?> {
        return .init()
    }

    var topTracks: FragmentPath<Music.LastFMTrackConnection?> { .init() }

    func biography(lang _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMWikiContent?> {
        return .init()
    }

    var biography: FragmentPath<Music.LastFMWikiContent?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMArtist? {
    var mbid: Path<String?> { .init() }

    var name: Path<String?> { .init() }

    var url: Path<String?> { .init() }

    func image(size _: GraphQLArgument<Music.LastFMImageSize?> = .argument) -> Path<String?> {
        return .init()
    }

    var image: Path<String?> { .init() }

    var listenerCount: Path<Double?> { .init() }

    var playCount: Path<Double?> { .init() }

    func similarArtists(first _: GraphQLArgument<Int?> = .argument,
                        after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMArtistConnection?> {
        return .init()
    }

    var similarArtists: FragmentPath<Music.LastFMArtistConnection?> { .init() }

    func topAlbums(first _: GraphQLArgument<Int?> = .argument,
                   after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMAlbumConnection?> {
        return .init()
    }

    var topAlbums: FragmentPath<Music.LastFMAlbumConnection?> { .init() }

    func topTags(first _: GraphQLArgument<Int?> = .argument,
                 after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTagConnection?> {
        return .init()
    }

    var topTags: FragmentPath<Music.LastFMTagConnection?> { .init() }

    func topTracks(first _: GraphQLArgument<Int?> = .argument,
                   after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTrackConnection?> {
        return .init()
    }

    var topTracks: FragmentPath<Music.LastFMTrackConnection?> { .init() }

    func biography(lang _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMWikiContent?> {
        return .init()
    }

    var biography: FragmentPath<Music.LastFMWikiContent?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMArtistConnection {
    var pageInfo: FragmentPath<Music.PageInfo> { .init() }

    var edges: FragmentPath<[Music.LastFMArtistEdge?]?> { .init() }

    var nodes: FragmentPath<[Music.LastFMArtist?]?> { .init() }

    var totalCount: Path<Int?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMArtistConnection? {
    var pageInfo: FragmentPath<Music.PageInfo?> { .init() }

    var edges: FragmentPath<[Music.LastFMArtistEdge?]?> { .init() }

    var nodes: FragmentPath<[Music.LastFMArtist?]?> { .init() }

    var totalCount: Path<Int?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMArtistEdge {
    var node: FragmentPath<Music.LastFMArtist?> { .init() }

    var cursor: Path<String> { .init() }

    var matchScore: Path<Double?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMArtistEdge? {
    var node: FragmentPath<Music.LastFMArtist?> { .init() }

    var cursor: Path<String?> { .init() }

    var matchScore: Path<Double?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMAlbumConnection {
    var pageInfo: FragmentPath<Music.PageInfo> { .init() }

    var edges: FragmentPath<[Music.LastFMAlbumEdge?]?> { .init() }

    var nodes: FragmentPath<[Music.LastFMAlbum?]?> { .init() }

    var totalCount: Path<Int?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMAlbumConnection? {
    var pageInfo: FragmentPath<Music.PageInfo?> { .init() }

    var edges: FragmentPath<[Music.LastFMAlbumEdge?]?> { .init() }

    var nodes: FragmentPath<[Music.LastFMAlbum?]?> { .init() }

    var totalCount: Path<Int?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMAlbumEdge {
    var node: FragmentPath<Music.LastFMAlbum?> { .init() }

    var cursor: Path<String> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMAlbumEdge? {
    var node: FragmentPath<Music.LastFMAlbum?> { .init() }

    var cursor: Path<String?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMTagConnection {
    var pageInfo: FragmentPath<Music.PageInfo> { .init() }

    var edges: FragmentPath<[Music.LastFMTagEdge?]?> { .init() }

    var nodes: FragmentPath<[Music.LastFMTag?]?> { .init() }

    var totalCount: Path<Int?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMTagConnection? {
    var pageInfo: FragmentPath<Music.PageInfo?> { .init() }

    var edges: FragmentPath<[Music.LastFMTagEdge?]?> { .init() }

    var nodes: FragmentPath<[Music.LastFMTag?]?> { .init() }

    var totalCount: Path<Int?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMTagEdge {
    var node: FragmentPath<Music.LastFMTag?> { .init() }

    var cursor: Path<String> { .init() }

    var tagCount: Path<Int?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMTagEdge? {
    var node: FragmentPath<Music.LastFMTag?> { .init() }

    var cursor: Path<String?> { .init() }

    var tagCount: Path<Int?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMTag {
    var name: Path<String> { .init() }

    var url: Path<String> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMTag? {
    var name: Path<String?> { .init() }

    var url: Path<String?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMTrackConnection {
    var pageInfo: FragmentPath<Music.PageInfo> { .init() }

    var edges: FragmentPath<[Music.LastFMTrackEdge?]?> { .init() }

    var nodes: FragmentPath<[Music.LastFMTrack?]?> { .init() }

    var totalCount: Path<Int?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMTrackConnection? {
    var pageInfo: FragmentPath<Music.PageInfo?> { .init() }

    var edges: FragmentPath<[Music.LastFMTrackEdge?]?> { .init() }

    var nodes: FragmentPath<[Music.LastFMTrack?]?> { .init() }

    var totalCount: Path<Int?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMTrackEdge {
    var node: FragmentPath<Music.LastFMTrack?> { .init() }

    var cursor: Path<String> { .init() }

    var matchScore: Path<Double?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMTrackEdge? {
    var node: FragmentPath<Music.LastFMTrack?> { .init() }

    var cursor: Path<String?> { .init() }

    var matchScore: Path<Double?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMTrack {
    var mbid: Path<String?> { .init() }

    var title: Path<String?> { .init() }

    var url: Path<String> { .init() }

    var duration: Path<String?> { .init() }

    var listenerCount: Path<Double?> { .init() }

    var playCount: Path<Double?> { .init() }

    func description(lang _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMWikiContent?> {
        return .init()
    }

    var description: FragmentPath<Music.LastFMWikiContent?> { .init() }

    var artist: FragmentPath<Music.LastFMArtist?> { .init() }

    var album: FragmentPath<Music.LastFMAlbum?> { .init() }

    func similarTracks(first _: GraphQLArgument<Int?> = .argument,
                       after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTrackConnection?> {
        return .init()
    }

    var similarTracks: FragmentPath<Music.LastFMTrackConnection?> { .init() }

    func topTags(first _: GraphQLArgument<Int?> = .argument,
                 after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTagConnection?> {
        return .init()
    }

    var topTags: FragmentPath<Music.LastFMTagConnection?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMTrack? {
    var mbid: Path<String?> { .init() }

    var title: Path<String?> { .init() }

    var url: Path<String?> { .init() }

    var duration: Path<String?> { .init() }

    var listenerCount: Path<Double?> { .init() }

    var playCount: Path<Double?> { .init() }

    func description(lang _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMWikiContent?> {
        return .init()
    }

    var description: FragmentPath<Music.LastFMWikiContent?> { .init() }

    var artist: FragmentPath<Music.LastFMArtist?> { .init() }

    var album: FragmentPath<Music.LastFMAlbum?> { .init() }

    func similarTracks(first _: GraphQLArgument<Int?> = .argument,
                       after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTrackConnection?> {
        return .init()
    }

    var similarTracks: FragmentPath<Music.LastFMTrackConnection?> { .init() }

    func topTags(first _: GraphQLArgument<Int?> = .argument,
                 after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTagConnection?> {
        return .init()
    }

    var topTags: FragmentPath<Music.LastFMTagConnection?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyMatchStrategy {}

extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyMatchStrategy? {}

extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyAlbum {
    var albumId: Path<String> { .init() }

    var uri: Path<String> { .init() }

    var href: Path<String> { .init() }

    var title: Path<String?> { .init() }

    var albumType: FragmentPath<Music.ReleaseGroupType> { .init() }

    var artists: FragmentPath<[Music.SpotifyArtist]> { .init() }

    var availableMarkets: Path<[String]> { .init() }

    var copyrights: FragmentPath<[Music.SpotifyCopyright]> { .init() }

    var externalIDs: FragmentPath<[Music.SpotifyExternalID]> { .init() }

    var externalUrLs: FragmentPath<[Music.SpotifyExternalURL]> { .init() }

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

    var albumType: FragmentPath<Music.ReleaseGroupType?> { .init() }

    var artists: FragmentPath<[Music.SpotifyArtist]?> { .init() }

    var availableMarkets: Path<[String]?> { .init() }

    var copyrights: FragmentPath<[Music.SpotifyCopyright]?> { .init() }

    var externalIDs: FragmentPath<[Music.SpotifyExternalID]?> { .init() }

    var externalUrLs: FragmentPath<[Music.SpotifyExternalURL]?> { .init() }

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

    var externalUrLs: FragmentPath<[Music.SpotifyExternalURL]> { .init() }

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

    var externalUrLs: FragmentPath<[Music.SpotifyExternalURL]?> { .init() }

    var genres: Path<[String]?> { .init() }

    var popularity: Path<Int?> { .init() }

    var images: FragmentPath<[Music.SpotifyImage]?> { .init() }

    func topTracks(market _: GraphQLArgument<String> = .argument) -> FragmentPath<[Music.SpotifyTrack]?> {
        return .init()
    }

    var topTracks: FragmentPath<[Music.SpotifyTrack]?> { .init() }

    var relatedArtists: FragmentPath<[Music.SpotifyArtist]?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyExternalURL {
    var type: Path<String> { .init() }

    var url: Path<String> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyExternalURL? {
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

    var externalIDs: FragmentPath<[Music.SpotifyExternalID]> { .init() }

    var externalUrLs: FragmentPath<[Music.SpotifyExternalURL]> { .init() }

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

    var externalIDs: FragmentPath<[Music.SpotifyExternalID]?> { .init() }

    var externalUrLs: FragmentPath<[Music.SpotifyExternalURL]?> { .init() }

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

    var mode: FragmentPath<Music.SpotifyTrackMode> { .init() }

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

    var mode: FragmentPath<Music.SpotifyTrackMode?> { .init() }

    var speechiness: Path<Double?> { .init() }

    var tempo: Path<Double?> { .init() }

    var timeSignature: Path<Double?> { .init() }

    var valence: Path<Double?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyTrackMode {}

extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyTrackMode? {}

extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyExternalID {
    var type: Path<String> { .init() }

    var id: Path<String> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyExternalID? {
    var type: Path<String?> { .init() }

    var id: Path<String?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyCopyright {
    var text: Path<String> { .init() }

    var type: FragmentPath<Music.SpotifyCopyrightType> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyCopyright? {
    var text: Path<String?> { .init() }

    var type: FragmentPath<Music.SpotifyCopyrightType?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyCopyrightType {}

extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyCopyrightType? {}

extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDBTrack {
    var trackId: Path<String?> { .init() }

    var albumId: Path<String?> { .init() }

    var artistId: Path<String?> { .init() }

    func description(lang _: GraphQLArgument<String?> = .argument) -> Path<String?> {
        return .init()
    }

    var description: Path<String?> { .init() }

    func thumbnail(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
        return .init()
    }

    var thumbnail: Path<String?> { .init() }

    var score: Path<Double?> { .init() }

    var scoreVotes: Path<Double?> { .init() }

    var trackNumber: Path<Int?> { .init() }

    var musicVideo: FragmentPath<Music.TheAudioDBMusicVideo?> { .init() }

    var genre: Path<String?> { .init() }

    var mood: Path<String?> { .init() }

    var style: Path<String?> { .init() }

    var theme: Path<String?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDBTrack? {
    var trackId: Path<String?> { .init() }

    var albumId: Path<String?> { .init() }

    var artistId: Path<String?> { .init() }

    func description(lang _: GraphQLArgument<String?> = .argument) -> Path<String?> {
        return .init()
    }

    var description: Path<String?> { .init() }

    func thumbnail(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
        return .init()
    }

    var thumbnail: Path<String?> { .init() }

    var score: Path<Double?> { .init() }

    var scoreVotes: Path<Double?> { .init() }

    var trackNumber: Path<Int?> { .init() }

    var musicVideo: FragmentPath<Music.TheAudioDBMusicVideo?> { .init() }

    var genre: Path<String?> { .init() }

    var mood: Path<String?> { .init() }

    var style: Path<String?> { .init() }

    var theme: Path<String?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDBMusicVideo {
    var url: Path<String?> { .init() }

    var companyName: Path<String?> { .init() }

    var directorName: Path<String?> { .init() }

    func screenshots(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<[String?]> {
        return .init()
    }

    var screenshots: Path<[String?]> { .init() }

    var viewCount: Path<Double?> { .init() }

    var likeCount: Path<Double?> { .init() }

    var dislikeCount: Path<Double?> { .init() }

    var commentCount: Path<Double?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDBMusicVideo? {
    var url: Path<String?> { .init() }

    var companyName: Path<String?> { .init() }

    var directorName: Path<String?> { .init() }

    func screenshots(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<[String?]?> {
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

extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDBArtist {
    var artistId: Path<String?> { .init() }

    func biography(lang _: GraphQLArgument<String?> = .argument) -> Path<String?> {
        return .init()
    }

    var biography: Path<String?> { .init() }

    var memberCount: Path<Int?> { .init() }

    func banner(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
        return .init()
    }

    var banner: Path<String?> { .init() }

    func fanArt(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<[String?]> {
        return .init()
    }

    var fanArt: Path<[String?]> { .init() }

    func logo(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
        return .init()
    }

    var logo: Path<String?> { .init() }

    func thumbnail(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
        return .init()
    }

    var thumbnail: Path<String?> { .init() }

    var genre: Path<String?> { .init() }

    var mood: Path<String?> { .init() }

    var style: Path<String?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDBArtist? {
    var artistId: Path<String?> { .init() }

    func biography(lang _: GraphQLArgument<String?> = .argument) -> Path<String?> {
        return .init()
    }

    var biography: Path<String?> { .init() }

    var memberCount: Path<Int?> { .init() }

    func banner(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
        return .init()
    }

    var banner: Path<String?> { .init() }

    func fanArt(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<[String?]?> {
        return .init()
    }

    var fanArt: Path<[String?]?> { .init() }

    func logo(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
        return .init()
    }

    var logo: Path<String?> { .init() }

    func thumbnail(size _: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument) -> Path<String?> {
        return .init()
    }

    var thumbnail: Path<String?> { .init() }

    var genre: Path<String?> { .init() }

    var mood: Path<String?> { .init() }

    var style: Path<String?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMCountry {
    func topArtists(first _: GraphQLArgument<Int?> = .argument,
                    after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMArtistConnection?> {
        return .init()
    }

    var topArtists: FragmentPath<Music.LastFMArtistConnection?> { .init() }

    func topTracks(first _: GraphQLArgument<Int?> = .argument,
                   after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTrackConnection?> {
        return .init()
    }

    var topTracks: FragmentPath<Music.LastFMTrackConnection?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMCountry? {
    func topArtists(first _: GraphQLArgument<Int?> = .argument,
                    after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMArtistConnection?> {
        return .init()
    }

    var topArtists: FragmentPath<Music.LastFMArtistConnection?> { .init() }

    func topTracks(first _: GraphQLArgument<Int?> = .argument,
                   after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTrackConnection?> {
        return .init()
    }

    var topTracks: FragmentPath<Music.LastFMTrackConnection?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.URL {
    var id: Path<String> { .init() }

    var mbid: Path<String> { .init() }

    var resource: Path<String> { .init() }

    var relationships: FragmentPath<Music.Relationships?> { .init() }

    var node: FragmentPath<Music.Node> { .init() }

    var entity: FragmentPath<Music.Entity> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.URL? {
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

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMQuery {
    var chart: FragmentPath<Music.LastFMChartQuery> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMQuery? {
    var chart: FragmentPath<Music.LastFMChartQuery?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMChartQuery {
    func topArtists(country _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument,
                    after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMArtistConnection?> {
        return .init()
    }

    var topArtists: FragmentPath<Music.LastFMArtistConnection?> { .init() }

    func topTags(first _: GraphQLArgument<Int?> = .argument,
                 after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTagConnection?> {
        return .init()
    }

    var topTags: FragmentPath<Music.LastFMTagConnection?> { .init() }

    func topTracks(country _: GraphQLArgument<String?> = .argument,
                   first _: GraphQLArgument<Int?> = .argument,
                   after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTrackConnection?> {
        return .init()
    }

    var topTracks: FragmentPath<Music.LastFMTrackConnection?> { .init() }
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMChartQuery? {
    func topArtists(country _: GraphQLArgument<String?> = .argument,
                    first _: GraphQLArgument<Int?> = .argument,
                    after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMArtistConnection?> {
        return .init()
    }

    var topArtists: FragmentPath<Music.LastFMArtistConnection?> { .init() }

    func topTags(first _: GraphQLArgument<Int?> = .argument,
                 after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTagConnection?> {
        return .init()
    }

    var topTags: FragmentPath<Music.LastFMTagConnection?> { .init() }

    func topTracks(country _: GraphQLArgument<String?> = .argument,
                   first _: GraphQLArgument<Int?> = .argument,
                   after _: GraphQLArgument<String?> = .argument) -> FragmentPath<Music.LastFMTrackConnection?> {
        return .init()
    }

    var topTracks: FragmentPath<Music.LastFMTrackConnection?> { .init() }
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

// MARK: - AlbumArtistCreditButton

extension ApolloStuff.AlbumArtistCreditButtonArtist: Fragment {
    typealias UnderlyingType = Music.Artist
}

extension AlbumArtistCreditButton {
    typealias Artist = ApolloStuff.AlbumArtistCreditButtonArtist

    init(api: Music,
         artist: Artist) {
        self.init(api: api,
                  id: GraphQL(artist.mbid),
                  name: GraphQL(artist.name))
    }
}

// MARK: - AlbumTrackCellCredit

extension ApolloStuff.AlbumTrackCellCreditArtistCredit: Fragment {
    typealias UnderlyingType = Music.ArtistCredit
}

extension AlbumTrackCellCredit {
    typealias ArtistCredit = ApolloStuff.AlbumTrackCellCreditArtistCredit

    init(artistCredit: ArtistCredit) {
        self.init(name: GraphQL(artistCredit.name),
                  joinPhrase: GraphQL(artistCredit.joinPhrase))
    }
}

// MARK: - ArtistAlbumCell

extension ApolloStuff.ArtistAlbumCellReleaseGroup: Fragment {
    typealias UnderlyingType = Music.ReleaseGroup
}

extension ArtistAlbumCell {
    typealias ReleaseGroup = ApolloStuff.ArtistAlbumCellReleaseGroup

    init(api: Music,
         releaseGroup: ReleaseGroup) {
        self.init(api: api,
                  title: GraphQL(releaseGroup.title),
                  cover: GraphQL(releaseGroup.theAudioDb?.frontImage),
                  discImage: GraphQL(releaseGroup.theAudioDb?.frontImage),
                  releaseIds: GraphQL(releaseGroup.releases?.nodes?.map { $0?.mbid }))
    }
}

// MARK: - SimilarArtistCell

extension ApolloStuff.SimilarArtistCellLastFmArtist: Fragment {
    typealias UnderlyingType = Music.LastFMArtist
}

extension SimilarArtistCell {
    typealias LastFMArtist = ApolloStuff.SimilarArtistCellLastFmArtist

    init(api: Music,
         lastFmArtist: LastFMArtist) {
        self.init(api: api,
                  id: GraphQL(lastFmArtist.mbid),
                  name: GraphQL(lastFmArtist.name),
                  images: GraphQL(lastFmArtist.topAlbums?.nodes?.map { $0?.image }))
    }
}

// MARK: - TrendingArtistCell

extension ApolloStuff.TrendingArtistCellLastFmArtist: Fragment {
    typealias UnderlyingType = Music.LastFMArtist
}

extension TrendingArtistCell {
    typealias LastFMArtist = ApolloStuff.TrendingArtistCellLastFmArtist

    init(api: Music,
         lastFmArtist: LastFMArtist) {
        self.init(api: api,
                  id: GraphQL(lastFmArtist.mbid),
                  name: GraphQL(lastFmArtist.name),
                  tags: GraphQL(lastFmArtist.topTags?.nodes?.map { $0?.name }),
                  images: GraphQL(lastFmArtist.topAlbums?.nodes?.map { $0?.image }),
                  mostFamousSongs: GraphQL(lastFmArtist.topTracks?.nodes?.map { $0?.title }))
    }
}

// MARK: - TrendingTrackCell

extension ApolloStuff.TrendingTrackCellLastFmTrack: Fragment {
    typealias UnderlyingType = Music.LastFMTrack
}

extension TrendingTrackCell {
    typealias LastFMTrack = ApolloStuff.TrendingTrackCellLastFmTrack

    init(api: Music,
         lastFmTrack: LastFMTrack) {
        self.init(api: api,
                  title: GraphQL(lastFmTrack.title),
                  artist: GraphQL(lastFmTrack.artist?.name),
                  image: GraphQL(lastFmTrack.album?.image),
                  albumId: GraphQL(lastFmTrack.album?.mbid))
    }
}

// MARK: - TrendingArtistsList

extension TrendingArtistsList {
    typealias Data = ApolloStuff.TrendingArtistsListQuery.Data

    init(api: Music,
         artists: Paging<TrendingArtistCell.LastFMArtist>?,
         tracks: Paging<TrendingTrackCell.LastFMTrack>?,
         data _: Data) {
        self.init(api: api,
                  artists: GraphQL(artists),
                  tracks: GraphQL(tracks))
    }
}

extension Music {
    func trendingArtistsList(country: String? = nil,
                             first: Int? = 25,
                             after: String? = nil,
                             size: Music.LastFMImageSize? = nil) -> some View {
        return QueryRenderer(client: client,
                             query: ApolloStuff.TrendingArtistsListQuery(country: country,
                                                                         first: first,
                                                                         after: after,
                                                                         LastFMTagConnection_first: 3,
                                                                         LastFMAlbumConnection_first: 4,
                                                                         size: .init(size),
                                                                         LastFMTrackConnection_first: 1)) { (data: ApolloStuff.TrendingArtistsListQuery.Data) -> TrendingArtistsList in

            TrendingArtistsList(api: self,
                                artists: data.lastFm?.chart.topArtists?.fragments.lastFmArtistConnectionTrendingArtistCellLastFmArtist.paging { _cursor, _pageSize, _completion in
                                    self.client.fetch(query: ApolloStuff.TrendingArtistsListArtistsLastFmArtistConnectionTrendingArtistCellLastFmArtistQuery(country: country,
                                                                                                                                                             first: _pageSize ?? first,
                                                                                                                                                             after: _cursor,
                                                                                                                                                             LastFMTagConnection_first: 3,
                                                                                                                                                             LastFMAlbumConnection_first: 4,
                                                                                                                                                             size: .init(size),
                                                                                                                                                             LastFMTrackConnection_first: 1)) { result in
                                        _completion(result.map { $0.data?.lastFm?.chart.topArtists?.fragments.lastFmArtistConnectionTrendingArtistCellLastFmArtist })
                                    }
                                },
                                
                                tracks: data.lastFm?.chart.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack.paging { _cursor, _pageSize, _completion in
                                    self.client.fetch(query: ApolloStuff.TrendingArtistsListTracksLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery(country: country,
                                                                                                                                                         first: _pageSize ?? first,
                                                                                                                                                         after: _cursor,
                                                                                                                                                         size: .init(size))) { result in
                                        _completion(result.map { $0.data?.lastFm?.chart.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack })
                                    }
                                },
                                
                                data: data)
        }
    }
}

extension ApolloStuff.TrendingArtistsListQuery.Data.LastFm.Chart.TopArtist {
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

extension ApolloStuff.TrendingArtistsListQuery.Data.LastFm.Chart.TopTrack {
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

extension ApolloStuff.TrendingArtistsListArtistsLastFmArtistConnectionTrendingArtistCellLastFmArtistQuery.Data.LastFm.Chart.TopArtist {
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

extension ApolloStuff.TrendingArtistsListTracksLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery.Data.LastFm.Chart.TopTrack {
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

extension ApolloStuff.TrendingArtistsListQuery.Data.LastFm.Chart.TopArtist.Fragments {
    public var lastFmArtistConnectionTrendingArtistCellLastFmArtist: ApolloStuff.LastFmArtistConnectionTrendingArtistCellLastFmArtist {
        get {
            return ApolloStuff.LastFmArtistConnectionTrendingArtistCellLastFmArtist(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }
}

extension ApolloStuff.TrendingArtistsListQuery.Data.LastFm.Chart.TopTrack.Fragments {
    public var lastFmTrackConnectionTrendingTrackCellLastFmTrack: ApolloStuff.LastFmTrackConnectionTrendingTrackCellLastFmTrack {
        get {
            return ApolloStuff.LastFmTrackConnectionTrendingTrackCellLastFmTrack(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }
}

extension ApolloStuff.TrendingArtistsListArtistsLastFmArtistConnectionTrendingArtistCellLastFmArtistQuery.Data.LastFm.Chart.TopArtist.Fragments {
    public var lastFmArtistConnectionTrendingArtistCellLastFmArtist: ApolloStuff.LastFmArtistConnectionTrendingArtistCellLastFmArtist {
        get {
            return ApolloStuff.LastFmArtistConnectionTrendingArtistCellLastFmArtist(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }
}

extension ApolloStuff.TrendingArtistsListTracksLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery.Data.LastFm.Chart.TopTrack.Fragments {
    public var lastFmTrackConnectionTrendingTrackCellLastFmTrack: ApolloStuff.LastFmTrackConnectionTrendingTrackCellLastFmTrack {
        get {
            return ApolloStuff.LastFmTrackConnectionTrendingTrackCellLastFmTrack(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }
}

// MARK: - AlbumTrackCell

extension ApolloStuff.AlbumTrackCellTrack: Fragment {
    typealias UnderlyingType = Music.Track
}

extension AlbumTrackCell {
    typealias Track = ApolloStuff.AlbumTrackCellTrack

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
}

// MARK: - ArtistDetailView

extension ArtistDetailView {
    typealias Data = ApolloStuff.ArtistDetailViewQuery.Data

    init(api: Music,
         topSongs: Paging<TrendingTrackCell.LastFMTrack>?,
         albums: Paging<ArtistAlbumCell.ReleaseGroup>?,
         singles: Paging<ArtistAlbumCell.ReleaseGroup>?,
         similarArtists: Paging<SimilarArtistCell.LastFMArtist>?,
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
                  mood: GraphQL(data.lookup?.artist?.theAudioDb?.mood),
                  similarArtists: GraphQL(similarArtists))
    }
}

extension Music {
    func artistDetailView(mbid: String,
                          size: Music.TheAudioDBImageSize? = Music.TheAudioDBImageSize.full,
                          after: String? = nil,
                          urlStringSize: Music.LastFMImageSize? = nil,
                          releaseConnectionFirst: Int? = nil,
                          lang: String? = "en") -> some View {
        return QueryRenderer(client: client,
                             query: ApolloStuff.ArtistDetailViewQuery(mbid: mbid,
                                                                      size: .init(size),
                                                                      first: 5,
                                                                      after: after,
                                                                      URLString_size: .init(urlStringSize),
                                                                      type: [.album],
                                                                      status: [.official],
                                                                      ReleaseConnection_first: releaseConnectionFirst,
                                                                      ReleaseGroupConnection_type: [.single],
                                                                      lang: lang,
                                                                      LastFMArtistConnection_first: 3,
                                                                      LastFMAlbumConnection_first: 1)) { (data: ApolloStuff.ArtistDetailViewQuery.Data) -> ArtistDetailView in

            ArtistDetailView(api: self,
                             topSongs: data.lookup?.artist?.lastFm?.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack.paging { _cursor, _pageSize, _completion in
                                 self.client.fetch(query: ApolloStuff.ArtistDetailViewTopSongsLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery(mbid: mbid,
                                                                                                                                                     first: _pageSize ?? 5,
                                                                                                                                                     after: _cursor,
                                                                                                                                                     URLString_size: .init(urlStringSize))) { result in
                                     _completion(result.map { $0.data?.lookup?.artist?.lastFm?.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack })
                                 }
                             },
                             
                             albums: data.lookup?.artist?.releaseGroups?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup.paging { _cursor, _pageSize, _completion in
                                 self.client.fetch(query: ApolloStuff.ArtistDetailViewAlbumsReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery(mbid: mbid,
                                                                                                                                                   type: [.album],
                                                                                                                                                   after: _cursor,
                                                                                                                                                   first: _pageSize ?? 5,
                                                                                                                                                   size: .init(size),
                                                                                                                                                   status: [.official],
                                                                                                                                                   ReleaseConnection_first: releaseConnectionFirst)) { result in
                                     _completion(result.map { $0.data?.lookup?.artist?.releaseGroups?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup })
                                 }
                             },
                             
                             singles: data.lookup?.artist?.releaseGroups1?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup.paging { _cursor, _pageSize, _completion in
                                 self.client.fetch(query: ApolloStuff.ArtistDetailViewSinglesReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery(mbid: mbid,
                                                                                                                                                    ReleaseGroupConnection_type: [.single],
                                                                                                                                                    after: _cursor,
                                                                                                                                                    first: _pageSize ?? 5,
                                                                                                                                                    size: .init(size),
                                                                                                                                                    type: [.album],
                                                                                                                                                    status: [.official],
                                                                                                                                                    ReleaseConnection_first: releaseConnectionFirst)) { result in
                                     _completion(result.map { $0.data?.lookup?.artist?.releaseGroups1?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup })
                                 }
                             },
                             
                             similarArtists: data.lookup?.artist?.lastFm?.similarArtists?.fragments.lastFmArtistConnectionSimilarArtistCellLastFmArtist.paging { _cursor, _, _completion in
                                 self.client.fetch(query: ApolloStuff.ArtistDetailViewSimilarArtistsLastFmArtistConnectionSimilarArtistCellLastFmArtistQuery(mbid: mbid,
                                                                                                                                                             LastFMArtistConnection_first: 3,
                                                                                                                                                             after: _cursor,
                                                                                                                                                             LastFMAlbumConnection_first: 1,
                                                                                                                                                             URLString_size: .init(urlStringSize))) { result in
                                     _completion(result.map { $0.data?.lookup?.artist?.lastFm?.similarArtists?.fragments.lastFmArtistConnectionSimilarArtistCellLastFmArtist })
                                 }
                             },
                             
                             data: data)
        }
    }
}

extension ApolloStuff.ArtistDetailViewQuery.Data.Lookup.Artist.LastFm.SimilarArtist {
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

extension ApolloStuff.ArtistDetailViewQuery.Data.Lookup.Artist.LastFm.TopTrack {
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

extension ApolloStuff.ArtistDetailViewQuery.Data.Lookup.Artist.ReleaseGroups1 {
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

extension ApolloStuff.ArtistDetailViewQuery.Data.Lookup.Artist.ReleaseGroup {
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

extension ApolloStuff.ArtistDetailViewTopSongsLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery.Data.Lookup.Artist.LastFm.TopTrack {
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

extension ApolloStuff.ArtistDetailViewAlbumsReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery.Data.Lookup.Artist.ReleaseGroup {
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

extension ApolloStuff.ArtistDetailViewSinglesReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery.Data.Lookup.Artist.ReleaseGroups1 {
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

extension ApolloStuff.ArtistDetailViewSimilarArtistsLastFmArtistConnectionSimilarArtistCellLastFmArtistQuery.Data.Lookup.Artist.LastFm.SimilarArtist {
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

extension ApolloStuff.ArtistDetailViewQuery.Data.Lookup.Artist.LastFm.SimilarArtist.Fragments {
    public var lastFmArtistConnectionSimilarArtistCellLastFmArtist: ApolloStuff.LastFmArtistConnectionSimilarArtistCellLastFmArtist {
        get {
            return ApolloStuff.LastFmArtistConnectionSimilarArtistCellLastFmArtist(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }
}

extension ApolloStuff.ArtistDetailViewQuery.Data.Lookup.Artist.LastFm.TopTrack.Fragments {
    public var lastFmTrackConnectionTrendingTrackCellLastFmTrack: ApolloStuff.LastFmTrackConnectionTrendingTrackCellLastFmTrack {
        get {
            return ApolloStuff.LastFmTrackConnectionTrendingTrackCellLastFmTrack(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }
}

extension ApolloStuff.ArtistDetailViewQuery.Data.Lookup.Artist.ReleaseGroups1.Fragments {
    public var releaseGroupConnectionArtistAlbumCellReleaseGroup: ApolloStuff.ReleaseGroupConnectionArtistAlbumCellReleaseGroup {
        get {
            return ApolloStuff.ReleaseGroupConnectionArtistAlbumCellReleaseGroup(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }
}

extension ApolloStuff.ArtistDetailViewQuery.Data.Lookup.Artist.ReleaseGroup.Fragments {
    public var releaseGroupConnectionArtistAlbumCellReleaseGroup: ApolloStuff.ReleaseGroupConnectionArtistAlbumCellReleaseGroup {
        get {
            return ApolloStuff.ReleaseGroupConnectionArtistAlbumCellReleaseGroup(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }
}

extension ApolloStuff.ArtistDetailViewTopSongsLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery.Data.Lookup.Artist.LastFm.TopTrack.Fragments {
    public var lastFmTrackConnectionTrendingTrackCellLastFmTrack: ApolloStuff.LastFmTrackConnectionTrendingTrackCellLastFmTrack {
        get {
            return ApolloStuff.LastFmTrackConnectionTrendingTrackCellLastFmTrack(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }
}

extension ApolloStuff.ArtistDetailViewAlbumsReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery.Data.Lookup.Artist.ReleaseGroup.Fragments {
    public var releaseGroupConnectionArtistAlbumCellReleaseGroup: ApolloStuff.ReleaseGroupConnectionArtistAlbumCellReleaseGroup {
        get {
            return ApolloStuff.ReleaseGroupConnectionArtistAlbumCellReleaseGroup(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }
}

extension ApolloStuff.ArtistDetailViewSinglesReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery.Data.Lookup.Artist.ReleaseGroups1.Fragments {
    public var releaseGroupConnectionArtistAlbumCellReleaseGroup: ApolloStuff.ReleaseGroupConnectionArtistAlbumCellReleaseGroup {
        get {
            return ApolloStuff.ReleaseGroupConnectionArtistAlbumCellReleaseGroup(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }
}

extension ApolloStuff.ArtistDetailViewSimilarArtistsLastFmArtistConnectionSimilarArtistCellLastFmArtistQuery.Data.Lookup.Artist.LastFm.SimilarArtist.Fragments {
    public var lastFmArtistConnectionSimilarArtistCellLastFmArtist: ApolloStuff.LastFmArtistConnectionSimilarArtistCellLastFmArtist {
        get {
            return ApolloStuff.LastFmArtistConnectionSimilarArtistCellLastFmArtist(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }
}

// MARK: - AlbumDetailView

extension AlbumDetailView {
    typealias Data = ApolloStuff.AlbumDetailViewQuery.Data

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
}

extension Music {
    func albumDetailView(mbid: String) -> some View {
        return QueryRenderer(client: client,
                             query: ApolloStuff.AlbumDetailViewQuery(mbid: mbid,
                                                                     size: .small)) { (data: ApolloStuff.AlbumDetailViewQuery.Data) -> AlbumDetailView in

            AlbumDetailView(api: self,
                            data: data)
        }
    }
}

extension ApolloStuff.LastFmArtistConnectionTrendingArtistCellLastFmArtist {
    typealias Completion = (Result<ApolloStuff.LastFmArtistConnectionTrendingArtistCellLastFmArtist?, Error>) -> Void
    typealias Loader = (String, Int?, @escaping Completion) -> Void

    private var response: Paging<ApolloStuff.TrendingArtistCellLastFmArtist>.Response {
        return Paging.Response(values: edges?.compactMap { $0?.node?.fragments.trendingArtistCellLastFmArtist } ?? [],
                               cursor: pageInfo.endCursor,
                               hasMore: pageInfo.hasNextPage)
    }

    fileprivate func paging(loader: @escaping Loader) -> Paging<ApolloStuff.TrendingArtistCellLastFmArtist> {
        return Paging(response) { cursor, pageSize, completion in
            loader(cursor, pageSize) { result in
                completion(result.map { $0?.response ?? .empty })
            }
        }
    }
}

extension ApolloStuff.LastFmArtistConnectionTrendingArtistCellLastFmArtist.Edge.Node {
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

extension ApolloStuff.LastFmArtistConnectionTrendingArtistCellLastFmArtist.Edge.Node.Fragments {
    public var trendingArtistCellLastFmArtist: ApolloStuff.TrendingArtistCellLastFmArtist {
        get {
            return ApolloStuff.TrendingArtistCellLastFmArtist(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }
}

extension ApolloStuff.LastFmTrackConnectionTrendingTrackCellLastFmTrack {
    typealias Completion = (Result<ApolloStuff.LastFmTrackConnectionTrendingTrackCellLastFmTrack?, Error>) -> Void
    typealias Loader = (String, Int?, @escaping Completion) -> Void

    private var response: Paging<ApolloStuff.TrendingTrackCellLastFmTrack>.Response {
        return Paging.Response(values: edges?.compactMap { $0?.node?.fragments.trendingTrackCellLastFmTrack } ?? [],
                               cursor: pageInfo.endCursor,
                               hasMore: pageInfo.hasNextPage)
    }

    fileprivate func paging(loader: @escaping Loader) -> Paging<ApolloStuff.TrendingTrackCellLastFmTrack> {
        return Paging(response) { cursor, pageSize, completion in
            loader(cursor, pageSize) { result in
                completion(result.map { $0?.response ?? .empty })
            }
        }
    }
}

extension ApolloStuff.LastFmTrackConnectionTrendingTrackCellLastFmTrack.Edge.Node {
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

extension ApolloStuff.LastFmTrackConnectionTrendingTrackCellLastFmTrack.Edge.Node.Fragments {
    public var trendingTrackCellLastFmTrack: ApolloStuff.TrendingTrackCellLastFmTrack {
        get {
            return ApolloStuff.TrendingTrackCellLastFmTrack(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }
}

extension ApolloStuff.ReleaseGroupConnectionArtistAlbumCellReleaseGroup {
    typealias Completion = (Result<ApolloStuff.ReleaseGroupConnectionArtistAlbumCellReleaseGroup?, Error>) -> Void
    typealias Loader = (String, Int?, @escaping Completion) -> Void

    private var response: Paging<ApolloStuff.ArtistAlbumCellReleaseGroup>.Response {
        return Paging.Response(values: edges?.compactMap { $0?.node?.fragments.artistAlbumCellReleaseGroup } ?? [],
                               cursor: pageInfo.endCursor,
                               hasMore: pageInfo.hasNextPage)
    }

    fileprivate func paging(loader: @escaping Loader) -> Paging<ApolloStuff.ArtistAlbumCellReleaseGroup> {
        return Paging(response) { cursor, pageSize, completion in
            loader(cursor, pageSize) { result in
                completion(result.map { $0?.response ?? .empty })
            }
        }
    }
}

extension ApolloStuff.ReleaseGroupConnectionArtistAlbumCellReleaseGroup.Edge.Node {
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

extension ApolloStuff.ReleaseGroupConnectionArtistAlbumCellReleaseGroup.Edge.Node.Fragments {
    public var artistAlbumCellReleaseGroup: ApolloStuff.ArtistAlbumCellReleaseGroup {
        get {
            return ApolloStuff.ArtistAlbumCellReleaseGroup(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }
}

extension ApolloStuff.LastFmArtistConnectionSimilarArtistCellLastFmArtist {
    typealias Completion = (Result<ApolloStuff.LastFmArtistConnectionSimilarArtistCellLastFmArtist?, Error>) -> Void
    typealias Loader = (String, Int?, @escaping Completion) -> Void

    private var response: Paging<ApolloStuff.SimilarArtistCellLastFmArtist>.Response {
        return Paging.Response(values: edges?.compactMap { $0?.node?.fragments.similarArtistCellLastFmArtist } ?? [],
                               cursor: pageInfo.endCursor,
                               hasMore: pageInfo.hasNextPage)
    }

    fileprivate func paging(loader: @escaping Loader) -> Paging<ApolloStuff.SimilarArtistCellLastFmArtist> {
        return Paging(response) { cursor, pageSize, completion in
            loader(cursor, pageSize) { result in
                completion(result.map { $0?.response ?? .empty })
            }
        }
    }
}

extension ApolloStuff.LastFmArtistConnectionSimilarArtistCellLastFmArtist.Edge.Node {
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

extension ApolloStuff.LastFmArtistConnectionSimilarArtistCellLastFmArtist.Edge.Node.Fragments {
    public var similarArtistCellLastFmArtist: ApolloStuff.SimilarArtistCellLastFmArtist {
        get {
            return ApolloStuff.SimilarArtistCellLastFmArtist(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }
}

//  This file was automatically generated and should not be edited.

import Apollo
import Foundation

/// ApolloStuff namespace
public enum ApolloStuff {
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
            case let .__unknown(value): return value
            }
        }

        public static func == (lhs: LastFMImageSize, rhs: LastFMImageSize) -> Bool {
            switch (lhs, rhs) {
            case (.small, .small): return true
            case (.medium, .medium): return true
            case (.large, .large): return true
            case (.extralarge, .extralarge): return true
            case (.mega, .mega): return true
            case let (.__unknown(lhsValue), .__unknown(rhsValue)): return lhsValue == rhsValue
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
            case let .__unknown(value): return value
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
            case let (.__unknown(lhsValue), .__unknown(rhsValue)): return lhsValue == rhsValue
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
            case let .__unknown(value): return value
            }
        }

        public static func == (lhs: TheAudioDBImageSize, rhs: TheAudioDBImageSize) -> Bool {
            switch (lhs, rhs) {
            case (.full, .full): return true
            case (.preview, .preview): return true
            case let (.__unknown(lhsValue), .__unknown(rhsValue)): return lhsValue == rhsValue
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
            case let .__unknown(value): return value
            }
        }

        public static func == (lhs: ReleaseStatus, rhs: ReleaseStatus) -> Bool {
            switch (lhs, rhs) {
            case (.official, .official): return true
            case (.promotion, .promotion): return true
            case (.bootleg, .bootleg): return true
            case (.pseudorelease, .pseudorelease): return true
            case let (.__unknown(lhsValue), .__unknown(rhsValue)): return lhsValue == rhsValue
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
            case let .__unknown(value): return value
            }
        }

        public static func == (lhs: CoverArtArchiveImageSize, rhs: CoverArtArchiveImageSize) -> Bool {
            switch (lhs, rhs) {
            case (.small, .small): return true
            case (.large, .large): return true
            case (.full, .full): return true
            case let (.__unknown(lhsValue), .__unknown(rhsValue)): return lhsValue == rhsValue
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
        public let operationDefinition =
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

        public let operationName = "TrendingArtistsListArtistsLastFMArtistConnectionTrendingArtistCellLastFMArtist"

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
            public static let possibleTypes = ["Query"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("lastFM", type: .object(LastFm.selections)),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
                public static let possibleTypes = ["LastFMQuery"]

                public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("chart", type: .nonNull(.object(Chart.selections))),
                ]

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                    resultMap = unsafeResultMap
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
                    public static let possibleTypes = ["LastFMChartQuery"]

                    public static let selections: [GraphQLSelection] = [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("topArtists", arguments: ["after": GraphQLVariable("after"), "country": GraphQLVariable("country"), "first": GraphQLVariable("first")], type: .object(TopArtist.selections)),
                    ]

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                        resultMap = unsafeResultMap
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
                        public static let possibleTypes = ["LastFMArtistConnection"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("edges", type: .list(.object(Edge.selections))),
                            GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
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
                            public static let possibleTypes = ["LastFMArtistEdge"]

                            public static let selections: [GraphQLSelection] = [
                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                GraphQLField("node", type: .object(Node.selections)),
                            ]

                            public private(set) var resultMap: ResultMap

                            public init(unsafeResultMap: ResultMap) {
                                resultMap = unsafeResultMap
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
                                public static let possibleTypes = ["LastFMArtist"]

                                public static let selections: [GraphQLSelection] = [
                                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                    GraphQLField("mbid", type: .scalar(String.self)),
                                    GraphQLField("name", type: .scalar(String.self)),
                                    GraphQLField("topAlbums", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("LastFMAlbumConnection_first")], type: .object(TopAlbum.selections)),
                                    GraphQLField("topTags", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("LastFMTagConnection_first")], type: .object(TopTag.selections)),
                                    GraphQLField("topTracks", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("LastFMTrackConnection_first")], type: .object(TopTrack.selections)),
                                ]

                                public private(set) var resultMap: ResultMap

                                public init(unsafeResultMap: ResultMap) {
                                    resultMap = unsafeResultMap
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
                                    public static let possibleTypes = ["LastFMAlbumConnection"]

                                    public static let selections: [GraphQLSelection] = [
                                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                        GraphQLField("nodes", type: .list(.object(Node.selections))),
                                    ]

                                    public private(set) var resultMap: ResultMap

                                    public init(unsafeResultMap: ResultMap) {
                                        resultMap = unsafeResultMap
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
                                        public static let possibleTypes = ["LastFMAlbum"]

                                        public static let selections: [GraphQLSelection] = [
                                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                            GraphQLField("image", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                                        ]

                                        public private(set) var resultMap: ResultMap

                                        public init(unsafeResultMap: ResultMap) {
                                            resultMap = unsafeResultMap
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
                                    public static let possibleTypes = ["LastFMTagConnection"]

                                    public static let selections: [GraphQLSelection] = [
                                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                        GraphQLField("nodes", type: .list(.object(Node.selections))),
                                    ]

                                    public private(set) var resultMap: ResultMap

                                    public init(unsafeResultMap: ResultMap) {
                                        resultMap = unsafeResultMap
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
                                        public static let possibleTypes = ["LastFMTag"]

                                        public static let selections: [GraphQLSelection] = [
                                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                            GraphQLField("name", type: .nonNull(.scalar(String.self))),
                                        ]

                                        public private(set) var resultMap: ResultMap

                                        public init(unsafeResultMap: ResultMap) {
                                            resultMap = unsafeResultMap
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
                                    public static let possibleTypes = ["LastFMTrackConnection"]

                                    public static let selections: [GraphQLSelection] = [
                                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                        GraphQLField("nodes", type: .list(.object(Node.selections))),
                                    ]

                                    public private(set) var resultMap: ResultMap

                                    public init(unsafeResultMap: ResultMap) {
                                        resultMap = unsafeResultMap
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
                                        public static let possibleTypes = ["LastFMTrack"]

                                        public static let selections: [GraphQLSelection] = [
                                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                            GraphQLField("title", type: .scalar(String.self)),
                                        ]

                                        public private(set) var resultMap: ResultMap

                                        public init(unsafeResultMap: ResultMap) {
                                            resultMap = unsafeResultMap
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
                            public static let possibleTypes = ["PageInfo"]

                            public static let selections: [GraphQLSelection] = [
                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                GraphQLField("endCursor", type: .scalar(String.self)),
                                GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                            ]

                            public private(set) var resultMap: ResultMap

                            public init(unsafeResultMap: ResultMap) {
                                resultMap = unsafeResultMap
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
        public let operationDefinition =
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

        public let operationName = "TrendingArtistsListTracksLastFMTrackConnectionTrendingTrackCellLastFMTrack"

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
            public static let possibleTypes = ["Query"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("lastFM", type: .object(LastFm.selections)),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
                public static let possibleTypes = ["LastFMQuery"]

                public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("chart", type: .nonNull(.object(Chart.selections))),
                ]

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                    resultMap = unsafeResultMap
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
                    public static let possibleTypes = ["LastFMChartQuery"]

                    public static let selections: [GraphQLSelection] = [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("topTracks", arguments: ["after": GraphQLVariable("after"), "country": GraphQLVariable("country"), "first": GraphQLVariable("first")], type: .object(TopTrack.selections)),
                    ]

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                        resultMap = unsafeResultMap
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
                        public static let possibleTypes = ["LastFMTrackConnection"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("edges", type: .list(.object(Edge.selections))),
                            GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
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
                            public static let possibleTypes = ["LastFMTrackEdge"]

                            public static let selections: [GraphQLSelection] = [
                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                GraphQLField("node", type: .object(Node.selections)),
                            ]

                            public private(set) var resultMap: ResultMap

                            public init(unsafeResultMap: ResultMap) {
                                resultMap = unsafeResultMap
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
                                public static let possibleTypes = ["LastFMTrack"]

                                public static let selections: [GraphQLSelection] = [
                                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                    GraphQLField("album", type: .object(Album.selections)),
                                    GraphQLField("artist", type: .object(Artist.selections)),
                                    GraphQLField("title", type: .scalar(String.self)),
                                ]

                                public private(set) var resultMap: ResultMap

                                public init(unsafeResultMap: ResultMap) {
                                    resultMap = unsafeResultMap
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
                                    public static let possibleTypes = ["LastFMAlbum"]

                                    public static let selections: [GraphQLSelection] = [
                                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                        GraphQLField("image", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                                        GraphQLField("mbid", type: .scalar(String.self)),
                                    ]

                                    public private(set) var resultMap: ResultMap

                                    public init(unsafeResultMap: ResultMap) {
                                        resultMap = unsafeResultMap
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
                                    public static let possibleTypes = ["LastFMArtist"]

                                    public static let selections: [GraphQLSelection] = [
                                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                        GraphQLField("name", type: .scalar(String.self)),
                                    ]

                                    public private(set) var resultMap: ResultMap

                                    public init(unsafeResultMap: ResultMap) {
                                        resultMap = unsafeResultMap
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
                            public static let possibleTypes = ["PageInfo"]

                            public static let selections: [GraphQLSelection] = [
                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                GraphQLField("endCursor", type: .scalar(String.self)),
                                GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                            ]

                            public private(set) var resultMap: ResultMap

                            public init(unsafeResultMap: ResultMap) {
                                resultMap = unsafeResultMap
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
        public let operationDefinition =
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

        public let operationName = "ArtistDetailViewTopSongsLastFMTrackConnectionTrendingTrackCellLastFMTrack"

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
            public static let possibleTypes = ["Query"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("lookup", type: .object(Lookup.selections)),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
                public static let possibleTypes = ["LookupQuery"]

                public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("artist", arguments: ["mbid": GraphQLVariable("mbid")], type: .object(Artist.selections)),
                ]

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                    resultMap = unsafeResultMap
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
                    public static let possibleTypes = ["Artist"]

                    public static let selections: [GraphQLSelection] = [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("lastFM", type: .object(LastFm.selections)),
                    ]

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                        resultMap = unsafeResultMap
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
                        public static let possibleTypes = ["LastFMArtist"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("topTracks", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first")], type: .object(TopTrack.selections)),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
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
                            public static let possibleTypes = ["LastFMTrackConnection"]

                            public static let selections: [GraphQLSelection] = [
                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                GraphQLField("edges", type: .list(.object(Edge.selections))),
                                GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
                            ]

                            public private(set) var resultMap: ResultMap

                            public init(unsafeResultMap: ResultMap) {
                                resultMap = unsafeResultMap
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
                                public static let possibleTypes = ["LastFMTrackEdge"]

                                public static let selections: [GraphQLSelection] = [
                                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                    GraphQLField("node", type: .object(Node.selections)),
                                ]

                                public private(set) var resultMap: ResultMap

                                public init(unsafeResultMap: ResultMap) {
                                    resultMap = unsafeResultMap
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
                                    public static let possibleTypes = ["LastFMTrack"]

                                    public static let selections: [GraphQLSelection] = [
                                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                        GraphQLField("album", type: .object(Album.selections)),
                                        GraphQLField("artist", type: .object(Artist.selections)),
                                        GraphQLField("title", type: .scalar(String.self)),
                                    ]

                                    public private(set) var resultMap: ResultMap

                                    public init(unsafeResultMap: ResultMap) {
                                        resultMap = unsafeResultMap
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
                                        public static let possibleTypes = ["LastFMAlbum"]

                                        public static let selections: [GraphQLSelection] = [
                                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                            GraphQLField("image", arguments: ["size": GraphQLVariable("URLString_size")], type: .scalar(String.self)),
                                            GraphQLField("mbid", type: .scalar(String.self)),
                                        ]

                                        public private(set) var resultMap: ResultMap

                                        public init(unsafeResultMap: ResultMap) {
                                            resultMap = unsafeResultMap
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
                                        public static let possibleTypes = ["LastFMArtist"]

                                        public static let selections: [GraphQLSelection] = [
                                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                            GraphQLField("name", type: .scalar(String.self)),
                                        ]

                                        public private(set) var resultMap: ResultMap

                                        public init(unsafeResultMap: ResultMap) {
                                            resultMap = unsafeResultMap
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
                                public static let possibleTypes = ["PageInfo"]

                                public static let selections: [GraphQLSelection] = [
                                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                    GraphQLField("endCursor", type: .scalar(String.self)),
                                    GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                                ]

                                public private(set) var resultMap: ResultMap

                                public init(unsafeResultMap: ResultMap) {
                                    resultMap = unsafeResultMap
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
        public let operationDefinition =
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

        public let operationName = "ArtistDetailViewAlbumsReleaseGroupConnectionArtistAlbumCellReleaseGroup"

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
            public static let possibleTypes = ["Query"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("lookup", type: .object(Lookup.selections)),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
                public static let possibleTypes = ["LookupQuery"]

                public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("artist", arguments: ["mbid": GraphQLVariable("mbid")], type: .object(Artist.selections)),
                ]

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                    resultMap = unsafeResultMap
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
                    public static let possibleTypes = ["Artist"]

                    public static let selections: [GraphQLSelection] = [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("releaseGroups", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first"), "type": GraphQLVariable("type")], type: .object(ReleaseGroup.selections)),
                    ]

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                        resultMap = unsafeResultMap
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
                        public static let possibleTypes = ["ReleaseGroupConnection"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("edges", type: .list(.object(Edge.selections))),
                            GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
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
                            public static let possibleTypes = ["ReleaseGroupEdge"]

                            public static let selections: [GraphQLSelection] = [
                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                GraphQLField("node", type: .object(Node.selections)),
                            ]

                            public private(set) var resultMap: ResultMap

                            public init(unsafeResultMap: ResultMap) {
                                resultMap = unsafeResultMap
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
                                public static let possibleTypes = ["ReleaseGroup"]

                                public static let selections: [GraphQLSelection] = [
                                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                    GraphQLField("releases", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("ReleaseConnection_first"), "status": GraphQLVariable("status"), "type": GraphQLVariable("type")], type: .object(Release.selections)),
                                    GraphQLField("theAudioDB", type: .object(TheAudioDb.selections)),
                                    GraphQLField("title", type: .scalar(String.self)),
                                ]

                                public private(set) var resultMap: ResultMap

                                public init(unsafeResultMap: ResultMap) {
                                    resultMap = unsafeResultMap
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
                                    public static let possibleTypes = ["ReleaseConnection"]

                                    public static let selections: [GraphQLSelection] = [
                                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                        GraphQLField("nodes", type: .list(.object(Node.selections))),
                                    ]

                                    public private(set) var resultMap: ResultMap

                                    public init(unsafeResultMap: ResultMap) {
                                        resultMap = unsafeResultMap
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
                                        public static let possibleTypes = ["Release"]

                                        public static let selections: [GraphQLSelection] = [
                                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                            GraphQLField("mbid", type: .nonNull(.scalar(String.self))),
                                        ]

                                        public private(set) var resultMap: ResultMap

                                        public init(unsafeResultMap: ResultMap) {
                                            resultMap = unsafeResultMap
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
                                    public static let possibleTypes = ["TheAudioDBAlbum"]

                                    public static let selections: [GraphQLSelection] = [
                                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                        GraphQLField("frontImage", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                                    ]

                                    public private(set) var resultMap: ResultMap

                                    public init(unsafeResultMap: ResultMap) {
                                        resultMap = unsafeResultMap
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
                            public static let possibleTypes = ["PageInfo"]

                            public static let selections: [GraphQLSelection] = [
                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                GraphQLField("endCursor", type: .scalar(String.self)),
                                GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                            ]

                            public private(set) var resultMap: ResultMap

                            public init(unsafeResultMap: ResultMap) {
                                resultMap = unsafeResultMap
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
        public let operationDefinition =
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

        public let operationName = "ArtistDetailViewSinglesReleaseGroupConnectionArtistAlbumCellReleaseGroup"

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
            public static let possibleTypes = ["Query"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("lookup", type: .object(Lookup.selections)),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
                public static let possibleTypes = ["LookupQuery"]

                public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("artist", arguments: ["mbid": GraphQLVariable("mbid")], type: .object(Artist.selections)),
                ]

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                    resultMap = unsafeResultMap
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
                    public static let possibleTypes = ["Artist"]

                    public static let selections: [GraphQLSelection] = [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("releaseGroups", alias: "releaseGroups1", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first"), "type": GraphQLVariable("ReleaseGroupConnection_type")], type: .object(ReleaseGroups1.selections)),
                    ]

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                        resultMap = unsafeResultMap
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
                        public static let possibleTypes = ["ReleaseGroupConnection"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("edges", type: .list(.object(Edge.selections))),
                            GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
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
                            public static let possibleTypes = ["ReleaseGroupEdge"]

                            public static let selections: [GraphQLSelection] = [
                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                GraphQLField("node", type: .object(Node.selections)),
                            ]

                            public private(set) var resultMap: ResultMap

                            public init(unsafeResultMap: ResultMap) {
                                resultMap = unsafeResultMap
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
                                public static let possibleTypes = ["ReleaseGroup"]

                                public static let selections: [GraphQLSelection] = [
                                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                    GraphQLField("releases", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("ReleaseConnection_first"), "status": GraphQLVariable("status"), "type": GraphQLVariable("type")], type: .object(Release.selections)),
                                    GraphQLField("theAudioDB", type: .object(TheAudioDb.selections)),
                                    GraphQLField("title", type: .scalar(String.self)),
                                ]

                                public private(set) var resultMap: ResultMap

                                public init(unsafeResultMap: ResultMap) {
                                    resultMap = unsafeResultMap
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
                                    public static let possibleTypes = ["ReleaseConnection"]

                                    public static let selections: [GraphQLSelection] = [
                                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                        GraphQLField("nodes", type: .list(.object(Node.selections))),
                                    ]

                                    public private(set) var resultMap: ResultMap

                                    public init(unsafeResultMap: ResultMap) {
                                        resultMap = unsafeResultMap
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
                                        public static let possibleTypes = ["Release"]

                                        public static let selections: [GraphQLSelection] = [
                                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                            GraphQLField("mbid", type: .nonNull(.scalar(String.self))),
                                        ]

                                        public private(set) var resultMap: ResultMap

                                        public init(unsafeResultMap: ResultMap) {
                                            resultMap = unsafeResultMap
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
                                    public static let possibleTypes = ["TheAudioDBAlbum"]

                                    public static let selections: [GraphQLSelection] = [
                                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                        GraphQLField("frontImage", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                                    ]

                                    public private(set) var resultMap: ResultMap

                                    public init(unsafeResultMap: ResultMap) {
                                        resultMap = unsafeResultMap
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
                            public static let possibleTypes = ["PageInfo"]

                            public static let selections: [GraphQLSelection] = [
                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                GraphQLField("endCursor", type: .scalar(String.self)),
                                GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                            ]

                            public private(set) var resultMap: ResultMap

                            public init(unsafeResultMap: ResultMap) {
                                resultMap = unsafeResultMap
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

    public final class ArtistDetailViewSimilarArtistsLastFmArtistConnectionSimilarArtistCellLastFmArtistQuery: GraphQLQuery {
        /// The raw GraphQL definition of this operation.
        public let operationDefinition =
            """
            query ArtistDetailViewSimilarArtistsLastFMArtistConnectionSimilarArtistCellLastFMArtist($mbid: MBID!, $LastFMArtistConnection_first: Int, $after: String, $LastFMAlbumConnection_first: Int, $URLString_size: LastFMImageSize) {
              lookup {
                __typename
                artist(mbid: $mbid) {
                  __typename
                  lastFM {
                    __typename
                    similarArtists(after: $after, first: $LastFMArtistConnection_first) {
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
                              image(size: $URLString_size)
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
            }
            """

        public let operationName = "ArtistDetailViewSimilarArtistsLastFMArtistConnectionSimilarArtistCellLastFMArtist"

        public var mbid: String
        public var LastFMArtistConnection_first: Int?
        public var after: String?
        public var LastFMAlbumConnection_first: Int?
        public var URLString_size: LastFMImageSize?

        public init(mbid: String, LastFMArtistConnection_first: Int? = nil, after: String? = nil, LastFMAlbumConnection_first: Int? = nil, URLString_size: LastFMImageSize? = nil) {
            self.mbid = mbid
            self.LastFMArtistConnection_first = LastFMArtistConnection_first
            self.after = after
            self.LastFMAlbumConnection_first = LastFMAlbumConnection_first
            self.URLString_size = URLString_size
        }

        public var variables: GraphQLMap? {
            return ["mbid": mbid, "LastFMArtistConnection_first": LastFMArtistConnection_first, "after": after, "LastFMAlbumConnection_first": LastFMAlbumConnection_first, "URLString_size": URLString_size]
        }

        public struct Data: GraphQLSelectionSet {
            public static let possibleTypes = ["Query"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("lookup", type: .object(Lookup.selections)),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
                public static let possibleTypes = ["LookupQuery"]

                public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("artist", arguments: ["mbid": GraphQLVariable("mbid")], type: .object(Artist.selections)),
                ]

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                    resultMap = unsafeResultMap
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
                    public static let possibleTypes = ["Artist"]

                    public static let selections: [GraphQLSelection] = [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("lastFM", type: .object(LastFm.selections)),
                    ]

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                        resultMap = unsafeResultMap
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
                        public static let possibleTypes = ["LastFMArtist"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("similarArtists", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("LastFMArtistConnection_first")], type: .object(SimilarArtist.selections)),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
                        }

                        public init(similarArtists: SimilarArtist? = nil) {
                            self.init(unsafeResultMap: ["__typename": "LastFMArtist", "similarArtists": similarArtists.flatMap { (value: SimilarArtist) -> ResultMap in value.resultMap }])
                        }

                        public var __typename: String {
                            get {
                                return resultMap["__typename"]! as! String
                            }
                            set {
                                resultMap.updateValue(newValue, forKey: "__typename")
                            }
                        }

                        /// A list of similar artists.
                        public var similarArtists: SimilarArtist? {
                            get {
                                return (resultMap["similarArtists"] as? ResultMap).flatMap { SimilarArtist(unsafeResultMap: $0) }
                            }
                            set {
                                resultMap.updateValue(newValue?.resultMap, forKey: "similarArtists")
                            }
                        }

                        public struct SimilarArtist: GraphQLSelectionSet {
                            public static let possibleTypes = ["LastFMArtistConnection"]

                            public static let selections: [GraphQLSelection] = [
                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                GraphQLField("edges", type: .list(.object(Edge.selections))),
                                GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
                            ]

                            public private(set) var resultMap: ResultMap

                            public init(unsafeResultMap: ResultMap) {
                                resultMap = unsafeResultMap
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
                                public static let possibleTypes = ["LastFMArtistEdge"]

                                public static let selections: [GraphQLSelection] = [
                                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                    GraphQLField("node", type: .object(Node.selections)),
                                ]

                                public private(set) var resultMap: ResultMap

                                public init(unsafeResultMap: ResultMap) {
                                    resultMap = unsafeResultMap
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
                                    public static let possibleTypes = ["LastFMArtist"]

                                    public static let selections: [GraphQLSelection] = [
                                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                        GraphQLField("mbid", type: .scalar(String.self)),
                                        GraphQLField("name", type: .scalar(String.self)),
                                        GraphQLField("topAlbums", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("LastFMAlbumConnection_first")], type: .object(TopAlbum.selections)),
                                    ]

                                    public private(set) var resultMap: ResultMap

                                    public init(unsafeResultMap: ResultMap) {
                                        resultMap = unsafeResultMap
                                    }

                                    public init(mbid: String? = nil, name: String? = nil, topAlbums: TopAlbum? = nil) {
                                        self.init(unsafeResultMap: ["__typename": "LastFMArtist", "mbid": mbid, "name": name, "topAlbums": topAlbums.flatMap { (value: TopAlbum) -> ResultMap in value.resultMap }])
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

                                    public struct TopAlbum: GraphQLSelectionSet {
                                        public static let possibleTypes = ["LastFMAlbumConnection"]

                                        public static let selections: [GraphQLSelection] = [
                                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                            GraphQLField("nodes", type: .list(.object(Node.selections))),
                                        ]

                                        public private(set) var resultMap: ResultMap

                                        public init(unsafeResultMap: ResultMap) {
                                            resultMap = unsafeResultMap
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
                                            public static let possibleTypes = ["LastFMAlbum"]

                                            public static let selections: [GraphQLSelection] = [
                                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                                GraphQLField("image", arguments: ["size": GraphQLVariable("URLString_size")], type: .scalar(String.self)),
                                            ]

                                            public private(set) var resultMap: ResultMap

                                            public init(unsafeResultMap: ResultMap) {
                                                resultMap = unsafeResultMap
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
                                }
                            }

                            public struct PageInfo: GraphQLSelectionSet {
                                public static let possibleTypes = ["PageInfo"]

                                public static let selections: [GraphQLSelection] = [
                                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                    GraphQLField("endCursor", type: .scalar(String.self)),
                                    GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                                ]

                                public private(set) var resultMap: ResultMap

                                public init(unsafeResultMap: ResultMap) {
                                    resultMap = unsafeResultMap
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

    public final class TrendingArtistsListQuery: GraphQLQuery {
        /// The raw GraphQL definition of this operation.
        public let operationDefinition =
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

        public let operationName = "TrendingArtistsList"

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
            public static let possibleTypes = ["Query"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("lastFM", type: .object(LastFm.selections)),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
                public static let possibleTypes = ["LastFMQuery"]

                public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("chart", type: .nonNull(.object(Chart.selections))),
                ]

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                    resultMap = unsafeResultMap
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
                    public static let possibleTypes = ["LastFMChartQuery"]

                    public static let selections: [GraphQLSelection] = [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("topArtists", arguments: ["after": GraphQLVariable("after"), "country": GraphQLVariable("country"), "first": GraphQLVariable("first")], type: .object(TopArtist.selections)),
                        GraphQLField("topTracks", arguments: ["after": GraphQLVariable("after"), "country": GraphQLVariable("country"), "first": GraphQLVariable("first")], type: .object(TopTrack.selections)),
                    ]

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                        resultMap = unsafeResultMap
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
                        public static let possibleTypes = ["LastFMArtistConnection"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("edges", type: .list(.object(Edge.selections))),
                            GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
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
                            public static let possibleTypes = ["LastFMArtistEdge"]

                            public static let selections: [GraphQLSelection] = [
                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                GraphQLField("node", type: .object(Node.selections)),
                            ]

                            public private(set) var resultMap: ResultMap

                            public init(unsafeResultMap: ResultMap) {
                                resultMap = unsafeResultMap
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
                                public static let possibleTypes = ["LastFMArtist"]

                                public static let selections: [GraphQLSelection] = [
                                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                    GraphQLField("mbid", type: .scalar(String.self)),
                                    GraphQLField("name", type: .scalar(String.self)),
                                    GraphQLField("topAlbums", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("LastFMAlbumConnection_first")], type: .object(TopAlbum.selections)),
                                    GraphQLField("topTags", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("LastFMTagConnection_first")], type: .object(TopTag.selections)),
                                    GraphQLField("topTracks", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("LastFMTrackConnection_first")], type: .object(TopTrack.selections)),
                                ]

                                public private(set) var resultMap: ResultMap

                                public init(unsafeResultMap: ResultMap) {
                                    resultMap = unsafeResultMap
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
                                    public static let possibleTypes = ["LastFMAlbumConnection"]

                                    public static let selections: [GraphQLSelection] = [
                                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                        GraphQLField("nodes", type: .list(.object(Node.selections))),
                                    ]

                                    public private(set) var resultMap: ResultMap

                                    public init(unsafeResultMap: ResultMap) {
                                        resultMap = unsafeResultMap
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
                                        public static let possibleTypes = ["LastFMAlbum"]

                                        public static let selections: [GraphQLSelection] = [
                                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                            GraphQLField("image", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                                        ]

                                        public private(set) var resultMap: ResultMap

                                        public init(unsafeResultMap: ResultMap) {
                                            resultMap = unsafeResultMap
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
                                    public static let possibleTypes = ["LastFMTagConnection"]

                                    public static let selections: [GraphQLSelection] = [
                                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                        GraphQLField("nodes", type: .list(.object(Node.selections))),
                                    ]

                                    public private(set) var resultMap: ResultMap

                                    public init(unsafeResultMap: ResultMap) {
                                        resultMap = unsafeResultMap
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
                                        public static let possibleTypes = ["LastFMTag"]

                                        public static let selections: [GraphQLSelection] = [
                                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                            GraphQLField("name", type: .nonNull(.scalar(String.self))),
                                        ]

                                        public private(set) var resultMap: ResultMap

                                        public init(unsafeResultMap: ResultMap) {
                                            resultMap = unsafeResultMap
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
                                    public static let possibleTypes = ["LastFMTrackConnection"]

                                    public static let selections: [GraphQLSelection] = [
                                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                        GraphQLField("nodes", type: .list(.object(Node.selections))),
                                    ]

                                    public private(set) var resultMap: ResultMap

                                    public init(unsafeResultMap: ResultMap) {
                                        resultMap = unsafeResultMap
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
                                        public static let possibleTypes = ["LastFMTrack"]

                                        public static let selections: [GraphQLSelection] = [
                                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                            GraphQLField("title", type: .scalar(String.self)),
                                        ]

                                        public private(set) var resultMap: ResultMap

                                        public init(unsafeResultMap: ResultMap) {
                                            resultMap = unsafeResultMap
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
                            public static let possibleTypes = ["PageInfo"]

                            public static let selections: [GraphQLSelection] = [
                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                GraphQLField("endCursor", type: .scalar(String.self)),
                                GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                            ]

                            public private(set) var resultMap: ResultMap

                            public init(unsafeResultMap: ResultMap) {
                                resultMap = unsafeResultMap
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
                        public static let possibleTypes = ["LastFMTrackConnection"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("edges", type: .list(.object(Edge.selections))),
                            GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
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
                            public static let possibleTypes = ["LastFMTrackEdge"]

                            public static let selections: [GraphQLSelection] = [
                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                GraphQLField("node", type: .object(Node.selections)),
                            ]

                            public private(set) var resultMap: ResultMap

                            public init(unsafeResultMap: ResultMap) {
                                resultMap = unsafeResultMap
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
                                public static let possibleTypes = ["LastFMTrack"]

                                public static let selections: [GraphQLSelection] = [
                                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                    GraphQLField("album", type: .object(Album.selections)),
                                    GraphQLField("artist", type: .object(Artist.selections)),
                                    GraphQLField("title", type: .scalar(String.self)),
                                ]

                                public private(set) var resultMap: ResultMap

                                public init(unsafeResultMap: ResultMap) {
                                    resultMap = unsafeResultMap
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
                                    public static let possibleTypes = ["LastFMAlbum"]

                                    public static let selections: [GraphQLSelection] = [
                                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                        GraphQLField("image", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                                        GraphQLField("mbid", type: .scalar(String.self)),
                                    ]

                                    public private(set) var resultMap: ResultMap

                                    public init(unsafeResultMap: ResultMap) {
                                        resultMap = unsafeResultMap
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
                                    public static let possibleTypes = ["LastFMArtist"]

                                    public static let selections: [GraphQLSelection] = [
                                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                        GraphQLField("name", type: .scalar(String.self)),
                                    ]

                                    public private(set) var resultMap: ResultMap

                                    public init(unsafeResultMap: ResultMap) {
                                        resultMap = unsafeResultMap
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
                            public static let possibleTypes = ["PageInfo"]

                            public static let selections: [GraphQLSelection] = [
                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                GraphQLField("endCursor", type: .scalar(String.self)),
                                GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                            ]

                            public private(set) var resultMap: ResultMap

                            public init(unsafeResultMap: ResultMap) {
                                resultMap = unsafeResultMap
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
        public let operationDefinition =
            """
            query ArtistDetailView($mbid: MBID!, $size: TheAudioDBImageSize, $first: Int, $after: String, $URLString_size: LastFMImageSize, $type: [ReleaseGroupType], $status: [ReleaseStatus], $ReleaseConnection_first: Int, $ReleaseGroupConnection_type: [ReleaseGroupType], $lang: String, $LastFMArtistConnection_first: Int, $LastFMAlbumConnection_first: Int) {
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
                    similarArtists(after: $after, first: $LastFMArtistConnection_first) {
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
                              image(size: $URLString_size)
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

        public let operationName = "ArtistDetailView"

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
        public var LastFMArtistConnection_first: Int?
        public var LastFMAlbumConnection_first: Int?

        public init(mbid: String, size: TheAudioDBImageSize? = nil, first: Int? = nil, after: String? = nil, URLString_size: LastFMImageSize? = nil, type: [ReleaseGroupType?]? = nil, status: [ReleaseStatus?]? = nil, ReleaseConnection_first: Int? = nil, ReleaseGroupConnection_type: [ReleaseGroupType?]? = nil, lang: String? = nil, LastFMArtistConnection_first: Int? = nil, LastFMAlbumConnection_first: Int? = nil) {
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
            self.LastFMArtistConnection_first = LastFMArtistConnection_first
            self.LastFMAlbumConnection_first = LastFMAlbumConnection_first
        }

        public var variables: GraphQLMap? {
            return ["mbid": mbid, "size": size, "first": first, "after": after, "URLString_size": URLString_size, "type": type, "status": status, "ReleaseConnection_first": ReleaseConnection_first, "ReleaseGroupConnection_type": ReleaseGroupConnection_type, "lang": lang, "LastFMArtistConnection_first": LastFMArtistConnection_first, "LastFMAlbumConnection_first": LastFMAlbumConnection_first]
        }

        public struct Data: GraphQLSelectionSet {
            public static let possibleTypes = ["Query"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("lookup", type: .object(Lookup.selections)),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
                public static let possibleTypes = ["LookupQuery"]

                public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("artist", arguments: ["mbid": GraphQLVariable("mbid")], type: .object(Artist.selections)),
                ]

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                    resultMap = unsafeResultMap
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
                    public static let possibleTypes = ["Artist"]

                    public static let selections: [GraphQLSelection] = [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("area", type: .object(Area.selections)),
                        GraphQLField("lastFM", type: .object(LastFm.selections)),
                        GraphQLField("lifeSpan", type: .object(LifeSpan.selections)),
                        GraphQLField("name", type: .scalar(String.self)),
                        GraphQLField("releaseGroups", alias: "releaseGroups1", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first"), "type": GraphQLVariable("ReleaseGroupConnection_type")], type: .object(ReleaseGroups1.selections)),
                        GraphQLField("releaseGroups", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first"), "type": GraphQLVariable("type")], type: .object(ReleaseGroup.selections)),
                        GraphQLField("theAudioDB", type: .object(TheAudioDb.selections)),
                        GraphQLField("type", type: .scalar(String.self)),
                    ]

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                        resultMap = unsafeResultMap
                    }

                    public init(area: Area? = nil, lastFm: LastFm? = nil, lifeSpan: LifeSpan? = nil, name: String? = nil, releaseGroups1: ReleaseGroups1? = nil, releaseGroups: ReleaseGroup? = nil, theAudioDb: TheAudioDb? = nil, type: String? = nil) {
                        self.init(unsafeResultMap: ["__typename": "Artist", "area": area.flatMap { (value: Area) -> ResultMap in value.resultMap }, "lastFM": lastFm.flatMap { (value: LastFm) -> ResultMap in value.resultMap }, "lifeSpan": lifeSpan.flatMap { (value: LifeSpan) -> ResultMap in value.resultMap }, "name": name, "releaseGroups1": releaseGroups1.flatMap { (value: ReleaseGroups1) -> ResultMap in value.resultMap }, "releaseGroups": releaseGroups.flatMap { (value: ReleaseGroup) -> ResultMap in value.resultMap }, "theAudioDB": theAudioDb.flatMap { (value: TheAudioDb) -> ResultMap in value.resultMap }, "type": type])
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
                    public var releaseGroups1: ReleaseGroups1? {
                        get {
                            return (resultMap["releaseGroups1"] as? ResultMap).flatMap { ReleaseGroups1(unsafeResultMap: $0) }
                        }
                        set {
                            resultMap.updateValue(newValue?.resultMap, forKey: "releaseGroups1")
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
                        public static let possibleTypes = ["Area"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("name", type: .scalar(String.self)),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
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
                        public static let possibleTypes = ["LastFMArtist"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("similarArtists", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("LastFMArtistConnection_first")], type: .object(SimilarArtist.selections)),
                            GraphQLField("topTracks", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first")], type: .object(TopTrack.selections)),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
                        }

                        public init(similarArtists: SimilarArtist? = nil, topTracks: TopTrack? = nil) {
                            self.init(unsafeResultMap: ["__typename": "LastFMArtist", "similarArtists": similarArtists.flatMap { (value: SimilarArtist) -> ResultMap in value.resultMap }, "topTracks": topTracks.flatMap { (value: TopTrack) -> ResultMap in value.resultMap }])
                        }

                        public var __typename: String {
                            get {
                                return resultMap["__typename"]! as! String
                            }
                            set {
                                resultMap.updateValue(newValue, forKey: "__typename")
                            }
                        }

                        /// A list of similar artists.
                        public var similarArtists: SimilarArtist? {
                            get {
                                return (resultMap["similarArtists"] as? ResultMap).flatMap { SimilarArtist(unsafeResultMap: $0) }
                            }
                            set {
                                resultMap.updateValue(newValue?.resultMap, forKey: "similarArtists")
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

                        public struct SimilarArtist: GraphQLSelectionSet {
                            public static let possibleTypes = ["LastFMArtistConnection"]

                            public static let selections: [GraphQLSelection] = [
                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                GraphQLField("edges", type: .list(.object(Edge.selections))),
                                GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
                            ]

                            public private(set) var resultMap: ResultMap

                            public init(unsafeResultMap: ResultMap) {
                                resultMap = unsafeResultMap
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
                                public static let possibleTypes = ["LastFMArtistEdge"]

                                public static let selections: [GraphQLSelection] = [
                                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                    GraphQLField("node", type: .object(Node.selections)),
                                ]

                                public private(set) var resultMap: ResultMap

                                public init(unsafeResultMap: ResultMap) {
                                    resultMap = unsafeResultMap
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
                                    public static let possibleTypes = ["LastFMArtist"]

                                    public static let selections: [GraphQLSelection] = [
                                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                        GraphQLField("mbid", type: .scalar(String.self)),
                                        GraphQLField("name", type: .scalar(String.self)),
                                        GraphQLField("topAlbums", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("LastFMAlbumConnection_first")], type: .object(TopAlbum.selections)),
                                    ]

                                    public private(set) var resultMap: ResultMap

                                    public init(unsafeResultMap: ResultMap) {
                                        resultMap = unsafeResultMap
                                    }

                                    public init(mbid: String? = nil, name: String? = nil, topAlbums: TopAlbum? = nil) {
                                        self.init(unsafeResultMap: ["__typename": "LastFMArtist", "mbid": mbid, "name": name, "topAlbums": topAlbums.flatMap { (value: TopAlbum) -> ResultMap in value.resultMap }])
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

                                    public struct TopAlbum: GraphQLSelectionSet {
                                        public static let possibleTypes = ["LastFMAlbumConnection"]

                                        public static let selections: [GraphQLSelection] = [
                                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                            GraphQLField("nodes", type: .list(.object(Node.selections))),
                                        ]

                                        public private(set) var resultMap: ResultMap

                                        public init(unsafeResultMap: ResultMap) {
                                            resultMap = unsafeResultMap
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
                                            public static let possibleTypes = ["LastFMAlbum"]

                                            public static let selections: [GraphQLSelection] = [
                                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                                GraphQLField("image", arguments: ["size": GraphQLVariable("URLString_size")], type: .scalar(String.self)),
                                            ]

                                            public private(set) var resultMap: ResultMap

                                            public init(unsafeResultMap: ResultMap) {
                                                resultMap = unsafeResultMap
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
                                }
                            }

                            public struct PageInfo: GraphQLSelectionSet {
                                public static let possibleTypes = ["PageInfo"]

                                public static let selections: [GraphQLSelection] = [
                                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                    GraphQLField("endCursor", type: .scalar(String.self)),
                                    GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                                ]

                                public private(set) var resultMap: ResultMap

                                public init(unsafeResultMap: ResultMap) {
                                    resultMap = unsafeResultMap
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
                            public static let possibleTypes = ["LastFMTrackConnection"]

                            public static let selections: [GraphQLSelection] = [
                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                GraphQLField("edges", type: .list(.object(Edge.selections))),
                                GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
                            ]

                            public private(set) var resultMap: ResultMap

                            public init(unsafeResultMap: ResultMap) {
                                resultMap = unsafeResultMap
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
                                public static let possibleTypes = ["LastFMTrackEdge"]

                                public static let selections: [GraphQLSelection] = [
                                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                    GraphQLField("node", type: .object(Node.selections)),
                                ]

                                public private(set) var resultMap: ResultMap

                                public init(unsafeResultMap: ResultMap) {
                                    resultMap = unsafeResultMap
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
                                    public static let possibleTypes = ["LastFMTrack"]

                                    public static let selections: [GraphQLSelection] = [
                                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                        GraphQLField("album", type: .object(Album.selections)),
                                        GraphQLField("artist", type: .object(Artist.selections)),
                                        GraphQLField("title", type: .scalar(String.self)),
                                    ]

                                    public private(set) var resultMap: ResultMap

                                    public init(unsafeResultMap: ResultMap) {
                                        resultMap = unsafeResultMap
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
                                        public static let possibleTypes = ["LastFMAlbum"]

                                        public static let selections: [GraphQLSelection] = [
                                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                            GraphQLField("image", arguments: ["size": GraphQLVariable("URLString_size")], type: .scalar(String.self)),
                                            GraphQLField("mbid", type: .scalar(String.self)),
                                        ]

                                        public private(set) var resultMap: ResultMap

                                        public init(unsafeResultMap: ResultMap) {
                                            resultMap = unsafeResultMap
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
                                        public static let possibleTypes = ["LastFMArtist"]

                                        public static let selections: [GraphQLSelection] = [
                                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                            GraphQLField("name", type: .scalar(String.self)),
                                        ]

                                        public private(set) var resultMap: ResultMap

                                        public init(unsafeResultMap: ResultMap) {
                                            resultMap = unsafeResultMap
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
                                public static let possibleTypes = ["PageInfo"]

                                public static let selections: [GraphQLSelection] = [
                                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                    GraphQLField("endCursor", type: .scalar(String.self)),
                                    GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                                ]

                                public private(set) var resultMap: ResultMap

                                public init(unsafeResultMap: ResultMap) {
                                    resultMap = unsafeResultMap
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
                        public static let possibleTypes = ["LifeSpan"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("begin", type: .scalar(String.self)),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
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

                    public struct ReleaseGroups1: GraphQLSelectionSet {
                        public static let possibleTypes = ["ReleaseGroupConnection"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("edges", type: .list(.object(Edge.selections))),
                            GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
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
                            public static let possibleTypes = ["ReleaseGroupEdge"]

                            public static let selections: [GraphQLSelection] = [
                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                GraphQLField("node", type: .object(Node.selections)),
                            ]

                            public private(set) var resultMap: ResultMap

                            public init(unsafeResultMap: ResultMap) {
                                resultMap = unsafeResultMap
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
                                public static let possibleTypes = ["ReleaseGroup"]

                                public static let selections: [GraphQLSelection] = [
                                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                    GraphQLField("releases", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("ReleaseConnection_first"), "status": GraphQLVariable("status"), "type": GraphQLVariable("type")], type: .object(Release.selections)),
                                    GraphQLField("theAudioDB", type: .object(TheAudioDb.selections)),
                                    GraphQLField("title", type: .scalar(String.self)),
                                ]

                                public private(set) var resultMap: ResultMap

                                public init(unsafeResultMap: ResultMap) {
                                    resultMap = unsafeResultMap
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
                                    public static let possibleTypes = ["ReleaseConnection"]

                                    public static let selections: [GraphQLSelection] = [
                                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                        GraphQLField("nodes", type: .list(.object(Node.selections))),
                                    ]

                                    public private(set) var resultMap: ResultMap

                                    public init(unsafeResultMap: ResultMap) {
                                        resultMap = unsafeResultMap
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
                                        public static let possibleTypes = ["Release"]

                                        public static let selections: [GraphQLSelection] = [
                                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                            GraphQLField("mbid", type: .nonNull(.scalar(String.self))),
                                        ]

                                        public private(set) var resultMap: ResultMap

                                        public init(unsafeResultMap: ResultMap) {
                                            resultMap = unsafeResultMap
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
                                    public static let possibleTypes = ["TheAudioDBAlbum"]

                                    public static let selections: [GraphQLSelection] = [
                                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                        GraphQLField("frontImage", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                                    ]

                                    public private(set) var resultMap: ResultMap

                                    public init(unsafeResultMap: ResultMap) {
                                        resultMap = unsafeResultMap
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
                            public static let possibleTypes = ["PageInfo"]

                            public static let selections: [GraphQLSelection] = [
                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                GraphQLField("endCursor", type: .scalar(String.self)),
                                GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                            ]

                            public private(set) var resultMap: ResultMap

                            public init(unsafeResultMap: ResultMap) {
                                resultMap = unsafeResultMap
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

                    public struct ReleaseGroup: GraphQLSelectionSet {
                        public static let possibleTypes = ["ReleaseGroupConnection"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("edges", type: .list(.object(Edge.selections))),
                            GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
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
                            public static let possibleTypes = ["ReleaseGroupEdge"]

                            public static let selections: [GraphQLSelection] = [
                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                GraphQLField("node", type: .object(Node.selections)),
                            ]

                            public private(set) var resultMap: ResultMap

                            public init(unsafeResultMap: ResultMap) {
                                resultMap = unsafeResultMap
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
                                public static let possibleTypes = ["ReleaseGroup"]

                                public static let selections: [GraphQLSelection] = [
                                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                    GraphQLField("releases", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("ReleaseConnection_first"), "status": GraphQLVariable("status"), "type": GraphQLVariable("type")], type: .object(Release.selections)),
                                    GraphQLField("theAudioDB", type: .object(TheAudioDb.selections)),
                                    GraphQLField("title", type: .scalar(String.self)),
                                ]

                                public private(set) var resultMap: ResultMap

                                public init(unsafeResultMap: ResultMap) {
                                    resultMap = unsafeResultMap
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
                                    public static let possibleTypes = ["ReleaseConnection"]

                                    public static let selections: [GraphQLSelection] = [
                                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                        GraphQLField("nodes", type: .list(.object(Node.selections))),
                                    ]

                                    public private(set) var resultMap: ResultMap

                                    public init(unsafeResultMap: ResultMap) {
                                        resultMap = unsafeResultMap
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
                                        public static let possibleTypes = ["Release"]

                                        public static let selections: [GraphQLSelection] = [
                                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                            GraphQLField("mbid", type: .nonNull(.scalar(String.self))),
                                        ]

                                        public private(set) var resultMap: ResultMap

                                        public init(unsafeResultMap: ResultMap) {
                                            resultMap = unsafeResultMap
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
                                    public static let possibleTypes = ["TheAudioDBAlbum"]

                                    public static let selections: [GraphQLSelection] = [
                                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                        GraphQLField("frontImage", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                                    ]

                                    public private(set) var resultMap: ResultMap

                                    public init(unsafeResultMap: ResultMap) {
                                        resultMap = unsafeResultMap
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
                            public static let possibleTypes = ["PageInfo"]

                            public static let selections: [GraphQLSelection] = [
                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                GraphQLField("endCursor", type: .scalar(String.self)),
                                GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                            ]

                            public private(set) var resultMap: ResultMap

                            public init(unsafeResultMap: ResultMap) {
                                resultMap = unsafeResultMap
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
                        public static let possibleTypes = ["TheAudioDBArtist"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("biography", arguments: ["lang": GraphQLVariable("lang")], type: .scalar(String.self)),
                            GraphQLField("mood", type: .scalar(String.self)),
                            GraphQLField("style", type: .scalar(String.self)),
                            GraphQLField("thumbnail", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
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
        public let operationDefinition =
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

        public let operationName = "AlbumDetailView"

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
            public static let possibleTypes = ["Query"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("lookup", type: .object(Lookup.selections)),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
                public static let possibleTypes = ["LookupQuery"]

                public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("release", arguments: ["mbid": GraphQLVariable("mbid")], type: .object(Release.selections)),
                ]

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                    resultMap = unsafeResultMap
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
                    public static let possibleTypes = ["Release"]

                    public static let selections: [GraphQLSelection] = [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("artistCredits", type: .list(.object(ArtistCredit.selections))),
                        GraphQLField("coverArtArchive", type: .object(CoverArtArchive.selections)),
                        GraphQLField("date", type: .scalar(String.self)),
                        GraphQLField("discogs", type: .object(Discog.selections)),
                        GraphQLField("lastFM", type: .object(LastFm.selections)),
                        GraphQLField("media", type: .list(.object(Medium.selections))),
                        GraphQLField("title", type: .scalar(String.self)),
                    ]

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                        resultMap = unsafeResultMap
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
                        public static let possibleTypes = ["ArtistCredit"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("artist", type: .object(Artist.selections)),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
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
                            public static let possibleTypes = ["Artist"]

                            public static let selections: [GraphQLSelection] = [
                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                GraphQLFragmentSpread(AlbumArtistCreditButtonArtist.self),
                            ]

                            public private(set) var resultMap: ResultMap

                            public init(unsafeResultMap: ResultMap) {
                                resultMap = unsafeResultMap
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
                                    resultMap = unsafeResultMap
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
                        public static let possibleTypes = ["CoverArtArchiveRelease"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("front", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
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
                        public static let possibleTypes = ["DiscogsRelease"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("genres", type: .nonNull(.list(.nonNull(.scalar(String.self))))),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
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
                        public static let possibleTypes = ["LastFMAlbum"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("playCount", type: .scalar(Double.self)),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
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
                        public static let possibleTypes = ["Medium"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("tracks", type: .list(.object(Track.selections))),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
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
                            public static let possibleTypes = ["Track"]

                            public static let selections: [GraphQLSelection] = [
                                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                                GraphQLFragmentSpread(AlbumTrackCellTrack.self),
                            ]

                            public private(set) var resultMap: ResultMap

                            public init(unsafeResultMap: ResultMap) {
                                resultMap = unsafeResultMap
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
                                    resultMap = unsafeResultMap
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
        public static let fragmentDefinition =
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

        public static let possibleTypes = ["LastFMArtistConnection"]

        public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("edges", type: .list(.object(Edge.selections))),
            GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
        ]

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
            resultMap = unsafeResultMap
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
            public static let possibleTypes = ["LastFMArtistEdge"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("node", type: .object(Node.selections)),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
                public static let possibleTypes = ["LastFMArtist"]

                public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("mbid", type: .scalar(String.self)),
                    GraphQLField("name", type: .scalar(String.self)),
                    GraphQLField("topAlbums", type: .object(TopAlbum.selections)),
                    GraphQLField("topTags", type: .object(TopTag.selections)),
                    GraphQLField("topTracks", type: .object(TopTrack.selections)),
                ]

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                    resultMap = unsafeResultMap
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
                    public static let possibleTypes = ["LastFMAlbumConnection"]

                    public static let selections: [GraphQLSelection] = [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("nodes", type: .list(.object(Node.selections))),
                    ]

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                        resultMap = unsafeResultMap
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
                        public static let possibleTypes = ["LastFMAlbum"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("image", type: .scalar(String.self)),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
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
                    public static let possibleTypes = ["LastFMTagConnection"]

                    public static let selections: [GraphQLSelection] = [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("nodes", type: .list(.object(Node.selections))),
                    ]

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                        resultMap = unsafeResultMap
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
                        public static let possibleTypes = ["LastFMTag"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("name", type: .nonNull(.scalar(String.self))),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
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
                    public static let possibleTypes = ["LastFMTrackConnection"]

                    public static let selections: [GraphQLSelection] = [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("nodes", type: .list(.object(Node.selections))),
                    ]

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                        resultMap = unsafeResultMap
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
                        public static let possibleTypes = ["LastFMTrack"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("title", type: .scalar(String.self)),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
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
            public static let possibleTypes = ["PageInfo"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("endCursor", type: .scalar(String.self)),
                GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
        public static let fragmentDefinition =
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

        public static let possibleTypes = ["LastFMTrackConnection"]

        public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("edges", type: .list(.object(Edge.selections))),
            GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
        ]

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
            resultMap = unsafeResultMap
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
            public static let possibleTypes = ["LastFMTrackEdge"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("node", type: .object(Node.selections)),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
                public static let possibleTypes = ["LastFMTrack"]

                public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("album", type: .object(Album.selections)),
                    GraphQLField("artist", type: .object(Artist.selections)),
                    GraphQLField("title", type: .scalar(String.self)),
                ]

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                    resultMap = unsafeResultMap
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
                    public static let possibleTypes = ["LastFMAlbum"]

                    public static let selections: [GraphQLSelection] = [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("image", type: .scalar(String.self)),
                        GraphQLField("mbid", type: .scalar(String.self)),
                    ]

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                        resultMap = unsafeResultMap
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
                    public static let possibleTypes = ["LastFMArtist"]

                    public static let selections: [GraphQLSelection] = [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("name", type: .scalar(String.self)),
                    ]

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                        resultMap = unsafeResultMap
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
            public static let possibleTypes = ["PageInfo"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("endCursor", type: .scalar(String.self)),
                GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
        public static let fragmentDefinition =
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

        public static let possibleTypes = ["ReleaseGroupConnection"]

        public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("edges", type: .list(.object(Edge.selections))),
            GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
        ]

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
            resultMap = unsafeResultMap
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
            public static let possibleTypes = ["ReleaseGroupEdge"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("node", type: .object(Node.selections)),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
                public static let possibleTypes = ["ReleaseGroup"]

                public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("releases", type: .object(Release.selections)),
                    GraphQLField("theAudioDB", type: .object(TheAudioDb.selections)),
                    GraphQLField("title", type: .scalar(String.self)),
                ]

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                    resultMap = unsafeResultMap
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
                    public static let possibleTypes = ["ReleaseConnection"]

                    public static let selections: [GraphQLSelection] = [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("nodes", type: .list(.object(Node.selections))),
                    ]

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                        resultMap = unsafeResultMap
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
                        public static let possibleTypes = ["Release"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("mbid", type: .nonNull(.scalar(String.self))),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
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
                    public static let possibleTypes = ["TheAudioDBAlbum"]

                    public static let selections: [GraphQLSelection] = [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("frontImage", type: .scalar(String.self)),
                    ]

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                        resultMap = unsafeResultMap
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
            public static let possibleTypes = ["PageInfo"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("endCursor", type: .scalar(String.self)),
                GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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

    public struct LastFmArtistConnectionSimilarArtistCellLastFmArtist: GraphQLFragment {
        /// The raw GraphQL definition of this fragment.
        public static let fragmentDefinition =
            """
            fragment LastFMArtistConnectionSimilarArtistCellLastFMArtist on LastFMArtistConnection {
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
                }
              }
              pageInfo {
                __typename
                endCursor
                hasNextPage
              }
            }
            """

        public static let possibleTypes = ["LastFMArtistConnection"]

        public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("edges", type: .list(.object(Edge.selections))),
            GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
        ]

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
            resultMap = unsafeResultMap
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
            public static let possibleTypes = ["LastFMArtistEdge"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("node", type: .object(Node.selections)),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
                public static let possibleTypes = ["LastFMArtist"]

                public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("mbid", type: .scalar(String.self)),
                    GraphQLField("name", type: .scalar(String.self)),
                    GraphQLField("topAlbums", type: .object(TopAlbum.selections)),
                ]

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                    resultMap = unsafeResultMap
                }

                public init(mbid: String? = nil, name: String? = nil, topAlbums: TopAlbum? = nil) {
                    self.init(unsafeResultMap: ["__typename": "LastFMArtist", "mbid": mbid, "name": name, "topAlbums": topAlbums.flatMap { (value: TopAlbum) -> ResultMap in value.resultMap }])
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

                public struct TopAlbum: GraphQLSelectionSet {
                    public static let possibleTypes = ["LastFMAlbumConnection"]

                    public static let selections: [GraphQLSelection] = [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("nodes", type: .list(.object(Node.selections))),
                    ]

                    public private(set) var resultMap: ResultMap

                    public init(unsafeResultMap: ResultMap) {
                        resultMap = unsafeResultMap
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
                        public static let possibleTypes = ["LastFMAlbum"]

                        public static let selections: [GraphQLSelection] = [
                            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                            GraphQLField("image", type: .scalar(String.self)),
                        ]

                        public private(set) var resultMap: ResultMap

                        public init(unsafeResultMap: ResultMap) {
                            resultMap = unsafeResultMap
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
            }
        }

        public struct PageInfo: GraphQLSelectionSet {
            public static let possibleTypes = ["PageInfo"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("endCursor", type: .scalar(String.self)),
                GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
        public static let fragmentDefinition =
            """
            fragment AlbumArtistCreditButtonArtist on Artist {
              __typename
              mbid
              name
            }
            """

        public static let possibleTypes = ["Artist"]

        public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("mbid", type: .nonNull(.scalar(String.self))),
            GraphQLField("name", type: .scalar(String.self)),
        ]

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
            resultMap = unsafeResultMap
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
        public static let fragmentDefinition =
            """
            fragment AlbumTrackCellCreditArtistCredit on ArtistCredit {
              __typename
              joinPhrase
              name
            }
            """

        public static let possibleTypes = ["ArtistCredit"]

        public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("joinPhrase", type: .scalar(String.self)),
            GraphQLField("name", type: .scalar(String.self)),
        ]

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
            resultMap = unsafeResultMap
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
        public static let fragmentDefinition =
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

        public static let possibleTypes = ["ReleaseGroup"]

        public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("releases", type: .object(Release.selections)),
            GraphQLField("theAudioDB", type: .object(TheAudioDb.selections)),
            GraphQLField("title", type: .scalar(String.self)),
        ]

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
            resultMap = unsafeResultMap
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
            public static let possibleTypes = ["ReleaseConnection"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("nodes", type: .list(.object(Node.selections))),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
                public static let possibleTypes = ["Release"]

                public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("mbid", type: .nonNull(.scalar(String.self))),
                ]

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                    resultMap = unsafeResultMap
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
            public static let possibleTypes = ["TheAudioDBAlbum"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("frontImage", type: .scalar(String.self)),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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

    public struct SimilarArtistCellLastFmArtist: GraphQLFragment {
        /// The raw GraphQL definition of this fragment.
        public static let fragmentDefinition =
            """
            fragment SimilarArtistCellLastFMArtist on LastFMArtist {
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
            }
            """

        public static let possibleTypes = ["LastFMArtist"]

        public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("mbid", type: .scalar(String.self)),
            GraphQLField("name", type: .scalar(String.self)),
            GraphQLField("topAlbums", type: .object(TopAlbum.selections)),
        ]

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
            resultMap = unsafeResultMap
        }

        public init(mbid: String? = nil, name: String? = nil, topAlbums: TopAlbum? = nil) {
            self.init(unsafeResultMap: ["__typename": "LastFMArtist", "mbid": mbid, "name": name, "topAlbums": topAlbums.flatMap { (value: TopAlbum) -> ResultMap in value.resultMap }])
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

        public struct TopAlbum: GraphQLSelectionSet {
            public static let possibleTypes = ["LastFMAlbumConnection"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("nodes", type: .list(.object(Node.selections))),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
                public static let possibleTypes = ["LastFMAlbum"]

                public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("image", type: .scalar(String.self)),
                ]

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                    resultMap = unsafeResultMap
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
    }

    public struct TrendingArtistCellLastFmArtist: GraphQLFragment {
        /// The raw GraphQL definition of this fragment.
        public static let fragmentDefinition =
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

        public static let possibleTypes = ["LastFMArtist"]

        public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("mbid", type: .scalar(String.self)),
            GraphQLField("name", type: .scalar(String.self)),
            GraphQLField("topAlbums", type: .object(TopAlbum.selections)),
            GraphQLField("topTags", type: .object(TopTag.selections)),
            GraphQLField("topTracks", type: .object(TopTrack.selections)),
        ]

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
            resultMap = unsafeResultMap
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
            public static let possibleTypes = ["LastFMAlbumConnection"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("nodes", type: .list(.object(Node.selections))),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
                public static let possibleTypes = ["LastFMAlbum"]

                public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("image", type: .scalar(String.self)),
                ]

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                    resultMap = unsafeResultMap
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
            public static let possibleTypes = ["LastFMTagConnection"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("nodes", type: .list(.object(Node.selections))),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
                public static let possibleTypes = ["LastFMTag"]

                public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("name", type: .nonNull(.scalar(String.self))),
                ]

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                    resultMap = unsafeResultMap
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
            public static let possibleTypes = ["LastFMTrackConnection"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("nodes", type: .list(.object(Node.selections))),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
                public static let possibleTypes = ["LastFMTrack"]

                public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("title", type: .scalar(String.self)),
                ]

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                    resultMap = unsafeResultMap
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
        public static let fragmentDefinition =
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

        public static let possibleTypes = ["LastFMTrack"]

        public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("album", type: .object(Album.selections)),
            GraphQLField("artist", type: .object(Artist.selections)),
            GraphQLField("title", type: .scalar(String.self)),
        ]

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
            resultMap = unsafeResultMap
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
            public static let possibleTypes = ["LastFMAlbum"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("image", type: .scalar(String.self)),
                GraphQLField("mbid", type: .scalar(String.self)),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
            public static let possibleTypes = ["LastFMArtist"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("name", type: .scalar(String.self)),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
        public static let fragmentDefinition =
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

        public static let possibleTypes = ["Track"]

        public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("position", type: .scalar(Int.self)),
            GraphQLField("recording", type: .object(Recording.selections)),
            GraphQLField("title", type: .scalar(String.self)),
        ]

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
            resultMap = unsafeResultMap
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
            public static let possibleTypes = ["Recording"]

            public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("artistCredits", type: .list(.object(ArtistCredit.selections))),
                GraphQLField("lastFM", type: .object(LastFm.selections)),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
                resultMap = unsafeResultMap
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
                public static let possibleTypes = ["ArtistCredit"]

                public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLFragmentSpread(AlbumTrackCellCreditArtistCredit.self),
                ]

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                    resultMap = unsafeResultMap
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
                        resultMap = unsafeResultMap
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
                public static let possibleTypes = ["LastFMTrack"]

                public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("playCount", type: .scalar(Double.self)),
                ]

                public private(set) var resultMap: ResultMap

                public init(unsafeResultMap: ResultMap) {
                    resultMap = unsafeResultMap
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
