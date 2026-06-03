import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:mobile_app/models/service_models.dart';
import 'package:mobile_app/screens/shared/service_detail_screen.dart';
import 'package:mobile_app/services/session_store.dart';
import 'package:mobile_app/services/services_api_service.dart';
import 'package:mobile_app/theme/app_theme.dart';

class ServiceDiscoveryScreen extends StatefulWidget {
  const ServiceDiscoveryScreen({super.key});

  @override
  State<ServiceDiscoveryScreen> createState() => _ServiceDiscoveryScreenState();
}

class _ServiceDiscoveryScreenState extends State<ServiceDiscoveryScreen> {
  final ServicesApiService _servicesService = ServicesApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Service> _services = [];
  List<Service> _filteredServices = [];
  bool _loading = true;
  String? _error;

  String _selectedServiceType = 'All';
  List<String> _selectedTags = [];
  double _minRating = 0;
  String _searchQuery = '';

  final List<String> _serviceTypes = const [
    'All',
    'tour_guide',
    'driver',
    'photographer',
    'interpreter',
    'local_expert',
  ];

  final List<String> _availableTags = const [
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

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _servicesService.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userId = SessionStore.instance.userId ?? 'user_001';
      final rawServices = await _servicesService.discoverServices(
        userId: userId,
        serviceType:
            _selectedServiceType == 'All' ? null : _selectedServiceType,
        tags: _selectedTags.isEmpty ? null : _selectedTags,
        minRating: _minRating,
        limit: 50,
      );

      final services = rawServices.map(Service.fromJson).toList();
      setState(() {
        _services = services;
        _applyFilters();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load services: $e';
        _loading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchQuery.toLowerCase();
    _filteredServices =
        _services.where((service) {
          final matchesQuery =
              query.isEmpty ||
              service.serviceName.toLowerCase().contains(query) ||
              service.serviceType.toLowerCase().contains(query) ||
              (service.description ?? '').toLowerCase().contains(query) ||
              service.tags.any((tag) => tag.toLowerCase().contains(query)) ||
              (service.providerName ?? '').toLowerCase().contains(query);

          final matchesType =
              _selectedServiceType == 'All' ||
              service.serviceType == _selectedServiceType;
          final matchesTags =
              _selectedTags.isEmpty ||
              _selectedTags.every((tag) => service.tags.contains(tag));
          final matchesRating = service.rating >= _minRating;

          return matchesQuery && matchesType && matchesTags && matchesRating;
        }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim();
      _applyFilters();
    });
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
      _applyFilters();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedServiceType = 'All';
      _selectedTags.clear();
      _minRating = 0;
      _searchQuery = '';
      _searchController.clear();
      _applyFilters();
    });
  }

  void _openServiceDetail(Service service) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: service)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppDesign.eerieBlack : AppDesign.pureWhite;
    final surface = isDark ? AppDesign.cardDark : AppDesign.offWhite;
    final card = isDark ? AppDesign.cardDark : Colors.white;
    final text = isDark ? Colors.white : AppDesign.eerieBlack;
    final muted = isDark ? Colors.white70 : AppDesign.midGrey;
    final border =
        isDark ? Colors.white.withOpacity(0.06) : AppDesign.lightGrey;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: Text(
          'Services',
          style: TextStyle(color: text, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _loadServices,
            icon: Icon(Icons.refresh_rounded, color: text),
          ),
          IconButton(
            onPressed: _showFilterModal,
            icon: Icon(LucideIcons.sliders_horizontal, color: text),
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _EmptyState(
                icon: LucideIcons.briefcase,
                title: 'Could not load services',
                message: _error!,
                onRetry: _loadServices,
              )
              : RefreshIndicator(
                onRefresh: _loadServices,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: TextStyle(color: text),
                      decoration: InputDecoration(
                        hintText: 'Search services',
                        prefixIcon: Icon(LucideIcons.search, color: muted),
                        filled: true,
                        fillColor: surface,
                        hintStyle: TextStyle(color: muted),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: AppDesign.navExplore,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionHeader(
                      title: 'Service type',
                      action: TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ChipRow(
                      items: _serviceTypes,
                      selected: {_selectedServiceType},
                      onTap: (value) {
                        setState(() {
                          _selectedServiceType = value;
                          _applyFilters();
                        });
                      },
                      exclusive: true,
                    ),
                    const SizedBox(height: 18),
                    _SectionHeader(title: 'Tags'),
                    const SizedBox(height: 10),
                    _ChipRow(
                      items: _availableTags,
                      selected: _selectedTags.toSet(),
                      onTap: _toggleTag,
                    ),
                    const SizedBox(height: 18),
                    _SectionHeader(
                      title: 'Minimum rating',
                      subtitle: _minRating.toStringAsFixed(1),
                    ),
                    Slider(
                      value: _minRating,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      activeColor: AppDesign.navExplore,
                      onChanged: (value) {
                        setState(() {
                          _minRating = value;
                          _applyFilters();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_filteredServices.length} services found',
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    if (_filteredServices.isEmpty)
                      _EmptyState(
                        icon: LucideIcons.search,
                        title: 'No services found',
                        message: 'Try adjusting the filters or search term.',
                        onRetry: _clearFilters,
                      )
                    else
                      ..._filteredServices.map(
                        (service) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ServiceCard(
                            service: service,
                            isDark: isDark,
                            card: card,
                            text: text,
                            muted: muted,
                            border: border,
                            onTap: () => _openServiceDetail(service),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  void _showFilterModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppDesign.cardDark : Colors.white;
    final text = isDark ? Colors.white : AppDesign.eerieBlack;
    final muted = isDark ? Colors.white70 : AppDesign.midGrey;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Filter services',
                        style: TextStyle(
                          color: text,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setModalState(_clearFilters);
                          _clearFilters();
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Service type', style: TextStyle(color: muted)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _serviceTypes.map((type) {
                          final selected = _selectedServiceType == type;
                          return ChoiceChip(
                            label: Text(type.replaceAll('_', ' ')),
                            selected: selected,
                            onSelected: (_) {
                              setModalState(() {
                                _selectedServiceType = type;
                                _applyFilters();
                              });
                              setState(() {});
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Tags', style: TextStyle(color: muted)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _availableTags.map((tag) {
                          final selected = _selectedTags.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: selected,
                            onSelected: (_) {
                              setModalState(() {
                                _toggleTag(tag);
                              });
                              setState(() {});
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Minimum rating: ${_minRating.toStringAsFixed(1)}',
                    style: TextStyle(color: muted),
                  ),
                  Slider(
                    value: _minRating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    activeColor: AppDesign.navExplore,
                    onChanged: (value) {
                      setModalState(() {
                        _minRating = value;
                        _applyFilters();
                      });
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(_applyFilters);
                      },
                      child: const Text('Apply filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle, this.action});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : AppDesign.eerieBlack;
    final muted = isDark ? Colors.white54 : AppDesign.midGrey;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: TextStyle(color: muted, fontSize: 12)),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.items,
    required this.selected,
    required this.onTap,
    this.exclusive = false,
  });

  final List<String> items;
  final Set<String> selected;
  final ValueChanged<String> onTap;
  final bool exclusive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : AppDesign.eerieBlack;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          items.map((item) {
            final isSelected = selected.contains(item);
            return ChoiceChip(
              label: Text(item.replaceAll('_', ' ')),
              selected: isSelected,
              onSelected: (_) => onTap(item),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : text,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: isDark ? AppDesign.darkGrey : AppDesign.offWhite,
              selectedColor:
                  exclusive ? AppDesign.navExplore : AppDesign.navConcierge,
              side: BorderSide(
                color:
                    isSelected
                        ? Colors.transparent
                        : (isDark ? Colors.white10 : AppDesign.lightGrey),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }).toList(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : AppDesign.eerieBlack;
    final muted = isDark ? Colors.white54 : AppDesign.midGrey;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: muted),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                color: text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.isDark,
    required this.card,
    required this.text,
    required this.muted,
    required this.border,
    required this.onTap,
  });

  final Service service;
  final bool isDark;
  final Color card;
  final Color text;
  final Color muted;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
          boxShadow:
              isDark
                  ? []
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppDesign.navExplore.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    LucideIcons.briefcase,
                    color: AppDesign.navExplore,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.serviceName,
                        style: TextStyle(
                          color: text,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.providerName ?? 'Unknown provider',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (service.rating > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppDesign.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      service.rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: AppDesign.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              service.serviceType.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(
                color: muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            if (service.description != null &&
                service.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                service.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: muted, height: 1.35),
              ),
            ],
            if (service.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    service.tags.take(4).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppDesign.navExplore.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: AppDesign.navExplore,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
