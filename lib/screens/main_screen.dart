import 'package:bucketlist/screens/add_screen.dart';
import 'package:bucketlist/screens/view_screen.dart';
import 'package:bucketlist/screens/completed_screen.dart'; // New screen for completed items
import 'package:bucketlist/widgets/bucket_list_item.dart'; // New custom widget
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bucketlist/utils/constants.dart'; // For app colors and styles

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<dynamic> bucketListData = [];
  bool isLoading = false;
  bool isError = false;
  String searchQuery = ""; // For search functionality

  // Sort options
  final List<String> _sortOptions = [
    "Default",
    "Cost: Low to High",
    "Cost: High to Low",
    "Alphabetical",
  ];
  String _currentSort = "Default";

  // Get data from Firebase
  Future<void> getData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get data from Firebase
      Response response = await Dio().get(
        "${dotenv.env['FIREBASE_URL']}/bucketlist.json",
      );

      // Process the response
      if (response.data == null) {
        bucketListData = [];
      } else if (response.data is Map) {
        // Convert Map to List with indices
        bucketListData = [];
        response.data.forEach((key, value) {
          if (value != null) {
            value['key'] = key; // Store the Firebase key
            bucketListData.add(value);
          }
        });
      } else {
        bucketListData = response.data;
      }

      isLoading = false;
      isError = false;
      setState(() {});
    } catch (e) {
      print("Error fetching data: $e");
      isLoading = false;
      isError = true;
      setState(() {});
    }
  }

  @override
  void initState() {
    getData();
    super.initState();
  }

  // Apply sorting to the list
  List<dynamic> getSortedList(List<dynamic> list) {
    switch (_currentSort) {
      case "Cost: Low to High":
        return List.from(list)..sort((a, b) {
          double aCost = double.tryParse(a?['cost']?.toString() ?? '0') ?? 0;
          double bCost = double.tryParse(b?['cost']?.toString() ?? '0') ?? 0;
          return aCost.compareTo(bCost);
        });
      case "Cost: High to Low":
        return List.from(list)..sort((a, b) {
          double aCost = double.tryParse(a?['cost']?.toString() ?? '0') ?? 0;
          double bCost = double.tryParse(b?['cost']?.toString() ?? '0') ?? 0;
          return bCost.compareTo(aCost);
        });
      case "Alphabetical":
        return List.from(list)..sort((a, b) {
          return (a?['item'] ?? "").toString().compareTo(
            (b?['item'] ?? "").toString(),
          );
        });
      default:
        return list;
    }
  }

  // Error widget with retry button
  Widget errorWidget({required String errorText}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning, size: 60, color: Colors.amber),
          SizedBox(height: 16),
          Text(errorText, style: TextStyle(fontSize: 16)),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: getData,
            icon: Icon(Icons.refresh),
            label: Text("Try again"),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Empty state widget when no data
  Widget emptyStateWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.format_list_bulleted, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            "Your bucket list is empty",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "Add your first dream by tapping the + button",
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _navigateToAddScreen();
            },
            icon: Icon(Icons.add),
            label: Text("Add First Item"),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Bucket list items widget
  Widget listDataWidget() {
    // Filter out completed items
    List<dynamic> filteredList =
        bucketListData
            .where(
              (element) =>
                  !(element?["completed"] ?? false) &&
                  (searchQuery.isEmpty ||
                      (element?["item"] ?? "")
                          .toString()
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase())),
            )
            .toList();

    // Sort the list
    filteredList = getSortedList(filteredList);

    // If list is empty, show empty state
    if (filteredList.isEmpty) {
      return emptyStateWidget();
    }

    // Otherwise show the list
    return ListView.builder(
      padding: EdgeInsets.only(bottom: 80), // Add padding for FAB
      itemCount: filteredList.length,
      itemBuilder: (BuildContext context, int index) {
        final item = filteredList[index];
        if (item == null || !(item is Map)) return SizedBox();

        // Get the original index/key
        final String itemKey = item['key'] ?? index.toString();

        // Use custom widget for list item
        return BucketListItem(
          item: item,
          onTap: () => _navigateToViewScreen(itemKey, item),
        );
      },
    );
  }

  // Navigate to view screen
  void _navigateToViewScreen(String itemKey, Map item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ViewItemScreen(
            itemKey: itemKey,
            title: item['item'] ?? "",
            image: item['image'] ?? "",
            cost: item['cost']?.toString() ?? "",
            description: item['description'] ?? "",
          );
        },
      ),
    ).then((value) {
      if (value == "refresh") {
        getData();
      }
    });
  }

  // Navigate to add screen
  void _navigateToAddScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return AddBucketListScreen();
        },
      ),
    ).then((value) {
      if (value == "refresh") {
        getData();
      }
    });
  }

  // Navigate to completed items screen
  void _navigateToCompletedScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return CompletedScreen(bucketListData: bucketListData);
        },
      ),
    ).then((value) {
      if (value == "refresh") {
        getData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Main app bar
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "My Bucket List",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Completed items button
          IconButton(
            icon: Icon(Icons.check_circle_outline),
            tooltip: "Completed Items",
            onPressed: _navigateToCompletedScreen,
          ),
          // Refresh button
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: getData,
          ),
          // Sort menu
          PopupMenuButton<String>(
            icon: Icon(Icons.sort),
            tooltip: "Sort",
            onSelected: (String value) {
              setState(() {
                _currentSort = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return _sortOptions.map((String option) {
                return PopupMenuItem<String>(
                  value: option,
                  child: Row(
                    children: [
                      Icon(
                        _currentSort == option
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color:
                            _currentSort == option
                                ? Theme.of(context).primaryColor
                                : null,
                      ),
                      SizedBox(width: 8),
                      Text(option),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),

      // Search bar
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search your bucket list...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),

          // Main list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await getData();
              },
              child:
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : isError
                      ? errorWidget(errorText: "Couldn't connect to the server")
                      : listDataWidget(),
            ),
          ),
        ],
      ),

      // FAB for adding new items
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddScreen,
        elevation: 4,
        tooltip: "Add New Item",
        child: Icon(Icons.add),
      ),
    );
  }
}
