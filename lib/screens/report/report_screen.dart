import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloudinary_service.dart';
import '../../models/incident_model.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  File? _imageFile;
  String _selectedType = 'Fire';
  bool _isLoading = false;
  Position? _currentPosition;
  String _address = "Fetching location...";

  final List<String> _incidentTypes = [
    'Fire',
    'Medical',
    'Police',
    'Crash',
    'Other',
  ];
  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // 1. Get Location
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _address = "Location services disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _address = "Location permissions denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _address = "Location permissions permanently denied.");
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        // In a real app, use Geocoding package to get address.
        // For MVP, we'll just show coords.
        _address =
            "${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}";
      });
    } catch (e) {
      setState(() => _address = "Error fetching location");
    }
  }

  // 2. Pick Image
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 3. Submit Report
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please attach a photo of the incident.")),
      );
      return;
    }
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Waiting for location... Try again shortly."),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthService>().currentUser;
      if (user == null) throw Exception("User not logged in");

      // A. Upload Image
      final imageUrl = await _cloudinaryService.uploadImage(_imageFile!);
      if (imageUrl == null) throw Exception("Image upload failed");

      // B. Create Incident Object
      final String incidentId = const Uuid().v4();
      final incident = IncidentModel(
        id: incidentId,
        reporterId: user.uid,
        type: _selectedType,
        description: _descriptionController.text.trim(),
        photoUrl: imageUrl,
        folder: 'sentinel',
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        address: _address, // Ideally reverse geocoded
        status: 'Pending',
        timestamp: DateTime.now(),
      );

      // C. Save to Firestore
      await FirebaseFirestore.instance
          .collection('incidents')
          .doc(incidentId)
          .set(incident.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Report Submitted Successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report Incident")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Section
              GestureDetector(
                onTap: () => _pickImage(ImageSource.camera),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageFile == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: Colors.grey,
                            ),
                            Text("Tap to take photo"),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Location Section
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                  ),
                  title: Text(_address),
                  subtitle: const Text("Current Location"),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _determinePosition,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Type Dropdown
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: "Incident Type",
                  border: OutlineInputBorder(),
                ),
                items: _incidentTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Description (Optional)",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "SUBMIT REPORT",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
