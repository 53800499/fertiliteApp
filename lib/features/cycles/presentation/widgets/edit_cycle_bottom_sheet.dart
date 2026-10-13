import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/cycle_models.dart';
import '../bloc/cycle_bloc.dart';
import '../bloc/cycle_event.dart';

class EditCycleBottomSheet extends StatefulWidget {
  final CycleModel cycle;

  const EditCycleBottomSheet({super.key, required this.cycle});

  static Future<void> show(BuildContext context, {required CycleModel cycle}) {
    final bloc = context.read<CycleBloc>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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

  void _saveChanges() {
    final request = UpdateCycleRequestModel(
      dateDebut: _formatDate(_dateDebut),
      dateFin: _dateFin != null ? _formatDate(_dateFin!) : null,
      statut: _statut,
    );

    context.read<CycleBloc>().add(
          UpdateCycleEvent(cycleId: widget.cycle.id, request: request),
        );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cycle mis à jour avec succès'),
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Supprimer ce cycle ?', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Text(
          'Cette action supprimera définitivement le cycle et l\'ensemble des flux enregistrés pour cette période.',
          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // fermer dialog
              context.read<CycleBloc>().add(DeleteCycleEvent(widget.cycle.id));
              Navigator.pop(context); // fermer bottom sheet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cycle supprimé'),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            onPressed: _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Enregistrer les modifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
