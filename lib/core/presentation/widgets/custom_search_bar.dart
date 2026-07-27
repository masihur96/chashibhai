import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final String hintText;
  final Function(String) onChanged;

  const CustomSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      hintText: hintText,
      leading: const Padding(
        padding: EdgeInsets.only(left: 8.0),
        child: Icon(Icons.search, color: Colors.grey),
      ),
      onChanged: onChanged,
      elevation: WidgetStateProperty.all(1),
      backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surface),
    );
  }
}
