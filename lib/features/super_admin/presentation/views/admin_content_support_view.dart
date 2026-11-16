import 'package:flutter/material.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../data/super_admin_service.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminContentsView extends StatefulWidget {
  const AdminContentsView({super.key});

  @override
  State<AdminContentsView> createState() => _AdminContentsViewState();
}

class _AdminContentsViewState extends State<AdminContentsView> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await SuperAdminApiService.instance.listContents();
      if (mounted) setState(() => _items = list);
    } catch (e) {
      if (mounted) AppFeedback.showError(context, message: ApiException.getDisplayMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createArticle() async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String category = 'fertilite';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Nouvel article / ressource'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Titre')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: const [
                    DropdownMenuItem(value: 'fertilite', child: Text('Fertilité')),
                    DropdownMenuItem(value: 'cycle', child: Text('Cycle menstruel')),
                    DropdownMenuItem(value: 'grossesse', child: Text('Grossesse')),
                    DropdownMenuItem(value: 'nutrition', child: Text('Nutrition')),
                    DropdownMenuItem(value: 'faq', child: Text('FAQ')),
                  ],
                  onChanged: (v) => setS(() => category = v ?? 'fertilite'),
                ),
                TextField(controller: bodyCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Contenu éducatif')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await SuperAdminApiService.instance.createContent({
                  'titre': titleCtrl.text,
                  'categorie': category,
                  'contenu': bodyCtrl.text,
                  'statut': 'en_validation_medicale',
                  'validationMedicaleRequise': true,
                });
                _load();
              },
              child: const Text('Soumettre'),
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
                  Text('Contenus & Ressources', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  Text('Workflow éditorial avec validation médicale obligatoire', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
            ElevatedButton.icon(onPressed: _createArticle, icon: const Icon(Icons.add), label: const Text('Créer')),
          ],
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_items.isEmpty)
          const AdminSectionCard(
            title: 'Espace éditorial prêt',
            child: Text('Créez vos articles fertilité, cycle, grossesse, nutrition et FAQ.'),
          )
        else
          ..._items.map((c) {
            final statut = (c['statut'] ?? 'brouillon').toString();
            final color = statut == 'publie' ? Colors.teal : Colors.orange;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(c['titre'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${c['categorie']} • Validé par: ${c['validePar'] ?? 'En attente'}'),
                trailing: statut != 'publie'
                    ? ElevatedButton(
                        onPressed: () async {
                          await SuperAdminApiService.instance.validateContentMedically(c['id'].toString());
                          _load();
                        },
                        child: const Text('Valider & Publier'),
                      )
                    : AdminStatusChip(label: 'PUBLIÉ', color: color),
              ),
            );
          }),
      ],
    );
  }
}

class AdminCampaignsView extends StatefulWidget {
  const AdminCampaignsView({super.key});

  @override
  State<AdminCampaignsView> createState() => _AdminCampaignsViewState();
}

