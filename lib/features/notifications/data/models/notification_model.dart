import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationItemModel {
  final String id;
  final String type;
  final String canal;
  final String statut;
  final String titre;
  final String message;
  final Map<String, dynamic>? donneesSupplementaires;
  final DateTime datePlanifiee;
  final DateTime? dateEnvoi;
  final DateTime? dateLecture;
  final DateTime dateCreation;

  const NotificationItemModel({
    required this.id,
    required this.type,
    required this.canal,
    required this.statut,
    required this.titre,
    required this.message,
    this.donneesSupplementaires,
    required this.datePlanifiee,
    this.dateEnvoi,
    this.dateLecture,
    required this.dateCreation,
  });

  bool get isRead => statut.toLowerCase() == 'lue' || dateLecture != null;

  String get categoryLabel {
    switch (type.toLowerCase()) {
      case 'fenetre_fertile':
        return 'Fertilité';
      case 'regles_prevues':
        return 'Cycle & Règles';
      case 'rappel_saisie':
        return 'Rappel Quotidien';
      case 'maj_prediction':
        return 'Algorithme';
      default:
        return 'Information';
    }
  }

  IconData get iconData {
    switch (type.toLowerCase()) {
      case 'fenetre_fertile':
        return Icons.auto_awesome_rounded;
      case 'regles_prevues':
        return Icons.water_drop_rounded;
      case 'rappel_saisie':
        return Icons.edit_calendar_rounded;
      case 'maj_prediction':
        return Icons.psychology_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color get accentColor {
    switch (type.toLowerCase()) {
      case 'fenetre_fertile':
        return AppTheme.fertileHighColor;
      case 'regles_prevues':
        return AppTheme.periodColor;
      case 'rappel_saisie':
        return AppTheme.primary;
      case 'maj_prediction':
        return Colors.teal;
      default:
        return AppTheme.primary;
    }
  }

  String get timeAgoFormatted {
    final now = DateTime.now();
    final ref = dateEnvoi ?? datePlanifiee;
    final diff = now.difference(ref);

    if (diff.inMinutes < 1) {
      return "À l'instant";
    } else if (diff.inMinutes < 60) {
      return "Il y a ${diff.inMinutes} min";
    } else if (diff.inHours < 24) {
      return "Il y a ${diff.inHours} h";
    } else if (diff.inDays == 1) {
      return "Hier";
    } else if (diff.inDays < 7) {
      return "Il y a ${diff.inDays} jours";
    } else {
      return "${ref.day.toString().padLeft(2, '0')}/${ref.month.toString().padLeft(2, '0')}/${ref.year}";
    }
  }

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val == null) return fallback;
      if (val is String) {
        return DateTime.tryParse(val) ?? fallback;
      }
      return fallback;
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is String) {
        return DateTime.tryParse(val);
      }
      return null;
    }

    final now = DateTime.now();

    return NotificationItemModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'information_generale',
      canal: json['canal']?.toString() ?? 'push',
      statut: json['statut']?.toString() ?? 'envoyee',
      titre: json['titre']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      donneesSupplementaires: json['donneesSupplementaires'] is Map<String, dynamic>
          ? json['donneesSupplementaires'] as Map<String, dynamic>
          : json['donnees_supplementaires'] is Map<String, dynamic>
              ? json['donnees_supplementaires'] as Map<String, dynamic>
              : null,
      datePlanifiee: parseDate(
        json['datePlanifiee'] ?? json['date_planifiee'],
        now,
      ),
      dateEnvoi: parseNullableDate(json['dateEnvoi'] ?? json['date_envoi']),
      dateLecture: parseNullableDate(json['dateLecture'] ?? json['date_lecture']),
      dateCreation: parseDate(
        json['dateCreation'] ?? json['date_creation'],
        now,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'canal': canal,
        'statut': statut,
        'titre': titre,
        'message': message,
        'donneesSupplementaires': donneesSupplementaires,
        'datePlanifiee': datePlanifiee.toIso8601String(),
        'dateEnvoi': dateEnvoi?.toIso8601String(),
        'dateLecture': dateLecture?.toIso8601String(),
        'dateCreation': dateCreation.toIso8601String(),
      };
}
