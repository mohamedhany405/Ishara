import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/core/api/auth_provider.dart';

class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key});

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  String? _selectedProblem;
  String _movieName = '';
  String _details = '';
  final _formKey = GlobalKey<FormState>();

  final List<String> _problems = [
    'False info',
    'Image not showing',
    'App bug',
    'Other'
  ];

  void _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProblem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a problem type')),
      );
      return;
    }

    try {
      final dataService = ref.read(dataServiceProvider);
      final result = await dataService.submitContactMessage(
        name: 'Report',
        email: '',
        subject: _selectedProblem!,
        message: 'Movie: ${_movieName.trim()}\nDetails: ${_details.trim()}',
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Problem'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Problem Type Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedProblem,
                  hint: const Text('Please select your problem',
                      style: TextStyle(color: Colors.grey)),
                  dropdownColor: Colors.grey[900],
                  decoration: InputDecoration(
                    labelText: 'Problem Type',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD94CF7)),
                    ),
                    filled: true,
                    fillColor: Colors.grey[900],
                    prefixIcon: const Icon(Icons.warning, color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Please select your problem',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    ..._problems.map((problem) => DropdownMenuItem(
                          value: problem,
                          child: Text(problem,
                              style: const TextStyle(color: Colors.white)),
                        )),
                  ],
                  onChanged: (value) => setState(() => _selectedProblem = value),
                  validator: (value) =>
                      value == null ? 'Please select a problem type' : null,
                ),

                const SizedBox(height: 20),

                // Movie Name Field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Movie Name (optional)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD94CF7)),
                    ),
                    filled: true,
                    fillColor: Colors.grey[900],
                    prefixIcon:
                        const Icon(Icons.movie_outlined, color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) => _movieName = value,
                ),

                const SizedBox(height: 20),

                // Details Field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Details',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD94CF7)),
                    ),
                    filled: true,
                    fillColor: Colors.grey[900],
                    prefixIcon: const Icon(Icons.description, color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please provide details about the problem';
                    }
                    return null;
                  },
                  onChanged: (value) => _details = value,
                ),

                const SizedBox(height: 30),

                // Submit Button
                ElevatedButton(
                  onPressed: _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD94CF7),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit Report',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}