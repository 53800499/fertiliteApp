import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/observation_models.dart';
import '../bloc/observation_bloc.dart';
import '../bloc/observation_event.dart';
import '../../../fertility/presentation/bloc/fertility_bloc.dart';
import '../../../cycles/presentation/bloc/cycle_bloc.dart';
import '../../../cycles/presentation/bloc/cycle_event.dart';
import '../../../../core/network/network_cubit.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/error/error_feedback.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/di/service_locator.dart';

class ObservationEntryBottomSheet extends StatefulWidget {
  final DateTime date;
  final DayObservationsModel? existingObservations;
  final List<TypeSymptomeModel> catalog;

  const ObservationEntryBottomSheet({
    super.key,
    required this.date,
    this.existingObservations,
    this.catalog = const [],
  });

  static Future<bool?> show(
    BuildContext context, {
    required DateTime date,
    DayObservationsModel? existingObservations,
    List<TypeSymptomeModel> catalog = const [],
  }) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final obsBloc = context.read<ObservationBloc>();
    final fertBloc = context.read<FertilityBloc>();
    final cycleBloc = context.read<CycleBloc>();
    obsBloc.add(LoadDayObservationsEvent(dateStr));

    final effectiveObs = existingObservations ?? obsBloc.cachedDays[dateStr];
    final effectiveCatalog = catalog.isNotEmpty ? catalog : obsBloc.cachedCatalog;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: obsBloc),
          BlocProvider.value(value: fertBloc),
          BlocProvider.value(value: cycleBloc),
        ],
        child: ObservationEntryBottomSheet(
          date: date,
          existingObservations: effectiveObs,
          catalog: effectiveCatalog,
        ),
      ),
    );
  }

  @override
  State<ObservationEntryBottomSheet> createState() =>
      _ObservationEntryBottomSheetState();
}

