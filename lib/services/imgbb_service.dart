import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '/pages/config/api.dart';

class ImgbbService {
  static const String apiKey = ApiConfig.imagesApiKey;
  static const String apiUrl = 'https://api.imgbb.com/1/upload';

  static Future<String> uploadImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'key': apiKey,
        'image': base64Image,
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['data']['url'];
    } else {
      throw Exception('Failed to upload image');
    }
  }
}