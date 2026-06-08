import 'package:flutter/foundation.dart';

import '../../data/datasources/local/patient_dao.dart';
import '../../data/models/patient.dart';

/// Holds the active patient and the list of recently registered patients.
class PatientProvider extends ChangeNotifier {
  final PatientDao _dao;

  PatientProvider({PatientDao? dao}) : _dao = dao ?? PatientDao();

  Patient? _currentPatient;
  List<Patient> _recentPatients = <Patient>[];

  Patient? get currentPatient => _currentPatient;
  List<Patient> get recentPatients => _recentPatients;

  /// Persist a new patient and make it the active one.
  Future<void> registerPatient(Patient patient) async {
    await _dao.insertPatient(patient);
    _currentPatient = patient;
    await loadPatients();
    notifyListeners();
  }

  /// Refresh the recent-patients list from the database.
  Future<void> loadPatients() async {
    _recentPatients = await _dao.getAllPatients();
    notifyListeners();
  }

  /// Clear the active patient (e.g. when starting a new session).
  void clearCurrent() {
    _currentPatient = null;
    notifyListeners();
  }
}
