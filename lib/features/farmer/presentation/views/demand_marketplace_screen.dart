import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/presentation/widgets/demand_card.dart';
import '../../../../core/presentation/widgets/custom_search_bar.dart';
import '../../../../core/presentation/widgets/empty_state_widget.dart';
import '../../../buyer/presentation/state/demand_provider.dart';
import 'package:intl/intl.dart';
import './demand_details_screen.dart';

class DemandMarketplaceScreen extends StatelessWidget {
  const DemandMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final demands = context.watch<DemandProvider>().demands;
    final currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Demand Marketplace', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Semantics(
              label: 'Search Demands',
              child: CustomSearchBar(
                hintText: 'Search by crop or location...',
                onChanged: (value) {},
              ),
            ),
          ),
          Expanded(
            child: demands.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.campaign_outlined,
                    title: 'No Demands Found',
                    subtitle: 'Buyers have not posted any new demands yet.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: demands.length,
                    itemBuilder: (context, index) {
                      return Semantics(
                        label: 'Demand Card ${index + 1}',
                        child: DemandCard(
                          demand: demands[index],
                          currencyFormat: currencyFormat,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DemandDetailsScreen(demand: demands[index]),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
