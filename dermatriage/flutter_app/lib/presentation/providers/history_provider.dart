import 'package:flutter/foundation.dart';

import '../../data/datasources/local/encounter_dao.dart';
import '../../data/models/encounter.dart';

/// Exposes the encounter history (most recent first).
class HistoryProvider extends ChangeNotifier {
  final EncounterDao _dao;

  HistoryProvider({EncounterDao? dao}) : _dao = dao ?? EncounterDao();

  List<Encounter> _encounters = <Encounter>[];

  List<Encounter> get encounters => _encounters;

  /// Load all encounters from the database.
  Future<void> loadEncounters() async {
    _encounters = await _dao.getAllEncounters();
    notifyListeners();
  }

  /// Persist an encounter and refresh the list.
  Future<void> saveEncounter(Encounter encounter) async {
    await _dao.insertEncounter(encounter);
    await loadEncounters();
  }
}
