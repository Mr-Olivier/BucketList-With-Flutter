import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart'; // Add this package for date formatting

class CompletedItem extends StatelessWidget {
  final Map item;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const CompletedItem({
    super.key,
    required this.item,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Get item data
    final String title = item['item'] ?? "Untitled";
    final String imageUrl = item['image'] ?? "";
    final String category = item['category'] ?? "Other";

    // Try to get the completion date
    DateTime? completedDate;
    if (item['updatedAt'] != null) {
      try {
        completedDate = DateTime.parse(item['updatedAt']);
      } catch (e) {
        // If date parsing fails, just leave it null
      }
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
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Achievement banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  "Achievement Unlocked!",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (completedDate != null) ...[
                  Spacer(),
                  Text(
                    "Completed: ${DateFormat('MMM d, yyyy').format(completedDate)}",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),

          // Content section
          ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: ClipOval(
                child:
                    imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) =>
                                  Center(child: CircularProgressIndicator()),
                          errorWidget:
                              (context, url, error) => Center(
                                child: Icon(categoryIcon, color: Colors.grey),
                              ),
                        )
                        : Center(child: Icon(categoryIcon, color: Colors.grey)),
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                decoration: TextDecoration.lineThrough,
                decorationColor: Colors.green,
                decorationThickness: 2,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(categoryIcon, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(category),
                ],
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Restore button
                OutlinedButton.icon(
                  onPressed: onRestore,
                  icon: Icon(Icons.restore),
                  label: Text("RESTORE"),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blue),
                    foregroundColor: Colors.blue,
                  ),
                ),
                SizedBox(width: 8),
                // Delete button
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline),
                  label: Text("DELETE"),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
