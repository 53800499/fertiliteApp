import 'package:dio/dio.dart';
import '../../../core/di/service_locator.dart';

/// Service client centralisé pour tous les modules du Back-Office Super Admin.
/// Prend en charge l'authentification via JWT (rôle super_admin) ou clé API (x-admin-api-key).
class SuperAdminApiService {
  SuperAdminApiService._();
  static final SuperAdminApiService instance = SuperAdminApiService._();

  String? adminApiKey;

  Dio get _dio => ServiceLocator.apiClient.dio;

  Options _options() {
    final key = adminApiKey?.trim();
    if (key != null && key.isNotEmpty) {
      return Options(headers: {'x-admin-api-key': key});
    }
    return Options();
  }

  // 1. Dashboard & Analytics
  Future<Map<String, dynamic>> getDashboard({String period = '30d'}) async {
    final res = await _dio.get(
      '/admin/dashboard',
      queryParameters: {'period': period},
      options: _options(),
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> getAnalytics({String period = '30d'}) async {
    final res = await _dio.get(
      '/admin/analytics',
      queryParameters: {'period': period},
      options: _options(),
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  // 2. Utilisatrices (données administratives uniquement)
  Future<List<Map<String, dynamic>>> listUsers({String? search, String? status}) async {
    final res = await _dio.get(
      '/admin/users',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      },
      options: _options(),
    );
    return (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> getUserDetails(String id) async {
    final res = await _dio.get('/admin/users/$id', options: _options());
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> updateUserStatus(String id, String statutCompte) async {
    await _dio.patch(
      '/admin/users/$id/status',
      data: {'statutCompte': statutCompte},
      options: _options(),
    );
  }

  Future<void> revokeUserSessions(String id) async {
    await _dio.post('/admin/users/$id/revoke-sessions', options: _options());
  }

  // 3. Professionnels de santé
  Future<List<Map<String, dynamic>>> listProfessionals({String? status}) async {
    final res = await _dio.get(
      '/admin/professionals',
      queryParameters: {if (status != null) 'status': status},
      options: _options(),
    );
    return (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> createProfessional(Map<String, dynamic> data) async {
    await _dio.post('/admin/professionals', data: data, options: _options());
  }

  Future<void> updateProfessional(String id, Map<String, dynamic> data) async {
    await _dio.patch('/admin/professionals/$id', data: data, options: _options());
  }

  // 4. Contenus & Ressources
  Future<List<Map<String, dynamic>>> listContents({String? status}) async {
    final res = await _dio.get(
      '/admin/contents',
      queryParameters: {if (status != null) 'status': status},
      options: _options(),
    );
    return (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> createContent(Map<String, dynamic> data) async {
    await _dio.post('/admin/contents', data: data, options: _options());
  }

  Future<void> updateContent(String id, Map<String, dynamic> data) async {
    await _dio.patch('/admin/contents/$id', data: data, options: _options());
  }

  Future<void> validateContentMedically(String id) async {
    await _dio.post('/admin/contents/$id/validate-medical', options: _options());
  }

  // 5. Politique d'abonnement, Offres & Promos
  Future<Map<String, dynamic>> getSubscriptionPolicy() async {
    final res = await _dio.get('/admin/subscriptions/policy', options: _options());
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> updateSubscriptionPolicy(Map<String, dynamic> data) async {
    final res = await _dio.put('/admin/subscriptions/policy', data: data, options: _options());
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<List<Map<String, dynamic>>> listOffers() async {
    final res = await _dio.get('/admin/offers', options: _options());
    return (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> upsertOffer(Map<String, dynamic> data) async {
    await _dio.post('/admin/offers', data: data, options: _options());
  }

  Future<List<Map<String, dynamic>>> listPromos() async {
    final res = await _dio.get('/admin/promos', options: _options());
    return (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> createPromo(Map<String, dynamic> data) async {
    await _dio.post('/admin/promos', data: data, options: _options());
  }

  Future<void> togglePromo(String id, bool actif) async {
    await _dio.patch('/admin/promos/$id/toggle', data: {'actif': actif}, options: _options());
  }

  // 6. Paiements & Finances
  Future<Map<String, dynamic>> listPayments({String? status, String? provider}) async {
    final res = await _dio.get(
      '/admin/payments',
      queryParameters: {
        if (status != null) 'status': status,
        if (provider != null) 'provider': provider,
      },
      options: _options(),
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> reconcilePayment(String id) async {
    final res = await _dio.post('/admin/payments/$id/reconcile', options: _options());
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<String> exportPaymentsCsv() async {
    final res = await _dio.get<String>(
      '/admin/payments/export',
      options: _options().copyWith(responseType: ResponseType.plain),
    );
    return res.data ?? '';
  }

  // 7. Notifications & Campagnes
  Future<List<Map<String, dynamic>>> listCampaigns() async {
    final res = await _dio.get('/admin/campaigns', options: _options());
    return (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> createCampaign(Map<String, dynamic> data) async {
    await _dio.post('/admin/campaigns', data: data, options: _options());
  }

  Future<void> sendCampaign(String id) async {
    await _dio.post('/admin/campaigns/$id/send', options: _options());
  }

  // 8. Support & Réclamations
  Future<List<Map<String, dynamic>>> listTickets({String? status}) async {
    final res = await _dio.get(
      '/admin/tickets',
      queryParameters: {if (status != null) 'status': status},
      options: _options(),
    );
    return (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> createTicket(Map<String, dynamic> data) async {
    await _dio.post('/admin/tickets', data: data, options: _options());
  }

  Future<void> updateTicket(String id, Map<String, dynamic> data) async {
    await _dio.patch('/admin/tickets/$id', data: data, options: _options());
  }

  Future<void> replyTicket(String id, String contenu) async {
    await _dio.post('/admin/tickets/$id/reply', data: {'contenu': contenu}, options: _options());
  }

  // 9. Sécurité, RBAC, Audit & Gouvernance
  Future<List<Map<String, dynamic>>> listAdmins() async {
    final res = await _dio.get('/admin/admins', options: _options());
    return (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> upsertAdmin(Map<String, dynamic> data) async {
    await _dio.post('/admin/admins', data: data, options: _options());
  }

  Future<List<Map<String, dynamic>>> getAuditLogs({String? module}) async {
    final res = await _dio.get(
      '/admin/audit-logs',
      queryParameters: {if (module != null) 'module': module},
      options: _options(),
    );
    return (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> getPrivacyGovernance() async {
    final res = await _dio.get('/admin/privacy/governance', options: _options());
    return Map<String, dynamic>.from(res.data as Map);
  }

  // 10 & 12. Paramètres & Monitoring
  Future<Map<String, dynamic>> getPlatformSettings() async {
    final res = await _dio.get('/admin/settings', options: _options());
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> updatePlatformSettings(Map<String, dynamic> data) async {
    final res = await _dio.put('/admin/settings', data: data, options: _options());
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> getSystemMonitoring() async {
    final res = await _dio.get('/admin/monitoring/health', options: _options());
    return Map<String, dynamic>.from(res.data as Map);
  }
}

