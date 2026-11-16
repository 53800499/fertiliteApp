import 'package:flutter/material.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../data/super_admin_service.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'tous';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await SuperAdminApiService.instance.listUsers(
        search: _searchCtrl.text.trim(),
        status: _statusFilter,
      );
      if (mounted) setState(() => _users = list);
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.getDisplayMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openUserDetail(String userId) async {
    try {
      final detail = await SuperAdminApiService.instance.getUserDetails(userId);
      if (!mounted) return;
      final compte = Map<String, dynamic>.from(detail['compte'] as Map);
      final sessions = (detail['sessions'] as List?) ?? [];
      final subs = (detail['abonnements'] as List?) ?? [];
      final consents = (detail['consentements'] as List?) ?? [];

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          builder: (_, ctrl) => ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(20),
            children: [
              Text(compte['email']?.toString() ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
                child: Text(detail['noteConfidentialite']?.toString() ?? '', style: TextStyle(fontSize: 11.5, color: Colors.amber.shade900)),
              ),
              const SizedBox(height: 14),
              Text('Statut : ${compte['statutCompte']} • Rôle : ${compte['role']}'),
              Text('Langue : ${compte['languePreferee']} • Fuseau : ${compte['fuseauHoraire']}'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await SuperAdminApiService.instance.updateUserStatus(
                        userId,
                        compte['statutCompte'] == 'suspendu' ? 'actif' : 'suspendu',
                      );
                      _load();
                    },
                    icon: const Icon(Icons.pause_circle_outline),
                    label: Text(compte['statutCompte'] == 'suspendu' ? 'Réactiver' : 'Suspendre'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await SuperAdminApiService.instance.revokeUserSessions(userId);
                      if (mounted) AppFeedback.showSuccess(context, message: 'Sessions révoquées.');
                    },
                    icon: const Icon(Icons.security_rounded),
                    label: const Text('Révoquer sessions'),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text('Sessions récentes (${sessions.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
              ...sessions.take(5).map((s) => Text('• ${s['plateforme']} — révoqué: ${s['revoque']}')),
              const SizedBox(height: 12),
              Text('Abonnements (${subs.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
              ...subs.take(5).map((s) => Text('• ${s['plan']} (${s['statut']}) — ${s['montant']} ${s['devise']}')),
              const SizedBox(height: 12),
              Text('Consentements RGPD (${consents.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
              ...consents.take(5).map((c) => Text('• ${c['typeConsentement']} : ${c['statutAccepte']}')),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) AppFeedback.showError(context, message: ApiException.getDisplayMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Gestion des utilisatrices', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const Text(
          'Vue administrative uniquement — les données médicales (cycles, BBT, symptômes) restent chiffrées et isolées.',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Rechercher par e-mail ou prénom...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
                onSubmitted: (_) => _load(),
              ),
            ),
            const SizedBox(width: 10),
            DropdownButton<String>(
              value: _statusFilter,
              items: const [
                DropdownMenuItem(value: 'tous', child: Text('Tous')),
                DropdownMenuItem(value: 'actif', child: Text('Actifs')),
                DropdownMenuItem(value: 'suspendu', child: Text('Suspendus')),
                DropdownMenuItem(value: 'supprime', child: Text('Supprimés')),
              ],
              onChanged: (v) {
                setState(() => _statusFilter = v ?? 'tous');
                _load();
              },
            ),
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        const SizedBox(height: 14),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red))
        else
          ..._users.map((u) {
            final status = (u['statutCompte'] ?? 'actif').toString();
            final color = status == 'actif'
                ? Colors.teal
                : (status == 'suspendu' ? Colors.orange : Colors.red);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                  child: const Icon(Icons.person_outline, color: AppTheme.primary),
                ),
                title: Text(u['email']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Prénom: ${u['prenom'] ?? '—'} • Rôle: ${u['role']}'),
                trailing: AdminStatusChip(label: status.toUpperCase(), color: color),
                onTap: () => _openUserDetail(u['id'].toString()),
              ),
            );
          }),
      ],
    );
  }
}

class AdminProfessionalsView extends StatefulWidget {
  const AdminProfessionalsView({super.key});

  @override
  State<AdminProfessionalsView> createState() => _AdminProfessionalsViewState();
}

class _AdminProfessionalsViewState extends State<AdminProfessionalsView> {
  bool _loading = true;
  List<Map<String, dynamic>> _pros = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await SuperAdminApiService.instance.listProfessionals();
      if (mounted) setState(() => _pros = res);
    } catch (e) {
      if (mounted) AppFeedback.showError(context, message: ApiException.getDisplayMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController();
    final etabCtrl = TextEditingController();
    final ordreCtrl = TextEditingController();
    String spec = 'gynecologue';
    String commune = 'Cotonou';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Ajouter un professionnel'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nom complet')),
                TextField(controller: etabCtrl, decoration: const InputDecoration(labelText: 'Établissement / Clinique')),
                TextField(controller: ordreCtrl, decoration: const InputDecoration(labelText: 'N° Ordre / Diplôme')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: spec,
                  decoration: const InputDecoration(labelText: 'Spécialité'),
                  items: const [
                    DropdownMenuItem(value: 'gynecologue', child: Text('Gynécologue')),
                    DropdownMenuItem(value: 'sage_femme', child: Text('Sage-femme')),
                    DropdownMenuItem(value: 'fertilite', child: Text('Médecin fertilité')),
                    DropdownMenuItem(value: 'psychologue', child: Text('Psychologue')),
                    DropdownMenuItem(value: 'conseiller', child: Text('Conseiller santé reproductive')),
                  ],
                  onChanged: (v) => setS(() => spec = v ?? 'gynecologue'),
                ),
                TextFormField(
                  initialValue: commune,
                  decoration: const InputDecoration(labelText: 'Commune'),
                  onChanged: (v) => commune = v,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await SuperAdminApiService.instance.createProfessional({
                  'nomComplet': nameCtrl.text,
                  'specialite': spec,
                  'etablissement': etabCtrl.text,
                  'numeroOrdre': ordreCtrl.text,
                  'commune': commune,
                  'statutValidation': 'valide',
                  'diplomeVerifie': true,
                });
                _load();
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Professionnels de santé', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  Text('Gynécologues, sages-femmes, spécialistes fertilité', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
            ElevatedButton.icon(onPressed: _showAddDialog, icon: const Icon(Icons.add), label: const Text('Ajouter')),
          ],
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_pros.isEmpty)
          const AdminSectionCard(
            title: 'Annuaire vide',
            child: Text('Ajoutez votre premier professionnel partenaire pour le Bénin.'),
          )
        else
          ..._pros.map((p) {
            final status = (p['statutValidation'] ?? 'en_attente').toString();
            final color = status == 'valide' ? Colors.teal : (status == 'suspendu' ? Colors.red : Colors.orange);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(p['nomComplet'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${p['specialite']} • ${p['etablissement'] ?? 'Cabinet'} (${p['commune']})'),
                trailing: PopupMenuButton<String>(
                  onSelected: (val) async {
                    await SuperAdminApiService.instance.updateProfessional(p['id'].toString(), {
                      'statutValidation': val,
                      'diplomeVerifie': val == 'valide',
                    });
                    _load();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'valide', child: Text('Valider diplôme')),
                    PopupMenuItem(value: 'suspendu', child: Text('Suspendre')),
                    PopupMenuItem(value: 'rejete', child: Text('Rejeter')),
                  ],
                  child: AdminStatusChip(label: status.toUpperCase(), color: color),
                ),
              ),
            );
          }),
      ],
    );
  }
}

