import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/apartment.dart';

/// A modern card widget for displaying property/apartment information
class PropertyCard extends StatelessWidget {
  final Apartment apartment;
  final VoidCallback onTap;
  final double elevation;
  final bool showFavoriteButton;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const PropertyCard({
    super.key,
    required this.apartment,
    required this.onTap,
    this.elevation = 2,
    this.showFavoriteButton = false,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    isDarkMode
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: Offset(0, elevation),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property image with badge and favorite button
              Stack(
                children: [
                  // Property image
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child:
                          apartment.imageUrls.isNotEmpty
                              ? CachedNetworkImage(
                                imageUrl: apartment.imageUrls[0],
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      color:
                                          isDarkMode
                                              ? Colors.grey[850]
                                              : Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      color:
                                          isDarkMode
                                              ? Colors.grey[850]
                                              : Colors.grey[200],
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 40,
                                        color:
                                            isDarkMode
                                                ? Colors.grey[700]
                                                : Colors.grey[400],
                                      ),
                                    ),
                              )
                              : Container(
                                color:
                                    isDarkMode
                                        ? Colors.grey[850]
                                        : Colors.grey[200],
                                child: Icon(
                                  Icons.apartment,
                                  size: 40,
                                  color:
                                      isDarkMode
                                          ? Colors.grey[700]
                                          : Colors.grey[400],
                                ),
                              ),
                    ),
                  ),

                  // Price badge
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
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
                        ),
                      ),
                    ),
                  ),

                  // Favorite button if enabled
                  if (showFavoriteButton)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? Colors.black.withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color:
                                isFavorite
                                    ? Colors.red
                                    : isDarkMode
                                    ? Colors.white
                                    : Colors.grey[800],
                          ),
                          onPressed: onFavoriteToggle,
                          constraints: const BoxConstraints(
                            minHeight: 36,
                            minWidth: 36,
                          ),
                          padding: const EdgeInsets.all(8),
                          iconSize: 20,
                          splashRadius: 24,
                        ),
                      ),
                    ),
                ],
              ),

              // Property details
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property name
                    Text(
                      apartment.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Location with icon
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            apartment.location,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Property features row (rooms, bathrooms)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFeature(
                          context,
                          Icons.bed,
                          '${apartment.rooms}',
                          'غرف',
                        ),
                        _buildFeature(
                          context,
                          Icons.bed,
                          '${apartment.bathrooms}',
                          'سرير',
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Details button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.9,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'التفاصيل',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
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

  // Helper method to build feature items
  Widget _buildFeature(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
