import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import '../models/available_place.dart';
import '../models/apartment.dart';
import '../services/property_service_supabase.dart';
import '../providers/navigation_provider.dart';
import 'property_details_screen.dart';
import 'main_navigation_screen.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final AvailablePlace place;
  final bool fromMainScreen;

  const PlaceDetailsScreen({
    super.key, 
    required this.place, 
    this.fromMainScreen = false,
  });

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  static final Logger _logger = Logger('PlaceDetailsScreen');
  final PropertyServiceSupabase _propertyService = PropertyServiceSupabase();
  bool _isLoading = true;
  List<Apartment> _properties = [];

  @override
  void initState() {
    super.initState();
    developer.log(
      'PlaceDetailsScreen initialized with place: ${widget.place.name}',
    );
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
    });

    try {
      developer.log('Loading properties for place: ${widget.place.name}');
      // استخدام دالة getPropertiesByPlace بدلاً من getLatestProperties
      // لعرض العقارات المرتبطة بالمكان المحدد فقط
      final properties = await _propertyService.getPropertiesByPlace(
        widget.place.name,
        limit: 20,
      );

      setState(() {
        _properties = properties;
        _isLoading = false;
      });
      developer.log(
        'Loaded ${properties.length} properties for place: ${widget.place.name}',
      );
    } catch (e) {
      developer.log('Error loading properties: $e', error: e);
      setState(() {
        _isLoading = false;
      });
      _logger.severe('Error loading properties: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    developer.log('Building PlaceDetailsScreen for: ${widget.place.name}');
    final navigationProvider = Provider.of<NavigationProvider>(context);

    final Widget content = Scaffold(
      appBar: AppBar(
        title: Text(widget.place.name),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            developer.log('Back button pressed in PlaceDetailsScreen');
            Navigator.of(context).pop();
          },
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(),
    );

    // If we're coming from the main screen, use MainNavigationScreen layout to keep bottom navbar
    // But only if we're not already inside the main navigation screen
    if (widget.fromMainScreen && !_isAlreadyInMainNavigation(context)) {
      return MainNavigationScreen.wrapWithBottomNav(
        context: context,
        child: content,
        selectedIndex: navigationProvider.selectedIndex,
      );
    }

    // Otherwise just return the content directly
    return content;
  }
  
  // Check if we're already inside the main navigation screen
  bool _isAlreadyInMainNavigation(BuildContext context) {
    // Check ancestors for MainNavigationScreen
    bool result = false;
    
    // Use element visitor to check ancestors
    context.visitAncestorElements((element) {
      if (element.widget.toString().contains('MainNavigationScreen')) {
        result = true;
        return false; // Stop visiting
      }
      return true; // Continue visiting
    });
    
    return result;
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadProperties,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // عنوان المكان المتاح
          _buildHeader(),

          const SizedBox(height: 24),

          // العقارات المرتبطة بالمكان المتاح
          Text(
            'العقارات المتاحة',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          // قائمة العقارات
          _properties.isEmpty ? _buildEmptyState() : _buildPropertiesList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // أيقونة المكان المتاح
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child:
                  widget.place.iconUrl.isNotEmpty
                      ? Image.network(
                        widget.place.iconUrl,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) => const Icon(
                              Icons.home_work,
                              size: 60,
                              color: Colors.blue,
                            ),
                      )
                      : const Icon(
                        Icons.home_work,
                        size: 60,
                        color: Colors.blue,
                      ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // اسم المكان المتاح
        Center(
          child: Text(
            widget.place.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_outlined, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا توجد عقارات متاحة حالياً',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _properties.length,
      itemBuilder: (context, index) {
        final property = _properties[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => PropertyDetailsScreen(
                        property: property,
                        fromCategoriesScreen: true,
                        fromMainScreen: widget.fromMainScreen,
                      ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // صورة العقار
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child:
                          property.imageUrls.isNotEmpty
                              ? Image.network(
                                property.imageUrls[0],
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.home),
                                    ),
                              )
                              : Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.home),
                              ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // تفاصيل العقار
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        Text(
                          property.location,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Icon(
                              Icons.attach_money,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${property.price.toInt()} جنيه',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
