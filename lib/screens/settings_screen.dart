import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/business_profile.dart';
import '../providers/settings_provider.dart';
import '../utils/indian_states.dart';

/// Business profile: GSTIN, name, home state and default GST rate. The home
/// state drives automatic CGST/SGST-vs-IGST selection on new sales.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _gstin = TextEditingController();
  String? _homeState;
  double _defaultGst = 18;
  bool _initialised = false;

  @override
  void dispose() {
    _name.dispose();
    _gstin.dispose();
    super.dispose();
  }

  void _hydrate(BusinessProfile p) {
    if (_initialised) return;
    _name.text = p.businessName;
    _gstin.text = p.gstin;
    _homeState = p.homeState.isEmpty ? null : p.homeState;
    _defaultGst = p.defaultGstRate;
    _initialised = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = BusinessProfile(
      businessName: _name.text.trim(),
      gstin: _gstin.text.trim(),
      homeState: _homeState ?? '',
      defaultGstRate: _defaultGst,
    );
    await context.read<SettingsProvider>().save(profile);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Settings saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    _hydrate(settings.profile);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Business profile',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Business name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gstin,
              textCapitalization: TextCapitalization.characters,
              maxLength: 15,
              decoration: const InputDecoration(
                labelText: 'GSTIN',
                helperText: '15-character GST identification number',
              ),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return null; // optional
                if (s.length != 15) return 'GSTIN must be 15 characters';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _homeState,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Home state (place of supply)',
                helperText:
                    'Sales to other states use IGST; same-state uses CGST+SGST',
              ),
              items: [
                for (final s in kIndianStates)
                  DropdownMenuItem(value: s, child: Text(s)),
              ],
              onChanged: (v) => setState(() => _homeState = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<double>(
              value: _defaultGst,
              decoration:
                  const InputDecoration(labelText: 'Default GST rate'),
              items: const <double>[0, 3, 5, 12, 18, 28]
                  .map((r) => DropdownMenuItem(
                      value: r, child: Text('${r.toStringAsFixed(0)}%')))
                  .toList(),
              onChanged: (v) => setState(() => _defaultGst = v ?? 18),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save settings'),
            ),
            const SizedBox(height: 24),
            const Card(
              color: Color(0xFFE3F2FD),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.sync, color: Color(0xFF1565C0)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Live Amazon SP-API / Flipkart auto-sync is planned. '
                        'For now, use CSV import from each seller portal.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