class _ObservationEntryBottomSheetState
    extends State<ObservationEntryBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSaving = false;

  // 1. Température state
  bool _enableTemp = false;
  double _temperature = 36.60;
  String _heurePrise = '07:00';
  bool _estPerturbee = false;
  String? _facteurPerturbateur;
  final TextEditingController _notesTempController = TextEditingController();

  // 2. Glaire state
  bool _enableGlaire = false;
  String _typeGlaire = GlaireType.cremeux;
  final TextEditingController _notesGlaireController = TextEditingController();

  // 3. Test LH state
  bool _enableLh = false;
  String _resultatLh = LhResult.negatif;
  double? _valeurMUiMl;
  final TextEditingController _notesLhController = TextEditingController();

  // 4. Symptômes state (Map<code, int (1-5)>)
  final Map<String, int> _selectedSymptoms = {};

  final List<String> _perturbateurs = [
    'Fièvre / Maladie',
    'Alcool la veille',
    'Sommeil écourté (< 5h)',
    'Prise de médicament',
    'Stress inhabituel',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initExistingValues();
  }

  void _initExistingValues() {
    final obs = widget.existingObservations;
    if (obs == null) return;

    if (obs.temperature != null) {
      _enableTemp = true;
      _temperature = obs.temperature!.temperatureCelsius;
      _heurePrise = obs.temperature!.heurePrise ?? '07:00';
      _estPerturbee = obs.temperature!.estPerturbee;
      _facteurPerturbateur = obs.temperature!.facteurPerturbateur;
      _notesTempController.text = obs.temperature!.notes ?? '';
    }

    if (obs.glaire != null) {
      _enableGlaire = true;
      _typeGlaire = obs.glaire!.typeGlaire;
      _notesGlaireController.text = obs.glaire!.notes ?? '';
    }

    if (obs.testsLh.isNotEmpty) {
      _enableLh = true;
      final first = obs.testsLh.first;
      _resultatLh = first.resultat;
      _valeurMUiMl = first.valeurMUiMl;
      _notesLhController.text = first.notes ?? '';
    }

    for (final s in obs.symptomes) {
      final code = s.typeSymptome?.code ?? s.typeSymptomeId;
      _selectedSymptoms[code] = s.intensite;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesTempController.dispose();
    _notesGlaireController.dispose();
    _notesLhController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    bool isOnline = true;
    try {
      isOnline = BlocProvider.of<NetworkCubit>(context, listen: false).state.isOnline;
    } catch (_) {}
    if (!isOnline) {
      AppFeedback.showError(
        context,
        error: const ApiException(
          title: 'Mode hors ligne',
          userFriendlyMessage:
              'Une connexion Internet est requise pour synchroniser vos biomarqueurs et observations.',
          actionSuggestion: 'Vérifiez votre connexion au réseau puis réessayez.',
          errorCode: 'NETWORK_OFFLINE',
        ),
      );
      return;
    }

    // Validation ergonomique des bornes de température
    if (_enableTemp && (_temperature < 35.0 || _temperature > 41.5)) {
      AppFeedback.showWarning(
        context,
        title: 'Température inhabituelle',
        message: 'La température saisie (${_temperature.toStringAsFixed(2)} °C) sort des bornes physiologiques courantes. Vérifiez votre mesure.',
      );
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);

    TemperatureBasaleModel? tempModel;
    if (_enableTemp) {
      tempModel = TemperatureBasaleModel(
        date: dateStr,
        temperatureCelsius: double.parse(_temperature.toStringAsFixed(2)),
        heurePrise: _heurePrise,
        estPerturbee: _estPerturbee,
        facteurPerturbateur: _estPerturbee ? _facteurPerturbateur : null,
        notes: _notesTempController.text.trim().isNotEmpty
            ? _notesTempController.text.trim()
            : null,
      );
    }

    GlaireCervicaleModel? glaireModel;
    if (_enableGlaire) {
      glaireModel = GlaireCervicaleModel(
        date: dateStr,
        typeGlaire: _typeGlaire,
        notes: _notesGlaireController.text.trim().isNotEmpty
            ? _notesGlaireController.text.trim()
            : null,
      );
    }

    TestOvulationModel? lhModel;
    if (_enableLh) {
      lhModel = TestOvulationModel(
        date: dateStr,
        resultat: _resultatLh,
        valeurMUiMl: _valeurMUiMl,
        notes: _notesLhController.text.trim().isNotEmpty
            ? _notesLhController.text.trim()
            : null,
      );
    }

    final symptomsList = _selectedSymptoms.entries.map((e) {
      return ObservationSymptomeModel(
        date: dateStr,
        typeSymptomeId: e.key,
        intensite: e.value,
      );
    }).toList();

    final req = SaveDayObservationRequest(
      date: dateStr,
      temperature: tempModel,
      glaire: glaireModel,
      testLh: lhModel,
      symptomes: symptomsList,
    );

    setState(() => _isSaving = true);
    try {
      await ServiceLocator.observationRepository.saveDayObservation(req);
      if (!mounted) return;
      context.read<ObservationBloc>().add(LoadDayObservationsEvent(dateStr));
      context.read<FertilityBloc>().add(const LoadCurrentFertilityEvent());
      context.read<FertilityBloc>().add(LoadMonthCalendarEvent(
            year: widget.date.year,
            month: widget.date.month,
          ));
      context.read<CycleBloc>().add(LoadCyclesEvent());
      Navigator.of(context).pop(true);
      AppFeedback.showSuccess(
        context,
        title: 'Biomarqueurs enregistrés ✨',
        message: 'Vos observations et biomarqueurs ont été enregistrés avec succès.',
      );
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        error: e,
        customTitle: 'Enregistrement impossible',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate;
    try {
      formattedDate =
          DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(widget.date);
    } catch (_) {
      formattedDate = DateFormat('yyyy-MM-dd').format(widget.date);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final hasChanges = _enableTemp ||
            _enableGlaire ||
            _enableLh ||
            _selectedSymptoms.isNotEmpty ||
            _notesTempController.text.trim().isNotEmpty ||
            _notesGlaireController.text.trim().isNotEmpty ||
            _notesLhController.text.trim().isNotEmpty;

        if (hasChanges) {
          final discard = await AppFeedback.showConfirmationDialog(
            context,
            title: 'Abandonner la saisie ?',
            message: 'Les biomarqueurs et symptômes renseignés ne seront pas enregistrés.',
            confirmLabel: 'Abandonner',
            cancelLabel: 'Continuer la saisie',
            isDestructive: true,
            icon: Icons.close_rounded,
          );
          if (discard && context.mounted) {
            Navigator.pop(context);
          }
        } else {
          Navigator.pop(context);
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Poignée supérieure
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),

            // En-tête
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Observations & Biomarqueurs',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Onglets (T°, Glaire, Test LH, Symptômes)
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textMuted,
              indicatorColor: AppTheme.primary,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(icon: Icon(Icons.thermostat_rounded, size: 20), text: 'Température'),
                Tab(icon: Icon(Icons.water_drop_rounded, size: 20), text: 'Glaire'),
                Tab(icon: Icon(Icons.biotech_rounded, size: 20), text: 'Test LH'),
                Tab(icon: Icon(Icons.sentiment_satisfied_rounded, size: 20), text: 'Symptômes'),
              ],
            ),

            // Corps des onglets
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTemperatureTab(),
                  _buildGlaireTab(),
                  _buildLhTab(),
                  _buildSymptomsTab(),
                ],
              ),
            ),

            // Bouton de validation
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.borderLight, width: 1)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  icon: _isSaving
                      ? const SizedBox.shrink()
                      : const Icon(Icons.check_rounded, color: Colors.white),
                  label: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Enregistrer les observations',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. Onglet Température ---
  Widget _buildTemperatureTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            title: const Text('Enregistrer la température basale', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Mesurée au réveil avant tout lever'),
            value: _enableTemp,
            activeThumbColor: AppTheme.primary,
            onChanged: (val) => setState(() => _enableTemp = val),
          ),
          if (_enableTemp) ...[
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_temperature.toStringAsFixed(2)} °C',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Slider(
              value: _temperature,
              min: 35.50,
              max: 38.50,
              divisions: 60,
              activeColor: AppTheme.primary,
              onChanged: (val) => setState(() => _temperature = val),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Température potentiellement perturbée'),
              subtitle: const Text('Mauvaise nuit, alcool, médicament ou fièvre'),
              value: _estPerturbee,
              activeColor: Colors.orange,
              onChanged: (v) => setState(() => _estPerturbee = v ?? false),
            ),
            if (_estPerturbee) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _facteurPerturbateur,
                decoration: InputDecoration(
                  labelText: 'Facteur perturbateur',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _perturbateurs
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) => setState(() => _facteurPerturbateur = val),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // --- 2. Onglet Glaire Cervicale ---
  Widget _buildGlaireTab() {
    final glaireOptions = [
      GlaireType.sec,
      GlaireType.collant,
      GlaireType.cremeux,
      GlaireType.filantBlancOeuf,
      GlaireType.aqueux,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            title: const Text('Observer la glaire cervicale', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Indicateur clé de la période fertile'),
            value: _enableGlaire,
            activeThumbColor: AppTheme.primary,
            onChanged: (val) => setState(() => _enableGlaire = val),
          ),
          if (_enableGlaire) ...[
            const SizedBox(height: 16),
            ...glaireOptions.map((type) {
              final isSelected = _typeGlaire == type;
              final isFertile = GlaireType.isFertile(type);

              return GestureDetector(
                onTap: () => setState(() => _typeGlaire = type),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryLight : Colors.white,
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.borderLight,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isFertile ? Icons.star_rounded : Icons.water_drop_outlined,
                        color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  GlaireType.getLabel(type),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? AppTheme.primary : AppTheme.textDark,
                                    fontSize: 14,
                                  ),
                                ),
                                if (isFertile) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Fertile',
                                      style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              GlaireType.getDescription(type),
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: AppTheme.primary),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // --- 3. Onglet Test LH ---
  Widget _buildLhTab() {
    final results = [
      LhResult.negatif,
      LhResult.faible,
      LhResult.positif,
      LhResult.pic,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            title: const Text("Test d'ovulation urinaire (LH)", style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Détecte le pic précurseur de l’ovulation (24-36h)'),
            value: _enableLh,
            activeThumbColor: AppTheme.primary,
            onChanged: (val) => setState(() => _enableLh = val),
          ),
          if (_enableLh) ...[
            const SizedBox(height: 16),
            const Text(
              'Résultat du test :',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: results.map((res) {
                final isSelected = _resultatLh == res;
                final isPeak = LhResult.isPeak(res);

                return ChoiceChip(
                  label: Text(LhResult.getLabel(res)),
                  selected: isSelected,
                  selectedColor: isPeak ? Colors.purple.shade100 : AppTheme.primaryLight,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? (isPeak ? Colors.purple.shade800 : AppTheme.primary)
                        : AppTheme.textDark,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _resultatLh = res);
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // --- 4. Onglet Symptômes ---
  Widget _buildSymptomsTab() {
    final catalog = widget.catalog.isNotEmpty
        ? widget.catalog
        : [
            const TypeSymptomeModel(id: '1', code: 'tension_mammaire', nom: 'Tension mammaire', categorie: 'physique'),
            const TypeSymptomeModel(id: '2', code: 'douleur_ovulatoire', nom: 'Douleur ovulation', categorie: 'physique'),
            const TypeSymptomeModel(id: '3', code: 'crampes_pelviennes', nom: 'Crampes pelviennes', categorie: 'physique'),
            const TypeSymptomeModel(id: '4', code: 'maux_de_tete', nom: 'Maux de tête', categorie: 'physique'),
            const TypeSymptomeModel(id: '5', code: 'fatigue', nom: 'Fatigue', categorie: 'physique'),
            const TypeSymptomeModel(id: '6', code: 'sautes_humeur', nom: "Sautes d'humeur", categorie: 'emotionnel'),
            const TypeSymptomeModel(id: '7', code: 'anxiete', nom: 'Anxiété / Irritabilité', categorie: 'emotionnel'),
            const TypeSymptomeModel(id: '8', code: 'energie_elevee', nom: "Regain d'énergie", categorie: 'emotionnel'),
            const TypeSymptomeModel(id: '9', code: 'ballonnements', nom: 'Ballonnements', categorie: 'digestif'),
            const TypeSymptomeModel(id: '10', code: 'acne', nom: "Poussée d'acné", categorie: 'cutane'),
          ];

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: catalog.length,
      itemBuilder: (context, index) {
        final sym = catalog[index];
        final isSelected = _selectedSymptoms.containsKey(sym.code);
        final intensity = _selectedSymptoms[sym.code] ?? 3;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: isSelected ? 1 : 0,
          color: isSelected ? AppTheme.primaryLight.withValues(alpha: 0.5) : Colors.grey.shade50,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  activeColor: AppTheme.primary,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedSymptoms[sym.code] = 3;
                      } else {
                        _selectedSymptoms.remove(sym.code);
                      }
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    sym.nom,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppTheme.primary : AppTheme.textDark,
                    ),
                  ),
                ),
                if (isSelected) ...[
                  Text(
                    'Intensité : $intensity/5',
                    style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    width: 100,
                    child: Slider(
                      value: intensity.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      activeColor: AppTheme.primary,
                      onChanged: (v) => setState(() => _selectedSymptoms[sym.code] = v.toInt()),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
