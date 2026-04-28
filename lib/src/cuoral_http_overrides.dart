import 'dart:io';
import 'dart:convert';
import 'dart:async';

/// Automatic HTTP interceptor for tracking network errors
///
/// Intercepts ALL HTTP requests globally without requiring special HTTP clients.
/// This mimics the behavior of the cuoral-ionic implementation where fetch and
/// XMLHttpRequest are automatically overridden.
class CuoralHttpOverrides extends HttpOverrides {
  final Function(
    String url,
    String method,
    int status,
    int duration,
    String? error,
  )?
  onNetworkError;

  CuoralHttpOverrides({this.onNetworkError});

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);

    // Intercept all requests
    return _CuoralHttpClient(client, onNetworkError);
  }
}

class _CuoralHttpClient implements HttpClient {
  final HttpClient _inner;
  final Function(
    String url,
    String method,
    int status,
    int duration,
    String? error,
  )?
  onNetworkError;

  _CuoralHttpClient(this._inner, this.onNetworkError);

  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) async {
    final startTime = DateTime.now();
    final url =
        Uri(
          scheme: port == 443 ? 'https' : 'http',
          host: host,
          port: port,
          path: path,
        ).toString();

    try {
      final request = await _inner.open(method, host, port, path);
      return _CuoralHttpClientRequest(
        request,
        method,
        url,
        startTime,
        onNetworkError,
      );
    } catch (e) {
      // Track network failure (but not for Cuoral API to avoid infinite loops)
      if (!url.contains('api.cuoral.com')) {
        final duration = DateTime.now().difference(startTime).inMilliseconds;
        onNetworkError?.call(url, method, 0, duration, e.toString());
      }
      rethrow;
    }
  }

  // Delegate all other methods to inner client
  @override
  bool get autoUncompress => _inner.autoUncompress;

  @override
  set autoUncompress(bool value) => _inner.autoUncompress = value;

  @override
  Duration? get connectionTimeout => _inner.connectionTimeout;

  @override
  set connectionTimeout(Duration? value) => _inner.connectionTimeout = value;

  @override
  Duration get idleTimeout => _inner.idleTimeout;

  @override
  set idleTimeout(Duration value) => _inner.idleTimeout = value;

  @override
  int? get maxConnectionsPerHost => _inner.maxConnectionsPerHost;

  @override
  set maxConnectionsPerHost(int? value) => _inner.maxConnectionsPerHost = value;

  @override
  String? get userAgent => _inner.userAgent;

  @override
  set userAgent(String? value) => _inner.userAgent = value;

  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) {
    _inner.addCredentials(url, realm, credentials);
  }

  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) {
    _inner.addProxyCredentials(host, port, realm, credentials);
  }

  @override
  void close({bool force = false}) {
    _inner.close(force: force);
  }

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) {
    return open('DELETE', host, port, path);
  }

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) {
    return openUrl('DELETE', url);
  }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) {
    return open('GET', host, port, path);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    return openUrl('GET', url);
  }

  @override
  Future<HttpClientRequest> head(String host, int port, String path) {
    return open('HEAD', host, port, path);
  }

  @override
  Future<HttpClientRequest> headUrl(Uri url) {
    return openUrl('HEAD', url);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    final startTime = DateTime.now();

    try {
      final request = await _inner.openUrl(method, url);
      return _CuoralHttpClientRequest(
        request,
        method,
        url.toString(),
        startTime,
        onNetworkError,
      );
    } catch (e) {
      // Track network failure
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      onNetworkError?.call(url.toString(), method, 0, duration, e.toString());
      rethrow;
    }
  }

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) {
    return open('PATCH', host, port, path);
  }

  @override
  Future<HttpClientRequest> patchUrl(Uri url) {
    return openUrl('PATCH', url);
  }

  @override
  Future<HttpClientRequest> post(String host, int port, String path) {
    return open('POST', host, port, path);
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) {
    return openUrl('POST', url);
  }

  @override
  Future<HttpClientRequest> put(String host, int port, String path) {
    return open('PUT', host, port, path);
  }

  @override
  Future<HttpClientRequest> putUrl(Uri url) {
    return openUrl('PUT', url);
  }

  @override
  set authenticate(
    Future<bool> Function(Uri url, String scheme, String? realm)? f,
  ) {
    _inner.authenticate = f;
  }

  @override
  set authenticateProxy(
    Future<bool> Function(String host, int port, String scheme, String? realm)?
    f,
  ) {
    _inner.authenticateProxy = f;
  }

  @override
  set badCertificateCallback(
    bool Function(X509Certificate cert, String host, int port)? callback,
  ) {
    _inner.badCertificateCallback = callback;
  }

  @override
  set findProxy(String Function(Uri url)? f) {
    _inner.findProxy = f;
  }

  @override
  set connectionFactory(
    Future<ConnectionTask<Socket>> Function(
      Uri url,
      String? proxyHost,
      int? proxyPort,
    )?
    f,
  ) {
    _inner.connectionFactory = f;
  }

  @override
  set keyLog(Function(String line)? callback) {
    _inner.keyLog = callback;
  }
}

