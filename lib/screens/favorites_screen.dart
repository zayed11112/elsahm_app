import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/apartment.dart';
import 'property_details_screen.dart';
// We might need a way to switch tabs programmatically later
// Potentially pass the MainNavigationScreen's state key or a callback

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  
  // Create a logger instance
  static final Logger _logger = Logger('FavoritesScreen');

  @override
  Widget build(BuildContext context) {
    // Check if Firebase is initialized
    try {
      final authProvider = Provider.of<AuthProvider>(context);
      final theme = Theme.of(context);
      // ignore: unused_local_variable
      final isDarkMode = theme.brightness == Brightness.dark;

      return Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'المفضلة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          elevation: 0,
          actions: [
            Consumer<FavoritesProvider>(
              builder: (context, favoritesProvider, _) {
                final hasFavorites = favoritesProvider.favorites.isNotEmpty;
                return hasFavorites
                    ? IconButton(
                        icon: Icon(
                          Icons.delete_sweep,
                          color: theme.colorScheme.primary,
                        ),
                        tooltip: 'مسح الكل',
                        onPressed: () {
                          _showClearConfirmationDialog(context, favoritesProvider);
                        },
                      )
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: authProvider.isAuthenticated
            ? _buildFavoritesList(context) // Show favorites if logged in
            : _buildEmptyState(context, theme), // Show empty state if logged out
      );
    } on FirebaseException catch (e) {
      // Handle Firebase initialization error
      _logger.severe('Firebase error in FavoritesScreen: ${e.message}');
      return _buildErrorScreen(context, 'حدث خطأ في تحميل البيانات', 'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.');
    } catch (e) {
      // Handle other errors
      _logger.severe('Error in FavoritesScreen: $e');
      return _buildErrorScreen(context, 'حدث خطأ غير متوقع', 'يرجى المحاولة مرة أخرى لاحقاً.');
    }
  }

  // Widget to display when the user is logged in
  Widget _buildFavoritesList(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, _) {
        final favorites = favoritesProvider.getFavoriteApartments();
        
        if (favoritesProvider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'جاري تحميل المفضلات...',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }
        
        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 80,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد عقارات في المفضلة',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'اضغط على أيقونة القلب لإضافة عقار إلى المفضلة',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to explore properties tab
                    Provider.of<NavigationProvider>(context, listen: false).setIndex(0);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'استكشف العقارات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final apartment = favorites[index];
            return _buildFavoriteCard(context, apartment, favoritesProvider);
          },
        );
      },
    );
  }

  // Widget to display a favorite property card
  Widget _buildFavoriteCard(BuildContext context, Apartment apartment, FavoritesProvider favoritesProvider) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PropertyDetailsScreen(property: apartment),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property image with favorite button
              Stack(
                children: [
                  // Property image
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    ),
                    child: apartment.imageUrls.isNotEmpty
                        ? Hero(
                            tag: 'property-${apartment.id}',
                            child: CachedNetworkImage(
                              imageUrl: apartment.imageUrls[0],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(
                                  color: theme.colorScheme.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.broken_image_rounded,
                                size: 40,
                                color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                              ),
                            ),
                          )
                        : Icon(
                            Icons.home_rounded,
                            size: 50,
                            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                          ),
                  ),
                  
                  // Favorite button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      elevation: 4,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      color: Colors.white.withOpacity(0.9),
                      child: InkWell(
                        onTap: () async {
                          try {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            await favoritesProvider.toggleFavorite(apartment);
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(16),
                                content: Text('تم إزالة ${apartment.name} من المفضلة'),
                                backgroundColor: theme.colorScheme.secondary,
                                duration: const Duration(seconds: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          } catch (e) {
                            _logger.severe('Error toggling favorite: $e');
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Property badge (show for recently added properties)
                  if (DateTime.now().difference(apartment.createdAt).inDays < 7) // Show "New" badge for properties less than 7 days old
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'جديد',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  
                  // Property price
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                          stops: const [0.1, 0.9],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withOpacity(0.9),
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Property details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property name
                    Text(
                      apartment.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Property location
                    Row(
                      children: [
                        Icon(Icons.location_on, 
                          size: 16, 
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600]
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            apartment.location,
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PropertyDetailsScreen(property: apartment),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'اكمل الحجز الان',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Empty state when not logged in
  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? theme.colorScheme.surface
                  : theme.colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isDarkMode 
                      ? Colors.black.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.favorite_border_rounded,
              size: 70,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'لم تقم بإضافة أي عقارات للمفضلة',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'استكشف العقارات وأضف المفضلة لديك للوصول إليها بسهولة',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Navigate to explore properties
              Provider.of<NavigationProvider>(context, listen: false).setIndex(0);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'استكشف العقارات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Error screen
  Widget _buildErrorScreen(BuildContext context, String title, String message) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('المفضلة'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 70,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Refresh the screen
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show confirmation dialog for clearing all favorites
  void _showClearConfirmationDialog(BuildContext context, FavoritesProvider favoritesProvider) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: theme.colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('مسح المفضلة'),
          ],
        ),
        content: const Text('هل أنت متأكد من رغبتك في مسح جميع العقارات من المفضلة؟'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              favoritesProvider.clearFavorites();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('تم مسح جميع العقارات من المفضلة'),
                  backgroundColor: theme.colorScheme.secondary,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('مسح الكل'),
          ),
        ],
      ),
    );
  }
}
