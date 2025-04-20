import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';

class EditScreen extends StatefulWidget {
  final String itemKey;
  final String title;
  final String image;
  final String cost;
  final String description;

  EditScreen({
    super.key,
    required this.itemKey,
    required this.title,
    required this.image,
    required this.cost,
    required this.description,
  });

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  // Text controllers
  late TextEditingController itemText;
  late TextEditingController costText;
  late TextEditingController descriptionText;

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // For image handling
  File? _imageFile;
  bool _isImageChanged = false;
  bool _isUploading = false;
  String? _base64Image;
  bool _isBase64Image = false;
  String _currentImage = "";

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

  @override
  void initState() {
    super.initState();

    // Initialize text controllers with current values
    itemText = TextEditingController(text: widget.title);
    costText = TextEditingController(text: widget.cost);
    descriptionText = TextEditingController(text: widget.description);
    _currentImage = widget.image;

    // Check if the existing image is a base64 image
    if (widget.image.startsWith('data:image')) {
      _base64Image = widget.image;
      _isBase64Image = true;
    }

    // Fetch full item data
    _fetchItemData();
  }

  @override
  void dispose() {
    // Dispose text controllers
    itemText.dispose();
    costText.dispose();
    descriptionText.dispose();
    super.dispose();
  }

  // Fetch full item data
  Future<void> _fetchItemData() async {
    try {
      Response response = await Dio().get(
        "${dotenv.env['FIREBASE_URL']}/bucketlist/${widget.itemKey}.json",
      );

      if (response.data != null && response.data is Map) {
        setState(() {
          _selectedCategory = response.data['category'] ?? "Travel";
          _selectedPriority = response.data['priority'] ?? "Medium";
        });
      }
    } catch (e) {
      print("Error fetching item data: $e");
    }
  }

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
          _isImageChanged = true;
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
        _isBase64Image = true;
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
    final urlController = TextEditingController(
      text: _isBase64Image ? '' : _currentImage,
    );

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
                    _base64Image = null;
                    _isBase64Image = false;
                    _imageFile = null;
                    _isImageChanged = true;
                    _currentImage = urlController.text;
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

  // Update data in Firebase
  Future<void> updateData() async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Prepare image data
      String imageData;

      if (_isImageChanged) {
        if (_base64Image != null) {
          imageData = _base64Image!;
        } else {
          imageData = _currentImage; // Use URL if base64 is null
        }
      } else {
        imageData = widget.image; // Keep original if not changed
      }

      // Prepare data
      Map<String, dynamic> data = {
        "item": itemText.text,
        "cost": costText.text,
        "image": imageData,
        "description": descriptionText.text,
        "category": _selectedCategory,
        "priority": _selectedPriority,
        "updatedAt": DateTime.now().toIso8601String(),
      };

      // Send data to Firebase
      Response response = await Dio().patch(
        "${dotenv.env['FIREBASE_URL']}/bucketlist/${widget.itemKey}.json",
        data: data,
      );

      // Show success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Changes saved successfully")));

      // Return to previous screen
      Navigator.pop(context, "refresh");
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      // Show error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error updating item: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Bucket List Item"),
        elevation: 0,
        actions: [
          // Save button
          TextButton.icon(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                updateData();
              }
            },
            icon: Icon(Icons.save),
            label: Text("SAVE"),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
      body: _isUploading ? _buildUploadingState() : _buildFormState(),
    );
  }

  // Loading state while uploading
  Widget _buildUploadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("Saving changes...", style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // Main form UI
  Widget _buildFormState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image picker section
              Text(
                "Change Image",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                controller: itemText,
                decoration: InputDecoration(
                  labelText: "Bucket List Item",
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
                controller: costText,
                decoration: InputDecoration(
                  labelText: "Estimated cost",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                controller: descriptionText,
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      updateData();
                    }
                  },
                  icon: Icon(Icons.save),
                  label: Text("SAVE CHANGES"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
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
    } else if (_currentImage.isNotEmpty) {
      // Show network image
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          _currentImage,
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
