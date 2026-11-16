import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../data/super_admin_service.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminMonetizationView extends StatefulWidget {
  final int initialTab;

  const AdminMonetizationView({super.key, this.initialTab = 0});

  @override
  State<AdminMonetizationView> createState() => _AdminMonetizationViewState();
}

class _AdminMonetizationViewState extends State<AdminMonetizationView> {
  late int _tab;
  bool _loading = true;
  Map<String, dynamic> _policy = {};
  List<Map<String, dynamic>> _offers = [];
  List<Map<String, dynamic>> _promos = [];
  Map<String, dynamic> _payments = {};
  final _msgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _load();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        SuperAdminApiService.instance.getSubscriptionPolicy(),
        SuperAdminApiService.instance.listOffers(),
        SuperAdminApiService.instance.listPayments(),
        SuperAdminApiService.instance.listPromos(),
      ]);
      if (!mounted) return;
      setState(() {
        _policy = results[0] as Map<String, dynamic>;
        _msgCtrl.text = (_policy['messageRecommandation'] ?? '').toString();
        _offers = results[1] as List<Map<String, dynamic>>;
        _payments = results[2] as Map<String, dynamic>;
        _promos = results[3] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      if (mounted) AppFeedback.showError(context, message: ApiException.getDisplayMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _savePolicy({bool? initGate, bool? paywalls}) async {
    try {
      final res = await SuperAdminApiService.instance.updateSubscriptionPolicy({
        if (initGate != null) 'exigenceAbonnementInitiale': initGate,
        if (paywalls != null) 'exigencePaywallsPremium': paywalls,
        'messageRecommandation': _msgCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        _policy = Map<String, dynamic>.from((res['policy'] as Map?) ?? _policy);
      });
      AppFeedback.showSuccess(context, message: 'Politique d\'abonnement mise à jour.');
    } catch (e) {
      if (mounted) AppFeedback.showError(context, message: ApiException.getDisplayMessage(e));
    }
  }

  Future<void> _createPromoDialog() async {
    final codeCtrl = TextEditingController();
    final pctCtrl = TextEditingController(text: '20');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouveau code promo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code (ex: BENIN20)')),
            TextField(controller: pctCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Réduction (%)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SuperAdminApiService.instance.createPromo({
                'code': codeCtrl.text,
                'pourcentageReduction': int.tryParse(pctCtrl.text) ?? 10,
              });
              _load();
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final txList = ((_payments['transactions'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final summary = Map<String, dynamic>.from((_payments['summary'] as Map?) ?? {});

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Abonnements & Offres')),
            ButtonSegment(value: 1, label: Text('Paiements & Finances')),
            ButtonSegment(value: 2, label: Text('Promotions')),
          ],
          selected: {_tab},
          onSelectionChanged: (s) => setState(() => _tab = s.first),
        ),
        const SizedBox(height: 18),

        if (_tab == 0) ...[
          AdminSectionCard(
            title: 'Pilotage global de l\'exigence d\'abonnement',
            subtitle: 'Contrôle en direct sans redéploiement mobile',
            child: Column(
              children: [
                SwitchListTile(
                  value: _policy['exigenceAbonnementInitiale'] == true,
                  title: const Text('Exiger un abonnement à l\'installation initiale'),
                  subtitle: const Text('Si activé, l\'app présente l\'abonnement au premier démarrage tout en laissant l\'accès gratuit possible avec recommandation.'),
                  onChanged: (v) => _savePolicy(initGate: v),
                ),
                SwitchListTile(
                  value: _policy['exigencePaywallsPremium'] ?? true,
                  title: const Text('Activer les blocages Premium (Paywalls)'),
                  subtitle: const Text('Verrouille Bilan médical, courbe BBT, facteurs fertilité et historique > 3 cycles pour les comptes gratuits.'),
                  onChanged: (v) => _savePolicy(paywalls: v),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _msgCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Message de recommandation',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => _savePolicy(),
                    child: const Text('Enregistrer le message'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Catalogue des offres actives', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ..._offers.map((o) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text('${o['nom']} (${o['prix']} ${o['devise']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${o['periode']} • Essai gratuit: ${o['essaiGratuitJours']}j'),
                  trailing: AdminStatusChip(
                    label: o['actif'] == true ? 'ACTIF' : 'SUSPENDU',
                    color: o['actif'] == true ? Colors.teal : Colors.grey,
                  ),
                ),
              )),
        ] else if (_tab == 1) ...[
          AdminSectionCard(
            title: 'Synthèse financière',
            trailing: OutlinedButton.icon(
              onPressed: () async {
                final csv = await SuperAdminApiService.instance.exportPaymentsCsv();
                await Clipboard.setData(ClipboardData(text: csv));
                if (context.mounted) {
                  AppFeedback.showSuccess(context, message: 'Export CSV copié dans le presse-papier.');
                }
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Exporter CSV'),
            ),
            child: Text(
              'Total encaissé : ${summary['totalEncaisse'] ?? 0} ${summary['devise'] ?? 'XOF'} (${summary['totalTransactions'] ?? 0} transactions)',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 14),
          ...txList.map((t) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('${t['utilisateurEmail']} — ${t['montant']} ${t['devise']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${t['plan']} • ${t['fournisseur']} • Réf: ${t['referenceTransaction'] ?? '—'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AdminStatusChip(
                        label: (t['statut'] ?? '').toString().toUpperCase(),
                        color: t['statut'] == 'actif' ? Colors.teal : Colors.orange,
                      ),
                      if (t['referenceTransaction'] != null)
                        IconButton(
                          tooltip: 'Rapprocher avec FedaPay',
                          icon: const Icon(Icons.sync_rounded),
                          onPressed: () async {
                            final res = await SuperAdminApiService.instance.reconcilePayment(t['id'].toString());
                            if (context.mounted) {
                              AppFeedback.showInfo(context, message: 'Statut FedaPay : ${res['providerStatus']}');
                            }
                          },
                        ),
                    ],
                  ),
                ),
              )),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Codes promotionnels', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(onPressed: _createPromoDialog, icon: const Icon(Icons.add), label: const Text('Créer')),
            ],
          ),
          const SizedBox(height: 12),
          ..._promos.map((p) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: SwitchListTile(
                  value: p['actif'] == true,
                  title: Text('${p['code']} (-${p['pourcentageReduction']}%)', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Utilisations : ${p['utilisationsActuelles']} / ${p['utilisationsMax']}'),
                  onChanged: (v) async {
                    await SuperAdminApiService.instance.togglePromo(p['id'].toString(), v);
                    _load();
                  },
                ),
              )),
        ],
      ],
    );
  }
}

