import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/apartment.dart';
import 'property_details_screen.dart';
// We might need a way to switch tabs programmatically later
// Potentially pass the MainNavigationScreen's state key or a callback

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if Firebase is initialized
    try {
      final authProvider = Provider.of<AuthProvider>(context);
      final theme = Theme.of(context);
      final textTheme = theme.textTheme;
      final colorScheme = theme.colorScheme;

      return Scaffold(
        appBar: AppBar(
          title: const Text('المفضلة'), // Favorites
          centerTitle: true,
          actions: [
            Consumer<FavoritesProvider>(
              builder: (context, favoritesProvider, _) {
                final hasFavorites = favoritesProvider.favorites.isNotEmpty;
                return hasFavorites
                    ? IconButton(
                        icon: const Icon(Icons.delete_sweep),
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
            : _buildLoginPrompt(context, colorScheme, textTheme), // Show login prompt if logged out
      );
    } on FirebaseException catch (e) {
      // Handle Firebase initialization error
      print('Firebase error in FavoritesScreen: ${e.message}');
      return Scaffold(
        appBar: AppBar(
          title: const Text('المفضلة'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.grey[500],
              ),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ في تحميل البيانات',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Handle other errors
      print('Error in FavoritesScreen: $e');
      return Scaffold(
        appBar: AppBar(
          title: const Text('المفضلة'),
          centerTitle: true,
        ),
        body: Center(
          child: Text('حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.'),
        ),
      );
    }
  }

  // Widget to display when the user is logged in
  Widget _buildFavoritesList(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, _) {
        final favorites = favoritesProvider.getFavoriteApartments();
        
        if (favoritesProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد عقارات في المفضلة',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'اضغط على أيقونة القلب لإضافة عقار إلى المفضلة',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: apartment.imageUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: apartment.imageUrls[0],
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 140,
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 140,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error, size: 40),
                          ),
                        )
                      : Container(
                          height: 140,
                          color: Colors.grey[300],
                          child: const Icon(Icons.home, size: 40, color: Colors.grey),
                        ),
                ),
                
                // Favorite button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: InkWell(
                      onTap: () async {
                        try {
                          await favoritesProvider.toggleFavorite(apartment);
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text('تم إزالة ${apartment.name} من المفضلة'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } catch (e) {
                          // Handle any errors that occur during toggling or showing the snackbar
                          print('Error toggling favorite: $e');
                        }
                      },
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 24,
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
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      '${apartment.price.toStringAsFixed(0)} ج.م',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Property details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property name
                  Text(
                    apartment.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Property location
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          apartment.location,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Botón para completar la reserva
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
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text(
                        'اكمل الحجز الان',
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

  // Widget for building a feature item
  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue[700]),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // Widget to display when the user is logged out
  Widget _buildLoginPrompt(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 24.0),
          Text(
            'قم بتسجيل الدخول لعرض المفضلة', // Log in to view favorites
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12.0),
          Text(
            'قم بتسجيل الدخول لحفظ العقارات المفضلة لديك والوصول إليها في أي وقت', // Log in to save your favorite properties and access them anytime
            style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24.0),
          ElevatedButton(
            onPressed: () {
              // Navigate to the Account Tab
              Provider.of<NavigationProvider>(context, listen: false).setIndex(4);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            ),
            child: const Text('تسجيل الدخول'), // Login
          ),
        ],
      ),
    );
  }

  // Show confirmation dialog for clearing all favorites
  void _showClearConfirmationDialog(BuildContext context, FavoritesProvider favoritesProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح المفضلة'),
        content: const Text('هل أنت متأكد من رغبتك في مسح جميع العقارات من المفضلة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              favoritesProvider.clearFavorites();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم مسح جميع العقارات من المفضلة'),
                ),
              );
            },
            child: const Text('مسح الكل'),
          ),
        ],
      ),
    );
  }
}
