import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/services_api_service.dart';
import '../services/session_store.dart';
import '../theme/app_theme.dart';

/// Create Service Screen
/// Allows providers to create a new service offering
class CreateServiceScreen extends StatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final ServicesApiService _servicesService = ServicesApiService();

  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Form fields
  String _serviceType = 'tour_guide';
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceMinController = TextEditingController();
  final _priceMaxController = TextEditingController();

  List<String> _selectedTags = [];
  List<String> _selectedKeywords = [];
  List<String> _selectedDays = [];
  String? _hoursStart;
  String? _hoursEnd;

  final List<String> _serviceTypes = [
    'tour_guide',
    'driver',
    'photographer',
    'interpreter',
    'local_expert',
  ];

  final List<String> _availableTags = [
    'history',
    'photography',
    'adventure',
    'food',
    'culture',
    'museums',
    'shopping',
    'nightlife',
    'nature',
    'wellness',
  ];

  final List<String> _availableKeywords = [
    'ancient_history',
    'modern_history',
    'photography',
    'monuments',
    'culture',
    'sightseeing',
    'adventure',
    'transport',
    'accommodation',
    'entertainment',
  ];

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one availability day'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final providerId = SessionStore.instance.userId ?? 'provider_001';

      await _servicesService.createService(
        providerId: providerId,
        serviceType: _serviceType,
        serviceName: _nameController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        tags: _selectedTags,
        clusterKeywords: _selectedKeywords,
        priceMin: double.tryParse(_priceMinController.text),
        priceMax: double.tryParse(_priceMaxController.text),
        availability: {
          'days': _selectedDays,
          'hours_start': _hoursStart,
          'hours_end': _hoursEnd,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service created successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppDesign.surfaceColor,
        elevation: 0,
        title: const Text(
          'Create Service',
          style: TextStyle(
            color: AppDesign.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Type
              const Text(
                'Service Type *',
                style: TextStyle(
                  color: AppDesign.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _serviceType,
                items:
                    _serviceTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.replaceAll('_', ' ')),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _serviceType = value;
                    });
                  }
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppDesign.cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Service Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Service Name *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppDesign.cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter service name';
                  }
                  if (value.length < 3) {
                    return 'Service name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppDesign.cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Price Range
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceMinController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Min Price',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppDesign.cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceMaxController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Max Price',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppDesign.cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tags
              const Text(
                'Service Tags',
                style: TextStyle(
                  color: AppDesign.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _availableTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                        backgroundColor: AppDesign.cardColor,
                        selectedColor: AppDesign.accentColor,
                        labelStyle: TextStyle(
                          color:
                              isSelected
                                  ? AppDesign.textColorLight
                                  : AppDesign.textColor,
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),

              // Keywords for cluster matching
              const Text(
                'Cluster Keywords (for matching)',
                style: TextStyle(
                  color: AppDesign.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _availableKeywords.map((keyword) {
                      final isSelected = _selectedKeywords.contains(keyword);
                      return FilterChip(
                        label: Text(keyword.replaceAll('_', ' ')),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedKeywords.add(keyword);
                            } else {
                              _selectedKeywords.remove(keyword);
                            }
                          });
                        },
                        backgroundColor: AppDesign.cardColor,
                        selectedColor: AppDesign.accentColor,
                        labelStyle: TextStyle(
                          color:
                              isSelected
                                  ? AppDesign.textColorLight
                                  : AppDesign.textColor,
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),

              // Availability Days
              const Text(
                'Availability Days *',
                style: TextStyle(
                  color: AppDesign.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _daysOfWeek.map((day) {
                      final isSelected = _selectedDays.contains(day);
                      return FilterChip(
                        label: Text(day),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDays.add(day);
                            } else {
                              _selectedDays.remove(day);
                            }
                          });
                        },
                        backgroundColor: AppDesign.cardColor,
                        selectedColor: AppDesign.accentColor,
                        labelStyle: TextStyle(
                          color:
                              isSelected
                                  ? AppDesign.textColorLight
                                  : AppDesign.textColor,
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),

              // Time Range
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Start Time',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppDesign.cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        suffixIcon: const Icon(LucideIcons.clock),
                      ),
                      controller: TextEditingController(text: _hoursStart),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            _hoursStart =
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'End Time',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppDesign.cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        suffixIcon: const Icon(LucideIcons.clock),
                      ),
                      controller: TextEditingController(text: _hoursEnd),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            _hoursEnd =
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppDesign.accentColor,
                    foregroundColor: AppDesign.textColorLight,
                    disabledBackgroundColor: AppDesign.textColorMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppDesign.textColorLight,
                              ),
                            ),
                          )
                          : const Text(
                            'Create Service',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceMinController.dispose();
    _priceMaxController.dispose();
    _servicesService.dispose();
    super.dispose();
  }
}
