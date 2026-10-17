/// Standard HTTP methods supported by the API client.
enum HttpMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  patch('PATCH'),
  delete('DELETE'),
  head('HEAD');

  final String value;
  const HttpMethod(this.value);

  @override
  String toString() => value;
}
