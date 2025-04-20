import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';

class AddBucketListScreen extends StatefulWidget {
  const AddBucketListScreen({super.key});

  @override
  State<AddBucketListScreen> createState() => _AddBucketListScreenState();
}

class _AddBucketListScreenState extends State<AddBucketListScreen> {
  // Text controllers
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // For image handling
  File? _imageFile;
  String? _base64Image;
  String? _imageUrl;
  bool _isLoading = false;

  // Categories for bucket list items
  final List<String> _categories = [
    "Travel",
    "Adventure",
    "Learning",
    "Career",
    "Personal",
    "Financial",
    "Health",
    "Other",
  ];
  String _selectedCategory = "Travel";

  // Priority levels
  final List<String> _priorities = ["Low", "Medium", "High"];
  String _selectedPriority = "Medium";

  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800, // Reduce image size
        maxHeight: 800,
        imageQuality: 70, // Compress quality
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageUrl = null; // Clear URL if we're using a local image
        });

        // Convert image to base64
        await _convertImageToBase64();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error selecting image: $e")));
    }
  }

  // Convert image to base64
  Future<void> _convertImageToBase64() async {
    if (_imageFile == null) return;

    try {
      // Read file as bytes
      final bytes = await _imageFile!.readAsBytes();

      // Check file size and potentially compress further
      if (bytes.length > 500000) {
        // 500KB
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image is large and may take longer to save")),
        );
      }

      // Encode to base64
      final base64String = base64Encode(bytes);

      // Get file extension for MIME type
      final extension = _imageFile!.path.split('.').last.toLowerCase();
      String mimeType;

      // Set MIME type based on extension
      switch (extension) {
        case 'png':
          mimeType = 'image/png';
          break;
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        default:
          mimeType = 'image/jpeg';
      }

      // Create data URL format
      setState(() {
        _base64Image = 'data:$mimeType;base64,$base64String';
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error processing image: $e")));
    }
  }

  // Show image source dialog
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.link),
                title: Text('Use URL Instead'),
                onTap: () {
                  Navigator.pop(context);
                  _showImageUrlDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Show dialog to enter image URL
  void _showImageUrlDialog() {
    final urlController = TextEditingController(text: _imageUrl);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Image URL'),
          content: TextField(
            controller: urlController,
            decoration: InputDecoration(
              hintText: 'https://example.com/image.jpg',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                if (urlController.text.isNotEmpty) {
                  setState(() {
                    _imageUrl = urlController.text;
                    _imageFile = null;
                    _base64Image = null;
                  });
                }
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Add data to Firebase
  Future<void> addData() async {
    // Check if form is valid
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Determine image source
      String imageData = '';
      if (_base64Image != null) {
        imageData = _base64Image!;
      } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
        imageData = _imageUrl!;
      }

      // Prepare data
      Map<String, dynamic> data = {
        "item": _itemController.text,
        "cost": _costController.text,
        "image": imageData,
        "description": _descriptionController.text,
        "category": _selectedCategory,
        "priority": _selectedPriority,
        "completed": false,
        "createdAt": DateTime.now().toIso8601String(),
      };

      // Send data to Firebase
      Response response = await Dio().post(
        "${dotenv.env['FIREBASE_URL']}/bucketlist.json",
        data: data,
      );

      // Reset form
      _formKey.currentState!.reset();
      _itemController.clear();
      _costController.clear();
      _descriptionController.clear();
      setState(() {
        _imageFile = null;
        _base64Image = null;
        _imageUrl = null;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Item added to your bucket list!"),
          backgroundColor: Colors.green,
        ),
      );

      // Return to previous screen with refresh signal
      Navigator.pop(context, "refresh");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error adding item: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    _itemController.dispose();
    _costController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add to Bucket List"), elevation: 0),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image section
                        Text(
                          "Image",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: _buildImagePreview(),
                          ),
                        ),
                        SizedBox(height: 24),

                        // Item name field
                        TextFormField(
                          controller: _itemController,
                          decoration: InputDecoration(
                            labelText: "What's on your bucket list?",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.star_outline),
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter an item";
                            }
                            if (value.length < 3) {
                              return "Must be at least 3 characters";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Cost field
                        TextFormField(
                          controller: _costController,
                          decoration: InputDecoration(
                            labelText: "Estimated cost",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter an estimated cost";
                            }
                            if (double.tryParse(value) == null) {
                              return "Please enter a valid number";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Description field
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: "Description (optional)",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 3,
                        ),
                        SizedBox(height: 16),

                        // Category dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: "Category",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items:
                              _categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          },
                        ),
                        SizedBox(height: 16),

                        // Priority selection
                        Text(
                          "Priority:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children:
                              _priorities.map((priority) {
                                return Expanded(
                                  child: RadioListTile<String>(
                                    title: Text(priority),
                                    value: priority,
                                    groupValue: _selectedPriority,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedPriority = value!;
                                      });
                                    },
                                  ),
                                );
                              }).toList(),
                        ),
                        SizedBox(height: 24),

                        // Add button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: addData,
                            icon: Icon(Icons.add),
                            label: Text("ADD TO BUCKET LIST"),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  // Handle different image source types
  Widget _buildImagePreview() {
    if (_imageFile != null) {
      // Show local image file
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(_imageFile!, fit: BoxFit.cover),
      );
    } else if (_base64Image != null) {
      // Show base64 image
      try {
        // Extract the base64 data after the comma
        final base64Data = _base64Image!.split(',')[1];
        final imageBytes = base64Decode(base64Data);

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(imageBytes, fit: BoxFit.cover),
        );
      } catch (e) {
        return _buildErrorImageWidget();
      }
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      // Show network image
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          _imageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorImageWidget();
          },
        ),
      );
    } else {
      // Show placeholder for empty image
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate, size: 60, color: Colors.grey[600]),
          SizedBox(height: 8),
          Text(
            "Tap to add an image",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      );
    }
  }

  // Error placeholder for invalid images
  Widget _buildErrorImageWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.broken_image, size: 60, color: Colors.red[300]),
        SizedBox(height: 8),
        Text("Could not load image", style: TextStyle(color: Colors.red[300])),
      ],
    );
  }
}
