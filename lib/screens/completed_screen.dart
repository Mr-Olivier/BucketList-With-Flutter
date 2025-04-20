import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bucketlist/widgets/completed_item.dart'; // Custom widget for completed items

class CompletedScreen extends StatefulWidget {
  final List<dynamic> bucketListData;

  CompletedScreen({super.key, required this.bucketListData});

  @override
  State<CompletedScreen> createState() => _CompletedScreenState();
}

class _CompletedScreenState extends State<CompletedScreen> {
  late List<dynamic> completedItems;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Filter completed items
    _filterCompletedItems();
  }

  // Filter completed items from the bucket list data
  void _filterCompletedItems() {
    completedItems =
        widget.bucketListData
            .where((element) => element?["completed"] == true)
            .toList();
  }

  // Move item back to bucket list (mark as incomplete)
  Future<void> _markAsIncomplete(String itemKey) async {
    setState(() {
      isLoading = true;
    });

    try {
      Map<String, dynamic> data = {"completed": false};

      Response response = await Dio().patch(
        "${dotenv.env['FIREBASE_URL']}/bucketlist/${itemKey}.json",
        data: data,
      );

      // Remove item from list
      setState(() {
        completedItems.removeWhere((item) => item['key'] == itemKey);
        isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Item moved back to your bucket list")),
      );

      // Return refresh to main screen
      Navigator.pop(context, "refresh");
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error updating item: $e")));
    }
  }

  // Delete completed item
  Future<void> _deleteItem(String itemKey) async {
    setState(() {
      isLoading = true;
    });

    try {
      Response response = await Dio().delete(
        "${dotenv.env['FIREBASE_URL']}/bucketlist/${itemKey}.json",
      );

      // Remove item from list
      setState(() {
        completedItems.removeWhere((item) => item['key'] == itemKey);
        isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Item deleted")));

      // Return refresh to main screen
      Navigator.pop(context, "refresh");
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting item: $e")));
    }
  }

  // Show delete confirmation dialog
  void _showDeleteDialog(String itemKey, String itemTitle) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete this achievement?"),
          content: Text(
            "Are you sure you want to delete '$itemTitle' from your completed items?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("CANCEL"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteItem(itemKey);
              },
              child: Text("DELETE", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Completed Items"), elevation: 0),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : _buildCompletedList(),
    );
  }

  Widget _buildCompletedList() {
    if (completedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              "No completed items yet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Your achievements will appear here",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: completedItems.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = completedItems[index];
        if (item == null || !(item is Map)) return SizedBox();

        // Get the item key
        final String itemKey = item['key'] ?? index.toString();

        return CompletedItem(
          item: item,
          onRestore: () {
            _markAsIncomplete(itemKey);
          },
          onDelete: () {
            _showDeleteDialog(itemKey, item['item'] ?? "");
          },
        );
      },
    );
  }
}
