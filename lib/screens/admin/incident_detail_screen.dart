import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../models/incident_model.dart';

class IncidentDetailScreen extends StatelessWidget {
  final IncidentModel incident;

  const IncidentDetailScreen({super.key, required this.incident});

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('incidents')
          .doc(incident.id)
          .update({'status': newStatus});

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Status updated to $newStatus")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Incident Details")),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            if (incident.photoUrl.isNotEmpty)
              Image.network(
                incident.photoUrl,
                height: 300,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  height: 300,
                  color: Colors.grey,
                  child: const Center(child: Text("Error loading image")),
                ),
              )
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image_not_supported, size: 50),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(incident.type),
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        labelStyle: const TextStyle(color: AppColors.primary),
                      ),
                      Chip(
                        label: Text(incident.status),
                        backgroundColor: _getStatusColor(
                          incident.status,
                        ).withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    "Location:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(incident.address),
                  const SizedBox(height: 8),

                  const Text(
                    "Coordinates:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text("${incident.latitude}, ${incident.longitude}"),
                  const SizedBox(height: 16),

                  const Text(
                    "Description:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    incident.description.isEmpty
                        ? "No description provided."
                        : incident.description,
                  ),
                ],
              ),
            ),

            const Divider(),

            // Admin Actions
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Admin Actions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (incident.status == 'Pending')
                    ElevatedButton.icon(
                      icon: const Icon(Icons.emergency),
                      label: const Text("DISPATCH RESPONDERS"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _updateStatus(context, 'Responding'),
                    ),

                  const SizedBox(height: 8),

                  if (incident.status != 'Resolved')
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text("MARK AS RESOLVED"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _updateStatus(context, 'Resolved'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'Responding') return Colors.blue;
    if (status == 'Resolved') return Colors.green;
    return Colors.orange;
  }
}
