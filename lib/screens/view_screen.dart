import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:share_plus/share_plus.dart'; // For sharing functionality
import 'package:bucketlist/screens/edit_screen.dart'; // Edit screen

class ViewItemScreen extends StatefulWidget {
  final String itemKey;
  final String title;
  final String image;
  final String cost;
  final String description;

  ViewItemScreen({
    super.key,
    required this.itemKey,
    required this.title,
    required this.image,
    required this.cost,
    this.description = "",
  });

  @override
  State<ViewItemScreen> createState() => _ViewItemScreenState();
}

class _ViewItemScreenState extends State<ViewItemScreen> {
  bool _isLoading = false;

  // Delete the item
  Future<void> deleteData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Response response = await Dio().delete(
        "${dotenv.env['FIREBASE_URL']}/bucketlist/${widget.itemKey}.json",
      );

      // Display success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Item deleted successfully")));

      // Return to previous screen
      Navigator.pop(context, "refresh");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Display error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting item: $e")));
    }
  }

  // Mark item as complete
  Future<void> markAsComplete() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> data = {
        "completed": true,
        "completedAt": DateTime.now().toIso8601String(),
      };

      Response response = await Dio().patch(
        "${dotenv.env['FIREBASE_URL']}/bucketlist/${widget.itemKey}.json",
        data: data,
      );

      // Display success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Marked as complete! Congratulations! 🎉"),
          backgroundColor: Colors.green,
        ),
      );

      // Return to previous screen
      Navigator.pop(context, "refresh");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Display error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error updating item: $e")));
    }
  }

  // Navigate to edit screen
  void _navigateToEditScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditScreen(
              itemKey: widget.itemKey,
              title: widget.title,
              image: widget.image,
              cost: widget.cost,
              description: widget.description,
            ),
      ),
    ).then((value) {
      if (value == "refresh") {
        Navigator.pop(context, "refresh");
      }
    });
  }

  // Share bucket list item
  void _shareItem() {
    String costText =
        widget.cost.isNotEmpty ? "Estimated cost: \$${widget.cost}\n" : "";

    String descriptionText =
        widget.description.isNotEmpty ? "${widget.description}\n" : "";

    Share.share(
      "🔥 From my Bucket List: ${widget.title}\n"
      "${descriptionText}"
      "${costText}"
      "I'm going to make this happen! 💪",
    );
  }

  // Show delete confirmation dialog
  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete from bucket list?"),
          content: Text(
            "Are you sure you want to delete '${widget.title}'? This action cannot be undone.",
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
                deleteData();
              },
              child: Text("DELETE", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Show complete confirmation dialog
  void _showCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Complete this item?"),
          content: Text(
            "Mark '${widget.title}' as complete? This will move it to your completed items list.",
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
                markAsComplete();
              },
              child: Text("COMPLETE", style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  // Get image decoration based on type (base64 or URL)
  DecorationImage _getImageDecoration() {
    // Check if image is base64 encoded
    if (widget.image.startsWith('data:image')) {
      try {
        // Extract the base64 data after the comma
        final base64Data = widget.image.split(',')[1];
        final imageBytes = base64Decode(base64Data);

        return DecorationImage(
          fit: BoxFit.cover,
          image: MemoryImage(imageBytes),
        );
      } catch (e) {
        // Fallback to placeholder for invalid base64
        return DecorationImage(
          fit: BoxFit.cover,
          image: NetworkImage(
            'https://via.placeholder.com/800x600?text=No+Image',
          ),
        );
      }
    }
    // Check if it's a URL
    else if (widget.image.isNotEmpty) {
      return DecorationImage(
        fit: BoxFit.cover,
        image: NetworkImage(widget.image),
      );
    }
    // No image
    else {
      return DecorationImage(
        fit: BoxFit.cover,
        image: NetworkImage(
          'https://via.placeholder.com/800x600?text=No+Image',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          // Edit button
          IconButton(
            icon: Icon(Icons.edit),
            tooltip: "Edit",
            onPressed: _navigateToEditScreen,
          ),
          // More options menu
          PopupMenuButton(
            icon: Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 1) {
                _showDeleteDialog();
              } else if (value == 2) {
                _showCompleteDialog();
              } else if (value == 3) {
                _shareItem();
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: 3,
                  child: Row(
                    children: [
                      Icon(Icons.share, color: Colors.blue),
                      SizedBox(width: 8),
                      Text("Share"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 2,
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text("Mark as complete"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Delete"),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),

      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero image
                    Stack(
                      children: [
                        Container(
                          height: 300,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            image: _getImageDecoration(),
                          ),
                        ),
                        // Gradient overlay for better text visibility
                        Container(
                          height: 300,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        // Title overlay at bottom of image
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.black.withOpacity(0.5),
                                  offset: Offset(2.0, 2.0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Content section
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cost indicator
                          if (widget.cost.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.attach_money,
                                    size: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Estimated cost: \$${widget.cost}",
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(height: 20),

                          // Description
                          if (widget.description.isNotEmpty) ...[
                            Text(
                              "Description",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              widget.description,
                              style: TextStyle(fontSize: 16, height: 1.5),
                            ),
                            SizedBox(height: 24),
                          ],

                          // Tips and ideas section
                          Text(
                            "Tips & Ideas",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.lightbulb,
                                        color: Colors.amber,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Planning tips",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Consider setting a specific date to accomplish this goal. Research the best time for this activity and start saving money in advance.",
                                    style: TextStyle(height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 40),

                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _showCompleteDialog,
                                  icon: Icon(Icons.check_circle_outline),
                                  label: Text("MARK AS COMPLETE"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                  ),
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