class _CuoralHttpClientRequest implements HttpClientRequest {
  final HttpClientRequest _inner;
  final String _method;
  final String _url;
  final DateTime _startTime;
  final Function(
    String url,
    String method,
    int status,
    int duration,
    String? error,
  )?
  _onNetworkError;

  _CuoralHttpClientRequest(
    this._inner,
    this._method,
    this._url,
    this._startTime,
    this._onNetworkError,
  );

  @override
  Future<HttpClientResponse> close() async {
    try {
      final response = await _inner.close();
      return _CuoralHttpClientResponse(
        response,
        _method,
        _url,
        _startTime,
        _onNetworkError,
      );
    } catch (e) {
      // Track network failure
      final duration = DateTime.now().difference(_startTime).inMilliseconds;
      _onNetworkError?.call(_url, _method, 0, duration, e.toString());
      rethrow;
    }
  }

  // Delegate all other methods
  @override
  Encoding get encoding => _inner.encoding;

  @override
  set encoding(Encoding value) => _inner.encoding = value;

  @override
  void add(List<int> data) => _inner.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _inner.addError(error, stackTrace);

  @override
  Future addStream(Stream<List<int>> stream) => _inner.addStream(stream);

  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;

  @override
  List<Cookie> get cookies => _inner.cookies;

  @override
  Future<HttpClientResponse> get done => close();

  @override
  Future flush() => _inner.flush();

  @override
  HttpHeaders get headers => _inner.headers;

  @override
  String get method => _inner.method;

  @override
  Uri get uri => _inner.uri;

  @override
  void write(Object? object) => _inner.write(object);

  @override
  void writeAll(Iterable objects, [String separator = ""]) =>
      _inner.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => _inner.writeCharCode(charCode);

  @override
  void writeln([Object? object = ""]) => _inner.writeln(object);

  @override
  bool get bufferOutput => _inner.bufferOutput;

  @override
  set bufferOutput(bool value) => _inner.bufferOutput = value;

  @override
  int get contentLength => _inner.contentLength;

  @override
  set contentLength(int value) => _inner.contentLength = value;

  @override
  bool get followRedirects => _inner.followRedirects;

  @override
  set followRedirects(bool value) => _inner.followRedirects = value;

  @override
  int get maxRedirects => _inner.maxRedirects;

  @override
  set maxRedirects(int value) => _inner.maxRedirects = value;

  @override
  bool get persistentConnection => _inner.persistentConnection;

  @override
  set persistentConnection(bool value) => _inner.persistentConnection = value;

  @override
  void abort([Object? exception, StackTrace? stackTrace]) =>
      _inner.abort(exception, stackTrace);
}

class _CuoralHttpClientResponse implements HttpClientResponse {
  final HttpClientResponse _inner;
  final String _method;
  final String _url;
  final DateTime _startTime;
  final Function(
    String url,
    String method,
    int status,
    int duration,
    String? error,
  )?
  _onNetworkError;

  _CuoralHttpClientResponse(
    this._inner,
    this._method,
    this._url,
    this._startTime,
    this._onNetworkError,
  ) {
    // Track 4xx and 5xx errors
    if (_inner.statusCode >= 400) {
      final duration = DateTime.now().difference(_startTime).inMilliseconds;

      // Don't track localhost or Cuoral API requests (avoid infinite loops)
      if (!_url.contains('localhost') &&
          !_url.contains('127.0.0.1') &&
          !_url.contains('api.cuoral.com')) {
        _onNetworkError?.call(_url, _method, _inner.statusCode, duration, null);
      }
    }
  }

  // Delegate all methods
  @override
  X509Certificate? get certificate => _inner.certificate;

  @override
  HttpClientResponseCompressionState get compressionState =>
      _inner.compressionState;

  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;

  @override
  int get contentLength => _inner.contentLength;

  @override
  List<Cookie> get cookies => _inner.cookies;

  @override
  Future<Socket> detachSocket() => _inner.detachSocket();

