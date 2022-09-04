import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:odin/utilities/persistent_storage/persistent_storage.dart';

class AuthDetails {
  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _chatTokenKey = 'chatToken';

  final String accessToken;
  final String refreshToken;
  final String chatToken;

  AuthDetails({
    required this.accessToken,
    required this.refreshToken,
    required this.chatToken,
  });

  AuthDetails.fromJson(Map<String, dynamic> json)
      : this(
          accessToken: json[_accessTokenKey],
          refreshToken: json[_refreshTokenKey],
          chatToken: json[_chatTokenKey],
        );

  Map<String, dynamic> toJson() => {
        _accessTokenKey: accessToken,
        _refreshTokenKey: refreshToken,
        _chatTokenKey: chatToken,
      };
}

// TODO: Limit the use of KeyChain to `data` layer only.
class AuthKeyChain {
  static const String _authenticationDetailsKey = 'authentication_details';

  static final AuthKeyChain instance = AuthKeyChain._();

  AuthKeyChain._();

  AuthDetails? _authenticationDetails;

  AuthDetails? get authenticationDetails => _authenticationDetails;

  final List<VoidCallback> _listeners = [];

  Future<void> bootUp() async {
    final persistentStorage = OPersistentStorage();

    _authenticationDetails = await persistentStorage.retrieve(
      key: _authenticationDetailsKey,
      decoder: (data) {
        final retrievedData = jsonDecode(data);

        return AuthDetails.fromJson(retrievedData);
      },
    );

    _notifyListeners();
  }

  void bootDown() {
    _listeners.clear();
  }

  void addListener(VoidCallback onChanged) {
    _listeners.add(onChanged);
  }

  Future<void> onLogIn({
    required AuthDetails authenticationDetails,
  }) async {
    // 1. Store in memory
    _authenticationDetails = authenticationDetails;

    // 2. Store on persistent storage for later access
    final persistentStorage = OPersistentStorage();

    await persistentStorage.store<AuthDetails>(
      key: _authenticationDetailsKey,
      data: authenticationDetails,
      encoder: (authenticationDetails) {
        final jsonString = jsonEncode(authenticationDetails.toJson());

        return jsonString;
      },
      overwrite: true,
    );

    // 3. Inform listeners that change in _authenticationDetails has occurred
    _notifyListeners();
  }

  void loginTempDetails({
    required AuthDetails googleAuthDetails,
  }) async {
    _authenticationDetails = googleAuthDetails;

    _notifyListeners();
  }

  Future<void> onLogOut() async {
    // 1. Remove from memory
    _authenticationDetails = null;

    // 2. Remove from persistent storage
    final persistentStorage = OPersistentStorage();

    await persistentStorage.delete(
      key: _authenticationDetailsKey,
    );

    // 3. Inform listeners that change in _authenticationDetails has occurred
    _notifyListeners();
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }
}
