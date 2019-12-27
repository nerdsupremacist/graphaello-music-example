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
        private var cancellable: Cancellable? = nil

        deinit {
            cancel()
        }

        func load(client: ApolloClient, query: Query) {
            guard value == nil, !isLoading else { return }
            self.cancellable = client.fetch(query: query) { [weak self] result in
                defer {
                    self?.cancellable = nil
                    self?.isLoading = false
                }
                switch result {
                case .success(let result):
                    self?.value = result.data
                    self?.error = result.errors?.map { $0.description }.joined(separator: ", ")
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
            self.isLoading = true
        }

        func cancel() {
            self.cancellable?.cancel()
        }
    }

    let client: ApolloClient
    let query: Query
    let factory: ContentFactory

    @ObservedObject private var viewModel = ViewModel()

    var body: some View {
        return VStack {
            viewModel.error.map { Text("Error: \($0)") }
            viewModel.value.map(factory)
            viewModel.isLoading ? Text("Loading") : nil
        }.onAppear {
            self.viewModel.load(client: self.client, query: self.query)
        }.onDisappear {
            self.viewModel.cancel()
        }
    }
}

protocol Fragment {
    associatedtype UnderlyingType
}

protocol Target { }

protocol API: Target { }

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
    fileprivate init() { }
}

struct GraphQLFragmentPath<TargetType: Target, UnderlyingType> {
    fileprivate init() { }
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

    func _forEach<Value, Output>(_ keyPath: KeyPath<GraphQLFragmentPath<TargetType, Value>, GraphQLPath<TargetType, Output>>) -> GraphQLPath<TargetType, [Output]> where UnderlyingType == [Value] {
        return .init()
    }

    func _forEach<Value, Output>(_ keyPath: KeyPath<GraphQLFragmentPath<TargetType, Value>, GraphQLPath<TargetType, Output>>) -> GraphQLPath<TargetType, [Output]?> where UnderlyingType == [Value]? {
        return .init()
    }

}

extension GraphQLFragmentPath {


    func _forEach<Value, Output>(_ keyPath: KeyPath<GraphQLFragmentPath<TargetType, Value>, GraphQLFragmentPath<TargetType, Output>>) -> GraphQLFragmentPath<TargetType, [Output]> where UnderlyingType == [Value] {
        return .init()
    }

