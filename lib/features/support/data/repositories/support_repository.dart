import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';

/// Business WhatsApp number customers reach out to from "حسابي" (0056) — a
/// business fact, admin-editable, not hardcoded. Null means not configured
/// yet.
abstract class SupportRepository {
  Future<String?> getWhatsapp();
  Future<void> setWhatsapp(String whatsapp);
}

class SupabaseSupportRepository implements SupportRepository {
  final SupabaseClient _client;
  SupabaseSupportRepository(this._client);

  @override
  Future<String?> getWhatsapp() async {
    try {
      final res = await _client.rpc('rpc_get_support_contact');
      return (res as Map)['whatsapp'] as String?;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> setWhatsapp(String whatsapp) async {
    try {
      await _client.rpc(
        'rpc_admin_set_text_setting',
        params: {'p_key': 'support_whatsapp', 'p_value': whatsapp},
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
