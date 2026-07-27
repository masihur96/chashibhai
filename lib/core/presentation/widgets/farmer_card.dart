import 'package:flutter/material.dart';
import './rating_widget.dart';

class FarmerCard extends StatelessWidget {
  final String farmerName;
  final double rating;
  final int reviews;
  final String? profileImageUrl;
  final VoidCallback? onTap;

  const FarmerCard({
    super.key,
    required this.farmerName,
    required this.rating,
    required this.reviews,
    this.profileImageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
                child: profileImageUrl == null 
                  ? Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimaryContainer)
                  : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farmerName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    RatingWidget(rating: rating, reviewCount: reviews),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
