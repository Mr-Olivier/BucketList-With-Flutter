import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Add this package

class BucketListItem extends StatelessWidget {
  final Map item;
  final VoidCallback onTap;

  const BucketListItem({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Get item data
    final String title = item['item'] ?? "Untitled";
    final String imageUrl = item['image'] ?? "";
    final String cost = item['cost']?.toString() ?? "";
    final String category = item['category'] ?? "Other";
    final String priority = item['priority'] ?? "Medium";

    // Priority color
    Color priorityColor;
    switch (priority) {
      case "High":
        priorityColor = Colors.red;
        break;
      case "Medium":
        priorityColor = Colors.orange;
        break;
      case "Low":
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    // Category icon
    IconData categoryIcon;
    switch (category) {
      case "Travel":
        categoryIcon = Icons.flight;
        break;
      case "Adventure":
        categoryIcon = Icons.hiking;
        break;
      case "Learning":
        categoryIcon = Icons.school;
        break;
      case "Career":
        categoryIcon = Icons.work;
        break;
      case "Personal":
        categoryIcon = Icons.person;
        break;
      case "Financial":
        categoryIcon = Icons.account_balance;
        break;
      case "Health":
        categoryIcon = Icons.favorite;
        break;
      default:
        categoryIcon = Icons.star;
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  // Item image
                  imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              height: 160,
                              color: Colors.grey[300],
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              height: 160,
                              color: Colors.grey[300],
                              child: Icon(Icons.error),
                            ),
                      )
                      : Container(
                        height: 160,
                        color: Colors.grey[300],
                        width: double.infinity,
                        child: Icon(
                          categoryIcon,
                          size: 50,
                          color: Colors.grey[500],
                        ),
                      ),

                  // Priority indicator
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.priority_high,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            priority,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Category badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(categoryIcon, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            category,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),

                  // Cost
                  if (cost.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 18,
                          color: Colors.green[700],
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Estimated: \$$cost",
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
