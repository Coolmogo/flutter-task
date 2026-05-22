import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppHttpClient {
  final String baseUrl;
  final Ref ref;

  const AppHttpClient({required this.baseUrl, required this.ref});
}

AppHttpClient buildHttpClient({required String baseUrl, required Ref ref}) {
  return AppHttpClient(baseUrl: baseUrl, ref: ref);
}
