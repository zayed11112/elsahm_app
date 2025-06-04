import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Define app bar color to match the wallet screen
const Color appBarBlue = Color(0xFF1976d3);

class WhyChooseUsScreen extends StatefulWidget {
  const WhyChooseUsScreen({super.key});

  @override
  State<WhyChooseUsScreen> createState() => _WhyChooseUsScreenState();
}

class _WhyChooseUsScreenState extends State<WhyChooseUsScreen> {
  bool isLoading = true;
  final String whyChooseUsUrl = 'https://zayed11112.github.io/why_elsahm/';
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            // Handle error
          },
        ),
      )
      ..loadRequest(Uri.parse(whyChooseUsUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarBlue,
        title: const Text(
          'لماذا تختار شركة السهم؟',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