class _AdminCampaignsViewState extends State<AdminCampaignsView> {
  bool _loading = true;
  List<Map<String, dynamic>> _campaigns = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await SuperAdminApiService.instance.listCampaigns();
      if (mounted) setState(() => _campaigns = res);
    } catch (e) {
      if (mounted) AppFeedback.showError(context, message: ApiException.getDisplayMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createCampaign() async {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    String canal = 'push';
    String segment = 'toutes';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Nouvelle campagne discrète'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Titre')),
              TextField(controller: msgCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Message privé (discret sur écran verrouillé)')),
              DropdownButtonFormField<String>(
                value: canal,
                items: const [
                  DropdownMenuItem(value: 'push', child: Text('Push Mobile')),
                  DropdownMenuItem(value: 'email', child: Text('E-mail')),
                  DropdownMenuItem(value: 'sms', child: Text('SMS')),
                ],
                onChanged: (v) => setS(() => canal = v ?? 'push'),
              ),
              DropdownButtonFormField<String>(
                value: segment,
                items: const [
                  DropdownMenuItem(value: 'toutes', child: Text('Toutes les utilisatrices')),
                  DropdownMenuItem(value: 'gratuites', child: Text('Comptes gratuits')),
                  DropdownMenuItem(value: 'premium', child: Text('Abonnées Premium')),
                ],
                onChanged: (v) => setS(() => segment = v ?? 'toutes'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await SuperAdminApiService.instance.createCampaign({
                  'titre': titleCtrl.text,
                  'messagePrive': msgCtrl.text,
                  'canal': canal,
                  'segment': segment,
                });
                _load();
              },
              child: const Text('Créer'),
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
                  Text('Notifications & Campagnes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  Text('Push, e-mails & SMS avec confidentialité écran verrouillé', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
            ElevatedButton.icon(onPressed: _createCampaign, icon: const Icon(Icons.campaign), label: const Text('Nouvelle')),
          ],
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_campaigns.isEmpty)
          const AdminSectionCard(
            title: 'Aucune campagne',
            child: Text('Créez une campagne de sensibilisation ou d\'information.'),
          )
        else
          ..._campaigns.map((c) {
            final sent = c['statut'] == 'envoyee';
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(c['titre'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${c['canal']} • Segment: ${c['segment']} • Destinataires: ${c['totalDestinataires']}'),
                trailing: sent
                    ? const AdminStatusChip(label: 'ENVOYÉE', color: Colors.teal)
                    : ElevatedButton(
                        onPressed: () async {
                          await SuperAdminApiService.instance.sendCampaign(c['id'].toString());
                          _load();
                        },
                        child: const Text('Envoyer'),
                      ),
              ),
            );
          }),
      ],
    );
  }
}

class AdminSupportTicketsView extends StatefulWidget {
  const AdminSupportTicketsView({super.key});

  @override
  State<AdminSupportTicketsView> createState() => _AdminSupportTicketsViewState();
}

class _AdminSupportTicketsViewState extends State<AdminSupportTicketsView> {
  bool _loading = true;
  List<Map<String, dynamic>> _tickets = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await SuperAdminApiService.instance.listTickets();
      if (mounted) setState(() => _tickets = res);
    } catch (e) {
      if (mounted) AppFeedback.showError(context, message: ApiException.getDisplayMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _replyTicket(Map<String, dynamic> t) async {
    final replyCtrl = TextEditingController();
    String nextStatus = (t['statut'] ?? 'en_cours').toString();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(t['sujet'].toString()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: nextStatus,
                items: const [
                  DropdownMenuItem(value: 'nouveau', child: Text('Nouveau')),
                  DropdownMenuItem(value: 'en_cours', child: Text('En cours')),
                  DropdownMenuItem(value: 'en_attente', child: Text('En attente')),
                  DropdownMenuItem(value: 'resolu', child: Text('Résolu')),
                  DropdownMenuItem(value: 'ferme', child: Text('Fermé')),
                ],
                onChanged: (v) => setS(() => nextStatus = v ?? 'en_cours'),
              ),
              TextField(controller: replyCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Réponse support')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await SuperAdminApiService.instance.updateTicket(t['id'].toString(), {'statut': nextStatus});
                if (replyCtrl.text.trim().isNotEmpty) {
                  await SuperAdminApiService.instance.replyTicket(t['id'].toString(), replyCtrl.text);
                }
                _load();
              },
              child: const Text('Mettre à jour'),
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
        const Text('Support & Réclamations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const Text('Tickets utilisatrices : Nouveau, En cours, En attente, Résolu, Fermé', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_tickets.isEmpty)
          const AdminSectionCard(
            title: 'Aucun ticket ouvert',
            child: Text('Tous les tickets de support sont à jour.'),
          )
        else
          ..._tickets.map((t) {
            final statut = (t['statut'] ?? 'nouveau').toString();
            final color = statut == 'resolu' || statut == 'ferme' ? Colors.teal : Colors.orange;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(t['sujet'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${t['utilisateurEmail']} • Priorité: ${t['priorite']}'),
                trailing: AdminStatusChip(label: statut.toUpperCase(), color: color),
                onTap: () => _replyTicket(t),
              ),
            );
          }),
      ],
    );
  }
}

