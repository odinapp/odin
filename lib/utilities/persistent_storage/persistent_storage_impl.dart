import 'package:odin/utilities/persistent_storage/persistent_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OPersistentStorageImpl implements OPersistentStorage {
  @override
  Future<void> store<T>({
    required String key,
    required T data,
    required PersistentStorageEncoder<T> encoder,
    bool overwrite = false,
  }) async {
    final database = await _obtainOrCreateDatabase();

    final isWriteable = await exists(key: key) ? overwrite : true;

    if (isWriteable) {
      final encodedData = encoder(data);
      await database.setString(key, encodedData);
    }
  }

  @override
  Future<void> update<T>({
    required String key,
    required T updatedData,
    required PersistentStorageEncoder<T> encoder,
    bool createIfNotExisting = true,
  }) async {
    if (await exists(key: key)) {
      await store<T>(
        key: key,
        data: updatedData,
        encoder: encoder,
        overwrite: true,
      );
    } else if (createIfNotExisting) {
      await store<T>(
        key: key,
        data: updatedData,
        encoder: encoder,
      );
    }
  }

  @override
  Future<T?> retrieve<T>({
    required String key,
    required PersistentStorageDecoder<T> decoder,
  }) async {
    final database = await _obtainOrCreateDatabase();

    final retrievedData = database.getString(key);

    late T? data;

    if (retrievedData != null) {
      data = decoder(retrievedData);
    } else {
      data = null;
    }

    return data;
  }

  @override
  Future<bool> exists({required String key}) async {
    final database = await _obtainOrCreateDatabase();

    final isExisting = database.containsKey(key);

    return isExisting;
  }

  @override
  Future<void> delete({required String key}) async {
    final database = await _obtainOrCreateDatabase();

    if (await exists(key: key)) {
      await database.remove(key);
    }
  }

  Future<SharedPreferences> _obtainOrCreateDatabase() async {
    final sharedPreferences = await SharedPreferences.getInstance();

    return sharedPreferences;
  }
}
