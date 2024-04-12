// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker_web/image_picker_web.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController dController = TextEditingController();
  final TextEditingController lController = TextEditingController();
  String unit = 'm';
  Uint8List? image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lambda Finder',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey.shade800,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: () async {
                  image = await ImagePickerWeb.getImageAsBytes();
                  setState(() {});
                },
                child: Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: image != null
                        ? DecorationImage(
                            image: MemoryImage(image!),
                            fit: BoxFit.contain,
                          )
                        : null,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.blueGrey.shade800,
                      width: 4,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: image == null
                      ? const Center(
                          child: Icon(
                            Icons.camera_alt,
                            size: 100,
                            color: Colors.blueGrey,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              valueField('D Value:', 'Enter D value', dController),
              const SizedBox(
                height: 20,
              ),
              valueField('L Value:', 'Enter L value', lController),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  const Text(
                    'Unit:',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  DropdownButton<String>(
                    value: unit,
                    items: const [
                      DropdownMenuItem(
                        value: 'm',
                        child: Text('Meters'),
                      ),
                      DropdownMenuItem(
                        value: 'cm',
                        child: Text('Centimeters'),
                      ),
                      DropdownMenuItem(
                        value: 'mm',
                        child: Text('Millimeters'),
                      ),
                    ],
                    onChanged: (String? value) {
                      setState(() {
                        unit = value ?? 'Meters';
                      });
                    },
                    hint: const Text('Select Unit'),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              GestureDetector(
                onTap: () async {
                  if (image == null) return;
                  if (dController.text.isEmpty) return;
                  if (lController.text.isEmpty) return;
                  if (unit.isEmpty) return;
                  showLoadingDialog();
                  String? result = await calculate(
                    image: image!,
                    d: dController.text,
                    l: lController.text,
                    unit: unit,
                  );
                  result = double.parse(result ?? "0").toStringAsFixed(4);
                  Navigator.pop(context);
                  if (result == "0") {
                    showResultDialog('Failed to calculate');
                  } else {
                    showResultDialog('Wave length = $result nm');
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade800,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'Calculate',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget valueField(
    String title,
    String hintText,
    TextEditingController controller,
  ) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
          ),
        ),
        const SizedBox(
          width: 20,
        ),
        SizedBox(
          width: 200,
          height: 50,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<String?> rootApi() async {
    try {
      final Uri url =
          Uri.parse("https://lambda-finder-eypnsolnpa-as.a.run.app/");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return response.body;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint("CODE ERROR");
      debugPrint(e.toString());
      return null;
    }
  }

  Future<String?> calculate({
    required Uint8List image,
    required String d,
    required String l,
    required String unit,
  }) async {
    try {
      final Uri url = Uri.parse(
          "https://lambda-finder-eypnsolnpa-as.a.run.app/calculate/$unit/$d/$l");
      var request = http.MultipartRequest('POST', url);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          image,
          filename: 'image.jpg',
        ),
      );
      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        dynamic result =
            jsonDecode(await response.stream.bytesToString()) as Map;
        if (result["status"].toString() == "success") {
          return result["result"].toString();
        }
      }
      debugPrint(response.statusCode.toString());
      debugPrint(response.reasonPhrase.toString());
      return null;
    } catch (e) {
      debugPrint("CODE ERROR");
      debugPrint(e.toString());
      return null;
    }
  }

  void showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Colors.blueGrey,
                ),
                SizedBox(height: 16),
                Text('Loading...'),
              ],
            ),
          ),
        );
      },
    );
  }

  void showResultDialog(String result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(result),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
