import 'package:flutter/foundation.dart';

import '../../data/datasources/local/encounter_dao.dart';
import '../../data/datasources/local/patient_dao.dart';
import '../../data/models/encounter.dart';
import '../../data/models/patient.dart';

/// Exposes the encounter history (most recent first).
class HistoryProvider extends ChangeNotifier {
  final EncounterDao _dao;
  final PatientDao _patientDao;

  HistoryProvider({EncounterDao? dao, PatientDao? patientDao})
      : _dao = dao ?? EncounterDao(),
        _patientDao = patientDao ?? PatientDao();

  List<Encounter> _encounters = <Encounter>[];
  Map<String, Patient> _patientsById = <String, Patient>{};

  List<Encounter> get encounters => _encounters;

  /// Look up the patient for an encounter's [Encounter.patientId], or null if
  /// the patient record is missing (e.g. deleted, or a pre-migration row).
  Patient? patientFor(String patientId) => _patientsById[patientId];

  /// Load all encounters (and the patients they belong to) from the database.
  Future<void> loadEncounters() async {
    _encounters = await _dao.getAllEncounters();
    final List<Patient> patients = await _patientDao.getAllPatients();
    _patientsById = <String, Patient>{
      for (final Patient p in patients) p.id: p,
    };
    notifyListeners();
  }

  /// Persist an encounter and refresh the list.
  Future<void> saveEncounter(Encounter encounter) async {
    await _dao.insertEncounter(encounter);
    await loadEncounters();
  }
}
