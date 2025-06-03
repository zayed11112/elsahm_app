import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../models/apartment.dart';
import 'property_details_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/property_service_supabase.dart';

class ApartmentsListScreen extends StatefulWidget {
  const ApartmentsListScreen({super.key});

  @override
  State<ApartmentsListScreen> createState() => _ApartmentsListScreenState();
}

class _ApartmentsListScreenState extends State<ApartmentsListScreen> {
  bool _isLoading = false;
  List<Apartment> _apartments = [];
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  final PropertyServiceSupabase _propertyService = PropertyServiceSupabase();
  final Logger _logger = Logger('ApartmentsListScreen');
  
  // Pagination variables
  int _itemsPerPage = 10;
  int _currentPage = 1;
  int get _totalPages => (_apartments.length / _itemsPerPage).ceil();
  
  // Theme colors
  final Color primaryBlue = const Color(0xFF1565C0);
  final Color secondaryBlue = const Color(0xFF42A5F5);

  // ScrollController for scrolling to top
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadApartments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadApartments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // استخدام خدمة Supabase للحصول على العقارات
      final apartments = await _propertyService.getAvailableProperties(
        limit: 200,
      );

      _logger.info('تم تحميل ${apartments.length} عقار');

      if (mounted) {
        setState(() {
          _apartments = apartments;
          _isLoading = false;
          _currentPage = 1; // Reset to first page when loading new data
        });
      }
    } catch (e) {
      _logger.severe('خطأ في تحميل العقارات: $e');

      if (mounted) {
        setState(() {
          _error = 'حدث خطأ أثناء تحميل الشقق: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  List<Apartment> get _filteredApartments {
    return _apartments;
  }
  
  List<Apartment> get _paginatedApartments {
    if (_filteredApartments.isEmpty) return [];
    
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage > _filteredApartments.length 
        ? _filteredApartments.length 
        : startIndex + _itemsPerPage;
    
    if (startIndex >= _filteredApartments.length) return [];
    return _filteredApartments.sublist(startIndex, endIndex);
  }
  
  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    
    setState(() {
      _currentPage = page;
    });
    
    // Scroll to top when changing pages
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'العقارات المتاحة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Error Message
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Loading indicator or apartments list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _apartments.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.apartment,
                            size: 80,
                            color: Colors.grey.withAlpha(128),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد شقق متاحة حالياً',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                    : Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadApartments,
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: _paginatedApartments.length,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemBuilder: (context, index) {
                                final apartment = _paginatedApartments[index];
                                return _buildApartmentCard(
                                  context,
                                  apartment,
                                  isDarkMode,
                                );
                              },
                            ),
                          ),
                        ),
                        // Pagination controls
                        if (_totalPages > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.black12 : Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, -3),
                                ),
                              ],
                            ),
                            child: _buildPaginationControls(context),
                          ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaginationControls(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          _buildPaginationButton(
            icon: Icons.arrow_back_ios,
            onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
            tooltip: 'الصفحة السابقة',
            theme: theme,
          ),
          
          const SizedBox(width: 8),
          
          // First page button (if not near the start)
          if (_currentPage > 3)
            _buildPageNumberButton(1, theme),
            
          // Ellipsis if needed
          if (_currentPage > 4)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('...', style: theme.textTheme.titleMedium),
            ),
            
          // Page numbers around current page
          ...List.generate(
            _totalPages,
            (index) {
              final pageNumber = index + 1;
              // Show current page and 1 page before/after
              if ((pageNumber >= _currentPage - 1 && pageNumber <= _currentPage + 1) &&
                  pageNumber > 0 && pageNumber <= _totalPages) {
                return _buildPageNumberButton(pageNumber, theme);
              }
              return const SizedBox.shrink();
            },
          ),
          
          // Ellipsis if needed
          if (_currentPage < _totalPages - 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('...', style: theme.textTheme.titleMedium),
            ),
            
          // Last page button (if not near the end)
          if (_currentPage < _totalPages - 2)
            _buildPageNumberButton(_totalPages, theme),
          
          const SizedBox(width: 8),
          
          // Next button
          _buildPaginationButton(
            icon: Icons.arrow_forward_ios,
            onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
            tooltip: 'الصفحة التالية',
            theme: theme,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaginationButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
    required ThemeData theme,
  }) {
    return Material(
      color: onPressed == null ? Colors.grey.shade200 : theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: tooltip,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              icon,
              size: 16,
              color: onPressed == null ? Colors.grey.shade400 : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPageNumberButton(int pageNumber, ThemeData theme) {
    final isCurrentPage = pageNumber == _currentPage;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Material(
        color: isCurrentPage ? theme.colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: isCurrentPage ? null : () => _goToPage(pageNumber),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: !isCurrentPage ? Border.all(color: theme.colorScheme.primary) : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              pageNumber.toString(),
              style: TextStyle(
                color: isCurrentPage ? Colors.white : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApartmentCard(
    BuildContext context,
    Apartment apartment,
    bool isDarkMode,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PropertyDetailsScreen(property: apartment),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image with overlay
            Stack(
              children: [
                // Main image
                SizedBox(
                  height: 200,
                  child:
                      apartment.imageUrls.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: apartment.imageUrls[0],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder:
                                (context, url) => Container(
                                  color: Colors.grey.shade300,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  color: Colors.grey.shade300,
                                  child: const Center(
                                    child: Icon(Icons.error, size: 40),
                                  ),
                                ),
                          )
                          : Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(Icons.apartment, size: 40),
                            ),
                          ),
                ),

                // Status badge (Available/Not Available)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          apartment.isAvailable
                              ? Colors.green.withAlpha(230)
                              : Colors.red.withAlpha(230),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      apartment.isAvailable ? 'متاح' : 'غير متاح',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                // Price badge
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(230),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${apartment.price.toStringAsFixed(0)} ج.م',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Apartment title
                  Text(
                    apartment.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Location with icon
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          apartment.location,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Features (Rooms, Bathrooms, etc.)
                  Row(
                    children: [
                      _buildFeatureItem(
                        context,
                        Icons.meeting_room,
                        '${apartment.rooms} غرف',
                        isDarkMode,
                      ),
                      const SizedBox(width: 24),
                      _buildFeatureItem(
                        context,
                        Icons.king_bed_outlined,
                        '${apartment.bedrooms} سرير',
                        isDarkMode,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Features preview chips
                  if (apartment.features.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          apartment.features.take(3).map((feature) {
                            return Chip(
                              label: Text(
                                feature,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              backgroundColor: colorScheme.primaryContainer,
                              padding: const EdgeInsets.all(0),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                    ),

                  // Description preview
                  if (apartment.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      apartment.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // View details button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    PropertyDetailsScreen(property: apartment),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'عرض التفاصيل',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String text,
    bool isDarkMode,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
