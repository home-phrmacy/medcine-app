import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_scanner_service.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final ImagePicker _picker = ImagePicker();
  final GeminiScannerService _scanner = GeminiScannerService();

  XFile? pickedImage;
  bool isScanning = false;

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController categoryCtrl = TextEditingController();
  final TextEditingController ingredientCtrl = TextEditingController();
  final TextEditingController storageCtrl = TextEditingController();

  Future<void> _pickAndScan(ImageSource source) async {
    final image = await _picker.pickImage(source: source);
    if (image == null) return;

    setState(() {
      pickedImage = image;
      isScanning = true;
    });

    final extracted = await _scanner.scanMedicinePackage(image);

    setState(() {
      isScanning = false;
      nameCtrl.text = extracted['name'] ?? '';
      categoryCtrl.text = extracted['category'] ?? '';
      ingredientCtrl.text = extracted['active_ingredient'] ?? '';
      storageCtrl.text = extracted['storage'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F1ED),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Add Medicine", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              if (pickedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(File(pickedImage!.path), height: 160, fit: BoxFit.cover),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickAndScan(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Camera"),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE57373), foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickAndScan(ImageSource.gallery),
                      icon: const Icon(Icons.photo),
                      label: const Text("Gallery"),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF5EFEB), foregroundColor: const Color(0xFF2A272A)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isScanning) const Center(child: CircularProgressIndicator(color: Color(0xFFE57373))),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Medicine Name")),
              const SizedBox(height: 8),
              TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: "Category (e.g. Painkiller)")),
              const SizedBox(height: 8),
              TextField(controller: ingredientCtrl, decoration: const InputDecoration(labelText: "Active Ingredient")),
              const SizedBox(height: 8),
              TextField(controller: storageCtrl, decoration: const InputDecoration(labelText: "Storage Instructions")),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Medicine Saved Successfully!")));
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E6335), foregroundColor: Colors.white),
                child: const Text("Save to Cabinet"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}