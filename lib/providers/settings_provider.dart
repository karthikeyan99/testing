import 'package:flutter/foundation.dart';

import '../models/business_profile.dart';
import '../repositories/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repo;

  SettingsProvider({SettingsRepository? repository})
      : _repo = repository ?? SettingsRepository();

  BusinessProfile _profile = const BusinessProfile();
  bool _loading = false;

  BusinessProfile get profile => _profile;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _profile = await _repo.getProfile();
    _loading = false;
    notifyListeners();
  }

  Future<void> save(BusinessProfile profile) async {
    await _repo.saveProfile(profile);
    _profile = profile;
    notifyListeners();
  }
}
