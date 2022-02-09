import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:new_app/backbone/exception.dart';

abstract class HttpClient {
  Future<http.Response> get(String path, {Map<String, String> data});

  Future<http.Response> post(
    String path, {
    Map<String, dynamic> data,
    String apiLink,
  });
}

class new_appHttpClient implements HttpClient {
  final String _link;
  final Map<String, String> _additionalHeaders;

  new_appHttpClient(this._link, this._additionalHeaders);

  @override
  Future<http.Response> get(String path, {Map<String, String> data}) {
    final StringBuffer parametersSB = StringBuffer();
    String parameters = "";
    if (data != null && data.isNotEmpty) {
      data.forEach((String key, String value) {
        parametersSB.write("&$key=$value");
      });
      parameters = "?${parametersSB.toString().substring(1)}";
    }
    final Uri url = Uri.parse("$_link$path$parameters");
    return http.get(url, headers: _additionalHeaders);
  }

  @override
  Future<http.Response> post(
    String path, {
    Map<String, dynamic> data,
    String apiLink,
  }) {
    final Uri url = Uri.parse("${apiLink ?? _link}$path");
    return http.post(
      url,
      body: data == null ? null : jsonEncode(data),
      headers: <String, String>{
        "Content-Type": "application/json",
        ..._additionalHeaders,
      },
    );
  }
}

class HttpClientErrorHandlingDecorator implements HttpClient {
  final HttpClient _client;

  HttpClientErrorHandlingDecorator(this._client);

  @override
  Future<http.Response> get(String path, {Map<String, String> data}) async {
    final http.Response response = await _client.get(path, data: data);
    if (response.statusCode != 200) {
      final Map<String, dynamic> errorMap =
          jsonDecode(response.body) as Map<String, dynamic>;
      throw HttpRequestException(
        cause:
            "${errorMap["error"] as String}: ${errorMap["error_description"] as String}",
      );
    }
    return response;
  }

  @override
  Future<http.Response> post(String path,
      {Map<String, dynamic> data, String apiLink}) async {
    final http.Response response =
        await _client.post(path, data: data, apiLink: apiLink);
    if (response.statusCode != 200) {
      final Map<String, dynamic> errorMap =
          jsonDecode(response.body) as Map<String, dynamic>;
      throw HttpRequestException(
        cause:
            "${errorMap["error"] as String}: ${errorMap["error_description"] as String}",
      );
    }
    return response;
  }
}

class HttpClientInvalidTokenPropagationDecorator implements HttpClient {
  final HttpClient _client;
  final Sink<DocumentedException> _globalExceptionSink;

  HttpClientInvalidTokenPropagationDecorator(
    this._client,
    this._globalExceptionSink,
  );

  @override
  Future<http.Response> get(String path, {Map<String, String> data}) async {
    try {
      return await _client.get(path, data: data);
    } on Object catch (e) {
      if (e != null && e.toString().contains(_invalidTokenException)) {
        final InvalidTokenException tokenException =
            InvalidTokenException(message: e.toString());
        _globalExceptionSink.add(tokenException);
        throw tokenException;
      } else {
        throw e;
      }
    }
  }

  @override
  Future<http.Response> post(String path,
      {Map<String, dynamic> data, String apiLink}) async {
    try {
      return await _client.post(path, data: data, apiLink: apiLink);
    } on Object catch (e) {
      if (e != null && e.toString().contains(_invalidTokenException)) {
        final InvalidTokenException tokenException =
            InvalidTokenException(message: e.toString());
        _globalExceptionSink.add(tokenException);
        throw tokenException;
      } else {
        throw e;
      }
    }
  }
}

class HttpClientInternetConnectionExceptionPropagationDecorator
    implements HttpClient {
  final HttpClient _client;
  final Sink<DocumentedException> _globalExceptionSink;

  HttpClientInternetConnectionExceptionPropagationDecorator(
    this._client,
    this._globalExceptionSink,
  );

  @override
  Future<http.Response> get(String path, {Map<String, String> data}) async {
    try {
      return await _client.get(path, data: data);
    } on Object catch (e) {
      if (e != null && e.toString().contains(_socketException)) {
        final InternetConnectionException internetConnectionException =
            InternetConnectionException(message: e.toString());
        _globalExceptionSink.add(internetConnectionException);
        throw internetConnectionException;
      } else {
        throw e;
      }
    }
  }

  @override
  Future<http.Response> post(String path,
      {Map<String, dynamic> data, String apiLink}) async {
    try {
      return await _client.post(path, data: data, apiLink: apiLink);
    } on Object catch (e) {
      if (e != null && e.toString().contains(_socketException)) {
        final InternetConnectionException internetConnectionException =
            InternetConnectionException(message: e.toString());
        _globalExceptionSink.add(internetConnectionException);
        throw internetConnectionException;
      } else {
        throw e;
      }
    }
  }
}

final String _invalidTokenException = "invalid_token";
final String _socketException = "SocketException";

class HttpRequestException extends DocumentedException {
  HttpRequestException({String message, Object cause})
      : super(message: message, cause: cause);
}

class InvalidTokenException extends DocumentedException {
  InvalidTokenException({String message, Object cause})
      : super(message: message, cause: cause);
}

class InternetConnectionException extends DocumentedException {
  InternetConnectionException({String message, Object cause})
      : super(message: message, cause: cause);
}

class InvalidTokenExceptionStream {
  final Stream<DocumentedException> _stream;

  InvalidTokenExceptionStream(Stream<DocumentedException> exceptionsStream)
      : this._stream = exceptionsStream.where((DocumentedException exception) =>
            exception is InvalidTokenException);

  Stream<DocumentedException> get stream => _stream;
}

class InternetConnectionExceptionStream {
  final Stream<DocumentedException> _stream;

  InternetConnectionExceptionStream(
      Stream<DocumentedException> exceptionsStream)
      : this._stream = exceptionsStream.where((DocumentedException exception) =>
            exception is InternetConnectionException);

  Stream<DocumentedException> get stream => _stream;
}
