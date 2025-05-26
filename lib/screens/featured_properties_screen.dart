import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/apartment.dart';
import '../services/property_service_supabase.dart';
import '../providers/favorites_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_utils.dart';
import 'property_details_screen.dart';

class FeaturedPropertiesScreen extends StatefulWidget {
  const FeaturedPropertiesScreen({super.key});

  @override
  State<FeaturedPropertiesScreen> createState() => _FeaturedPropertiesScreenState();
}

class _FeaturedPropertiesScreenState extends State<FeaturedPropertiesScreen> {
  final PropertyServiceSupabase _propertyService = PropertyServiceSupabase();
  List<Apartment> _featuredProperties = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadFeaturedProperties();
  }

  Future<void> _loadFeaturedProperties() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final properties = await _propertyService.getFeaturedProperties();
      
      if (mounted) {
        setState(() {
          _featuredProperties = properties;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              color: Colors.amber,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text('العقارات المميزة'),
          ],
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor,
                theme.primaryColor.withValues(alpha: 204), // 0.8 ≈ 204/255
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeaturedProperties,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _hasError
                ? _buildErrorView()
                : _featuredProperties.isEmpty
                    ? _buildEmptyView()
                    : _buildPropertiesGrid(),
      ),
    );
  }

  Widget _buildEmptyView() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_work_outlined,
            size: 80,
            color: theme.colorScheme.primary.withValues(alpha: 128), // 0.5 ≈ 128/255
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد عقارات مميزة متاحة حالياً',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 179), // 0.7 ≈ 179/255
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'قد تتوفر عقارات مميزة جديدة قريباً',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 128), // 0.5 ≈ 128/255
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadFeaturedProperties,
            icon: Icon(Icons.refresh),
            label: Text('تحديث'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.withValues(alpha: 179), // 0.7 ≈ 179/255
          ),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ أثناء تحميل العقارات المميزة',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadFeaturedProperties,
            icon: Icon(Icons.refresh),
            label: Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: theme.colorScheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesGrid() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _featuredProperties.length,
      itemBuilder: (context, index) {
        final apartment = _featuredProperties[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildFeaturedPropertyCard(apartment),
        );
      },
    );
  }

  Widget _buildFeaturedPropertyCard(Apartment apartment) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 51), // 0.2 ≈ 51/255
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PropertyDetailsScreen(
                property: apartment,
                fromCategoriesScreen: false,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property image with gradient overlay
            Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: apartment.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: apartment.imageUrls[0],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.broken_image,
                          size: 40,
                          color: Colors.grey,
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.home,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                ),
                
                // Gradient overlay for better text readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 179), // 0.7 ≈ 179/255
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                // Featured badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 77), // 0.3 ≈ 77/255
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'مميز',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Price tag
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 77), // 0.3 ≈ 77/255
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${apartment.price.toInt()} جنيه',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                
                // Location
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        apartment.location,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Favorite button
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.black.withValues(alpha: 128) // 0.5 ≈ 128/255
                          : Colors.white.withValues(alpha: 204), // 0.8 ≈ 204/255
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 51), // 0.2 ≈ 51/255
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Consumer<FavoritesProvider>(
                      builder: (context, favoritesProvider, _) {
                        final isFavorite = favoritesProvider.isFavorite(apartment.id);
                        return IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey,
                            size: 20,
                          ),
                          constraints: BoxConstraints(
                            minHeight: 36,
                            minWidth: 36,
                          ),
                          padding: EdgeInsets.all(8),
                          onPressed: () async {
                            final authProvider = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );
                            if (!authProvider.isAuthenticated) {
                              AuthUtils.showAuthRequiredDialog(context);
                              return;
                            }

                            await favoritesProvider.toggleFavorite(apartment);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            
            // Property details
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    apartment.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Features row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildFeatureChip(
                        icon: Icons.bedroom_parent_outlined,
                        label: '${apartment.rooms} غرف',
                        color: Colors.blue.shade100,
                        textColor: Colors.blue.shade800,
                      ),
                      _buildFeatureChip(
                        icon: Icons.king_bed_outlined,
                        label: '${apartment.bedrooms} سرير',
                        color: Colors.purple.shade100,
                        textColor: Colors.purple.shade800,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 