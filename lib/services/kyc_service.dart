import 'dart:io';
import 'package:dio/dio.dart';
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/kyc_status.dart';

/// Mono-powered KYC — verification happens in discrete steps, each with
/// its own endpoint, rather than one big form submission:
///   1. Email OTP  (send -> verify)
///   2. Phone OTP  (send -> verify)
///   3. Identity   (NIN, BVN, driver's license, or passport — pick one)
///   4. Business   (CAC number — optional, unlocks the verified badge)
class KycService {
  final _client = ApiClient.instance;

  Future<KycStatus> getStatus() async {
    final res = await _client.get(ApiConfig.kycStatus);
    return KycStatus.fromJson(Map<String, dynamic>.from(res.data['data'] ?? res.data));
  }

  // ---- Email ------------------------------------------------------------
  Future<void> sendEmailOtp() async {
    await _client.post(ApiConfig.kycEmailSendOtp);
  }

  /// MonoKycController::verifyEmail() only returns {success, message} — no
  /// status snapshot — so re-fetch the authoritative status afterward
  /// rather than trying to parse one out of this response.
  Future<KycStatus> verifyEmailOtp(String otp) async {
    await _client.post(ApiConfig.kycEmailVerify, data: {'otp': otp});
    return getStatus();
  }

  // ---- Phone --------------------------------------------------------------
  Future<void> sendPhoneOtp() async {
    await _client.post(ApiConfig.kycPhoneSendOtp);
  }

  Future<KycStatus> verifyPhoneOtp(String otp) async {
    await _client.post(ApiConfig.kycPhoneVerify, data: {'otp': otp});
    return getStatus();
  }

  // ---- Identity (pick one method) -----------------------------------------
  /// MonoKycController::verifyNin() (and BVN/license/passport below) do
  /// return a `data` key on success, but it's the raw Mono provider
  /// payload (name, photo, etc.) — not {email_verified, phone_verified,
  /// identity_verified, is_verified} — so it can't be parsed as a
  /// KycStatus either. Re-fetch status the same way as the OTP steps.
  Future<KycStatus> verifyNin(String nin) async {
    await _client.post(ApiConfig.kycIdentityNin, data: {'nin': nin});
    return getStatus();
  }

  Future<KycStatus> verifyBvn(String bvn) async {
    await _client.post(ApiConfig.kycIdentityBvn, data: {'bvn': bvn});
    return getStatus();
  }

  /// Backend (MonoKycController::verifyDriversLicense) requires
  /// `license_number` + `date_of_birth` as plain JSON fields — it does
  /// not accept or store a document image for this method.
  Future<KycStatus> verifyDriversLicense({
    required String licenseNumber,
    required DateTime dateOfBirth,
  }) async {
    await _client.post(ApiConfig.kycIdentityDriversLicense, data: {
      'license_number': licenseNumber,
      'date_of_birth': _formatDate(dateOfBirth),
    });
    return getStatus();
  }

  /// Backend (MonoKycController::verifyPassport) requires
  /// `passport_number` + `last_name` + `date_of_birth` as plain JSON
  /// fields — no document image is accepted here either.
  Future<KycStatus> verifyPassport({
    required String passportNumber,
    required String lastName,
    required DateTime dateOfBirth,
  }) async {
    await _client.post(ApiConfig.kycIdentityPassport, data: {
      'passport_number': passportNumber,
      'last_name': lastName,
      'date_of_birth': _formatDate(dateOfBirth),
    });
    return getStatus();
  }

  /// Fallback: raw document upload if a chosen identity method also needs
  /// a supporting photo (e.g. NIN/BVN + selfie for liveness). Backend
  /// (MonoKycController::uploadDocuments) validates `images.*`, not
  /// `documents`, and — like the OTP steps — returns no status snapshot.
  Future<KycStatus> uploadIdentityDocuments(List<File> files) async {
    final formData = FormData.fromMap({
      'images': [
        for (final f in files) await MultipartFile.fromFile(f.path, filename: f.path.split('/').last),
      ],
    });
    await _client.postMultipart(ApiConfig.kycIdentityDocuments, formData);
    return getStatus();
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---- Business (CAC) -------------------------------------------------------
  Future<KycStatus> verifyCac(String cacNumber) async {
    await _client.post(ApiConfig.kycBusinessCac, data: {'cac_number': cacNumber});
    return getStatus();
  }
}
