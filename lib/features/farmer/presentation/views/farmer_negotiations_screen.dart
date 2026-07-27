import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/presentation/widgets/empty_state_widget.dart';

class FarmerNegotiationsScreen extends StatelessWidget {
  const FarmerNegotiationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Negotiations', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body:  Center(
        child: Semantics(
          label: 'Empty Negotiations State',
          child: EmptyStateWidget(
            icon: Icons.handshake_outlined,
            title: 'No Active Negotiations',
            subtitle: 'You are not negotiating with any buyers right now.',
          ),
        ),
      ),
    );
  }
}
