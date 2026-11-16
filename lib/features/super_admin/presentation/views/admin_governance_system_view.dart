import 'package:flutter/material.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../data/super_admin_service.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminGovernanceView extends StatefulWidget {
  final int initialTab;

  const AdminGovernanceView({super.key, this.initialTab = 0});

  @override
  State<AdminGovernanceView> createState() => _AdminGovernanceViewState();
}

class _AdminGovernanceViewState extends State<AdminGovernanceView> {
  late int _tab;
  bool _loading = true;
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _logs = [];
  Map<String, dynamic> _monitoring = {};
  Map<String, dynamic> _settings = {};
  Map<String, dynamic> _governance = {};
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _androidVerCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _androidVerCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        SuperAdminApiService.instance.listAdmins(),
        SuperAdminApiService.instance.getAuditLogs(),
        SuperAdminApiService.instance.getSystemMonitoring(),
        SuperAdminApiService.instance.getPlatformSettings(),
        SuperAdminApiService.instance.getPrivacyGovernance(),
      ]);
      if (!mounted) return;
      setState(() {
        _admins = results[0] as List<Map<String, dynamic>>;
        _logs = results[1] as List<Map<String, dynamic>>;
        _monitoring = results[2] as Map<String, dynamic>;
        _settings = results[3] as Map<String, dynamic>;
        _governance = results[4] as Map<String, dynamic>;
        _nameCtrl.text = (_settings['nomPlateforme'] ?? 'MyFertility').toString();
        _emailCtrl.text = (_settings['emailContact'] ?? '').toString();
        _androidVerCtrl.text = (_settings['versionMinAndroid'] ?? '1.0.0').toString();
      });
    } catch (e) {
      if (mounted) AppFeedback.showError(context, message: ApiException.getDisplayMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addAdminDialog() async {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'admin';
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Ajouter / Promouvoir un administrateur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'E-mail')),
              TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Mot de passe (si nouveau compte)')),
              DropdownButtonFormField<String>(
                value: role,
                items: const [
                  DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
                ],
                onChanged: (v) => setS(() => role = v ?? 'admin'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await SuperAdminApiService.instance.upsertAdmin({
                  'email': emailCtrl.text.trim(),
                  if (passCtrl.text.isNotEmpty) 'password': passCtrl.text,
                  'role': role,
                });
                _load();
              },
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final db = Map<String, dynamic>.from((_monitoring['database'] as Map?) ?? {});
    final mem = Map<String, dynamic>.from((_monitoring['memoryMb'] as Map?) ?? {});
    final services = Map<String, dynamic>.from((_monitoring['services'] as Map?) ?? {});
    final deletions = (_governance['deletionRequests'] as List?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Rôles & RBAC')),
            ButtonSegment(value: 1, label: Text('Audit & RGPD')),
            ButtonSegment(value: 2, label: Text('Monitoring')),
            ButtonSegment(value: 3, label: Text('Paramètres')),
          ],
          selected: {_tab},
          onSelectionChanged: (s) => setState(() => _tab = s.first),
        ),
        const SizedBox(height: 18),

        if (_tab == 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Administrateurs & Rôles', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(onPressed: _addAdminDialog, icon: const Icon(Icons.person_add), label: const Text('Ajouter')),
            ],
          ),
          const SizedBox(height: 12),
          ..._admins.map((a) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(a['email'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Statut: ${a['statutCompte']}'),
                  trailing: AdminStatusChip(label: a['role'].toString().toUpperCase(), color: AppTheme.primary),
                ),
              )),
        ] else if (_tab == 1) ...[
          AdminSectionCard(
            title: 'Demandes de suppression & Gouvernance RGPD',
            child: deletions.isEmpty
                ? const Text('Aucune demande de suppression en attente.')
                : Column(
                    children: deletions.map((d) => ListTile(
                      dense: true,
                      title: Text(d['email'].toString()),
                      subtitle: Text('Demandée le ${d['dateSuppressionDemandee']}'),
                    )).toList(),
                  ),
          ),
          const SizedBox(height: 16),
          const Text('Journal d\'audit immuable', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._logs.take(50).map((l) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  title: Text('${l['module']} • ${l['action']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${l['actorEmail']} (${l['actorRole']}) • ${l['dateCreation']}'),
                ),
              )),
        ] else if (_tab == 2) ...[
          AdminSectionCard(
            title: 'Surveillance technique & santé système',
            trailing: IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('API : ${_monitoring['apiStatus']} (${_monitoring['nodeEnv']})'),
                Text('PostgreSQL : ${db['status']} (latence ${db['latencyMs']} ms)'),
                Text('Mémoire Node : ${mem['heapUsed']} / ${mem['heapTotal']} MB (RSS ${mem['rss']} MB)'),
                Text('Uptime : ${_monitoring['uptimeSeconds']} s'),
                Text('FedaPay : mode ${services['fedapayMode']} (configuré: ${services['fedapayConfigured']})'),
              ],
            ),
          ),
        ] else ...[
          AdminSectionCard(
            title: 'Paramètres généraux de la plateforme',
            child: Column(
              children: [
                TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nom de la plateforme')),
                TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'E-mail support')),
                TextField(controller: _androidVerCtrl, decoration: const InputDecoration(labelText: 'Version min Android')),
                SwitchListTile(
                  value: _settings['modeMaintenance'] == true,
                  title: const Text('Mode maintenance'),
                  onChanged: (v) async {
                    await SuperAdminApiService.instance.updatePlatformSettings({'modeMaintenance': v});
                    _load();
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    await SuperAdminApiService.instance.updatePlatformSettings({
                      'nomPlateforme': _nameCtrl.text,
                      'emailContact': _emailCtrl.text,
                      'versionMinAndroid': _androidVerCtrl.text,
                    });
                    if (mounted) AppFeedback.showSuccess(context, message: 'Paramètres enregistrés.');
                  },
                  child: const Text('Enregistrer les paramètres'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

