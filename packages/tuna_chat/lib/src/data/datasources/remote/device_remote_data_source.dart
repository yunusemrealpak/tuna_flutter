import 'api_client.dart';

abstract class DeviceRemoteDataSource {
  Future<void> registerToken({
    required String token,
    required String platform,
    required String pushProvider,
  });

  Future<void> deregisterToken(String token);
}

class DeviceRemoteDataSourceImpl implements DeviceRemoteDataSource {
  DeviceRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<void> registerToken({
    required String token,
    required String platform,
    required String pushProvider,
  }) async {
    await _client.post('/devices', body: {
      'token': token,
      'platform': platform,
      'push_provider': pushProvider,
    });
  }

  @override
  Future<void> deregisterToken(String token) async {
    await _client.delete('/devices', body: {'token': token});
  }
}
