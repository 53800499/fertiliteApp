import 'dart:async';
import 'dart:convert';
import '../../../../core/security/secure_storage_helper.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_data_source.dart';
import '../models/user_profile_model.dart';

class UserRepositoryImpl implements IUserRepository {
  final IUserRemoteDataSource remoteDataSource;
  final SecureStorageHelper? storage;

  FullUserProfileModel? _currentProfile;
  final _profileController = StreamController<FullUserProfileModel>.broadcast();

  UserRepositoryImpl({
    required this.remoteDataSource,
    this.storage,
  }) {
    // Initialisation instantanée depuis le cache si disponible
    getCachedProfile();
  }

  @override
  FullUserProfileModel? get currentProfile => _currentProfile;

  @override
  Stream<FullUserProfileModel> get profileStream => _profileController.stream;

  @override
  Future<FullUserProfileModel?> getCachedProfile() async {
    if (storage == null) return _currentProfile;
    try {
      final cached = await storage!.getCache('cached_user_profile');
      if (cached != null && cached.isNotEmpty) {
        final parsed = FullUserProfileModel.fromJson(jsonDecode(cached) as Map<String, dynamic>);
        _currentProfile = parsed;
        _profileController.add(parsed);
        return parsed;
      }
    } catch (_) {}
    return _currentProfile;
  }

  @override
  Future<FullUserProfileModel> getProfile() async {
    try {
      final profile = await remoteDataSource.getProfile();
      _currentProfile = profile;
      if (storage != null) {
        await storage!.saveCache('cached_user_profile', jsonEncode(profile.toJson()));
      }
      _profileController.add(profile);
      return profile;
    } catch (e) {
      if (storage != null) {
        final cached = await storage!.getCache('cached_user_profile');
        if (cached != null && cached.isNotEmpty) {
          final parsed = FullUserProfileModel.fromJson(jsonDecode(cached) as Map<String, dynamic>);
          _currentProfile = parsed;
          _profileController.add(parsed);
          return parsed;
        }
      }
      if (_currentProfile != null) return _currentProfile!;
      rethrow;
    }
  }

  @override
  Future<FullUserProfileModel> updateProfile(UpdateProfileRequestModel request) async {
    // 1. Mise à jour optimiste immédiate en mémoire et dans le cache local
    if (_currentProfile != null) {
      final optimistic = FullUserProfileModel(
        id: _currentProfile!.id,
        email: _currentProfile!.email,
        role: _currentProfile!.role,
        dateNaissance: _currentProfile!.dateNaissance,
        languePreferee: _currentProfile!.languePreferee,
        fuseauHoraire: _currentProfile!.fuseauHoraire,
        parametresConfidentialite:
            request.parametresConfidentialite ?? _currentProfile!.parametresConfidentialite,
        profil: UserProfileDetailModel(
          prenom: request.prenom ?? _currentProfile!.profil.prenom,
          dureeMoyenneCycle: request.dureeMoyenneCycle ?? _currentProfile!.profil.dureeMoyenneCycle,
          dureeMoyenneRegles: request.dureeMoyenneRegles ?? _currentProfile!.profil.dureeMoyenneRegles,
          objectifPrincipal: request.objectifPrincipal ?? _currentProfile!.profil.objectifPrincipal,
          irregulariteDeclaree:
              request.irregulariteDeclaree ?? _currentProfile!.profil.irregulariteDeclaree,
          dateDernieresReglesConnues:
              request.dateDernieresReglesConnues ?? _currentProfile!.profil.dateDernieresReglesConnues,
        ),
      );
      _currentProfile = optimistic;
      if (storage != null) {
        await storage!.saveCache('cached_user_profile', jsonEncode(optimistic.toJson()));
      }
      _profileController.add(optimistic);
    }

    // 2. Synchronisation avec le backend distant
    try {
      final updated = await remoteDataSource.updateProfile(request);
      _currentProfile = updated;
      if (storage != null) {
        await storage!.saveCache('cached_user_profile', jsonEncode(updated.toJson()));
      }
      _profileController.add(updated);
      return updated;
    } catch (e) {
      // Si hors-ligne ou erreur réseau, la mise à jour locale persiste
      if (_currentProfile != null) {
        return _currentProfile!;
      }
      rethrow;
    }
  }

  @override
  Future<void> requestAccountDeletion({required String password, String? reason}) {
    return remoteDataSource.requestAccountDeletion(password: password, reason: reason);
  }
}
