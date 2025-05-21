# Page Navigation with Loading Animation

This module provides a modern and customizable way to show loading animations during page navigation in your Flutter app.

## Features

- Display Lottie animations during page transitions
- Load pages in the background while showing animations
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

## Custom Loading Animation

To use your own Lottie animation:

1. Place your animation file in the assets directory
2. Update pubspec.yaml if needed
3. Pass the animation path to the `lottieAsset` parameter
4. Run `flutter pub get` to update assets

## Performance Tips

- Keep your Lottie animations lightweight
- For better performance, optimize your animation file
- Use the `minimumLoadingTime` parameter to ensure smooth transitions
- Pre-load heavy assets with the `precacheImage` method 