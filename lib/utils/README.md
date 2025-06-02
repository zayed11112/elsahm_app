# Page Navigation with Loading Animation

This module provides a modern and customizable way to show loading indicators during page navigation in your Flutter app.

## Features

- Display loading indicators during page transitions
- Load pages in the background while showing loading indicators
- Fetch data before showing the destination page
- Customizable minimum loading time
- Support for both light and dark themes
- Easy to use API

## Usage

### Simple Page Navigation with Loading

```dart
// Using NavigationProvider (recommended)
final navProvider = Provider.of<NavigationProvider>(context, listen: false);
navProvider.navigateWithLoading(
  context: context,
  page: DestinationPage(),
  lottieAsset: 'assets/animations/loading.json',
  minimumLoadingTime: Duration(milliseconds: 1500),
);

// Using NavigationUtils directly
NavigationUtils.navigateWithLoading(
  context: context,
  page: DestinationPage(),
);
```

### Navigation with Data Loading

```dart
// Using NavigationProvider (recommended)
final navProvider = Provider.of<NavigationProvider>(context, listen: false);
navProvider.navigateWithDataLoading<void, List<String>>(
  context: context,
  dataLoader: () => fetchDataFromApi(),  // Your data fetching function
  pageBuilder: (context, data) => DataPage(items: data),
  lottieAsset: 'assets/animations/loading.json',
);

// Using NavigationUtils directly
NavigationUtils.navigateWithDataLoading<void, List<String>>(
  context: context,
  dataLoader: () => fetchDataFromApi(),
  pageBuilder: (context, data) => DataPage(items: data),
);
```

## Custom Loading Indicator

The loading indicator uses Flutter's built-in CircularProgressIndicator for optimal performance and consistency.

## Performance Tips

- Use the `minimumLoadingTime` parameter to ensure smooth transitions
- Pre-load heavy assets with the `precacheImage` method
- Keep data loading operations efficient