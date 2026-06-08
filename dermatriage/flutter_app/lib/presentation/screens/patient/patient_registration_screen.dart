import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/colors.dart';
import '../../../data/models/patient.dart';
import '../../providers/patient_provider.dart';

/// Collects patient demographics and consent before image capture.
class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({super.key});

  @override
  State<PatientRegistrationScreen> createState() =>
      _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState
    extends State<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();

  // Age range label -> representative age stored as approximateAge.
  static const Map<String, int> _ageRanges = <String, int>{
    '0-5': 3,
    '6-12': 9,
    '13-17': 15,
    '18-30': 24,
    '31-50': 40,
    '51-70': 60,
    '70+': 75,
  };

  // Fitzpatrick type descriptions (index 0 -> type 1).
  static const List<String> _fitzpatrickDescriptions = <String>[
    'Type I — Very fair skin; always burns, never tans.',
    'Type II — Fair skin; usually burns, tans minimally.',
    'Type III — Medium skin; sometimes burns, tans uniformly.',
    'Type IV — Olive skin; rarely burns, tans easily.',
    'Type V — Brown skin; very rarely burns, tans darkly.',
    'Type VI — Deeply pigmented skin; never burns.',
  ];

  String? _sex;
  String? _ageRange;
  int? _fitzpatrickType; // 1–6
  bool _consentGiven = false;
  bool _photoConsent = false;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  bool get _canContinue => _consentGiven && _photoConsent;

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;

    if (_sex == null || _ageRange == null || _fitzpatrickType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete sex, age range and skin type.'),
        ),
      );
      return;
    }

    final patient = Patient(
      id: const Uuid().v4(),
      approximateAge: _ageRanges[_ageRange],
      sex: _sex!,
      location: _locationController.text.trim(),
      fitzpatrickType: _fitzpatrickType!,
      consentGiven: _consentGiven,
      photoConsent: _photoConsent,
      createdAt: DateTime.now(),
    );

    context.read<PatientProvider>().registerPatient(patient);
    context.go('/camera');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Patient')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _sectionLabel(context, 'Sex'),
            Wrap(
              spacing: 8,
              children: <String>['M', 'F', 'Other'].map((String option) {
                return ChoiceChip(
                  label: Text(option),
                  selected: _sex == option,
                  onSelected: (_) => setState(() => _sex = option),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            _sectionLabel(context, 'Age range'),
            DropdownButtonFormField<String>(
              initialValue: _ageRange,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select age range',
              ),
              items: _ageRanges.keys
                  .map((String r) =>
                      DropdownMenuItem<String>(value: r, child: Text(r)))
                  .toList(),
              onChanged: (String? value) => setState(() => _ageRange = value),
            ),
            const SizedBox(height: 20),

            _sectionLabel(context, 'Location'),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Village / clinic / district',
              ),
              validator: (String? value) =>
                  (value == null || value.trim().isEmpty)
                      ? 'Location is required'
                      : null,
            ),
            const SizedBox(height: 20),

            _sectionLabel(context, 'Fitzpatrick skin type'),
            _buildFitzpatrickSelector(),
            const SizedBox(height: 8),
            Text(
              _fitzpatrickType == null
                  ? 'Tap a circle to select the closest skin tone.'
                  : _fitzpatrickDescriptions[_fitzpatrickType! - 1],
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _consentGiven,
              onChanged: (bool? v) =>
                  setState(() => _consentGiven = v ?? false),
              title: const Text(
                'I confirm the patient has given verbal and written consent '
                'for this assessment and photo.',
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _photoConsent,
              onChanged: (bool? v) =>
                  setState(() => _photoConsent = v ?? false),
              title: const Text(
                'The patient consents to a photo being taken and stored on '
                'this device for the assessment.',
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Continue to Capture'),
              onPressed: _canContinue ? _onContinue : null,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildFitzpatrickSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List<Widget>.generate(6, (int i) {
        final int type = i + 1;
        final bool selected = _fitzpatrickType == type;
        return GestureDetector(
          onTap: () => setState(() => _fitzpatrickType = type),
          child: Column(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.fitzpatrickColors[i],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.divider,
                    width: selected ? 3 : 1,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 20, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 4),
              Text('$type', style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }),
    );
  }
}
