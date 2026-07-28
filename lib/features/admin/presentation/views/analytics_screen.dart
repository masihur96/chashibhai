import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 32 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform Analytics', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Visualize growth and engagement metrics over time.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          const SizedBox(height: 32),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildChartContainer(context, 'Monthly Gross Merchandise Value (GMV)', _buildMockBarChart()),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: _buildChartContainer(context, 'User Demographics', _buildMockPieChart(context)),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildChartContainer(context, 'Monthly Gross Merchandise Value (GMV)', _buildMockBarChart()),
                const SizedBox(height: 24),
                _buildChartContainer(context, 'User Demographics', _buildMockPieChart(context)),
              ],
            ),
          const SizedBox(height: 32),
          _buildChartContainer(context, 'Active Orders vs Completed Orders (Trailing 7 Days)', _buildMockLineChart()),
        ],
      ),
    );
  }

  Widget _buildChartContainer(BuildContext context, String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          SizedBox(height: 250, child: chart),
        ],
      ),
    );
  }

  Widget _buildMockBarChart() {
    final values = [0.2, 0.4, 0.3, 0.6, 0.8, 1.0, 0.7];
    final labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 32,
                  height: 200 * values[index],
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(labels[index], style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMockPieChart(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: CircularProgressIndicator(
                value: 0.65, // Mock value representing farmers vs buyers
                strokeWidth: 24,
                backgroundColor: Colors.blue.shade200,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Text('Users', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(Theme.of(context).colorScheme.primary, 'Farmers (65%)'),
            const SizedBox(width: 24),
            _buildLegendItem(Colors.blue.shade200, 'Buyers (35%)'),
          ],
        ),
      ],
    );
  }

  Widget _buildMockLineChart() {
    final values = [0.5, 0.6, 0.5, 0.8, 0.7, 0.9, 0.6];
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 12,
                  height: 200 * values[index],
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(labels[index], style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
