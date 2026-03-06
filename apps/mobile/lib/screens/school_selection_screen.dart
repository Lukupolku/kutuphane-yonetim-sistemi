import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/school.dart';
import '../providers/school_provider.dart';

class SchoolSelectionScreen extends StatefulWidget {
  const SchoolSelectionScreen({super.key});

  @override
  State<SchoolSelectionScreen> createState() => _SchoolSelectionScreenState();
}

class _SchoolSelectionScreenState extends State<SchoolSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SchoolProvider>().loadProvinces();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Okul Seçimi'),
      ),
      body: Consumer<SchoolProvider>(
        builder: (context, provider, _) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Image.asset(
                  'assets/images/meb-logo-text.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                Text(
                  'Okulunuzu Seçin',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 32),
                // Province dropdown
                DropdownButtonFormField<String>(
                  value: provider.selectedProvince,
                  decoration: const InputDecoration(
                    labelText: 'İl Seçin',
                    border: OutlineInputBorder(),
                  ),
                  items: provider.provinces
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      provider.selectProvince(value);
                    }
                  },
                ),
                // District dropdown
                if (provider.districts.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: provider.selectedDistrict,
                    decoration: const InputDecoration(
                      labelText: 'İlçe Seçin',
                      border: OutlineInputBorder(),
                    ),
                    items: provider.districts
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        provider.selectDistrict(value);
                      }
                    },
                  ),
                ],
                // School dropdown
                if (provider.schools.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<School>(
                    value: provider.selectedSchool,
                    decoration: const InputDecoration(
                      labelText: 'Okul Seçin',
                      border: OutlineInputBorder(),
                    ),
                    items: provider.schools
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        provider.selectSchool(value);
                      }
                    },
                  ),
                ],
                const Spacer(),
                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.hasSelectedSchool
                        ? () async {
                            await provider.saveSelectedSchool();
                            if (context.mounted) {
                              Navigator.of(context)
                                  .pushReplacementNamed('/inventory');
                            }
                          }
                        : null,
                    child: const Text('Devam Et'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