    func _forEach<Value, Output>(_ keyPath: KeyPath<GraphQLFragmentPath<TargetType, Value>, GraphQLFragmentPath<TargetType, Output>>) -> GraphQLFragmentPath<TargetType, [Output]?> where UnderlyingType == [Value]? {
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
            case .item(_, let int):
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

            self.loader(data).onAppear {  self.onAppear(data: data) }
        }
    }

    private func onAppear(data: Data) {
        guard !paging.isLoading,
            paging.hasMore,
            case .item(_, let index) = data,
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
            case .item(let item, _):
                return AnyView(itemView(item))
            case .error(let error):
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

@propertyWrapper
struct GraphQL<Value> {
    var wrappedValue: Value

    init<T: Target>(_: @autoclosure () -> GraphQLPath<T, Value>) {
        fatalError("Initializer with path only should never be used")
    }

    fileprivate init(_ wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}

extension GraphQL where Value: Fragment {
    init<T: Target>(_: @autoclosure () -> GraphQLFragmentPath<T, Value.UnderlyingType>) {
        fatalError("Initializer with path only should never be used")
    }
}

extension GraphQL {
    init<T: API, C: Connection, F: Fragment>(_: @autoclosure () -> GraphQLFragmentPath<T, C>) where Value == Paging<F>, C.Node == F.UnderlyingType {
        fatalError("Initializer with path only should never be used")
    }

    init<T: API, C: Connection, F: Fragment>(_: @autoclosure () -> GraphQLFragmentPath<T, C?>) where Value == Paging<F>?, C.Node == F.UnderlyingType {
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
    fileprivate init<Raw: RawRepresentable, Other: RawRepresentable>(_ other: [Other?]) where Element == Raw?,  Other.RawValue == Raw.RawValue {
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


static func node(id: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Node?> {
    return .init()
}

static var node: FragmentPath<Music.Node?> { .init() }


static var lastFm: FragmentPath<Music.LastFMQuery?> { .init() }


static var spotify: FragmentPath<Music.SpotifyQuery> { .init() }

    enum LookupQuery: Target {

    
    typealias Path<V> = GraphQLPath<LookupQuery, V>
    typealias FragmentPath<V> = GraphQLFragmentPath<LookupQuery, V>

    

    

    
    
static func area(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Area?> {
    return .init()
}

static var area: FragmentPath<Music.Area?> { .init() }


static func artist(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Artist?> {
    return .init()
}

static var artist: FragmentPath<Music.Artist?> { .init() }


static func collection(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Collection?> {
    return .init()
}

static var collection: FragmentPath<Music.Collection?> { .init() }


static func disc(discID: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Disc?> {
    return .init()
}

static var disc: FragmentPath<Music.Disc?> { .init() }


static func event(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Event?> {
    return .init()
}

static var event: FragmentPath<Music.Event?> { .init() }


static func instrument(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Instrument?> {
    return .init()
}

static var instrument: FragmentPath<Music.Instrument?> { .init() }


static func label(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Label?> {
    return .init()
}

static var label: FragmentPath<Music.Label?> { .init() }


static func place(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Place?> {
    return .init()
}

static var place: FragmentPath<Music.Place?> { .init() }


static func recording(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Recording?> {
    return .init()
}

static var recording: FragmentPath<Music.Recording?> { .init() }


static func release(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Release?> {
    return .init()
}

static var release: FragmentPath<Music.Release?> { .init() }


static func releaseGroup(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.ReleaseGroup?> {
    return .init()
}

static var releaseGroup: FragmentPath<Music.ReleaseGroup?> { .init() }


static func series(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Series?> {
    return .init()
}

static var series: FragmentPath<Music.Series?> { .init() }


static func url(mbid: GraphQLArgument<String?> = .argument
, resource: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.URL?> {
    return .init()
}

static var url: FragmentPath<Music.URL?> { .init() }


static func work(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Work?> {
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


static func isoCodes(standard: GraphQLArgument<String?> = .argument
) -> Path<[String?]?> {
    return .init()
}

static var isoCodes: Path<[String?]?> { .init() }


static var type: Path<String?> { .init() }


static var typeId: Path<String?> { .init() }


static func artists(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

static var artists: FragmentPath<Music.ArtistConnection?> { .init() }


static func events(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.EventConnection?> {
    return .init()
}

static var events: FragmentPath<Music.EventConnection?> { .init() }


static func labels(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.LabelConnection?> {
    return .init()
}

static var labels: FragmentPath<Music.LabelConnection?> { .init() }


static func places(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.PlaceConnection?> {
    return .init()
}

static var places: FragmentPath<Music.PlaceConnection?> { .init() }


static func releases(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, status: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

static var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


static var relationships: FragmentPath<Music.Relationships?> { .init() }


static func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

static var collections: FragmentPath<Music.CollectionConnection?> { .init() }


static func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
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


static func recordings(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RecordingConnection?> {
    return .init()
}

static var recordings: FragmentPath<Music.RecordingConnection?> { .init() }


static func releases(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, status: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

static var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


static func releaseGroups(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseGroupConnection?> {
    return .init()
}

static var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }


static func works(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.WorkConnection?> {
    return .init()
}

static var works: FragmentPath<Music.WorkConnection?> { .init() }


static var relationships: FragmentPath<Music.Relationships?> { .init() }


static func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

static var collections: FragmentPath<Music.CollectionConnection?> { .init() }


static var rating: FragmentPath<Music.Rating?> { .init() }


static func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
    return .init()
}

static var tags: FragmentPath<Music.TagConnection?> { .init() }


static var fanArt: FragmentPath<Music.FanArtArtist?> { .init() }


static func mediaWikiImages(type: GraphQLArgument<String?> = .argument
) -> FragmentPath<[Music.MediaWikiImage?]> {
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


static func artists(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

static var artists: FragmentPath<Music.ArtistConnection?> { .init() }


static func releases(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, status: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

static var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


static var relationships: FragmentPath<Music.Relationships?> { .init() }


static func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

static var collections: FragmentPath<Music.CollectionConnection?> { .init() }


static var rating: FragmentPath<Music.Rating?> { .init() }


static func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
    return .init()
}

static var tags: FragmentPath<Music.TagConnection?> { .init() }


static var theAudioDb: FragmentPath<Music.TheAudioDBTrack?> { .init() }


static var lastFm: FragmentPath<Music.LastFMTrack?> { .init() }


static func spotify(strategy: GraphQLArgument<[Music.SpotifyMatchStrategy]?> = .argument
) -> FragmentPath<Music.SpotifyTrack?> {
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


static func artists(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

static var artists: FragmentPath<Music.ArtistConnection?> { .init() }


static func labels(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.LabelConnection?> {
    return .init()
}

static var labels: FragmentPath<Music.LabelConnection?> { .init() }


static func recordings(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RecordingConnection?> {
    return .init()
}

static var recordings: FragmentPath<Music.RecordingConnection?> { .init() }


static func releaseGroups(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseGroupConnection?> {
    return .init()
}

static var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }


static var relationships: FragmentPath<Music.Relationships?> { .init() }


static func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

static var collections: FragmentPath<Music.CollectionConnection?> { .init() }


static func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
    return .init()
}

static var tags: FragmentPath<Music.TagConnection?> { .init() }


static var coverArtArchive: FragmentPath<Music.CoverArtArchiveRelease?> { .init() }


static var discogs: FragmentPath<Music.DiscogsRelease?> { .init() }


static var lastFm: FragmentPath<Music.LastFMAlbum?> { .init() }


static func spotify(strategy: GraphQLArgument<[Music.SpotifyMatchStrategy]?> = .argument
) -> FragmentPath<Music.SpotifyAlbum?> {
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


static func releases(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
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


static func releases(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, status: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

static var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


static var relationships: FragmentPath<Music.Relationships?> { .init() }


static func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

static var collections: FragmentPath<Music.CollectionConnection?> { .init() }


static var rating: FragmentPath<Music.Rating?> { .init() }


static func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
    return .init()
}

static var tags: FragmentPath<Music.TagConnection?> { .init() }


static var fanArt: FragmentPath<Music.FanArtLabel?> { .init() }


static func mediaWikiImages(type: GraphQLArgument<String?> = .argument
) -> FragmentPath<[Music.MediaWikiImage?]> {
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

    

    

    
    
static func areas(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

static var areas: FragmentPath<Music.RelationshipConnection?> { .init() }


static func artists(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

static var artists: FragmentPath<Music.RelationshipConnection?> { .init() }


static func events(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

static var events: FragmentPath<Music.RelationshipConnection?> { .init() }


static func instruments(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

static var instruments: FragmentPath<Music.RelationshipConnection?> { .init() }


static func labels(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

static var labels: FragmentPath<Music.RelationshipConnection?> { .init() }


static func places(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

static var places: FragmentPath<Music.RelationshipConnection?> { .init() }


static func recordings(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

static var recordings: FragmentPath<Music.RelationshipConnection?> { .init() }


static func releases(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

static var releases: FragmentPath<Music.RelationshipConnection?> { .init() }


static func releaseGroups(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

static var releaseGroups: FragmentPath<Music.RelationshipConnection?> { .init() }


static func series(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

static var series: FragmentPath<Music.RelationshipConnection?> { .init() }


static func urls(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

static var urls: FragmentPath<Music.RelationshipConnection?> { .init() }


static func works(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
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


static func areas(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.AreaConnection?> {
    return .init()
}

static var areas: FragmentPath<Music.AreaConnection?> { .init() }


static func artists(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

static var artists: FragmentPath<Music.ArtistConnection?> { .init() }


static func events(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.EventConnection?> {
    return .init()
}

static var events: FragmentPath<Music.EventConnection?> { .init() }


static func instruments(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.InstrumentConnection?> {
    return .init()
}

static var instruments: FragmentPath<Music.InstrumentConnection?> { .init() }


static func labels(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.LabelConnection?> {
    return .init()
}

static var labels: FragmentPath<Music.LabelConnection?> { .init() }


static func places(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.PlaceConnection?> {
    return .init()
}

static var places: FragmentPath<Music.PlaceConnection?> { .init() }


static func recordings(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RecordingConnection?> {
    return .init()
}

static var recordings: FragmentPath<Music.RecordingConnection?> { .init() }


static func releases(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, status: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

static var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


static func releaseGroups(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseGroupConnection?> {
    return .init()
}

static var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }


static func series(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.SeriesConnection?> {
    return .init()
}

static var series: FragmentPath<Music.SeriesConnection?> { .init() }


static func works(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.WorkConnection?> {
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


static func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

static var collections: FragmentPath<Music.CollectionConnection?> { .init() }


static var rating: FragmentPath<Music.Rating?> { .init() }


static func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
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


static var value: Path<Float?> { .init() }


    

    
    
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


static func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

static var collections: FragmentPath<Music.CollectionConnection?> { .init() }


static func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
    return .init()
}

static var tags: FragmentPath<Music.TagConnection?> { .init() }


static func mediaWikiImages(type: GraphQLArgument<String?> = .argument
) -> FragmentPath<[Music.MediaWikiImage?]> {
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


static func events(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.EventConnection?> {
    return .init()
}

static var events: FragmentPath<Music.EventConnection?> { .init() }


static var relationships: FragmentPath<Music.Relationships?> { .init() }


static func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

static var collections: FragmentPath<Music.CollectionConnection?> { .init() }


static func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
    return .init()
}

static var tags: FragmentPath<Music.TagConnection?> { .init() }


static func mediaWikiImages(type: GraphQLArgument<String?> = .argument
) -> FragmentPath<[Music.MediaWikiImage?]> {
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


static func artists(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

static var artists: FragmentPath<Music.ArtistConnection?> { .init() }


static func releases(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, status: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

static var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


static var relationships: FragmentPath<Music.Relationships?> { .init() }


static func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

static var collections: FragmentPath<Music.CollectionConnection?> { .init() }


static var rating: FragmentPath<Music.Rating?> { .init() }


static func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
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

    

    

    
    
static func front(size: GraphQLArgument<Music.CoverArtArchiveImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

static var front: Path<String?> { .init() }


static func back(size: GraphQLArgument<Music.CoverArtArchiveImageSize?> = .argument
) -> Path<String?> {
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


static func url(size: GraphQLArgument<Music.FanArtImageSize?> = .argument
) -> Path<String?> {
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


static func url(size: GraphQLArgument<Music.FanArtImageSize?> = .argument
) -> Path<String?> {
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


static func description(lang: GraphQLArgument<String?> = .argument
) -> Path<String?> {
    return .init()
}

static var description: Path<String?> { .init() }


static var review: Path<String?> { .init() }


static var salesCount: Path<Float?> { .init() }


static var score: Path<Float?> { .init() }


static var scoreVotes: Path<Float?> { .init() }


static func discImage(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

static var discImage: Path<String?> { .init() }


static func spineImage(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

static var spineImage: Path<String?> { .init() }


static func frontImage(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

static var frontImage: Path<String?> { .init() }


static func backImage(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
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


static func lowestPrice(currency: GraphQLArgument<String?> = .argument
) -> Path<Float?> {
    return .init()
}

static var lowestPrice: Path<Float?> { .init() }


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


static func lowestPrice(currency: GraphQLArgument<String?> = .argument
) -> Path<Float?> {
    return .init()
}

static var lowestPrice: Path<Float?> { .init() }


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


static var value: Path<Float?> { .init() }


    

    
    
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


static func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

static var collections: FragmentPath<Music.CollectionConnection?> { .init() }


static func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
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


static func artists(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

static var artists: FragmentPath<Music.ArtistConnection?> { .init() }


static var relationships: FragmentPath<Music.Relationships?> { .init() }


static func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

static var collections: FragmentPath<Music.CollectionConnection?> { .init() }


static var rating: FragmentPath<Music.Rating?> { .init() }


static func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
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


static func url(size: GraphQLArgument<Music.FanArtImageSize?> = .argument
) -> Path<String?> {
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


static func image(size: GraphQLArgument<Music.LastFMImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

static var image: Path<String?> { .init() }


static var listenerCount: Path<Float?> { .init() }


static var playCount: Path<Float?> { .init() }


static func description(lang: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMWikiContent?> {
    return .init()
}

static var description: FragmentPath<Music.LastFMWikiContent?> { .init() }


static var artist: FragmentPath<Music.LastFMArtist?> { .init() }


static func topTags(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTagConnection?> {
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


static func image(size: GraphQLArgument<Music.LastFMImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

static var image: Path<String?> { .init() }


static var listenerCount: Path<Float?> { .init() }


static var playCount: Path<Float?> { .init() }


static func similarArtists(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMArtistConnection?> {
    return .init()
}

static var similarArtists: FragmentPath<Music.LastFMArtistConnection?> { .init() }


static func topAlbums(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMAlbumConnection?> {
    return .init()
}

static var topAlbums: FragmentPath<Music.LastFMAlbumConnection?> { .init() }


static func topTags(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTagConnection?> {
    return .init()
}

static var topTags: FragmentPath<Music.LastFMTagConnection?> { .init() }


static func topTracks(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTrackConnection?> {
    return .init()
}

static var topTracks: FragmentPath<Music.LastFMTrackConnection?> { .init() }


static func biography(lang: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMWikiContent?> {
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


static var matchScore: Path<Float?> { .init() }


    

    
    
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


static var matchScore: Path<Float?> { .init() }


    

    
    
    static var _fragment: FragmentPath<LastFMTrackEdge> { .init() }
}

enum LastFMTrack: Target {

    
    typealias Path<V> = GraphQLPath<LastFMTrack, V>
    typealias FragmentPath<V> = GraphQLFragmentPath<LastFMTrack, V>

    

    

    
    
static var mbid: Path<String?> { .init() }


static var title: Path<String?> { .init() }


static var url: Path<String> { .init() }


static var duration: Path<String?> { .init() }


static var listenerCount: Path<Float?> { .init() }


static var playCount: Path<Float?> { .init() }


static func description(lang: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMWikiContent?> {
    return .init()
}

static var description: FragmentPath<Music.LastFMWikiContent?> { .init() }


static var artist: FragmentPath<Music.LastFMArtist?> { .init() }


static var album: FragmentPath<Music.LastFMAlbum?> { .init() }


static func similarTracks(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTrackConnection?> {
    return .init()
}

static var similarTracks: FragmentPath<Music.LastFMTrackConnection?> { .init() }


static func topTags(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTagConnection?> {
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


static func topTracks(market: GraphQLArgument<String> = .argument
) -> FragmentPath<[Music.SpotifyTrack]> {
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


static func musicBrainz(strategy: GraphQLArgument<[Music.SpotifyMatchStrategy]?> = .argument
) -> FragmentPath<Music.Recording?> {
    return .init()
}

static var musicBrainz: FragmentPath<Music.Recording?> { .init() }


    

    
    
    static var _fragment: FragmentPath<SpotifyTrack> { .init() }
}

enum SpotifyAudioFeatures: Target {

    
    typealias Path<V> = GraphQLPath<SpotifyAudioFeatures, V>
    typealias FragmentPath<V> = GraphQLFragmentPath<SpotifyAudioFeatures, V>

    

    

    
    
static var acousticness: Path<Float> { .init() }


static var danceability: Path<Float> { .init() }


static var duration: Path<String> { .init() }


static var energy: Path<Float> { .init() }


static var instrumentalness: Path<Float> { .init() }


static var key: Path<Int> { .init() }


static var keyName: Path<String> { .init() }


static var liveness: Path<Float> { .init() }


static var loudness: Path<Float> { .init() }


static var mode: FragmentPath<Music.SpotifyTrackMode> { .init() }


static var speechiness: Path<Float> { .init() }


static var tempo: Path<Float> { .init() }


static var timeSignature: Path<Float> { .init() }


static var valence: Path<Float> { .init() }


    

    
    
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


static func description(lang: GraphQLArgument<String?> = .argument
) -> Path<String?> {
    return .init()
}

static var description: Path<String?> { .init() }


static func thumbnail(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

static var thumbnail: Path<String?> { .init() }


static var score: Path<Float?> { .init() }


static var scoreVotes: Path<Float?> { .init() }


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


static func screenshots(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<[String?]> {
    return .init()
}

static var screenshots: Path<[String?]> { .init() }


static var viewCount: Path<Float?> { .init() }


static var likeCount: Path<Float?> { .init() }


static var dislikeCount: Path<Float?> { .init() }


static var commentCount: Path<Float?> { .init() }


    

    
    
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


static func biography(lang: GraphQLArgument<String?> = .argument
) -> Path<String?> {
    return .init()
}

static var biography: Path<String?> { .init() }


static var memberCount: Path<Int?> { .init() }


static func banner(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

static var banner: Path<String?> { .init() }


static func fanArt(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<[String?]> {
    return .init()
}

static var fanArt: Path<[String?]> { .init() }


static func logo(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

static var logo: Path<String?> { .init() }


static func thumbnail(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
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

    

    

    
    
static func topArtists(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMArtistConnection?> {
    return .init()
}

static var topArtists: FragmentPath<Music.LastFMArtistConnection?> { .init() }


static func topTracks(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTrackConnection?> {
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

    

    

    
    
static func areas(collection: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.AreaConnection?> {
    return .init()
}

static var areas: FragmentPath<Music.AreaConnection?> { .init() }


static func artists(area: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, recording: GraphQLArgument<String?> = .argument
, release: GraphQLArgument<String?> = .argument
, releaseGroup: GraphQLArgument<String?> = .argument
, work: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

static var artists: FragmentPath<Music.ArtistConnection?> { .init() }


static func collections(area: GraphQLArgument<String?> = .argument
, artist: GraphQLArgument<String?> = .argument
, editor: GraphQLArgument<String?> = .argument
, event: GraphQLArgument<String?> = .argument
, label: GraphQLArgument<String?> = .argument
, place: GraphQLArgument<String?> = .argument
, recording: GraphQLArgument<String?> = .argument
, release: GraphQLArgument<String?> = .argument
, releaseGroup: GraphQLArgument<String?> = .argument
, work: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

static var collections: FragmentPath<Music.CollectionConnection?> { .init() }


static func events(area: GraphQLArgument<String?> = .argument
, artist: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, place: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.EventConnection?> {
    return .init()
}

static var events: FragmentPath<Music.EventConnection?> { .init() }


static func labels(area: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, release: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.LabelConnection?> {
    return .init()
}

static var labels: FragmentPath<Music.LabelConnection?> { .init() }


static func places(area: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.PlaceConnection?> {
    return .init()
}

static var places: FragmentPath<Music.PlaceConnection?> { .init() }


static func recordings(artist: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, isrc: GraphQLArgument<String?> = .argument
, release: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RecordingConnection?> {
    return .init()
}

static var recordings: FragmentPath<Music.RecordingConnection?> { .init() }


static func releases(area: GraphQLArgument<String?> = .argument
, artist: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, discID: GraphQLArgument<String?> = .argument
, label: GraphQLArgument<String?> = .argument
, recording: GraphQLArgument<String?> = .argument
, releaseGroup: GraphQLArgument<String?> = .argument
, track: GraphQLArgument<String?> = .argument
, trackArtist: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, status: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

static var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


static func releaseGroups(artist: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, release: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseGroupConnection?> {
    return .init()
}

static var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }


static func works(artist: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, iswc: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.WorkConnection?> {
    return .init()
}

static var works: FragmentPath<Music.WorkConnection?> { .init() }


    

    
    
    static var _fragment: FragmentPath<BrowseQuery> { .init() }
}

enum SearchQuery: Target {

    
    typealias Path<V> = GraphQLPath<SearchQuery, V>
    typealias FragmentPath<V> = GraphQLFragmentPath<SearchQuery, V>

    

    

    
    
static func areas(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.AreaConnection?> {
    return .init()
}

static var areas: FragmentPath<Music.AreaConnection?> { .init() }


static func artists(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

static var artists: FragmentPath<Music.ArtistConnection?> { .init() }


static func events(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.EventConnection?> {
    return .init()
}

static var events: FragmentPath<Music.EventConnection?> { .init() }


static func instruments(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.InstrumentConnection?> {
    return .init()
}

static var instruments: FragmentPath<Music.InstrumentConnection?> { .init() }


static func labels(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.LabelConnection?> {
    return .init()
}

static var labels: FragmentPath<Music.LabelConnection?> { .init() }


static func places(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.PlaceConnection?> {
    return .init()
}

static var places: FragmentPath<Music.PlaceConnection?> { .init() }


static func recordings(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RecordingConnection?> {
    return .init()
}

static var recordings: FragmentPath<Music.RecordingConnection?> { .init() }


static func releases(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

static var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


static func releaseGroups(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseGroupConnection?> {
    return .init()
}

static var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }


static func series(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.SeriesConnection?> {
    return .init()
}

static var series: FragmentPath<Music.SeriesConnection?> { .init() }


static func works(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.WorkConnection?> {
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

    

    

    
    
static func topArtists(country: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMArtistConnection?> {
    return .init()
}

static var topArtists: FragmentPath<Music.LastFMArtistConnection?> { .init() }


static func topTags(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTagConnection?> {
    return .init()
}

static var topTags: FragmentPath<Music.LastFMTagConnection?> { .init() }


static func topTracks(country: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTrackConnection?> {
    return .init()
}

static var topTracks: FragmentPath<Music.LastFMTrackConnection?> { .init() }


    

    
    
    static var _fragment: FragmentPath<LastFMChartQuery> { .init() }
}

enum SpotifyQuery: Target {

    
    typealias Path<V> = GraphQLPath<SpotifyQuery, V>
    typealias FragmentPath<V> = GraphQLFragmentPath<SpotifyQuery, V>

    

    

    
    
static func recommendations(seedArtists: GraphQLArgument<[String]?> = .argument
, seedGenres: GraphQLArgument<[String]?> = .argument
, seedTracks: GraphQLArgument<[String]?> = .argument
, limit: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.SpotifyRecommendations> {
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
    
func area(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Area?> {
    return .init()
}

var area: FragmentPath<Music.Area?> { .init() }


func artist(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Artist?> {
    return .init()
}

var artist: FragmentPath<Music.Artist?> { .init() }


func collection(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Collection?> {
    return .init()
}

var collection: FragmentPath<Music.Collection?> { .init() }


func disc(discID: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Disc?> {
    return .init()
}

var disc: FragmentPath<Music.Disc?> { .init() }


func event(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Event?> {
    return .init()
}

var event: FragmentPath<Music.Event?> { .init() }


func instrument(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Instrument?> {
    return .init()
}

var instrument: FragmentPath<Music.Instrument?> { .init() }


func label(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Label?> {
    return .init()
}

var label: FragmentPath<Music.Label?> { .init() }


func place(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Place?> {
    return .init()
}

var place: FragmentPath<Music.Place?> { .init() }


func recording(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Recording?> {
    return .init()
}

var recording: FragmentPath<Music.Recording?> { .init() }


func release(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Release?> {
    return .init()
}

var release: FragmentPath<Music.Release?> { .init() }


func releaseGroup(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.ReleaseGroup?> {
    return .init()
}

var releaseGroup: FragmentPath<Music.ReleaseGroup?> { .init() }


func series(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Series?> {
    return .init()
}

var series: FragmentPath<Music.Series?> { .init() }


func url(mbid: GraphQLArgument<String?> = .argument
, resource: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.URL?> {
    return .init()
}

var url: FragmentPath<Music.URL?> { .init() }


func work(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Work?> {
    return .init()
}

var work: FragmentPath<Music.Work?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.LookupQuery? {
    
func area(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Area?> {
    return .init()
}

var area: FragmentPath<Music.Area?> { .init() }


func artist(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Artist?> {
    return .init()
}

var artist: FragmentPath<Music.Artist?> { .init() }


func collection(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Collection?> {
    return .init()
}

var collection: FragmentPath<Music.Collection?> { .init() }


func disc(discID: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Disc?> {
    return .init()
}

var disc: FragmentPath<Music.Disc?> { .init() }


func event(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Event?> {
    return .init()
}

var event: FragmentPath<Music.Event?> { .init() }


func instrument(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Instrument?> {
    return .init()
}

var instrument: FragmentPath<Music.Instrument?> { .init() }


func label(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Label?> {
    return .init()
}

var label: FragmentPath<Music.Label?> { .init() }


func place(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Place?> {
    return .init()
}

var place: FragmentPath<Music.Place?> { .init() }


func recording(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Recording?> {
    return .init()
}

var recording: FragmentPath<Music.Recording?> { .init() }


func release(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Release?> {
    return .init()
}

var release: FragmentPath<Music.Release?> { .init() }


func releaseGroup(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.ReleaseGroup?> {
    return .init()
}

var releaseGroup: FragmentPath<Music.ReleaseGroup?> { .init() }


func series(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Series?> {
    return .init()
}

var series: FragmentPath<Music.Series?> { .init() }


func url(mbid: GraphQLArgument<String?> = .argument
, resource: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.URL?> {
    return .init()
}

var url: FragmentPath<Music.URL?> { .init() }


func work(mbid: GraphQLArgument<String> = .argument
) -> FragmentPath<Music.Work?> {
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


func isoCodes(standard: GraphQLArgument<String?> = .argument
) -> Path<[String?]?> {
    return .init()
}

var isoCodes: Path<[String?]?> { .init() }


var type: Path<String?> { .init() }


var typeId: Path<String?> { .init() }


func artists(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

var artists: FragmentPath<Music.ArtistConnection?> { .init() }


func events(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.EventConnection?> {
    return .init()
}

var events: FragmentPath<Music.EventConnection?> { .init() }


func labels(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.LabelConnection?> {
    return .init()
}

var labels: FragmentPath<Music.LabelConnection?> { .init() }


func places(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.PlaceConnection?> {
    return .init()
}

var places: FragmentPath<Music.PlaceConnection?> { .init() }


func releases(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, status: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


var relationships: FragmentPath<Music.Relationships?> { .init() }


func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
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


func isoCodes(standard: GraphQLArgument<String?> = .argument
) -> Path<[String?]?> {
    return .init()
}

var isoCodes: Path<[String?]?> { .init() }


var type: Path<String?> { .init() }


var typeId: Path<String?> { .init() }


func artists(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

var artists: FragmentPath<Music.ArtistConnection?> { .init() }


func events(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.EventConnection?> {
    return .init()
}

var events: FragmentPath<Music.EventConnection?> { .init() }


func labels(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.LabelConnection?> {
    return .init()
}

var labels: FragmentPath<Music.LabelConnection?> { .init() }


func places(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.PlaceConnection?> {
    return .init()
}

var places: FragmentPath<Music.PlaceConnection?> { .init() }


func releases(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, status: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


var relationships: FragmentPath<Music.Relationships?> { .init() }


func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
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


func recordings(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RecordingConnection?> {
    return .init()
}

var recordings: FragmentPath<Music.RecordingConnection?> { .init() }


func releases(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, status: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


func releaseGroups(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseGroupConnection?> {
    return .init()
}

var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }


func works(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.WorkConnection?> {
    return .init()
}

var works: FragmentPath<Music.WorkConnection?> { .init() }


var relationships: FragmentPath<Music.Relationships?> { .init() }


func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


var rating: FragmentPath<Music.Rating?> { .init() }


func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
    return .init()
}

var tags: FragmentPath<Music.TagConnection?> { .init() }


var fanArt: FragmentPath<Music.FanArtArtist?> { .init() }


func mediaWikiImages(type: GraphQLArgument<String?> = .argument
) -> FragmentPath<[Music.MediaWikiImage?]> {
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


func recordings(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RecordingConnection?> {
    return .init()
}

var recordings: FragmentPath<Music.RecordingConnection?> { .init() }


func releases(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, status: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


func releaseGroups(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseGroupConnection?> {
    return .init()
}

var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }


func works(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.WorkConnection?> {
    return .init()
}

var works: FragmentPath<Music.WorkConnection?> { .init() }


var relationships: FragmentPath<Music.Relationships?> { .init() }


func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


var rating: FragmentPath<Music.Rating?> { .init() }


func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
    return .init()
}

var tags: FragmentPath<Music.TagConnection?> { .init() }


var fanArt: FragmentPath<Music.FanArtArtist?> { .init() }


func mediaWikiImages(type: GraphQLArgument<String?> = .argument
) -> FragmentPath<[Music.MediaWikiImage?]?> {
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


func artists(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

var artists: FragmentPath<Music.ArtistConnection?> { .init() }


func releases(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, status: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


var relationships: FragmentPath<Music.Relationships?> { .init() }


func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


var rating: FragmentPath<Music.Rating?> { .init() }


func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
    return .init()
}

var tags: FragmentPath<Music.TagConnection?> { .init() }


var theAudioDb: FragmentPath<Music.TheAudioDBTrack?> { .init() }


var lastFm: FragmentPath<Music.LastFMTrack?> { .init() }


func spotify(strategy: GraphQLArgument<[Music.SpotifyMatchStrategy]?> = .argument
) -> FragmentPath<Music.SpotifyTrack?> {
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


func artists(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

var artists: FragmentPath<Music.ArtistConnection?> { .init() }


func releases(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, status: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


var relationships: FragmentPath<Music.Relationships?> { .init() }


func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


var rating: FragmentPath<Music.Rating?> { .init() }


func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
    return .init()
}

var tags: FragmentPath<Music.TagConnection?> { .init() }


var theAudioDb: FragmentPath<Music.TheAudioDBTrack?> { .init() }


var lastFm: FragmentPath<Music.LastFMTrack?> { .init() }


func spotify(strategy: GraphQLArgument<[Music.SpotifyMatchStrategy]?> = .argument
) -> FragmentPath<Music.SpotifyTrack?> {
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

extension GraphQLFragmentPath where UnderlyingType == Music.ReleaseGroupType {
    

    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.ReleaseGroupType? {
    

    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.ReleaseStatus {
    

    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.ReleaseStatus? {
    

    

    
}

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


func artists(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

var artists: FragmentPath<Music.ArtistConnection?> { .init() }


func labels(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.LabelConnection?> {
    return .init()
}

var labels: FragmentPath<Music.LabelConnection?> { .init() }


func recordings(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RecordingConnection?> {
    return .init()
}

var recordings: FragmentPath<Music.RecordingConnection?> { .init() }


func releaseGroups(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseGroupConnection?> {
    return .init()
}

var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }


var relationships: FragmentPath<Music.Relationships?> { .init() }


func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
    return .init()
}

var tags: FragmentPath<Music.TagConnection?> { .init() }


var coverArtArchive: FragmentPath<Music.CoverArtArchiveRelease?> { .init() }


var discogs: FragmentPath<Music.DiscogsRelease?> { .init() }


var lastFm: FragmentPath<Music.LastFMAlbum?> { .init() }


func spotify(strategy: GraphQLArgument<[Music.SpotifyMatchStrategy]?> = .argument
) -> FragmentPath<Music.SpotifyAlbum?> {
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


func artists(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

var artists: FragmentPath<Music.ArtistConnection?> { .init() }


func labels(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.LabelConnection?> {
    return .init()
}

var labels: FragmentPath<Music.LabelConnection?> { .init() }


func recordings(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RecordingConnection?> {
    return .init()
}

var recordings: FragmentPath<Music.RecordingConnection?> { .init() }


func releaseGroups(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseGroupConnection?> {
    return .init()
}

var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }


var relationships: FragmentPath<Music.Relationships?> { .init() }


func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
    return .init()
}

var tags: FragmentPath<Music.TagConnection?> { .init() }


var coverArtArchive: FragmentPath<Music.CoverArtArchiveRelease?> { .init() }


var discogs: FragmentPath<Music.DiscogsRelease?> { .init() }


var lastFm: FragmentPath<Music.LastFMAlbum?> { .init() }


func spotify(strategy: GraphQLArgument<[Music.SpotifyMatchStrategy]?> = .argument
) -> FragmentPath<Music.SpotifyAlbum?> {
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


func releases(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
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


func releases(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
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


func releases(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, status: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


var relationships: FragmentPath<Music.Relationships?> { .init() }


func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


var rating: FragmentPath<Music.Rating?> { .init() }


func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
    return .init()
}

var tags: FragmentPath<Music.TagConnection?> { .init() }


var fanArt: FragmentPath<Music.FanArtLabel?> { .init() }


func mediaWikiImages(type: GraphQLArgument<String?> = .argument
) -> FragmentPath<[Music.MediaWikiImage?]> {
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


func releases(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, status: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


var relationships: FragmentPath<Music.Relationships?> { .init() }


func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


var rating: FragmentPath<Music.Rating?> { .init() }


func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
    return .init()
}

var tags: FragmentPath<Music.TagConnection?> { .init() }


var fanArt: FragmentPath<Music.FanArtLabel?> { .init() }


func mediaWikiImages(type: GraphQLArgument<String?> = .argument
) -> FragmentPath<[Music.MediaWikiImage?]?> {
    return .init()
}

var mediaWikiImages: FragmentPath<[Music.MediaWikiImage?]?> { .init() }


var discogs: FragmentPath<Music.DiscogsLabel?> { .init() }


    
    var node: FragmentPath<Music.Node?> { .init() }
    
    var entity: FragmentPath<Music.Entity?> { .init() }
    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.Relationships {
    
func areas(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

var areas: FragmentPath<Music.RelationshipConnection?> { .init() }


func artists(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

var artists: FragmentPath<Music.RelationshipConnection?> { .init() }


func events(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

var events: FragmentPath<Music.RelationshipConnection?> { .init() }


func instruments(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

var instruments: FragmentPath<Music.RelationshipConnection?> { .init() }


func labels(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

var labels: FragmentPath<Music.RelationshipConnection?> { .init() }


func places(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

var places: FragmentPath<Music.RelationshipConnection?> { .init() }


func recordings(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

var recordings: FragmentPath<Music.RelationshipConnection?> { .init() }


func releases(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

var releases: FragmentPath<Music.RelationshipConnection?> { .init() }


func releaseGroups(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

var releaseGroups: FragmentPath<Music.RelationshipConnection?> { .init() }


func series(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

var series: FragmentPath<Music.RelationshipConnection?> { .init() }


func urls(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

var urls: FragmentPath<Music.RelationshipConnection?> { .init() }


func works(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

var works: FragmentPath<Music.RelationshipConnection?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.Relationships? {
    
func areas(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

var areas: FragmentPath<Music.RelationshipConnection?> { .init() }


func artists(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

var artists: FragmentPath<Music.RelationshipConnection?> { .init() }


func events(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

var events: FragmentPath<Music.RelationshipConnection?> { .init() }


func instruments(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

var instruments: FragmentPath<Music.RelationshipConnection?> { .init() }


func labels(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

var labels: FragmentPath<Music.RelationshipConnection?> { .init() }


func places(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

var places: FragmentPath<Music.RelationshipConnection?> { .init() }


func recordings(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

var recordings: FragmentPath<Music.RelationshipConnection?> { .init() }


func releases(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

var releases: FragmentPath<Music.RelationshipConnection?> { .init() }


func releaseGroups(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

var releaseGroups: FragmentPath<Music.RelationshipConnection?> { .init() }


func series(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

var series: FragmentPath<Music.RelationshipConnection?> { .init() }


func urls(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
    return .init()
}

var urls: FragmentPath<Music.RelationshipConnection?> { .init() }


func works(direction: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<String?> = .argument
, typeID: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, before: GraphQLArgument<String?> = .argument
, last: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RelationshipConnection?> {
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


func areas(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.AreaConnection?> {
    return .init()
}

var areas: FragmentPath<Music.AreaConnection?> { .init() }


func artists(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

var artists: FragmentPath<Music.ArtistConnection?> { .init() }


func events(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.EventConnection?> {
    return .init()
}

var events: FragmentPath<Music.EventConnection?> { .init() }


func instruments(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.InstrumentConnection?> {
    return .init()
}

var instruments: FragmentPath<Music.InstrumentConnection?> { .init() }


func labels(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.LabelConnection?> {
    return .init()
}

var labels: FragmentPath<Music.LabelConnection?> { .init() }


func places(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.PlaceConnection?> {
    return .init()
}

var places: FragmentPath<Music.PlaceConnection?> { .init() }


func recordings(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RecordingConnection?> {
    return .init()
}

var recordings: FragmentPath<Music.RecordingConnection?> { .init() }


func releases(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, status: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


func releaseGroups(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseGroupConnection?> {
    return .init()
}

var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }


func series(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.SeriesConnection?> {
    return .init()
}

var series: FragmentPath<Music.SeriesConnection?> { .init() }


func works(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.WorkConnection?> {
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


func areas(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.AreaConnection?> {
    return .init()
}

var areas: FragmentPath<Music.AreaConnection?> { .init() }


func artists(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

var artists: FragmentPath<Music.ArtistConnection?> { .init() }


func events(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.EventConnection?> {
    return .init()
}

var events: FragmentPath<Music.EventConnection?> { .init() }


func instruments(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.InstrumentConnection?> {
    return .init()
}

var instruments: FragmentPath<Music.InstrumentConnection?> { .init() }


func labels(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.LabelConnection?> {
    return .init()
}

var labels: FragmentPath<Music.LabelConnection?> { .init() }


func places(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.PlaceConnection?> {
    return .init()
}

var places: FragmentPath<Music.PlaceConnection?> { .init() }


func recordings(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RecordingConnection?> {
    return .init()
}

var recordings: FragmentPath<Music.RecordingConnection?> { .init() }


func releases(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, status: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


func releaseGroups(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseGroupConnection?> {
    return .init()
}

var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }


func series(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.SeriesConnection?> {
    return .init()
}

var series: FragmentPath<Music.SeriesConnection?> { .init() }


func works(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.WorkConnection?> {
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


func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


var rating: FragmentPath<Music.Rating?> { .init() }


func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
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


func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


var rating: FragmentPath<Music.Rating?> { .init() }


func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
    return .init()
}

var tags: FragmentPath<Music.TagConnection?> { .init() }


    
    var node: FragmentPath<Music.Node?> { .init() }
    
    var entity: FragmentPath<Music.Entity?> { .init() }
    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.Rating {
    
var voteCount: Path<Int> { .init() }


var value: Path<Float?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.Rating? {
    
var voteCount: Path<Int?> { .init() }


var value: Path<Float?> { .init() }


    

    
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


func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
    return .init()
}

var tags: FragmentPath<Music.TagConnection?> { .init() }


func mediaWikiImages(type: GraphQLArgument<String?> = .argument
) -> FragmentPath<[Music.MediaWikiImage?]> {
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


func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
    return .init()
}

var tags: FragmentPath<Music.TagConnection?> { .init() }


func mediaWikiImages(type: GraphQLArgument<String?> = .argument
) -> FragmentPath<[Music.MediaWikiImage?]?> {
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


func events(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.EventConnection?> {
    return .init()
}

var events: FragmentPath<Music.EventConnection?> { .init() }


var relationships: FragmentPath<Music.Relationships?> { .init() }


func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
    return .init()
}

var tags: FragmentPath<Music.TagConnection?> { .init() }


func mediaWikiImages(type: GraphQLArgument<String?> = .argument
) -> FragmentPath<[Music.MediaWikiImage?]> {
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


func events(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.EventConnection?> {
    return .init()
}

var events: FragmentPath<Music.EventConnection?> { .init() }


var relationships: FragmentPath<Music.Relationships?> { .init() }


func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
    return .init()
}

var tags: FragmentPath<Music.TagConnection?> { .init() }


func mediaWikiImages(type: GraphQLArgument<String?> = .argument
) -> FragmentPath<[Music.MediaWikiImage?]?> {
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


func artists(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

var artists: FragmentPath<Music.ArtistConnection?> { .init() }


func releases(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, status: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


var relationships: FragmentPath<Music.Relationships?> { .init() }


func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


var rating: FragmentPath<Music.Rating?> { .init() }


func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
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


func artists(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

var artists: FragmentPath<Music.ArtistConnection?> { .init() }


func releases(type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, status: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


var relationships: FragmentPath<Music.Relationships?> { .init() }


func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


var rating: FragmentPath<Music.Rating?> { .init() }


func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
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
    
func front(size: GraphQLArgument<Music.CoverArtArchiveImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var front: Path<String?> { .init() }


func back(size: GraphQLArgument<Music.CoverArtArchiveImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var back: Path<String?> { .init() }


var images: FragmentPath<[Music.CoverArtArchiveImage?]> { .init() }


var artwork: Path<Bool> { .init() }


var count: Path<Int> { .init() }


var release: FragmentPath<Music.Release?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.CoverArtArchiveRelease? {
    
func front(size: GraphQLArgument<Music.CoverArtArchiveImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var front: Path<String?> { .init() }


func back(size: GraphQLArgument<Music.CoverArtArchiveImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var back: Path<String?> { .init() }


var images: FragmentPath<[Music.CoverArtArchiveImage?]?> { .init() }


var artwork: Path<Bool?> { .init() }


var count: Path<Int?> { .init() }


var release: FragmentPath<Music.Release?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.CoverArtArchiveImageSize {
    

    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.CoverArtArchiveImageSize? {
    

    

    
}

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


func url(size: GraphQLArgument<Music.FanArtImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var url: Path<String?> { .init() }


var likeCount: Path<Int?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.FanArtImage? {
    
var imageId: Path<String?> { .init() }


func url(size: GraphQLArgument<Music.FanArtImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var url: Path<String?> { .init() }


var likeCount: Path<Int?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.FanArtImageSize {
    

    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.FanArtImageSize? {
    

    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.FanArtDiscImage {
    
var imageId: Path<String?> { .init() }


func url(size: GraphQLArgument<Music.FanArtImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var url: Path<String?> { .init() }


var likeCount: Path<Int?> { .init() }


var discNumber: Path<Int?> { .init() }


var size: Path<Int?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.FanArtDiscImage? {
    
var imageId: Path<String?> { .init() }


func url(size: GraphQLArgument<Music.FanArtImageSize?> = .argument
) -> Path<String?> {
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


func description(lang: GraphQLArgument<String?> = .argument
) -> Path<String?> {
    return .init()
}

var description: Path<String?> { .init() }


var review: Path<String?> { .init() }


var salesCount: Path<Float?> { .init() }


var score: Path<Float?> { .init() }


var scoreVotes: Path<Float?> { .init() }


func discImage(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var discImage: Path<String?> { .init() }


func spineImage(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var spineImage: Path<String?> { .init() }


func frontImage(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var frontImage: Path<String?> { .init() }


func backImage(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
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


func description(lang: GraphQLArgument<String?> = .argument
) -> Path<String?> {
    return .init()
}

var description: Path<String?> { .init() }


var review: Path<String?> { .init() }


var salesCount: Path<Float?> { .init() }


var score: Path<Float?> { .init() }


var scoreVotes: Path<Float?> { .init() }


func discImage(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var discImage: Path<String?> { .init() }


func spineImage(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var spineImage: Path<String?> { .init() }


func frontImage(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var frontImage: Path<String?> { .init() }


func backImage(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var backImage: Path<String?> { .init() }


var genre: Path<String?> { .init() }


var mood: Path<String?> { .init() }


var style: Path<String?> { .init() }


var speed: Path<String?> { .init() }


var theme: Path<String?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDBImageSize {
    

    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDBImageSize? {
    

    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsMaster {
    
var masterId: Path<String> { .init() }


var title: Path<String> { .init() }


var url: Path<String> { .init() }


var artistCredits: FragmentPath<[Music.DiscogsArtistCredit]> { .init() }


var genres: Path<[String]> { .init() }


var styles: Path<[String]> { .init() }


var forSaleCount: Path<Int?> { .init() }


func lowestPrice(currency: GraphQLArgument<String?> = .argument
) -> Path<Float?> {
    return .init()
}

var lowestPrice: Path<Float?> { .init() }


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


func lowestPrice(currency: GraphQLArgument<String?> = .argument
) -> Path<Float?> {
    return .init()
}

var lowestPrice: Path<Float?> { .init() }


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

extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsImageType {
    

    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsImageType? {
    

    

    
}

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


func lowestPrice(currency: GraphQLArgument<String?> = .argument
) -> Path<Float?> {
    return .init()
}

var lowestPrice: Path<Float?> { .init() }


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


func lowestPrice(currency: GraphQLArgument<String?> = .argument
) -> Path<Float?> {
    return .init()
}

var lowestPrice: Path<Float?> { .init() }


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


var value: Path<Float?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.DiscogsRating? {
    
var voteCount: Path<Int?> { .init() }


var value: Path<Float?> { .init() }


    

    
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


func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
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


func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
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


func artists(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

var artists: FragmentPath<Music.ArtistConnection?> { .init() }


var relationships: FragmentPath<Music.Relationships?> { .init() }


func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


var rating: FragmentPath<Music.Rating?> { .init() }


func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
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


func artists(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

var artists: FragmentPath<Music.ArtistConnection?> { .init() }


var relationships: FragmentPath<Music.Relationships?> { .init() }


func collections(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


var rating: FragmentPath<Music.Rating?> { .init() }


func tags(after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.TagConnection?> {
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


func url(size: GraphQLArgument<Music.FanArtImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var url: Path<String?> { .init() }


var likeCount: Path<Int?> { .init() }


var color: Path<String?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.FanArtLabelImage? {
    
var imageId: Path<String?> { .init() }


func url(size: GraphQLArgument<Music.FanArtImageSize?> = .argument
) -> Path<String?> {
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


func image(size: GraphQLArgument<Music.LastFMImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var image: Path<String?> { .init() }


var listenerCount: Path<Float?> { .init() }


var playCount: Path<Float?> { .init() }


func description(lang: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMWikiContent?> {
    return .init()
}

var description: FragmentPath<Music.LastFMWikiContent?> { .init() }


var artist: FragmentPath<Music.LastFMArtist?> { .init() }


func topTags(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTagConnection?> {
    return .init()
}

var topTags: FragmentPath<Music.LastFMTagConnection?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMAlbum? {
    
var mbid: Path<String?> { .init() }


var title: Path<String?> { .init() }


var url: Path<String?> { .init() }


func image(size: GraphQLArgument<Music.LastFMImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var image: Path<String?> { .init() }


var listenerCount: Path<Float?> { .init() }


var playCount: Path<Float?> { .init() }


func description(lang: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMWikiContent?> {
    return .init()
}

var description: FragmentPath<Music.LastFMWikiContent?> { .init() }


var artist: FragmentPath<Music.LastFMArtist?> { .init() }


func topTags(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTagConnection?> {
    return .init()
}

var topTags: FragmentPath<Music.LastFMTagConnection?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMImageSize {
    

    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMImageSize? {
    

    

    
}

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


func image(size: GraphQLArgument<Music.LastFMImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var image: Path<String?> { .init() }


var listenerCount: Path<Float?> { .init() }


var playCount: Path<Float?> { .init() }


func similarArtists(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMArtistConnection?> {
    return .init()
}

var similarArtists: FragmentPath<Music.LastFMArtistConnection?> { .init() }


func topAlbums(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMAlbumConnection?> {
    return .init()
}

var topAlbums: FragmentPath<Music.LastFMAlbumConnection?> { .init() }


func topTags(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTagConnection?> {
    return .init()
}

var topTags: FragmentPath<Music.LastFMTagConnection?> { .init() }


func topTracks(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTrackConnection?> {
    return .init()
}

var topTracks: FragmentPath<Music.LastFMTrackConnection?> { .init() }


func biography(lang: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMWikiContent?> {
    return .init()
}

var biography: FragmentPath<Music.LastFMWikiContent?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMArtist? {
    
var mbid: Path<String?> { .init() }


var name: Path<String?> { .init() }


var url: Path<String?> { .init() }


func image(size: GraphQLArgument<Music.LastFMImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var image: Path<String?> { .init() }


var listenerCount: Path<Float?> { .init() }


var playCount: Path<Float?> { .init() }


func similarArtists(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMArtistConnection?> {
    return .init()
}

var similarArtists: FragmentPath<Music.LastFMArtistConnection?> { .init() }


func topAlbums(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMAlbumConnection?> {
    return .init()
}

var topAlbums: FragmentPath<Music.LastFMAlbumConnection?> { .init() }


func topTags(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTagConnection?> {
    return .init()
}

var topTags: FragmentPath<Music.LastFMTagConnection?> { .init() }


func topTracks(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTrackConnection?> {
    return .init()
}

var topTracks: FragmentPath<Music.LastFMTrackConnection?> { .init() }


func biography(lang: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMWikiContent?> {
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


var matchScore: Path<Float?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMArtistEdge? {
    
var node: FragmentPath<Music.LastFMArtist?> { .init() }


var cursor: Path<String?> { .init() }


var matchScore: Path<Float?> { .init() }


    

    
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


var matchScore: Path<Float?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMTrackEdge? {
    
var node: FragmentPath<Music.LastFMTrack?> { .init() }


var cursor: Path<String?> { .init() }


var matchScore: Path<Float?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMTrack {
    
var mbid: Path<String?> { .init() }


var title: Path<String?> { .init() }


var url: Path<String> { .init() }


var duration: Path<String?> { .init() }


var listenerCount: Path<Float?> { .init() }


var playCount: Path<Float?> { .init() }


func description(lang: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMWikiContent?> {
    return .init()
}

var description: FragmentPath<Music.LastFMWikiContent?> { .init() }


var artist: FragmentPath<Music.LastFMArtist?> { .init() }


var album: FragmentPath<Music.LastFMAlbum?> { .init() }


func similarTracks(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTrackConnection?> {
    return .init()
}

var similarTracks: FragmentPath<Music.LastFMTrackConnection?> { .init() }


func topTags(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTagConnection?> {
    return .init()
}

var topTags: FragmentPath<Music.LastFMTagConnection?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMTrack? {
    
var mbid: Path<String?> { .init() }


var title: Path<String?> { .init() }


var url: Path<String?> { .init() }


var duration: Path<String?> { .init() }


var listenerCount: Path<Float?> { .init() }


var playCount: Path<Float?> { .init() }


func description(lang: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMWikiContent?> {
    return .init()
}

var description: FragmentPath<Music.LastFMWikiContent?> { .init() }


var artist: FragmentPath<Music.LastFMArtist?> { .init() }


var album: FragmentPath<Music.LastFMAlbum?> { .init() }


func similarTracks(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTrackConnection?> {
    return .init()
}

var similarTracks: FragmentPath<Music.LastFMTrackConnection?> { .init() }


func topTags(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTagConnection?> {
    return .init()
}

var topTags: FragmentPath<Music.LastFMTagConnection?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyMatchStrategy {
    

    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyMatchStrategy? {
    

    

    
}

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


func topTracks(market: GraphQLArgument<String> = .argument
) -> FragmentPath<[Music.SpotifyTrack]> {
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


func topTracks(market: GraphQLArgument<String> = .argument
) -> FragmentPath<[Music.SpotifyTrack]?> {
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


func musicBrainz(strategy: GraphQLArgument<[Music.SpotifyMatchStrategy]?> = .argument
) -> FragmentPath<Music.Recording?> {
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


func musicBrainz(strategy: GraphQLArgument<[Music.SpotifyMatchStrategy]?> = .argument
) -> FragmentPath<Music.Recording?> {
    return .init()
}

var musicBrainz: FragmentPath<Music.Recording?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyAudioFeatures {
    
var acousticness: Path<Float> { .init() }


var danceability: Path<Float> { .init() }


var duration: Path<String> { .init() }


var energy: Path<Float> { .init() }


var instrumentalness: Path<Float> { .init() }


var key: Path<Int> { .init() }


var keyName: Path<String> { .init() }


var liveness: Path<Float> { .init() }


var loudness: Path<Float> { .init() }


var mode: FragmentPath<Music.SpotifyTrackMode> { .init() }


var speechiness: Path<Float> { .init() }


var tempo: Path<Float> { .init() }


var timeSignature: Path<Float> { .init() }


var valence: Path<Float> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyAudioFeatures? {
    
var acousticness: Path<Float?> { .init() }


var danceability: Path<Float?> { .init() }


var duration: Path<String?> { .init() }


var energy: Path<Float?> { .init() }


var instrumentalness: Path<Float?> { .init() }


var key: Path<Int?> { .init() }


var keyName: Path<String?> { .init() }


var liveness: Path<Float?> { .init() }


var loudness: Path<Float?> { .init() }


var mode: FragmentPath<Music.SpotifyTrackMode?> { .init() }


var speechiness: Path<Float?> { .init() }


var tempo: Path<Float?> { .init() }


var timeSignature: Path<Float?> { .init() }


var valence: Path<Float?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyTrackMode {
    

    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyTrackMode? {
    

    

    
}

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

extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyCopyrightType {
    

    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyCopyrightType? {
    

    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDBTrack {
    
var trackId: Path<String?> { .init() }


var albumId: Path<String?> { .init() }


var artistId: Path<String?> { .init() }


func description(lang: GraphQLArgument<String?> = .argument
) -> Path<String?> {
    return .init()
}

var description: Path<String?> { .init() }


func thumbnail(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var thumbnail: Path<String?> { .init() }


var score: Path<Float?> { .init() }


var scoreVotes: Path<Float?> { .init() }


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


func description(lang: GraphQLArgument<String?> = .argument
) -> Path<String?> {
    return .init()
}

var description: Path<String?> { .init() }


func thumbnail(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var thumbnail: Path<String?> { .init() }


var score: Path<Float?> { .init() }


var scoreVotes: Path<Float?> { .init() }


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


func screenshots(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<[String?]> {
    return .init()
}

var screenshots: Path<[String?]> { .init() }


var viewCount: Path<Float?> { .init() }


var likeCount: Path<Float?> { .init() }


var dislikeCount: Path<Float?> { .init() }


var commentCount: Path<Float?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDBMusicVideo? {
    
var url: Path<String?> { .init() }


var companyName: Path<String?> { .init() }


var directorName: Path<String?> { .init() }


func screenshots(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<[String?]?> {
    return .init()
}

var screenshots: Path<[String?]?> { .init() }


var viewCount: Path<Float?> { .init() }


var likeCount: Path<Float?> { .init() }


var dislikeCount: Path<Float?> { .init() }


var commentCount: Path<Float?> { .init() }


    

    
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


func biography(lang: GraphQLArgument<String?> = .argument
) -> Path<String?> {
    return .init()
}

var biography: Path<String?> { .init() }


var memberCount: Path<Int?> { .init() }


func banner(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var banner: Path<String?> { .init() }


func fanArt(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<[String?]> {
    return .init()
}

var fanArt: Path<[String?]> { .init() }


func logo(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var logo: Path<String?> { .init() }


func thumbnail(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var thumbnail: Path<String?> { .init() }


var genre: Path<String?> { .init() }


var mood: Path<String?> { .init() }


var style: Path<String?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.TheAudioDBArtist? {
    
var artistId: Path<String?> { .init() }


func biography(lang: GraphQLArgument<String?> = .argument
) -> Path<String?> {
    return .init()
}

var biography: Path<String?> { .init() }


var memberCount: Path<Int?> { .init() }


func banner(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var banner: Path<String?> { .init() }


func fanArt(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<[String?]?> {
    return .init()
}

var fanArt: Path<[String?]?> { .init() }


func logo(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var logo: Path<String?> { .init() }


func thumbnail(size: GraphQLArgument<Music.TheAudioDBImageSize?> = .argument
) -> Path<String?> {
    return .init()
}

var thumbnail: Path<String?> { .init() }


var genre: Path<String?> { .init() }


var mood: Path<String?> { .init() }


var style: Path<String?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMCountry {
    
func topArtists(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMArtistConnection?> {
    return .init()
}

var topArtists: FragmentPath<Music.LastFMArtistConnection?> { .init() }


func topTracks(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTrackConnection?> {
    return .init()
}

var topTracks: FragmentPath<Music.LastFMTrackConnection?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMCountry? {
    
func topArtists(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMArtistConnection?> {
    return .init()
}

var topArtists: FragmentPath<Music.LastFMArtistConnection?> { .init() }


func topTracks(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTrackConnection?> {
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
    
func areas(collection: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.AreaConnection?> {
    return .init()
}

var areas: FragmentPath<Music.AreaConnection?> { .init() }


func artists(area: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, recording: GraphQLArgument<String?> = .argument
, release: GraphQLArgument<String?> = .argument
, releaseGroup: GraphQLArgument<String?> = .argument
, work: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

var artists: FragmentPath<Music.ArtistConnection?> { .init() }


func collections(area: GraphQLArgument<String?> = .argument
, artist: GraphQLArgument<String?> = .argument
, editor: GraphQLArgument<String?> = .argument
, event: GraphQLArgument<String?> = .argument
, label: GraphQLArgument<String?> = .argument
, place: GraphQLArgument<String?> = .argument
, recording: GraphQLArgument<String?> = .argument
, release: GraphQLArgument<String?> = .argument
, releaseGroup: GraphQLArgument<String?> = .argument
, work: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


func events(area: GraphQLArgument<String?> = .argument
, artist: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, place: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.EventConnection?> {
    return .init()
}

var events: FragmentPath<Music.EventConnection?> { .init() }


func labels(area: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, release: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.LabelConnection?> {
    return .init()
}

var labels: FragmentPath<Music.LabelConnection?> { .init() }


func places(area: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.PlaceConnection?> {
    return .init()
}

var places: FragmentPath<Music.PlaceConnection?> { .init() }


func recordings(artist: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, isrc: GraphQLArgument<String?> = .argument
, release: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RecordingConnection?> {
    return .init()
}

var recordings: FragmentPath<Music.RecordingConnection?> { .init() }


func releases(area: GraphQLArgument<String?> = .argument
, artist: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, discID: GraphQLArgument<String?> = .argument
, label: GraphQLArgument<String?> = .argument
, recording: GraphQLArgument<String?> = .argument
, releaseGroup: GraphQLArgument<String?> = .argument
, track: GraphQLArgument<String?> = .argument
, trackArtist: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, status: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


func releaseGroups(artist: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, release: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseGroupConnection?> {
    return .init()
}

var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }


func works(artist: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, iswc: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.WorkConnection?> {
    return .init()
}

var works: FragmentPath<Music.WorkConnection?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.BrowseQuery? {
    
func areas(collection: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.AreaConnection?> {
    return .init()
}

var areas: FragmentPath<Music.AreaConnection?> { .init() }


func artists(area: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, recording: GraphQLArgument<String?> = .argument
, release: GraphQLArgument<String?> = .argument
, releaseGroup: GraphQLArgument<String?> = .argument
, work: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

var artists: FragmentPath<Music.ArtistConnection?> { .init() }


func collections(area: GraphQLArgument<String?> = .argument
, artist: GraphQLArgument<String?> = .argument
, editor: GraphQLArgument<String?> = .argument
, event: GraphQLArgument<String?> = .argument
, label: GraphQLArgument<String?> = .argument
, place: GraphQLArgument<String?> = .argument
, recording: GraphQLArgument<String?> = .argument
, release: GraphQLArgument<String?> = .argument
, releaseGroup: GraphQLArgument<String?> = .argument
, work: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.CollectionConnection?> {
    return .init()
}

var collections: FragmentPath<Music.CollectionConnection?> { .init() }


func events(area: GraphQLArgument<String?> = .argument
, artist: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, place: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.EventConnection?> {
    return .init()
}

var events: FragmentPath<Music.EventConnection?> { .init() }


func labels(area: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, release: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.LabelConnection?> {
    return .init()
}

var labels: FragmentPath<Music.LabelConnection?> { .init() }


func places(area: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.PlaceConnection?> {
    return .init()
}

var places: FragmentPath<Music.PlaceConnection?> { .init() }


func recordings(artist: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, isrc: GraphQLArgument<String?> = .argument
, release: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RecordingConnection?> {
    return .init()
}

var recordings: FragmentPath<Music.RecordingConnection?> { .init() }


func releases(area: GraphQLArgument<String?> = .argument
, artist: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, discID: GraphQLArgument<String?> = .argument
, label: GraphQLArgument<String?> = .argument
, recording: GraphQLArgument<String?> = .argument
, releaseGroup: GraphQLArgument<String?> = .argument
, track: GraphQLArgument<String?> = .argument
, trackArtist: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, status: GraphQLArgument<[Music.ReleaseStatus?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


func releaseGroups(artist: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, release: GraphQLArgument<String?> = .argument
, type: GraphQLArgument<[Music.ReleaseGroupType?]?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseGroupConnection?> {
    return .init()
}

var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }


func works(artist: GraphQLArgument<String?> = .argument
, collection: GraphQLArgument<String?> = .argument
, iswc: GraphQLArgument<String?> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.WorkConnection?> {
    return .init()
}

var works: FragmentPath<Music.WorkConnection?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.SearchQuery {
    
func areas(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.AreaConnection?> {
    return .init()
}

var areas: FragmentPath<Music.AreaConnection?> { .init() }


func artists(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

var artists: FragmentPath<Music.ArtistConnection?> { .init() }


func events(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.EventConnection?> {
    return .init()
}

var events: FragmentPath<Music.EventConnection?> { .init() }


func instruments(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.InstrumentConnection?> {
    return .init()
}

var instruments: FragmentPath<Music.InstrumentConnection?> { .init() }


func labels(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.LabelConnection?> {
    return .init()
}

var labels: FragmentPath<Music.LabelConnection?> { .init() }


func places(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.PlaceConnection?> {
    return .init()
}

var places: FragmentPath<Music.PlaceConnection?> { .init() }


func recordings(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RecordingConnection?> {
    return .init()
}

var recordings: FragmentPath<Music.RecordingConnection?> { .init() }


func releases(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


func releaseGroups(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseGroupConnection?> {
    return .init()
}

var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }


func series(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.SeriesConnection?> {
    return .init()
}

var series: FragmentPath<Music.SeriesConnection?> { .init() }


func works(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.WorkConnection?> {
    return .init()
}

var works: FragmentPath<Music.WorkConnection?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.SearchQuery? {
    
func areas(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.AreaConnection?> {
    return .init()
}

var areas: FragmentPath<Music.AreaConnection?> { .init() }


func artists(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ArtistConnection?> {
    return .init()
}

var artists: FragmentPath<Music.ArtistConnection?> { .init() }


func events(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.EventConnection?> {
    return .init()
}

var events: FragmentPath<Music.EventConnection?> { .init() }


func instruments(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.InstrumentConnection?> {
    return .init()
}

var instruments: FragmentPath<Music.InstrumentConnection?> { .init() }


func labels(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.LabelConnection?> {
    return .init()
}

var labels: FragmentPath<Music.LabelConnection?> { .init() }


func places(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.PlaceConnection?> {
    return .init()
}

var places: FragmentPath<Music.PlaceConnection?> { .init() }


func recordings(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.RecordingConnection?> {
    return .init()
}

var recordings: FragmentPath<Music.RecordingConnection?> { .init() }


func releases(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseConnection?> {
    return .init()
}

var releases: FragmentPath<Music.ReleaseConnection?> { .init() }


func releaseGroups(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.ReleaseGroupConnection?> {
    return .init()
}

var releaseGroups: FragmentPath<Music.ReleaseGroupConnection?> { .init() }


func series(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.SeriesConnection?> {
    return .init()
}

var series: FragmentPath<Music.SeriesConnection?> { .init() }


func works(query: GraphQLArgument<String> = .argument
, after: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.WorkConnection?> {
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
    
func topArtists(country: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMArtistConnection?> {
    return .init()
}

var topArtists: FragmentPath<Music.LastFMArtistConnection?> { .init() }


func topTags(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTagConnection?> {
    return .init()
}

var topTags: FragmentPath<Music.LastFMTagConnection?> { .init() }


func topTracks(country: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTrackConnection?> {
    return .init()
}

var topTracks: FragmentPath<Music.LastFMTrackConnection?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.LastFMChartQuery? {
    
func topArtists(country: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMArtistConnection?> {
    return .init()
}

var topArtists: FragmentPath<Music.LastFMArtistConnection?> { .init() }


func topTags(first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTagConnection?> {
    return .init()
}

var topTags: FragmentPath<Music.LastFMTagConnection?> { .init() }


func topTracks(country: GraphQLArgument<String?> = .argument
, first: GraphQLArgument<Int?> = .argument
, after: GraphQLArgument<String?> = .argument
) -> FragmentPath<Music.LastFMTrackConnection?> {
    return .init()
}

var topTracks: FragmentPath<Music.LastFMTrackConnection?> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyQuery {
    
func recommendations(seedArtists: GraphQLArgument<[String]?> = .argument
, seedGenres: GraphQLArgument<[String]?> = .argument
, seedTracks: GraphQLArgument<[String]?> = .argument
, limit: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.SpotifyRecommendations> {
    return .init()
}

var recommendations: FragmentPath<Music.SpotifyRecommendations> { .init() }


    

    
}

extension GraphQLFragmentPath where UnderlyingType == Music.SpotifyQuery? {
    
func recommendations(seedArtists: GraphQLArgument<[String]?> = .argument
, seedGenres: GraphQLArgument<[String]?> = .argument
, seedTracks: GraphQLArgument<[String]?> = .argument
, limit: GraphQLArgument<Int?> = .argument
) -> FragmentPath<Music.SpotifyRecommendations?> {
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





// MARK: - AlbumDetailView



extension AlbumDetailView {
    
    
    typealias Data = ApolloStuff.AlbumDetailViewQuery.Data
    
    
    init(data: Data
) {
        self.init(title: GraphQL(data.lookup?.release?.title)
, cover: GraphQL(data.lookup?.release?.coverArtArchive?.front)
, media: GraphQL(data.lookup?.release?.media?.map { $0?.tracks?.map { $0?.fragments.albumTrackCellTrack } })
)
    }
}


extension Music {
    
    func albumDetailView(mbid: String
, size: Music.CoverArtArchiveImageSize? = Music.CoverArtArchiveImageSize.full
) -> some View {
        return QueryRenderer(client: client,
                             query: ApolloStuff.AlbumDetailViewQuery(mbid: mbid
, size: .init(size)
)) { data in
        
            AlbumDetailView(data: data
)
        }
    }
    
}






// MARK: - AlbumTrackCell


extension ApolloStuff.AlbumTrackCellTrack : Fragment {
    typealias UnderlyingType = Music.Track
}


extension AlbumTrackCell {
    
    typealias Track = ApolloStuff.AlbumTrackCellTrack
    
    
    
    init(track: Track
) {
        self.init(position: GraphQL(track.position)
, title: GraphQL(track.title)
)
    }
}







// MARK: - ArtistAlbumCell


extension ApolloStuff.ArtistAlbumCellReleaseGroup : Fragment {
    typealias UnderlyingType = Music.ReleaseGroup
}


extension ArtistAlbumCell {
    
    typealias ReleaseGroup = ApolloStuff.ArtistAlbumCellReleaseGroup
    
    
    
    init(api: Music
, releaseGroup: ReleaseGroup
) {
        self.init(api: api
, title: GraphQL(releaseGroup.title)
, cover: GraphQL(releaseGroup.theAudioDb?.frontImage)
, discImage: GraphQL(releaseGroup.theAudioDb?.frontImage)
, releaseIds: GraphQL(releaseGroup.releases?.nodes?.map { $0?.mbid })
)
    }
}







// MARK: - ArtistAlbumList



extension ArtistAlbumList {
    
    
    typealias Data = ApolloStuff.ArtistAlbumListQuery.Data
    
    
    init(api: Music
, albums: Paging<ArtistAlbumCell.ReleaseGroup>?
, data: Data
) {
        self.init(api: api
, albums: GraphQL(albums)
)
    }
}


extension Music {
    
    func artistAlbumList(mbid: String
, type: [Music.ReleaseGroupType?]? = nil
, after: String? = nil
, first: Int? = nil
, status: [Music.ReleaseStatus?]? = [.official]
, size: Music.TheAudioDBImageSize? = Music.TheAudioDBImageSize.full
) -> some View {
        return QueryRenderer(client: client,
                             query: ApolloStuff.ArtistAlbumListQuery(mbid: mbid
, type: .init(type)
, after: after
, first: first
, status: [.official]
, size: .init(size)
)) { data in
        
            ArtistAlbumList(api: self
, albums: data.lookup?.artist?.releaseGroups?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup.paging { _cursor, _pageSize, _completion in
    self.client.fetch(query: ApolloStuff.ArtistAlbumListReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery(mbid: mbid
, type: .init(type)
, after: _cursor
, first: _pageSize ?? first
, status: [.official]
, size: .init(size)
)) { result in
        _completion(result.map { $0.data?.lookup?.artist?.releaseGroups?.fragments.releaseGroupConnectionArtistAlbumCellReleaseGroup })
    }
}

, data: data
)
        }
    }
    
}


extension ApolloStuff.ArtistAlbumListQuery.Data.Lookup.Artist.ReleaseGroup {
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

extension ApolloStuff.ArtistAlbumListReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery.Data.Lookup.Artist.ReleaseGroup {
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

extension ApolloStuff.ArtistAlbumListQuery.Data.Lookup.Artist.ReleaseGroup.Fragments {

    public var releaseGroupConnectionArtistAlbumCellReleaseGroup: ApolloStuff.ReleaseGroupConnectionArtistAlbumCellReleaseGroup {
        get {
            return ApolloStuff.ReleaseGroupConnectionArtistAlbumCellReleaseGroup(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }

}

extension ApolloStuff.ArtistAlbumListReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery.Data.Lookup.Artist.ReleaseGroup.Fragments {

    public var releaseGroupConnectionArtistAlbumCellReleaseGroup: ApolloStuff.ReleaseGroupConnectionArtistAlbumCellReleaseGroup {
        get {
            return ApolloStuff.ReleaseGroupConnectionArtistAlbumCellReleaseGroup(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }

}



// MARK: - ArtistDetailView



extension ArtistDetailView {
    
    
    typealias Data = ApolloStuff.ArtistDetailViewQuery.Data
    
    
    init(api: Music
, data: Data
) {
        self.init(api: api
, id: GraphQL(data.lookup?.artist?.mbid)
, name: GraphQL(data.lookup?.artist?.name)
, image: GraphQL(data.lookup?.artist?.theAudioDb?.thumbnail)
, bio: GraphQL(data.lookup?.artist?.theAudioDb?.biography)
, area: GraphQL(data.lookup?.artist?.area?.name)
, type: GraphQL(data.lookup?.artist?.type)
, formed: GraphQL(data.lookup?.artist?.lifeSpan?.begin)
, genre: GraphQL(data.lookup?.artist?.theAudioDb?.style)
, mood: GraphQL(data.lookup?.artist?.theAudioDb?.mood)
)
    }
}


extension Music {
    
    func artistDetailView(mbid: String
, size: Music.TheAudioDBImageSize? = Music.TheAudioDBImageSize.full
, lang: String? = "en"
) -> some View {
        return QueryRenderer(client: client,
                             query: ApolloStuff.ArtistDetailViewQuery(mbid: mbid
, size: .init(size)
, lang: lang
)) { data in
        
            ArtistDetailView(api: self
, data: data
)
        }
    }
    
}






// MARK: - ArtistTopSongsList



extension ArtistTopSongsList {
    
    
    typealias Data = ApolloStuff.ArtistTopSongsListQuery.Data
    
    
    init(tracks: Paging<TrendingTrackCell.LastFMTrack>?
, data: Data
) {
        self.init(tracks: GraphQL(tracks)
)
    }
}


extension Music {
    
    func artistTopSongsList(mbid: String
, first: Int? = 25
, after: String? = nil
, size: Music.LastFMImageSize? = nil
) -> some View {
        return QueryRenderer(client: client,
                             query: ApolloStuff.ArtistTopSongsListQuery(mbid: mbid
, first: first
, after: after
, size: .init(size)
)) { data in
        
            ArtistTopSongsList(tracks: data.lookup?.artist?.lastFm?.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack.paging { _cursor, _pageSize, _completion in
    self.client.fetch(query: ApolloStuff.ArtistTopSongsListLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery(mbid: mbid
, first: _pageSize ?? first
, after: _cursor
, size: .init(size)
)) { result in
        _completion(result.map { $0.data?.lookup?.artist?.lastFm?.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack })
    }
}

, data: data
)
        }
    }
    
}


extension ApolloStuff.ArtistTopSongsListQuery.Data.Lookup.Artist.LastFm.TopTrack {
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

extension ApolloStuff.ArtistTopSongsListLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery.Data.Lookup.Artist.LastFm.TopTrack {
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

extension ApolloStuff.ArtistTopSongsListQuery.Data.Lookup.Artist.LastFm.TopTrack.Fragments {

    public var lastFmTrackConnectionTrendingTrackCellLastFmTrack: ApolloStuff.LastFmTrackConnectionTrendingTrackCellLastFmTrack {
        get {
            return ApolloStuff.LastFmTrackConnectionTrendingTrackCellLastFmTrack(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }

}

extension ApolloStuff.ArtistTopSongsListLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery.Data.Lookup.Artist.LastFm.TopTrack.Fragments {

    public var lastFmTrackConnectionTrendingTrackCellLastFmTrack: ApolloStuff.LastFmTrackConnectionTrendingTrackCellLastFmTrack {
        get {
            return ApolloStuff.LastFmTrackConnectionTrendingTrackCellLastFmTrack(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }

}



// MARK: - SimilarArtistCell


extension ApolloStuff.SimilarArtistCellLastFmArtist : Fragment {
    typealias UnderlyingType = Music.LastFMArtist
}


extension SimilarArtistCell {
    
    typealias LastFMArtist = ApolloStuff.SimilarArtistCellLastFmArtist
    
    
    
    init(api: Music
, lastFmArtist: LastFMArtist
) {
        self.init(api: api
, id: GraphQL(lastFmArtist.mbid)
, name: GraphQL(lastFmArtist.name)
, images: GraphQL(lastFmArtist.topAlbums?.nodes?.map { $0?.image })
)
    }
}







// MARK: - SimilarArtistsList



extension SimilarArtistsList {
    
    
    typealias Data = ApolloStuff.SimilarArtistsListQuery.Data
    
    
    init(api: Music
, artists: Paging<SimilarArtistCell.LastFMArtist>?
, data: Data
) {
        self.init(api: api
, artists: GraphQL(artists)
)
    }
}


extension Music {
    
    func similarArtistsList(mbid: String
, first: Int? = 25
, after: String? = nil
, size: Music.LastFMImageSize? = nil
) -> some View {
        return QueryRenderer(client: client,
                             query: ApolloStuff.SimilarArtistsListQuery(mbid: mbid
, first: first
, after: after
, size: .init(size)
)) { data in
        
            SimilarArtistsList(api: self
, artists: data.lookup?.artist?.lastFm?.similarArtists?.fragments.lastFmArtistConnectionSimilarArtistCellLastFmArtist.paging { _cursor, _pageSize, _completion in
    self.client.fetch(query: ApolloStuff.SimilarArtistsListLastFmArtistConnectionSimilarArtistCellLastFmArtistQuery(mbid: mbid
, first: _pageSize ?? first
, after: _cursor
, size: .init(size)
)) { result in
        _completion(result.map { $0.data?.lookup?.artist?.lastFm?.similarArtists?.fragments.lastFmArtistConnectionSimilarArtistCellLastFmArtist })
    }
}

, data: data
)
        }
    }
    
}


extension ApolloStuff.SimilarArtistsListQuery.Data.Lookup.Artist.LastFm.SimilarArtist {
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

extension ApolloStuff.SimilarArtistsListLastFmArtistConnectionSimilarArtistCellLastFmArtistQuery.Data.Lookup.Artist.LastFm.SimilarArtist {
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

extension ApolloStuff.SimilarArtistsListQuery.Data.Lookup.Artist.LastFm.SimilarArtist.Fragments {

    public var lastFmArtistConnectionSimilarArtistCellLastFmArtist: ApolloStuff.LastFmArtistConnectionSimilarArtistCellLastFmArtist {
        get {
            return ApolloStuff.LastFmArtistConnectionSimilarArtistCellLastFmArtist(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }

}

extension ApolloStuff.SimilarArtistsListLastFmArtistConnectionSimilarArtistCellLastFmArtistQuery.Data.Lookup.Artist.LastFm.SimilarArtist.Fragments {

    public var lastFmArtistConnectionSimilarArtistCellLastFmArtist: ApolloStuff.LastFmArtistConnectionSimilarArtistCellLastFmArtist {
        get {
            return ApolloStuff.LastFmArtistConnectionSimilarArtistCellLastFmArtist(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }

}



// MARK: - TrendingArtistCell


extension ApolloStuff.TrendingArtistCellLastFmArtist : Fragment {
    typealias UnderlyingType = Music.LastFMArtist
}


extension TrendingArtistCell {
    
    typealias LastFMArtist = ApolloStuff.TrendingArtistCellLastFmArtist
    
    
    
    init(api: Music
, lastFmArtist: LastFMArtist
) {
        self.init(api: api
, id: GraphQL(lastFmArtist.mbid)
, name: GraphQL(lastFmArtist.name)
, tags: GraphQL(lastFmArtist.topTags?.nodes?.map { $0?.name })
, images: GraphQL(lastFmArtist.topAlbums?.nodes?.map { $0?.image })
, mostFamousSongs: GraphQL(lastFmArtist.topTracks?.nodes?.map { $0?.title })
)
    }
}







// MARK: - TrendingArtistsList



extension TrendingArtistsList {
    
    
    typealias Data = ApolloStuff.TrendingArtistsListQuery.Data
    
    
    init(api: Music
, artists: Paging<TrendingArtistCell.LastFMArtist>?
, tracks: Paging<TrendingTrackCell.LastFMTrack>?
, data: Data
) {
        self.init(api: api
, artists: GraphQL(artists)
, tracks: GraphQL(tracks)
)
    }
}


extension Music {
    
    func trendingArtistsList(country: String? = nil
, first: Int? = 25
, after: String? = nil
, size: Music.LastFMImageSize? = nil
) -> some View {
        return QueryRenderer(client: client,
                             query: ApolloStuff.TrendingArtistsListQuery(country: country
, first: first
, after: after
, size: .init(size)
)) { data in
        
            TrendingArtistsList(api: self
, artists: data.lastFm?.chart.topArtists?.fragments.lastFmArtistConnectionTrendingArtistCellLastFmArtist.paging { _cursor, _pageSize, _completion in
    self.client.fetch(query: ApolloStuff.TrendingArtistsListLastFmArtistConnectionTrendingArtistCellLastFmArtistQuery(country: country
, first: _pageSize ?? first
, after: _cursor
, size: .init(size)
)) { result in
        _completion(result.map { $0.data?.lastFm?.chart.topArtists?.fragments.lastFmArtistConnectionTrendingArtistCellLastFmArtist })
    }
}

, tracks: data.lastFm?.chart.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack.paging { _cursor, _pageSize, _completion in
    self.client.fetch(query: ApolloStuff.TrendingArtistsListLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery(country: country
, first: _pageSize ?? first
, after: _cursor
, size: .init(size)
)) { result in
        _completion(result.map { $0.data?.lastFm?.chart.topTracks?.fragments.lastFmTrackConnectionTrendingTrackCellLastFmTrack })
    }
}

, data: data
)
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

extension ApolloStuff.TrendingArtistsListLastFmArtistConnectionTrendingArtistCellLastFmArtistQuery.Data.LastFm.Chart.TopArtist {
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

extension ApolloStuff.TrendingArtistsListLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery.Data.LastFm.Chart.TopTrack {
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

extension ApolloStuff.TrendingArtistsListLastFmArtistConnectionTrendingArtistCellLastFmArtistQuery.Data.LastFm.Chart.TopArtist.Fragments {

    public var lastFmArtistConnectionTrendingArtistCellLastFmArtist: ApolloStuff.LastFmArtistConnectionTrendingArtistCellLastFmArtist {
        get {
            return ApolloStuff.LastFmArtistConnectionTrendingArtistCellLastFmArtist(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }

}

extension ApolloStuff.TrendingArtistsListLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery.Data.LastFm.Chart.TopTrack.Fragments {

    public var lastFmTrackConnectionTrendingTrackCellLastFmTrack: ApolloStuff.LastFmTrackConnectionTrendingTrackCellLastFmTrack {
        get {
            return ApolloStuff.LastFmTrackConnectionTrendingTrackCellLastFmTrack(unsafeResultMap: resultMap)
        }
        set {
            resultMap += newValue.resultMap
        }
    }

}



// MARK: - TrendingTrackCell


extension ApolloStuff.TrendingTrackCellLastFmTrack : Fragment {
    typealias UnderlyingType = Music.LastFMTrack
}


extension TrendingTrackCell {
    
    typealias LastFMTrack = ApolloStuff.TrendingTrackCellLastFmTrack
    
    
    
    init(lastFmTrack: LastFMTrack
) {
        self.init(title: GraphQL(lastFmTrack.title)
, artist: GraphQL(lastFmTrack.artist?.name)
, image: GraphQL(lastFmTrack.album?.image)
)
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





//  This file was automatically generated and should not be edited.

import Apollo
import Foundation

/// ApolloStuff namespace
public enum ApolloStuff {
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

  public final class ArtistAlbumListReleaseGroupConnectionArtistAlbumCellReleaseGroupQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition =
      """
      query ArtistAlbumListReleaseGroupConnectionArtistAlbumCellReleaseGroup($mbid: MBID!, $type: [ReleaseGroupType], $after: String, $first: Int, $status: [ReleaseStatus], $size: TheAudioDBImageSize) {
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
                  releases(after: $after, first: $first, status: $status, type: $type) {
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

    public let operationName = "ArtistAlbumListReleaseGroupConnectionArtistAlbumCellReleaseGroup"

    public var mbid: String
    public var type: [ReleaseGroupType?]?
    public var after: String?
    public var first: Int?
    public var status: [ReleaseStatus?]?
    public var size: TheAudioDBImageSize?

    public init(mbid: String, type: [ReleaseGroupType?]? = nil, after: String? = nil, first: Int? = nil, status: [ReleaseStatus?]? = nil, size: TheAudioDBImageSize? = nil) {
      self.mbid = mbid
      self.type = type
      self.after = after
      self.first = first
      self.status = status
      self.size = size
    }

    public var variables: GraphQLMap? {
      return ["mbid": mbid, "type": type, "after": after, "first": first, "status": status, "size": size]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes = ["Query"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("lookup", type: .object(Lookup.selections)),
      ]

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
        public static let possibleTypes = ["LookupQuery"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("artist", arguments: ["mbid": GraphQLVariable("mbid")], type: .object(Artist.selections)),
        ]

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
          public static let possibleTypes = ["Artist"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("releaseGroups", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first"), "type": GraphQLVariable("type")], type: .object(ReleaseGroup.selections)),
          ]

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
            public static let possibleTypes = ["ReleaseGroupConnection"]

            public static let selections: [GraphQLSelection] = [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("edges", type: .list(.object(Edge.selections))),
              GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
            ]

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
              public static let possibleTypes = ["ReleaseGroupEdge"]

              public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("node", type: .object(Node.selections)),
              ]

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
                public static let possibleTypes = ["ReleaseGroup"]

                public static let selections: [GraphQLSelection] = [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("releases", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first"), "status": GraphQLVariable("status"), "type": GraphQLVariable("type")], type: .object(Release.selections)),
                  GraphQLField("theAudioDB", type: .object(TheAudioDb.selections)),
                  GraphQLField("title", type: .scalar(String.self)),
                ]

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
                  public static let possibleTypes = ["ReleaseConnection"]

                  public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("nodes", type: .list(.object(Node.selections))),
                  ]

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
                    public static let possibleTypes = ["Release"]

                    public static let selections: [GraphQLSelection] = [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("mbid", type: .nonNull(.scalar(String.self))),
                    ]

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
                  public static let possibleTypes = ["TheAudioDBAlbum"]

                  public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("frontImage", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                  ]

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
              public static let possibleTypes = ["PageInfo"]

              public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("endCursor", type: .scalar(String.self)),
                GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
              ]

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

  public final class ArtistTopSongsListLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition =
      """
      query ArtistTopSongsListLastFMTrackConnectionTrendingTrackCellLastFMTrack($mbid: MBID!, $first: Int, $after: String, $size: LastFMImageSize) {
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
                      image(size: $size)
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

    public let operationName = "ArtistTopSongsListLastFMTrackConnectionTrendingTrackCellLastFMTrack"

    public var mbid: String
    public var first: Int?
    public var after: String?
    public var size: LastFMImageSize?

    public init(mbid: String, first: Int? = nil, after: String? = nil, size: LastFMImageSize? = nil) {
      self.mbid = mbid
      self.first = first
      self.after = after
      self.size = size
    }

    public var variables: GraphQLMap? {
      return ["mbid": mbid, "first": first, "after": after, "size": size]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes = ["Query"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("lookup", type: .object(Lookup.selections)),
      ]

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
        public static let possibleTypes = ["LookupQuery"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("artist", arguments: ["mbid": GraphQLVariable("mbid")], type: .object(Artist.selections)),
        ]

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
          public static let possibleTypes = ["Artist"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("lastFM", type: .object(LastFm.selections)),
          ]

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
            public static let possibleTypes = ["LastFMArtist"]

            public static let selections: [GraphQLSelection] = [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("topTracks", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first")], type: .object(TopTrack.selections)),
            ]

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
              public static let possibleTypes = ["LastFMTrackConnection"]

              public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("edges", type: .list(.object(Edge.selections))),
                GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
              ]

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
                public static let possibleTypes = ["LastFMTrackEdge"]

                public static let selections: [GraphQLSelection] = [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("node", type: .object(Node.selections)),
                ]

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
                  public static let possibleTypes = ["LastFMTrack"]

                  public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("album", type: .object(Album.selections)),
                    GraphQLField("artist", type: .object(Artist.selections)),
                    GraphQLField("title", type: .scalar(String.self)),
                  ]

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
                    public static let possibleTypes = ["LastFMAlbum"]

                    public static let selections: [GraphQLSelection] = [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("image", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                    ]

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

                  public struct Artist: GraphQLSelectionSet {
                    public static let possibleTypes = ["LastFMArtist"]

                    public static let selections: [GraphQLSelection] = [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("name", type: .scalar(String.self)),
                    ]

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
                public static let possibleTypes = ["PageInfo"]

                public static let selections: [GraphQLSelection] = [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("endCursor", type: .scalar(String.self)),
                  GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                ]

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

  public final class SimilarArtistsListLastFmArtistConnectionSimilarArtistCellLastFmArtistQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition =
      """
      query SimilarArtistsListLastFMArtistConnectionSimilarArtistCellLastFMArtist($mbid: MBID!, $first: Int, $after: String, $size: LastFMImageSize) {
        lookup {
          __typename
          artist(mbid: $mbid) {
            __typename
            lastFM {
              __typename
              similarArtists(after: $after, first: $first) {
                __typename
                edges {
                  __typename
                  node {
                    __typename
                    mbid
                    name
                    topAlbums(after: $after, first: $first) {
                      __typename
                      nodes {
                        __typename
                        image(size: $size)
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

    public let operationName = "SimilarArtistsListLastFMArtistConnectionSimilarArtistCellLastFMArtist"

    public var mbid: String
    public var first: Int?
    public var after: String?
    public var size: LastFMImageSize?

    public init(mbid: String, first: Int? = nil, after: String? = nil, size: LastFMImageSize? = nil) {
      self.mbid = mbid
      self.first = first
      self.after = after
      self.size = size
    }

    public var variables: GraphQLMap? {
      return ["mbid": mbid, "first": first, "after": after, "size": size]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes = ["Query"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("lookup", type: .object(Lookup.selections)),
      ]

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
        public static let possibleTypes = ["LookupQuery"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("artist", arguments: ["mbid": GraphQLVariable("mbid")], type: .object(Artist.selections)),
        ]

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
          public static let possibleTypes = ["Artist"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("lastFM", type: .object(LastFm.selections)),
          ]

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
            public static let possibleTypes = ["LastFMArtist"]

            public static let selections: [GraphQLSelection] = [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("similarArtists", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first")], type: .object(SimilarArtist.selections)),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
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
                public static let possibleTypes = ["LastFMArtistEdge"]

                public static let selections: [GraphQLSelection] = [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("node", type: .object(Node.selections)),
                ]

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
                  public static let possibleTypes = ["LastFMArtist"]

                  public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("mbid", type: .scalar(String.self)),
                    GraphQLField("name", type: .scalar(String.self)),
                    GraphQLField("topAlbums", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first")], type: .object(TopAlbum.selections)),
                  ]

                  public private(set) var resultMap: ResultMap

                  public init(unsafeResultMap: ResultMap) {
                    self.resultMap = unsafeResultMap
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
                      public static let possibleTypes = ["LastFMAlbum"]

                      public static let selections: [GraphQLSelection] = [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("image", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                      ]

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

  public final class TrendingArtistsListLastFmArtistConnectionTrendingArtistCellLastFmArtistQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition =
      """
      query TrendingArtistsListLastFMArtistConnectionTrendingArtistCellLastFMArtist($country: String, $first: Int, $after: String, $size: LastFMImageSize) {
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
                  topAlbums(after: $after, first: $first) {
                    __typename
                    nodes {
                      __typename
                      image(size: $size)
                    }
                  }
                  topTags(after: $after, first: $first) {
                    __typename
                    nodes {
                      __typename
                      name
                    }
                  }
                  topTracks(after: $after, first: $first) {
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

    public let operationName = "TrendingArtistsListLastFMArtistConnectionTrendingArtistCellLastFMArtist"

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
        public static let possibleTypes = ["LastFMQuery"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("chart", type: .nonNull(.object(Chart.selections))),
        ]

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
          public static let possibleTypes = ["LastFMChartQuery"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("topArtists", arguments: ["after": GraphQLVariable("after"), "country": GraphQLVariable("country"), "first": GraphQLVariable("first")], type: .object(TopArtist.selections)),
          ]

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
            public static let possibleTypes = ["LastFMArtistConnection"]

            public static let selections: [GraphQLSelection] = [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("edges", type: .list(.object(Edge.selections))),
              GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
            ]

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
              public static let possibleTypes = ["LastFMArtistEdge"]

              public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("node", type: .object(Node.selections)),
              ]

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
                public static let possibleTypes = ["LastFMArtist"]

                public static let selections: [GraphQLSelection] = [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("mbid", type: .scalar(String.self)),
                  GraphQLField("name", type: .scalar(String.self)),
                  GraphQLField("topAlbums", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first")], type: .object(TopAlbum.selections)),
                  GraphQLField("topTags", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first")], type: .object(TopTag.selections)),
                  GraphQLField("topTracks", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first")], type: .object(TopTrack.selections)),
                ]

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
                  public static let possibleTypes = ["LastFMAlbumConnection"]

                  public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("nodes", type: .list(.object(Node.selections))),
                  ]

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
                    public static let possibleTypes = ["LastFMAlbum"]

                    public static let selections: [GraphQLSelection] = [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("image", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                    ]

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
                  public static let possibleTypes = ["LastFMTagConnection"]

                  public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("nodes", type: .list(.object(Node.selections))),
                  ]

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
                    public static let possibleTypes = ["LastFMTag"]

                    public static let selections: [GraphQLSelection] = [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("name", type: .nonNull(.scalar(String.self))),
                    ]

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
                  public static let possibleTypes = ["LastFMTrackConnection"]

                  public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("nodes", type: .list(.object(Node.selections))),
                  ]

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
                    public static let possibleTypes = ["LastFMTrack"]

                    public static let selections: [GraphQLSelection] = [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("title", type: .scalar(String.self)),
                    ]

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
              public static let possibleTypes = ["PageInfo"]

              public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("endCursor", type: .scalar(String.self)),
                GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
              ]

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

  public final class TrendingArtistsListLastFmTrackConnectionTrendingTrackCellLastFmTrackQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition =
      """
      query TrendingArtistsListLastFMTrackConnectionTrendingTrackCellLastFMTrack($country: String, $first: Int, $after: String, $size: LastFMImageSize) {
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

    public let operationName = "TrendingArtistsListLastFMTrackConnectionTrendingTrackCellLastFMTrack"

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
        public static let possibleTypes = ["LastFMQuery"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("chart", type: .nonNull(.object(Chart.selections))),
        ]

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
          public static let possibleTypes = ["LastFMChartQuery"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("topTracks", arguments: ["after": GraphQLVariable("after"), "country": GraphQLVariable("country"), "first": GraphQLVariable("first")], type: .object(TopTrack.selections)),
          ]

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
            public static let possibleTypes = ["LastFMTrackConnection"]

            public static let selections: [GraphQLSelection] = [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("edges", type: .list(.object(Edge.selections))),
              GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
            ]

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
              public static let possibleTypes = ["LastFMTrackEdge"]

              public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("node", type: .object(Node.selections)),
              ]

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
                public static let possibleTypes = ["LastFMTrack"]

                public static let selections: [GraphQLSelection] = [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("album", type: .object(Album.selections)),
                  GraphQLField("artist", type: .object(Artist.selections)),
                  GraphQLField("title", type: .scalar(String.self)),
                ]

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
                  public static let possibleTypes = ["LastFMAlbum"]

                  public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("image", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                  ]

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

                public struct Artist: GraphQLSelectionSet {
                  public static let possibleTypes = ["LastFMArtist"]

                  public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("name", type: .scalar(String.self)),
                  ]

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
              public static let possibleTypes = ["PageInfo"]

              public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("endCursor", type: .scalar(String.self)),
                GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
              ]

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

  public final class AlbumDetailViewQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition =
      """
      query AlbumDetailView($mbid: MBID!, $size: CoverArtArchiveImageSize) {
        lookup {
          __typename
          release(mbid: $mbid) {
            __typename
            coverArtArchive {
              __typename
              front(size: $size)
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

    public var queryDocument: String { return operationDefinition.appending(AlbumTrackCellTrack.fragmentDefinition) }

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
        public static let possibleTypes = ["LookupQuery"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("release", arguments: ["mbid": GraphQLVariable("mbid")], type: .object(Release.selections)),
        ]

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
          public static let possibleTypes = ["Release"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("coverArtArchive", type: .object(CoverArtArchive.selections)),
            GraphQLField("media", type: .list(.object(Medium.selections))),
            GraphQLField("title", type: .scalar(String.self)),
          ]

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(coverArtArchive: CoverArtArchive? = nil, media: [Medium?]? = nil, title: String? = nil) {
            self.init(unsafeResultMap: ["__typename": "Release", "coverArtArchive": coverArtArchive.flatMap { (value: CoverArtArchive) -> ResultMap in value.resultMap }, "media": media.flatMap { (value: [Medium?]) -> [ResultMap?] in value.map { (value: Medium?) -> ResultMap? in value.flatMap { (value: Medium) -> ResultMap in value.resultMap } } }, "title": title])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
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

          public struct CoverArtArchive: GraphQLSelectionSet {
            public static let possibleTypes = ["CoverArtArchiveRelease"]

            public static let selections: [GraphQLSelection] = [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("front", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
            ]

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

          public struct Medium: GraphQLSelectionSet {
            public static let possibleTypes = ["Medium"]

            public static let selections: [GraphQLSelection] = [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("tracks", type: .list(.object(Track.selections))),
            ]

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
              public static let possibleTypes = ["Track"]

              public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLFragmentSpread(AlbumTrackCellTrack.self),
              ]

              public private(set) var resultMap: ResultMap

              public init(unsafeResultMap: ResultMap) {
                self.resultMap = unsafeResultMap
              }

              public init(position: Int? = nil, title: String? = nil) {
                self.init(unsafeResultMap: ["__typename": "Track", "position": position, "title": title])
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

  public final class ArtistAlbumListQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition =
      """
      query ArtistAlbumList($mbid: MBID!, $type: [ReleaseGroupType], $after: String, $first: Int, $status: [ReleaseStatus], $size: TheAudioDBImageSize) {
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
                  releases(after: $after, first: $first, status: $status, type: $type) {
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

    public let operationName = "ArtistAlbumList"

    public var mbid: String
    public var type: [ReleaseGroupType?]?
    public var after: String?
    public var first: Int?
    public var status: [ReleaseStatus?]?
    public var size: TheAudioDBImageSize?

    public init(mbid: String, type: [ReleaseGroupType?]? = nil, after: String? = nil, first: Int? = nil, status: [ReleaseStatus?]? = nil, size: TheAudioDBImageSize? = nil) {
      self.mbid = mbid
      self.type = type
      self.after = after
      self.first = first
      self.status = status
      self.size = size
    }

    public var variables: GraphQLMap? {
      return ["mbid": mbid, "type": type, "after": after, "first": first, "status": status, "size": size]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes = ["Query"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("lookup", type: .object(Lookup.selections)),
      ]

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
        public static let possibleTypes = ["LookupQuery"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("artist", arguments: ["mbid": GraphQLVariable("mbid")], type: .object(Artist.selections)),
        ]

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
          public static let possibleTypes = ["Artist"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("releaseGroups", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first"), "type": GraphQLVariable("type")], type: .object(ReleaseGroup.selections)),
          ]

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
            public static let possibleTypes = ["ReleaseGroupConnection"]

            public static let selections: [GraphQLSelection] = [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("edges", type: .list(.object(Edge.selections))),
              GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
            ]

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
              public static let possibleTypes = ["ReleaseGroupEdge"]

              public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("node", type: .object(Node.selections)),
              ]

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
                public static let possibleTypes = ["ReleaseGroup"]

                public static let selections: [GraphQLSelection] = [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("releases", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first"), "status": GraphQLVariable("status"), "type": GraphQLVariable("type")], type: .object(Release.selections)),
                  GraphQLField("theAudioDB", type: .object(TheAudioDb.selections)),
                  GraphQLField("title", type: .scalar(String.self)),
                ]

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
                  public static let possibleTypes = ["ReleaseConnection"]

                  public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("nodes", type: .list(.object(Node.selections))),
                  ]

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
                    public static let possibleTypes = ["Release"]

                    public static let selections: [GraphQLSelection] = [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("mbid", type: .nonNull(.scalar(String.self))),
                    ]

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
                  public static let possibleTypes = ["TheAudioDBAlbum"]

                  public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("frontImage", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                  ]

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
              public static let possibleTypes = ["PageInfo"]

              public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("endCursor", type: .scalar(String.self)),
                GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
              ]

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
    public let operationDefinition =
      """
      query ArtistDetailView($mbid: MBID!, $size: TheAudioDBImageSize, $lang: String) {
        lookup {
          __typename
          artist(mbid: $mbid) {
            __typename
            area {
              __typename
              name
            }
            lifeSpan {
              __typename
              begin
            }
            mbid
            name
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
    public var lang: String?

    public init(mbid: String, size: TheAudioDBImageSize? = nil, lang: String? = nil) {
      self.mbid = mbid
      self.size = size
      self.lang = lang
    }

    public var variables: GraphQLMap? {
      return ["mbid": mbid, "size": size, "lang": lang]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes = ["Query"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("lookup", type: .object(Lookup.selections)),
      ]

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
        public static let possibleTypes = ["LookupQuery"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("artist", arguments: ["mbid": GraphQLVariable("mbid")], type: .object(Artist.selections)),
        ]

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
          public static let possibleTypes = ["Artist"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("area", type: .object(Area.selections)),
            GraphQLField("lifeSpan", type: .object(LifeSpan.selections)),
            GraphQLField("mbid", type: .nonNull(.scalar(String.self))),
            GraphQLField("name", type: .scalar(String.self)),
            GraphQLField("theAudioDB", type: .object(TheAudioDb.selections)),
            GraphQLField("type", type: .scalar(String.self)),
          ]

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(area: Area? = nil, lifeSpan: LifeSpan? = nil, mbid: String, name: String? = nil, theAudioDb: TheAudioDb? = nil, type: String? = nil) {
            self.init(unsafeResultMap: ["__typename": "Artist", "area": area.flatMap { (value: Area) -> ResultMap in value.resultMap }, "lifeSpan": lifeSpan.flatMap { (value: LifeSpan) -> ResultMap in value.resultMap }, "mbid": mbid, "name": name, "theAudioDB": theAudioDb.flatMap { (value: TheAudioDb) -> ResultMap in value.resultMap }, "type": type])
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

          public struct LifeSpan: GraphQLSelectionSet {
            public static let possibleTypes = ["LifeSpan"]

            public static let selections: [GraphQLSelection] = [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("begin", type: .scalar(String.self)),
            ]

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

  public final class ArtistTopSongsListQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition =
      """
      query ArtistTopSongsList($mbid: MBID!, $first: Int, $after: String, $size: LastFMImageSize) {
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
                      image(size: $size)
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

    public let operationName = "ArtistTopSongsList"

    public var mbid: String
    public var first: Int?
    public var after: String?
    public var size: LastFMImageSize?

    public init(mbid: String, first: Int? = nil, after: String? = nil, size: LastFMImageSize? = nil) {
      self.mbid = mbid
      self.first = first
      self.after = after
      self.size = size
    }

    public var variables: GraphQLMap? {
      return ["mbid": mbid, "first": first, "after": after, "size": size]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes = ["Query"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("lookup", type: .object(Lookup.selections)),
      ]

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
        public static let possibleTypes = ["LookupQuery"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("artist", arguments: ["mbid": GraphQLVariable("mbid")], type: .object(Artist.selections)),
        ]

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
          public static let possibleTypes = ["Artist"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("lastFM", type: .object(LastFm.selections)),
          ]

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
            public static let possibleTypes = ["LastFMArtist"]

            public static let selections: [GraphQLSelection] = [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("topTracks", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first")], type: .object(TopTrack.selections)),
            ]

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
              public static let possibleTypes = ["LastFMTrackConnection"]

              public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("edges", type: .list(.object(Edge.selections))),
                GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
              ]

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
                public static let possibleTypes = ["LastFMTrackEdge"]

                public static let selections: [GraphQLSelection] = [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("node", type: .object(Node.selections)),
                ]

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
                  public static let possibleTypes = ["LastFMTrack"]

                  public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("album", type: .object(Album.selections)),
                    GraphQLField("artist", type: .object(Artist.selections)),
                    GraphQLField("title", type: .scalar(String.self)),
                  ]

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
                    public static let possibleTypes = ["LastFMAlbum"]

                    public static let selections: [GraphQLSelection] = [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("image", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                    ]

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

                  public struct Artist: GraphQLSelectionSet {
                    public static let possibleTypes = ["LastFMArtist"]

                    public static let selections: [GraphQLSelection] = [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("name", type: .scalar(String.self)),
                    ]

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
                public static let possibleTypes = ["PageInfo"]

                public static let selections: [GraphQLSelection] = [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("endCursor", type: .scalar(String.self)),
                  GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
                ]

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

  public final class SimilarArtistsListQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition =
      """
      query SimilarArtistsList($mbid: MBID!, $first: Int, $after: String, $size: LastFMImageSize) {
        lookup {
          __typename
          artist(mbid: $mbid) {
            __typename
            lastFM {
              __typename
              similarArtists(after: $after, first: $first) {
                __typename
                edges {
                  __typename
                  node {
                    __typename
                    mbid
                    name
                    topAlbums(after: $after, first: $first) {
                      __typename
                      nodes {
                        __typename
                        image(size: $size)
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

    public let operationName = "SimilarArtistsList"

    public var mbid: String
    public var first: Int?
    public var after: String?
    public var size: LastFMImageSize?

    public init(mbid: String, first: Int? = nil, after: String? = nil, size: LastFMImageSize? = nil) {
      self.mbid = mbid
      self.first = first
      self.after = after
      self.size = size
    }

    public var variables: GraphQLMap? {
      return ["mbid": mbid, "first": first, "after": after, "size": size]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes = ["Query"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("lookup", type: .object(Lookup.selections)),
      ]

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
        public static let possibleTypes = ["LookupQuery"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("artist", arguments: ["mbid": GraphQLVariable("mbid")], type: .object(Artist.selections)),
        ]

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
          public static let possibleTypes = ["Artist"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("lastFM", type: .object(LastFm.selections)),
          ]

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
            public static let possibleTypes = ["LastFMArtist"]

            public static let selections: [GraphQLSelection] = [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("similarArtists", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first")], type: .object(SimilarArtist.selections)),
            ]

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
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
                public static let possibleTypes = ["LastFMArtistEdge"]

                public static let selections: [GraphQLSelection] = [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("node", type: .object(Node.selections)),
                ]

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
                  public static let possibleTypes = ["LastFMArtist"]

                  public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("mbid", type: .scalar(String.self)),
                    GraphQLField("name", type: .scalar(String.self)),
                    GraphQLField("topAlbums", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first")], type: .object(TopAlbum.selections)),
                  ]

                  public private(set) var resultMap: ResultMap

                  public init(unsafeResultMap: ResultMap) {
                    self.resultMap = unsafeResultMap
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
                      public static let possibleTypes = ["LastFMAlbum"]

                      public static let selections: [GraphQLSelection] = [
                        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                        GraphQLField("image", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                      ]

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

  public final class TrendingArtistsListQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition =
      """
      query TrendingArtistsList($country: String, $first: Int, $after: String, $size: LastFMImageSize) {
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
                  topAlbums(after: $after, first: $first) {
                    __typename
                    nodes {
                      __typename
                      image(size: $size)
                    }
                  }
                  topTags(after: $after, first: $first) {
                    __typename
                    nodes {
                      __typename
                      name
                    }
                  }
                  topTracks(after: $after, first: $first) {
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
        public static let possibleTypes = ["LastFMQuery"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("chart", type: .nonNull(.object(Chart.selections))),
        ]

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
          public static let possibleTypes = ["LastFMChartQuery"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("topArtists", arguments: ["after": GraphQLVariable("after"), "country": GraphQLVariable("country"), "first": GraphQLVariable("first")], type: .object(TopArtist.selections)),
            GraphQLField("topTracks", arguments: ["after": GraphQLVariable("after"), "country": GraphQLVariable("country"), "first": GraphQLVariable("first")], type: .object(TopTrack.selections)),
          ]

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
            public static let possibleTypes = ["LastFMArtistConnection"]

            public static let selections: [GraphQLSelection] = [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("edges", type: .list(.object(Edge.selections))),
              GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
            ]

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
              public static let possibleTypes = ["LastFMArtistEdge"]

              public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("node", type: .object(Node.selections)),
              ]

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
                public static let possibleTypes = ["LastFMArtist"]

                public static let selections: [GraphQLSelection] = [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("mbid", type: .scalar(String.self)),
                  GraphQLField("name", type: .scalar(String.self)),
                  GraphQLField("topAlbums", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first")], type: .object(TopAlbum.selections)),
                  GraphQLField("topTags", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first")], type: .object(TopTag.selections)),
                  GraphQLField("topTracks", arguments: ["after": GraphQLVariable("after"), "first": GraphQLVariable("first")], type: .object(TopTrack.selections)),
                ]

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
                  public static let possibleTypes = ["LastFMAlbumConnection"]

                  public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("nodes", type: .list(.object(Node.selections))),
                  ]

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
                    public static let possibleTypes = ["LastFMAlbum"]

                    public static let selections: [GraphQLSelection] = [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("image", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                    ]

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
                  public static let possibleTypes = ["LastFMTagConnection"]

                  public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("nodes", type: .list(.object(Node.selections))),
                  ]

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
                    public static let possibleTypes = ["LastFMTag"]

                    public static let selections: [GraphQLSelection] = [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("name", type: .nonNull(.scalar(String.self))),
                    ]

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
                  public static let possibleTypes = ["LastFMTrackConnection"]

                  public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("nodes", type: .list(.object(Node.selections))),
                  ]

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
                    public static let possibleTypes = ["LastFMTrack"]

                    public static let selections: [GraphQLSelection] = [
                      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                      GraphQLField("title", type: .scalar(String.self)),
                    ]

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
              public static let possibleTypes = ["PageInfo"]

              public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("endCursor", type: .scalar(String.self)),
                GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
              ]

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
            public static let possibleTypes = ["LastFMTrackConnection"]

            public static let selections: [GraphQLSelection] = [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("edges", type: .list(.object(Edge.selections))),
              GraphQLField("pageInfo", type: .nonNull(.object(PageInfo.selections))),
            ]

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
              public static let possibleTypes = ["LastFMTrackEdge"]

              public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("node", type: .object(Node.selections)),
              ]

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
                public static let possibleTypes = ["LastFMTrack"]

                public static let selections: [GraphQLSelection] = [
                  GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                  GraphQLField("album", type: .object(Album.selections)),
                  GraphQLField("artist", type: .object(Artist.selections)),
                  GraphQLField("title", type: .scalar(String.self)),
                ]

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
                  public static let possibleTypes = ["LastFMAlbum"]

                  public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("image", arguments: ["size": GraphQLVariable("size")], type: .scalar(String.self)),
                  ]

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

                public struct Artist: GraphQLSelectionSet {
                  public static let possibleTypes = ["LastFMArtist"]

                  public static let selections: [GraphQLSelection] = [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("name", type: .scalar(String.self)),
                  ]

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
              public static let possibleTypes = ["PageInfo"]

              public static let selections: [GraphQLSelection] = [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("endCursor", type: .scalar(String.self)),
                GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
              ]

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
      public static let possibleTypes = ["ReleaseGroupEdge"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("node", type: .object(Node.selections)),
      ]

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
        public static let possibleTypes = ["ReleaseGroup"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("releases", type: .object(Release.selections)),
          GraphQLField("theAudioDB", type: .object(TheAudioDb.selections)),
          GraphQLField("title", type: .scalar(String.self)),
        ]

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
          public static let possibleTypes = ["ReleaseConnection"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("nodes", type: .list(.object(Node.selections))),
          ]

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
            public static let possibleTypes = ["Release"]

            public static let selections: [GraphQLSelection] = [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("mbid", type: .nonNull(.scalar(String.self))),
            ]

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
          public static let possibleTypes = ["TheAudioDBAlbum"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("frontImage", type: .scalar(String.self)),
          ]

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
      public static let possibleTypes = ["PageInfo"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("endCursor", type: .scalar(String.self)),
        GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
      ]

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
      public static let possibleTypes = ["LastFMTrackEdge"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("node", type: .object(Node.selections)),
      ]

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
        public static let possibleTypes = ["LastFMTrack"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("album", type: .object(Album.selections)),
          GraphQLField("artist", type: .object(Artist.selections)),
          GraphQLField("title", type: .scalar(String.self)),
        ]

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
          public static let possibleTypes = ["LastFMAlbum"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("image", type: .scalar(String.self)),
          ]

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

        public struct Artist: GraphQLSelectionSet {
          public static let possibleTypes = ["LastFMArtist"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("name", type: .scalar(String.self)),
          ]

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
      public static let possibleTypes = ["PageInfo"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("endCursor", type: .scalar(String.self)),
        GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
      ]

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
      public static let possibleTypes = ["LastFMArtistEdge"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("node", type: .object(Node.selections)),
      ]

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
        public static let possibleTypes = ["LastFMArtist"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("mbid", type: .scalar(String.self)),
          GraphQLField("name", type: .scalar(String.self)),
          GraphQLField("topAlbums", type: .object(TopAlbum.selections)),
        ]

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
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
            public static let possibleTypes = ["LastFMAlbum"]

            public static let selections: [GraphQLSelection] = [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("image", type: .scalar(String.self)),
            ]

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
      public static let possibleTypes = ["LastFMArtistEdge"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("node", type: .object(Node.selections)),
      ]

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
          public static let possibleTypes = ["LastFMAlbumConnection"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("nodes", type: .list(.object(Node.selections))),
          ]

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
            public static let possibleTypes = ["LastFMAlbum"]

            public static let selections: [GraphQLSelection] = [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("image", type: .scalar(String.self)),
            ]

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
          public static let possibleTypes = ["LastFMTagConnection"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("nodes", type: .list(.object(Node.selections))),
          ]

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
            public static let possibleTypes = ["LastFMTag"]

            public static let selections: [GraphQLSelection] = [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("name", type: .nonNull(.scalar(String.self))),
            ]

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
          public static let possibleTypes = ["LastFMTrackConnection"]

          public static let selections: [GraphQLSelection] = [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("nodes", type: .list(.object(Node.selections))),
          ]

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
            public static let possibleTypes = ["LastFMTrack"]

            public static let selections: [GraphQLSelection] = [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("title", type: .scalar(String.self)),
            ]

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
      public static let possibleTypes = ["PageInfo"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("endCursor", type: .scalar(String.self)),
        GraphQLField("hasNextPage", type: .nonNull(.scalar(Bool.self))),
      ]

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

  public struct AlbumTrackCellTrack: GraphQLFragment {
    /// The raw GraphQL definition of this fragment.
    public static let fragmentDefinition =
      """
      fragment AlbumTrackCellTrack on Track {
        __typename
        position
        title
      }
      """

    public static let possibleTypes = ["Track"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
      GraphQLField("position", type: .scalar(Int.self)),
      GraphQLField("title", type: .scalar(String.self)),
    ]

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(position: Int? = nil, title: String? = nil) {
      self.init(unsafeResultMap: ["__typename": "Track", "position": position, "title": title])
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

    /// The official title of the entity.
    public var title: String? {
      get {
        return resultMap["title"] as? String
      }
      set {
        resultMap.updateValue(newValue, forKey: "title")
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
      public static let possibleTypes = ["ReleaseConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("nodes", type: .list(.object(Node.selections))),
      ]

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
        public static let possibleTypes = ["Release"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("mbid", type: .nonNull(.scalar(String.self))),
        ]

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
      public static let possibleTypes = ["TheAudioDBAlbum"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("frontImage", type: .scalar(String.self)),
      ]

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
      self.resultMap = unsafeResultMap
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
        public static let possibleTypes = ["LastFMAlbum"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("image", type: .scalar(String.self)),
        ]

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
      public static let possibleTypes = ["LastFMAlbumConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("nodes", type: .list(.object(Node.selections))),
      ]

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
        public static let possibleTypes = ["LastFMAlbum"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("image", type: .scalar(String.self)),
        ]

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
      public static let possibleTypes = ["LastFMTagConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("nodes", type: .list(.object(Node.selections))),
      ]

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
        public static let possibleTypes = ["LastFMTag"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
        ]

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
      public static let possibleTypes = ["LastFMTrackConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("nodes", type: .list(.object(Node.selections))),
      ]

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
        public static let possibleTypes = ["LastFMTrack"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("title", type: .scalar(String.self)),
        ]

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
    public static let fragmentDefinition =
      """
      fragment TrendingTrackCellLastFMTrack on LastFMTrack {
        __typename
        album {
          __typename
          image
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
      public static let possibleTypes = ["LastFMAlbum"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("image", type: .scalar(String.self)),
      ]

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

    public struct Artist: GraphQLSelectionSet {
      public static let possibleTypes = ["LastFMArtist"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("name", type: .scalar(String.self)),
      ]

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



