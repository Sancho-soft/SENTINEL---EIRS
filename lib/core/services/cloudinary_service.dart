import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  // We use direct HTTP upload for unsigned presets usually.

  final String _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  final String _uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  Future<String?> uploadImage(
    File imageFile, {
    String folder = 'sentinel',
  }) async {
    if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
      debugPrint("Cloudinary Config Missing");
      return null;
    }

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] =
          folder // Requesting specific folder
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);

        return jsonMap['secure_url'];
      } else {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        debugPrint(
          "Cloudinary Upload Failed: ${response.statusCode} - $responseString",
        );
        return null;
      }
    } catch (e) {
      debugPrint("Error uploading to Cloudinary: $e");
      return null;
    }
  }
}
