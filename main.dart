import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ingredient Recognition',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image;
  String? _imageUrl;
  Map<String, dynamic>? _ingredientsData;
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePicture() async {
    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
      await _sendImageToServer(_image!);
    }
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
      await _sendImageToServer(_image!);
    }
  }

  Future<void> _sendImageToServer(File image) async {
    final uri = Uri.parse('http://10.0.2.2:5000/upload-image');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', image.path));
    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      setState(() {
        _imageUrl = responseData['imageUrl'];
        _ingredientsData = responseData['ingredients'];
      });
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Upload Error'),
            content: Text('Server responded with status code: ${response.statusCode}'),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingredient Recognition'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_image != null) Image.file(_image!),
            if (_imageUrl != null) Image.network(_imageUrl!),
            if (_ingredientsData != null) ...[
              const Text('Ingredients:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(jsonEncode(_ingredientsData))
            ],
            ElevatedButton(
              onPressed: _takePicture,
              child: const Text('Take a Picture'),
            ),
            ElevatedButton(
              onPressed: _pickImageFromGallery,
              child: const Text('Upload Image from Gallery'),
            ),
          ],
        ),
      ),
    );
  }
}