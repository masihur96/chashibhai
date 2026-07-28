import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/status_badge.dart';
import '../../../../core/presentation/widgets/custom_buttons.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final List<AppUser> _mockUsers = [
    AppUser(id: 'U1001', name: 'Rahim Uddin', role: UserRole.farmer, phone: '01711223344', rating: 4.8, isVerified: true),
    AppUser(id: 'U1002', name: 'Karim Traders', role: UserRole.buyer, phone: '01811223344', rating: 4.5, isVerified: true),
    AppUser(id: 'U1003', name: 'Mofizur Rahman', role: UserRole.farmer, phone: '01911223344', rating: 0.0, isVerified: false),
    AppUser(id: 'U1004', name: 'Fresh Grocers', role: UserRole.buyer, phone: '01611223344', rating: 4.9, isVerified: true),
    AppUser(id: 'U1005', name: 'Jalil Mia', role: UserRole.farmer, phone: '01511223344', rating: 3.5, isVerified: false),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
              columns: const [
                DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _mockUsers.map((user) {
                return DataRow(
                  cells: [
                    DataCell(Text(user.id, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    DataCell(Text(user.name)),
                    DataCell(
                      StatusBadge(
                        label: user.role.toString().split('.').last.toUpperCase(),
                        variant: user.role == UserRole.farmer ? BadgeVariant.info : BadgeVariant.warning,
                      ),
                    ),
                    DataCell(Text(user.phone)),
                    DataCell(
                      StatusBadge(
                        label: user.isVerified ? 'VERIFIED' : 'PENDING KYC',
                        variant: user.isVerified ? BadgeVariant.success : BadgeVariant.neutral,
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (!user.isVerified)
                            TextButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('KYC Approved (Mocked)')));
                              },
                              icon: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                              label: const Text('Approve', style: TextStyle(color: Colors.green)),
                            ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User Suspended (Mocked)')));
                            },
                            icon: const Icon(Icons.block, size: 16, color: Colors.red),
                            label: const Text('Suspend', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
