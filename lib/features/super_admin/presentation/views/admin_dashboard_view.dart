import 'package:flutter/material.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/super_admin_service.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminDashboardView extends StatefulWidget {
  final bool showAdvancedAnalytics;

  const AdminDashboardView({
    super.key,
    this.showAdvancedAnalytics = false,
  });

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  String _period = '30d';
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = widget.showAdvancedAnalytics
          ? await SuperAdminApiService.instance.getAnalytics(period: _period)
          : await SuperAdminApiService.instance.getDashboard(period: _period);
      if (mounted) setState(() => _data = res);
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.getDisplayMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    final kpis = Map<String, dynamic>.from((_data?['kpis'] as Map?) ?? {});
    final charts = Map<String, dynamic>.from((_data?['charts'] as Map?) ?? {});
    final monthly = ((charts['monthlySeries'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final geo = ((charts['geoDistribution'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final features = ((charts['featureUsage'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.showAdvancedAnalytics
                        ? 'Statistiques & Rapports Avancés'
                        : 'Tableau de bord général',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                  ),
                  const Text(
                    'Pilotage en temps réel • Données agrégées et anonymisées',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: '7d', label: Text('7j')),
                  ButtonSegment(value: '30d', label: Text('30j')),
                  ButtonSegment(value: '90d', label: Text('90j')),
                  ButtonSegment(value: 'all', label: Text('Tout')),
                ],
                selected: {_period},
                onSelectionChanged: (s) {
                  setState(() => _period = s.first);
                  _load();
                },
              ),
            ],
          ),
          const SizedBox(height: 18),

          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 550 ? 2 : 1);
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: cols == 1 ? 2.4 : 1.35,
                children: [
                  AdminKpiCard(
                    title: 'Utilisatrices inscrites',
                    value: '${kpis['totalUsers'] ?? 0}',
                    subtitle: '+${kpis['newRegistrations'] ?? 0} sur la période',
                    icon: Icons.people_alt_rounded,
                    color: AppTheme.primary,
                  ),
                  AdminKpiCard(
                    title: 'Actives (J / S / M)',
                    value: '${kpis['activeDay'] ?? 0} / ${kpis['activeWeek'] ?? 0} / ${kpis['activeMonth'] ?? 0}',
                    subtitle: 'Rétention : ${kpis['retentionRate'] ?? 0}%',
                    icon: Icons.trending_up_rounded,
                    color: Colors.teal,
                  ),
                  AdminKpiCard(
                    title: 'Abonnements Premium',
                    value: '${kpis['activeSubscriptions'] ?? 0}',
                    subtitle: 'Conversion : ${kpis['conversionRate'] ?? 0}%',
                    icon: Icons.workspace_premium_rounded,
                    color: Colors.deepPurple,
                  ),
                  AdminKpiCard(
                    title: 'Chiffre d\'affaires',
                    value: '${kpis['totalRevenue'] ?? 0} XOF',
                    subtitle: '${kpis['totalCycles'] ?? 0} cycles suivis',
                    icon: Icons.payments_rounded,
                    color: Colors.orange.shade800,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          AdminSectionCard(
            title: 'Évolution des inscriptions (6 mois)',
            subtitle: 'Croissance mensuelle des comptes créés',
            child: AdminSimpleBarChart(
              series: monthly,
              valueKey: 'inscriptions',
              labelKey: 'label',
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),

          AdminSectionCard(
            title: 'Revenus mensuels (XOF)',
            subtitle: 'Transactions encaissées sur 6 mois',
            child: AdminSimpleBarChart(
              series: monthly,
              valueKey: 'revenus',
              labelKey: 'label',
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 16),

          AdminSectionCard(
            title: 'Répartition géographique (Bénin)',
            subtitle: 'Départements & communes',
            child: Column(
              children: geo.map((g) {
                final pct = (g['pourcentage'] as num?)?.toDouble() ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(g['departement'].toString(), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                          Text('${g['utilisatrices']} (${pct.toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (pct / 100).clamp(0.0, 1.0),
                          minHeight: 7,
                          backgroundColor: Colors.grey.shade200,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          AdminSectionCard(
            title: 'Utilisation des fonctionnalités',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: features.map((f) {
                return Chip(
                  avatar: const Icon(Icons.analytics_outlined, size: 16, color: AppTheme.primary),
                  label: Text('${f['module']}: ${f['volume']}'),
                  backgroundColor: Colors.grey.shade50,
                );
              }).toList(),
            ),
          ),

          if (widget.showAdvancedAnalytics && _data?['retentionMetrics'] != null) ...[
            const SizedBox(height: 16),
            AdminSectionCard(
              title: 'Rétention & Objectifs (Anonymisés)',
              subtitle: 'Seuil k-anonymat appliqué pour la protection des données de santé',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Abonnements expirés : ${_data!['retentionMetrics']['expiredSubscriptions']}'),
                  Text('Désabonnements (churn) : ${_data!['retentionMetrics']['churnRate']}%'),
                  Text('Consentements tracés : ${_data!['retentionMetrics']['totalConsentsRecorded']}'),
                  const Divider(height: 20),
                  ...((_data!['anonymizedObjectives'] as List?) ?? []).map(
                    (o) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• ${o['objectif']} : ${o['count']}'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

