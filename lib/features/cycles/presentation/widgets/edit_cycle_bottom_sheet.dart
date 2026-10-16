import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/network_cubit.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/di/service_locator.dart';
import '../../data/models/cycle_models.dart';
import '../bloc/cycle_bloc.dart';
import '../bloc/cycle_event.dart';

class EditCycleBottomSheet extends StatefulWidget {
  final CycleModel cycle;

  const EditCycleBottomSheet({super.key, required this.cycle});

  static Future<dynamic> show(
    BuildContext context, {
    required CycleModel cycle,
    bool useRootNavigator = true,
  }) {
    CycleBloc bloc;
    try {
      bloc = context.read<CycleBloc>();
    } catch (_) {
      bloc = ServiceLocator.cycleBloc;
    }
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: useRootNavigator,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: EditCycleBottomSheet(cycle: cycle),
      ),
    );
  }

  @override
  State<EditCycleBottomSheet> createState() => _EditCycleBottomSheetState();
}

class _EditCycleBottomSheetState extends State<EditCycleBottomSheet> {
  late DateTime _dateDebut;
  DateTime? _dateFin;
  late String _statut;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    try {
      _dateDebut = DateTime.parse(widget.cycle.dateDebut);
    } catch (_) {
      _dateDebut = DateTime.now();
    }

    if (widget.cycle.dateFin != null) {
      try {
        _dateFin = DateTime.parse(widget.cycle.dateFin!);
      } catch (_) {
        _dateFin = null;
      }
    }
    _statut = widget.cycle.statut;
  }

  String _formatDate(DateTime d) {
    return "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateDebut,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateDebut = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFin ?? _dateDebut.add(const Duration(days: 28)),
      firstDate: _dateDebut,
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateFin = picked;
        _statut = 'termine';
      });
    }
  }

  Future<void> _saveChanges() async {
    bool isOnline = true;
    try {
      isOnline = BlocProvider.of<NetworkCubit>(context, listen: false).state.isOnline;
    } catch (_) {}
    if (!isOnline) {
      AppFeedback.showError(
        context,
        error: const ApiException(
          title: 'Mode hors ligne',
          message: 'La modification du cycle nécessite une connexion active pour recalculer vos biomarqueurs.',
          statusCode: 0,
        ),
      );
      return;
    }

    // Validation ergonomique de cohérence temporelle
    if (_dateFin != null && _dateFin!.isBefore(_dateDebut)) {
      AppFeedback.showWarning(
        context,
        title: 'Incohérence des dates',
        message: 'La date de fin ne peut pas être antérieure à la date de début du cycle (${_formatDate(_dateDebut)}).',
      );
      return;
    }

    final hasChanges = _formatDate(_dateDebut) != widget.cycle.dateDebut ||
        (_dateFin != null ? _formatDate(_dateFin!) : null) != widget.cycle.dateFin ||
        _statut != widget.cycle.statut;

    if (hasChanges) {
      final confirmed = await AppFeedback.showConfirmationDialog(
        context,
        title: 'Enregistrer les modifications ?',
        message: 'L\'ajustement de ces dates recalculera automatiquement la durée de votre cycle et les prédictions d\'ovulation.',
        confirmLabel: 'Enregistrer',
        cancelLabel: 'Annuler',
        icon: Icons.edit_calendar_rounded,
        confirmColor: AppTheme.primary,
      );
      if (!confirmed || !mounted) return;
    }

    final request = UpdateCycleRequestModel(
      dateDebut: _formatDate(_dateDebut),
      dateFin: _dateFin != null ? _formatDate(_dateFin!) : null,
      statut: _statut,
    );

    setState(() => _isSaving = true);
    try {
      await ServiceLocator.cycleRepository.updateCycle(widget.cycle.id, request);
      if (!mounted) return;
      context.read<CycleBloc>().add(LoadCyclesEvent());
      Navigator.pop(context, 'updated');
      AppFeedback.showSuccess(
        context,
        title: 'Cycle mis à jour ✨',
        message: 'Les dates et le statut du cycle ont été enregistrés avec succès.',
      );
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        error: e,
        customTitle: 'Modification impossible',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    bool isOnline = true;
    try {
      isOnline = BlocProvider.of<NetworkCubit>(context, listen: false).state.isOnline;
    } catch (_) {}
    if (!isOnline) {
      AppFeedback.showError(
        context,
        error: const ApiException(
          title: 'Mode hors ligne',
          message: 'La suppression du cycle nécessite une connexion active.',
          statusCode: 0,
        ),
      );
      return;
    }

    final confirmed = await AppFeedback.showConfirmationDialog(
      context,
      title: 'Supprimer ce cycle ?',
      message: 'Cette action est irréversible. Le cycle ainsi que l\'ensemble des flux menstruels enregistrés pour cette période seront définitivement effacés.',
      confirmLabel: 'Supprimer définitivement',
      cancelLabel: 'Conserver',
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
    );

    if (!confirmed || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await ServiceLocator.cycleRepository.deleteCycle(widget.cycle.id);
      if (!mounted) return;
      context.read<CycleBloc>().add(LoadCyclesEvent());
      Navigator.pop(context, 'deleted');
      AppFeedback.showSuccess(
        context,
        title: 'Cycle supprimé',
        message: 'Le cycle a été retiré de votre carnet.',
      );
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        error: e,
        customTitle: 'Suppression impossible',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final hasChanges = _formatDate(_dateDebut) != widget.cycle.dateDebut ||
            (_dateFin != null ? _formatDate(_dateFin!) : null) != widget.cycle.dateFin ||
            _statut != widget.cycle.statut;

        if (hasChanges) {
          final discard = await AppFeedback.showConfirmationDialog(
            context,
            title: 'Abandonner les modifications ?',
            message: 'Les dates ou le statut modifiés ne seront pas conservés.',
            confirmLabel: 'Abandonner',
            cancelLabel: 'Continuer l\'édition',
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // En-tête
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Modifier le cycle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: _confirmDelete,
                  tooltip: 'Supprimer ce cycle',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date de début
            const Text('Date de début (J1 des règles) :', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickStartDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderLight),
                  borderRadius: BorderRadius.circular(14),
                  color: AppTheme.background,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDate(_dateDebut), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date de fin
            const Text('Date de fin de cycle :', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickEndDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderLight),
                  borderRadius: BorderRadius.circular(14),
                  color: AppTheme.background,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dateFin != null ? _formatDate(_dateFin!) : 'En cours (non terminée)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _dateFin != null ? AppTheme.textDark : AppTheme.textMuted,
                      ),
                    ),
                    const Icon(Icons.event_available_rounded, size: 18, color: AppTheme.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Statut du cycle
            const Text('Statut du cycle :', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('En cours'),
                    selected: _statut == 'en_cours',
                    selectedColor: Colors.teal.withValues(alpha: 0.2),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _statut = 'en_cours';
                          _dateFin = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Terminé'),
                    selected: _statut == 'termine',
                    selectedColor: AppTheme.primaryLight,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _statut = 'termine';
                          _dateFin ??= _dateDebut.add(const Duration(days: 28));
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bouton enregistrer
            ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Enregistrer les modifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
