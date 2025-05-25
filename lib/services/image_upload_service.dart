import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ImageUploadService {
  // API Keys
  static const String _imgbbApiKey = 'd4c80caf18ac57a20be196713f4245c2';
  static const String _freeimageApiKey = '6d207e02198a847aa98d0a2a901485a5';
  
  // Upload endpoints
  static const String _imgbbUploadUrl = 'https://api.imgbb.com/1/upload';
  static const String _freeimageUploadUrl = 'https://freeimage.host/api/1/upload';
  
  /// Uploads an image to Imgbb, with fallback to Freeimage.host if Imgbb fails
  /// Returns the URL of the uploaded image or null if both uploads fail
  static Future<String?> uploadImage(File imageFile) async {
    try {
      // Try Imgbb first
      final String? imgbbUrl = await _uploadToImgbb(imageFile);
      if (imgbbUrl != null) {
        return imgbbUrl;
      }
      
      // If Imgbb fails, try Freeimage.host as fallback
      final String? freeimageUrl = await _uploadToFreeimage(imageFile);
      return freeimageUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }
  
  /// Uploads an image to Imgbb
  /// Returns the URL of the uploaded image or null if upload fails
  static Future<String?> _uploadToImgbb(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final response = await http.post(
        Uri.parse('$_imgbbUploadUrl?key=$_imgbbApiKey'),
        body: {
          'image': base64Image,
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return responseData['data']['url'];
        }
      }
      
      debugPrint('Imgbb upload failed with status: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error uploading to Imgbb: $e');
      return null;
    }
  }
  
  /// Uploads an image to Freeimage.host
  /// Returns the URL of the uploaded image or null if upload fails
  static Future<String?> _uploadToFreeimage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final response = await http.post(
        Uri.parse(_freeimageUploadUrl),
        body: {
          'key': _freeimageApiKey,
          'source': base64Image,
          'format': 'json',
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status_code'] == 200 && responseData['image'] != null) {
          return responseData['image']['url'];
        }
      }
      
      debugPrint('Freeimage upload failed with status: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error uploading to Freeimage: $e');
      return null;
    }
  }
} 