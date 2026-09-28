import 'package:encrypt/encrypt.dart' as enc;

/// WebPros ERP AES-128-CBC Password Encryption Service
/// Matches the client-side CryptoJS implementation on WebPros portal
class CryptoService {
  // Hardcoded key & IV used by WebPros India ERP
  static final _key = enc.Key.fromUtf8('8701661282118308');
  static final _iv = enc.IV.fromUtf8('8701661282118308');

  /// Encrypts plain password into AES-128-CBC Base64 string
  static String encryptPassword(String plainPassword) {
    if (plainPassword.isEmpty) return '';
    try {
      final encrypter = enc.Encrypter(
        enc.AES(_key, mode: enc.AESMode.cbc, padding: 'PKCS7'),
      );
      final encrypted = encrypter.encrypt(plainPassword, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      return plainPassword;
    }
  }
}
