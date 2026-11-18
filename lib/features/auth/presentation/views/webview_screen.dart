import 'package:flutter/material.dart';

class WebviewScreen extends StatelessWidget {
  final String title;
  final String url;

  const WebviewScreen({
    super.key,
    this.title = 'Terms & Conditions',
    this.url = 'https://chashibhai.com/terms',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.public, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Opening $url',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Webview component placeholder',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
