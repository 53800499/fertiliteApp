import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/super_admin_service.dart';
import '../views/admin_dashboard_view.dart';
import '../views/admin_users_pros_view.dart';
import '../views/admin_content_support_view.dart';
import '../views/admin_monetization_view.dart';
import '../views/admin_governance_system_view.dart';

class _AdminNavItem {
  final String group;
  final String title;
  final IconData icon;
  final Widget Function() builder;

  const _AdminNavItem({
    required this.group,
    required this.title,
    required this.icon,
    required this.builder,
  });
}

/// Centre de pilotage Super Admin MyFertility (14 modules organisés par espace).
class SuperAdminShellScreen extends StatefulWidget {
  const SuperAdminShellScreen({super.key});

  @override
  State<SuperAdminShellScreen> createState() => _SuperAdminShellScreenState();
}

class _SuperAdminShellScreenState extends State<SuperAdminShellScreen> {
  int _selectedIndex = 0;

  late final List<_AdminNavItem> _items = [
    // PILOTAGE
    _AdminNavItem(
      group: 'PILOTAGE',
      title: 'Tableau de bord',
      icon: Icons.dashboard_rounded,
      builder: () => const AdminDashboardView(showAdvancedAnalytics: false),
    ),
    _AdminNavItem(
      group: 'PILOTAGE',
      title: 'Statistiques et rapports',
      icon: Icons.analytics_rounded,
      builder: () => const AdminDashboardView(showAdvancedAnalytics: true),
    ),
    // GESTION
    _AdminNavItem(
      group: 'GESTION',
      title: 'Utilisatrices',
      icon: Icons.people_alt_rounded,
      builder: () => const AdminUsersView(),
    ),
    _AdminNavItem(
      group: 'GESTION',
      title: 'Professionnels de santé',
      icon: Icons.medical_services_rounded,
      builder: () => const AdminProfessionalsView(),
    ),
    _AdminNavItem(
      group: 'GESTION',
      title: 'Contenus et ressources',
      icon: Icons.article_rounded,
      builder: () => const AdminContentsView(),
    ),
    _AdminNavItem(
      group: 'GESTION',
      title: 'Notifications et campagnes',
      icon: Icons.campaign_rounded,
      builder: () => const AdminCampaignsView(),
    ),
    _AdminNavItem(
      group: 'GESTION',
      title: 'Support et réclamations',
      icon: Icons.support_agent_rounded,
      builder: () => const AdminSupportTicketsView(),
    ),
    // MONÉTISATION
    _AdminNavItem(
      group: 'MONÉTISATION',
      title: 'Abonnements et offres',
      icon: Icons.workspace_premium_rounded,
      builder: () => const AdminMonetizationView(key: ValueKey('mon_0'), initialTab: 0),
    ),
    _AdminNavItem(
      group: 'MONÉTISATION',
      title: 'Paiements et finances',
      icon: Icons.payments_rounded,
      builder: () => const AdminMonetizationView(key: ValueKey('mon_1'), initialTab: 1),
    ),
    _AdminNavItem(
      group: 'MONÉTISATION',
      title: 'Promotions et coupons',
      icon: Icons.local_offer_rounded,
      builder: () => const AdminMonetizationView(key: ValueKey('mon_2'), initialTab: 2),
    ),
    // ADMINISTRATION
    _AdminNavItem(
      group: 'ADMINISTRATION',
      title: 'Rôles et permissions',
      icon: Icons.admin_panel_settings_rounded,
      builder: () => const AdminGovernanceView(key: ValueKey('gov_0'), initialTab: 0),
    ),
    _AdminNavItem(
      group: 'ADMINISTRATION',
      title: 'Journaux d\'audit & RGPD',
      icon: Icons.policy_rounded,
      builder: () => const AdminGovernanceView(key: ValueKey('gov_1'), initialTab: 1),
    ),
    _AdminNavItem(
      group: 'ADMINISTRATION',
      title: 'Surveillance technique',
      icon: Icons.monitor_heart_rounded,
      builder: () => const AdminGovernanceView(key: ValueKey('gov_2'), initialTab: 2),
    ),
    _AdminNavItem(
      group: 'ADMINISTRATION',
      title: 'Paramètres généraux',
      icon: Icons.settings_rounded,
      builder: () => const AdminGovernanceView(key: ValueKey('gov_3'), initialTab: 3),
    ),
  ];

  Future<void> _promptApiKey() async {
    final ctrl = TextEditingController(text: SuperAdminApiService.instance.adminApiKey ?? '');
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clé Back-Office Super Admin'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'x-admin-api-key (optionnel si compte super_admin)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
    if (saved != null && mounted) {
      setState(() {
        SuperAdminApiService.instance.adminApiKey = saved.isEmpty ? null : saved;
      });
    }
  }

  Widget _buildSidebarContent({bool closeDrawer = false}) {
    final groups = <String>[];
    for (final item in _items) {
      if (!groups.contains(item.group)) groups.add(item.group);
    }

    return Container(
      width: 268,
      color: const Color(0xFF141824),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              alignment: Alignment.centerLeft,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MyFertility',
                    style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'SUPER ADMIN • PILOTAGE',
                    style: TextStyle(color: Color(0xFFF48FB1), fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.1),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  for (final group in groups) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 16, 6),
                      child: Text(
                        group,
                        style: const TextStyle(color: Colors.white38, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                      ),
                    ),
                    ..._items.asMap().entries.where((e) => e.value.group == group).map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      final active = idx == _selectedIndex;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          tileColor: active ? AppTheme.primary.withValues(alpha: 0.22) : Colors.transparent,
                          leading: Icon(item.icon, size: 19, color: active ? const Color(0xFFF48FB1) : Colors.white70),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: active ? FontWeight.bold : FontWeight.w500,
                              color: active ? Colors.white : Colors.white70,
                            ),
                          ),
                          onTap: () {
                            setState(() => _selectedIndex = idx);
                            if (closeDrawer) Navigator.pop(context);
                          },
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final current = _items[_selectedIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0.5,
        title: Text(current.title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Clé API Super Admin',
            icon: const Icon(Icons.vpn_key_rounded),
            onPressed: _promptApiKey,
          ),
          IconButton(
            tooltip: 'Fermer le Back-Office',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      drawer: isWide ? null : Drawer(child: _buildSidebarContent(closeDrawer: true)),
      body: Row(
        children: [
          if (isWide) _buildSidebarContent(),
          Expanded(child: current.builder()),
        ],
      ),
    );
  }
}

