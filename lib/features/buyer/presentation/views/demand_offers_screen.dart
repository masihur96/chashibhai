import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/empty_state_widget.dart';

class DemandOffersScreen extends StatelessWidget {
  final DemandPost demand;

  const DemandOffersScreen({super.key, required this.demand});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Offers for ${demand.productName}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: const Center(
        child: Semantics(
          label: 'Empty Offers State',
          child: EmptyStateWidget(
            icon: Icons.local_offer_outlined,
            title: 'No Offers Yet',
            subtitle: 'Farmers have not responded to this demand.',
          ),
        ),
      ),
    );
  }
}