  @override
  HttpHeaders get headers => _inner.headers;

  @override
  bool get isRedirect => _inner.isRedirect;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _inner.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  bool get persistentConnection => _inner.persistentConnection;

  @override
  String get reasonPhrase => _inner.reasonPhrase;

  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) {
    return _inner.redirect(method, url, followLoops);
  }

  @override
  List<RedirectInfo> get redirects => _inner.redirects;

  @override
  int get statusCode => _inner.statusCode;

  @override
  bool get isBroadcast => _inner.isBroadcast;

  @override
  Future<bool> any(bool Function(List<int> element) test) => _inner.any(test);

  @override
  Stream<List<int>> asBroadcastStream({
    void Function(StreamSubscription<List<int>> subscription)? onListen,
    void Function(StreamSubscription<List<int>> subscription)? onCancel,
  }) {
    return _inner.asBroadcastStream(onListen: onListen, onCancel: onCancel);
  }

  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(List<int> event) convert) =>
      _inner.asyncExpand(convert);

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(List<int> event) convert) =>
      _inner.asyncMap(convert);

  @override
  Stream<R> cast<R>() => _inner.cast<R>();

  @override
  Future<bool> contains(Object? needle) => _inner.contains(needle);

  @override
  Stream<List<int>> distinct([
    bool Function(List<int> previous, List<int> next)? equals,
  ]) => _inner.distinct(equals);

  @override
  Future<E> drain<E>([E? futureValue]) => _inner.drain(futureValue);

  @override
  Future<List<int>> elementAt(int index) => _inner.elementAt(index);

  @override
  Future<bool> every(bool Function(List<int> element) test) =>
      _inner.every(test);

  @override
  Stream<S> expand<S>(Iterable<S> Function(List<int> element) convert) =>
      _inner.expand(convert);

  @override
  Future<List<int>> get first => _inner.first;

  @override
  Future<List<int>> firstWhere(
    bool Function(List<int> element) test, {
    List<int> Function()? orElse,
  }) {
    return _inner.firstWhere(test, orElse: orElse);
  }

  @override
  Future<S> fold<S>(
    S initialValue,
    S Function(S previous, List<int> element) combine,
  ) {
    return _inner.fold(initialValue, combine);
  }

  @override
  Future forEach(void Function(List<int> element) action) =>
      _inner.forEach(action);

  @override
  Stream<List<int>> handleError(
    Function onError, {
    bool Function(dynamic error)? test,
  }) {
    return _inner.handleError(onError, test: test);
  }

  @override
  Future<bool> get isEmpty => _inner.isEmpty;

  @override
  Future<String> join([String separator = ""]) => _inner.join(separator);

  @override
  Future<List<int>> get last => _inner.last;

  @override
  Future<List<int>> lastWhere(
    bool Function(List<int> element) test, {
    List<int> Function()? orElse,
  }) {
    return _inner.lastWhere(test, orElse: orElse);
  }

  @override
  Future<int> get length => _inner.length;

  @override
  Stream<S> map<S>(S Function(List<int> event) convert) => _inner.map(convert);

  @override
  Future pipe(StreamConsumer<List<int>> streamConsumer) =>
      _inner.pipe(streamConsumer);

  @override
  Future<List<int>> reduce(
    List<int> Function(List<int> previous, List<int> element) combine,
  ) {
    return _inner.reduce(combine);
  }

  @override
  Future<List<int>> get single => _inner.single;

  @override
  Future<List<int>> singleWhere(
    bool Function(List<int> element) test, {
    List<int> Function()? orElse,
  }) {
    return _inner.singleWhere(test, orElse: orElse);
  }

  @override
  Stream<List<int>> skip(int count) => _inner.skip(count);

  @override
  Stream<List<int>> skipWhile(bool Function(List<int> element) test) =>
      _inner.skipWhile(test);

  @override
  Stream<List<int>> take(int count) => _inner.take(count);

  @override
  Stream<List<int>> takeWhile(bool Function(List<int> element) test) =>
      _inner.takeWhile(test);

  @override
  Stream<List<int>> timeout(
    Duration timeLimit, {
    void Function(EventSink<List<int>> sink)? onTimeout,
  }) {
    return _inner.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<List<List<int>>> toList() => _inner.toList();

  @override
  Future<Set<List<int>>> toSet() => _inner.toSet();

  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) {
    return _inner.transform(streamTransformer);
  }

  @override
  Stream<List<int>> where(bool Function(List<int> event) test) =>
      _inner.where(test);
}
