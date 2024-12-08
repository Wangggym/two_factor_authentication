import 'package:two_factor_authentication/manager/otp_token_manager.dart';
import 'package:two_factor_authentication/manager/storage_manager.dart';
import 'package:two_factor_authentication/store/otp_token_store.dart';
import 'package:two_factor_authentication/store/user_store.dart';

import '../api/services/otp_token_service.dart';
import '../api/models/otp_token.dart';
import '../api/models/token_update_request.dart';
import '../api/models/sync_response.dart';
import '../api/models/token_restore_response.dart';

class CloudSyncManager {
  static final CloudSyncManager _instance = CloudSyncManager._internal();
  factory CloudSyncManager() => _instance;
  CloudSyncManager._internal();

  final OTPTokenManager _otpTokenManager = OTPTokenManager();
  final StorageManager _storageManager = StorageManager();
  final OTPTokenService _otpTokenService = OTPTokenService();
  final UserStore _userStore = UserStore();
  final OTPTokenStore _otpTokenStore = OTPTokenStore();

  Future<void> syncLastSyncAt(DateTime syncTime) async {
    _userStore.setLastSyncAt(syncTime);
    await _storageManager.setLastSyncAt(syncTime);
  }

  Future<void> syncAccounts(List<OTPToken> tokens) async {
    _otpTokenStore.setTokens(tokens);
    await _storageManager.setAccounts(tokens);
  }

  Future<void> sync() async {
    final lastSyncAt = _userStore.lastSyncTime;
    final storageTokens = await _storageManager.getAccounts();

    try {
      final response = await _otpTokenManager.syncTokens(storageTokens, lastSyncAt);
      if (response.success) {
        await syncAccounts(response.tokens);
        await syncLastSyncAt(response.syncTime);
        return;
      }
      print(response.error);
    } catch (e) {
      print('Failed to sync local data: $e');
    }
    _otpTokenStore.setTokens(storageTokens);
  }

  // Create tokens
  Future<void> createTokens(List<OTPToken> newTokens) async {
    var copyTokens = _otpTokenStore.copyWith();

    // Save locally first
    final allTokens = _otpTokenStore.addTokens(newTokens);
    _storageManager.setAccounts(allTokens);

    try {
      final response = await _otpTokenManager.createTokens(newTokens);
      if (response.success) {
        var newTokens = [...copyTokens, ...response.tokens];
        _otpTokenStore.setTokens(newTokens);
        _userStore.setLastSyncAt(response.syncTime);
        await _storageManager.setLastSyncAt(response.syncTime);
        await _storageManager.setAccounts(newTokens);
        return;
      }
      print('Failed to sync local data: ${response.error}');
    } catch (e) {
      print('Failed to sync local data: $e');
    }
  }

  // Update token
  Future<void> updateToken(TokenUpdateRequest token) async {
    var updatedTokens = _otpTokenStore.updateToken(token);
    _storageManager.setAccounts(updatedTokens);

    try {
      final response = await _otpTokenService.updateTokens([token]);
      if (response.success) {
        await syncLastSyncAt(response.syncTime);
        return;
      }
      print('Failed to update token: ${response.error}');
    } catch (e) {
      print('Failed to update token: $e');
    }
  }

  // Delete token
  Future<void> deleteToken(String id) async {
    var updatedTokens = _otpTokenStore.removeToken(id);
    _storageManager.setAccounts(updatedTokens);

    try {
      final response = await _otpTokenService.deleteToken(id);
      if (response.success) {
        await syncLastSyncAt(response.syncTime);
      }
      print('Failed to delete token: ${response.error}');
    } catch (e) {
      print('Failed to delete token: $e');
    }
  }

  // Get deleted tokens
  Future<List<OTPToken>> getDeletedTokens() async {
    try {
      return await _otpTokenService.getDeletedTokens();
    } catch (e) {
      print('Failed to get deleted tokens: $e');
      rethrow;
    }
  }

  // Restore tokens
  Future<TokenRestoreResponse> restoreTokens(List<String> ids) async {
    try {
      return await _otpTokenService.restoreTokens(ids);
    } catch (e) {
      print('Failed to restore tokens: $e');
      rethrow;
    }
  }

  // Delete history
  Future<SyncResponse> deleteHistory() async {
    try {
      return await _otpTokenService.deleteHistory();
    } catch (e) {
      print('Failed to delete history: $e');
      rethrow;
    }
  }
}