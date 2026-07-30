import 'package:flutter/material.dart';

import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/status_badge.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final List<AppUser> _mockUsers = [
    AppUser(
      id: 'U1001',
      name: 'Rahim Uddin',
      role: UserRole.farmer,
      phone: '01711223344',
      rating: 4.8,
      isVerified: true,
    ),
    AppUser(
      id: 'U1002',
      name: 'Karim Traders',
      role: UserRole.buyer,
      phone: '01811223344',
      rating: 4.5,
      isVerified: true,
    ),
    AppUser(
      id: 'U1003',
      name: 'Mofizur Rahman',
      role: UserRole.farmer,
      phone: '01911223344',
      rating: 0.0,
      isVerified: false,
    ),
    AppUser(
      id: 'U1004',
      name: 'Fresh Grocers',
      role: UserRole.buyer,
      phone: '01611223344',
      rating: 4.9,
      isVerified: true,
    ),
    AppUser(
      id: 'U1005',
      name: 'Jalil Mia',
      role: UserRole.farmer,
      phone: '01511223344',
      rating: 3.5,
      isVerified: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _mockUsers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final user = _mockUsers[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.teal.shade50,
                                child: Text(
                                  user.name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.teal.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                              SizedBox(height: 5),

                              StatusBadge(
                                label: user.isVerified
                                    ? 'VERIFIED'
                                    : 'PENDING KYC',
                                variant: user.isVerified
                                    ? BadgeVariant.success
                                    : BadgeVariant.neutral,
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                                StatusBadge(
                                  label: user.role
                                      .toString()
                                      .split('.')
                                      .last
                                      .toUpperCase(),
                                  variant: user.role == UserRole.farmer
                                      ? BadgeVariant.info
                                      : BadgeVariant.warning,
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 4,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.phone_outlined,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          user.phone,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.fingerprint,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'ID: ${user.id}',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (!user.isVerified)
                              OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('KYC Approved (Mocked)'),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 18,
                                ),
                                label: const Text('Approve'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green.shade700,
                                  side: BorderSide(
                                    color: Colors.green.shade200,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('User Suspended (Mocked)'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.block, size: 18),
                              label: const Text('Suspend'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(color: Colors.red.shade200),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
