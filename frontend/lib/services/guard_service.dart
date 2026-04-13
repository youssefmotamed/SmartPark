// guard_service.dart — Handles all guard API calls for SmartPark
import '../models/scan_entry_response.dart';
import '../models/scan_exit_response.dart';
import 'base_api_service.dart';

class GuardService extends BaseApiService {

  /// Scans a QR code for gate entry.
  /// Always returns HTTP 200 — check [ScanEntryResponse.isValid] for the result.
  /// Only throws on network errors, never on scan validation failures.
  Future<ScanEntryResponse> scanEntry(String qrCodeData) async {
    final response = await post('/gate/scan-entry', body: {'qrCodeData': qrCodeData});
    return ScanEntryResponse.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Scans a QR code for gate exit.
  /// Always returns HTTP 200 — check [ScanExitResponse.isSuccess] for the result.
  /// Only throws on network errors, never on scan validation failures.
  Future<ScanExitResponse> scanExit(String qrCodeData) async {
    final response = await post('/gate/scan-exit', body: {'qrCodeData': qrCodeData});
    return ScanExitResponse.fromJson(response['data'] as Map<String, dynamic>);
  }
}
