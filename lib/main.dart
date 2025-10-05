import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';


import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

Future<void> saveVideoToGallery(String videoPath) async {
  final fileName = videoPath.split('/').last;
  final videoFile = File(videoPath);

  if (await Permission.manageExternalStorage.isGranted) {
    try {
      final directory = Directory('/storage/emulated/0/Movies');
	  if (!(await directory.exists())) {
		await directory.create(recursive: true);
      }
	  
	  final newPath = '${directory.path}/$fileName';
	  final videoFile = File(videoPath);
      await videoFile.copy(newPath);
	  
      
    } catch (e) {
      print('err $e');
    }
  } else {
    print('Permission denied to manage external storage');
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraHome(cameras: cameras),
    );
  }
}

class CameraHome extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraHome({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraHomeState createState() => _CameraHomeState();
}

class _CameraHomeState extends State<CameraHome> {
  late CameraDescription selectedCamera;
  String selectedFigure = 'circle'; // Default selection is circle
  final TextEditingController centerXController = TextEditingController();
  final TextEditingController centerYController = TextEditingController();
  final TextEditingController radiusController = TextEditingController();
  final TextEditingController upperLeftXController = TextEditingController();
  final TextEditingController upperLeftYController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedCamera = widget.cameras.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick the camera, choose figure type and enter coordinates')),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              DropdownButton<CameraDescription>(
                value: selectedCamera,
                onChanged: (CameraDescription? newCamera) {
                  if (newCamera != null) {
                    setState(() {
                      selectedCamera = newCamera;
                    });
                  }
                },
                items: widget.cameras.map((camera) {
                  return DropdownMenuItem<CameraDescription>(
                    value: camera,
                    child: Text(
                      camera.lensDirection == CameraLensDirection.front
                          ? 'Front Camera'
                          : 'Rear Camera',
                    ),
                  );
                }).toList(),
              ),
              FigurePicker(
                selectedFigure: selectedFigure,
                onFigureChanged: (String value) {
                  setState(() {
                    selectedFigure = value;
                  });
                },
              ),
              if (selectedFigure == 'circle') ...[
                const Text('Center X:'),
                TextField(controller: centerXController),
                const Text('Center Y:'),
                TextField(controller: centerYController),
                const Text('Radius:'),
                TextField(controller: radiusController),
              ] else if (selectedFigure == 'rectangle') ...[
                const Text('Upper Left X:'),
                TextField(controller: upperLeftXController),
                const Text('Upper Left Y:'),
                TextField(controller: upperLeftYController),
                const Text('Width:'),
                TextField(controller: widthController),

                const Text('Height:'),
                TextField(controller: heightController),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                child: const Text('Open'),
                onPressed: () {
                  final figureData = {
                    'figure': selectedFigure,
                    'centerX': double.tryParse(centerXController.text) ?? 0.0,
                    'centerY': double.tryParse(centerYController.text) ?? 0.0,
                    'radius': double.tryParse(radiusController.text) ?? 50.0,
                    'upperLeftX': double.tryParse(upperLeftXController.text) ?? 100.0,
                    'upperLeftY': double.tryParse(upperLeftYController.text) ?? 100.0,
                    'width': double.tryParse(widthController.text) ?? 100.0,
                    'height': double.tryParse(heightController.text) ?? 100.0,
                  };

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CameraPreviewScreen(
                        camera: selectedCamera,
                        figureData: figureData,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FigurePicker extends StatelessWidget {
  final String selectedFigure;
  final Function(String) onFigureChanged;

  const FigurePicker({
    Key? key,
    required this.selectedFigure,
    required this.onFigureChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Radio<String>(
          value: 'circle',
          groupValue: selectedFigure,
          onChanged: (String? value) {
            if (value != null) onFigureChanged(value);
          },
        ),
        const Text('Circle'),
        Radio<String>(
          value: 'rectangle',
          groupValue: selectedFigure,
          onChanged: (String? value) {
            if (value != null) onFigureChanged(value);
          },
        ),
        const Text('Rectangle'),
      ],
    );
  }
}

class CameraPreviewScreen extends StatefulWidget {
  final CameraDescription camera;
  final Map<String, Object> figureData;

  const CameraPreviewScreen({
    Key? key,
    required this.camera,
    required this.figureData,
  }) : super(key: key);

  @override
  _CameraPreviewScreenState createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool isRecording = false;
  late String videoPath;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
	_requestPermissions();
  }
  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.photos, // Request media access on Android 13+
      Permission.videos, // For video media access on Android 13+
    ].request();

    if (await Permission.camera.isPermanentlyDenied ||
      await Permission.microphone.isPermanentlyDenied ||
      await Permission.photos.isPermanentlyDenied ||
      await Permission.videos.isPermanentlyDenied) {
        await openAppSettings();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    try {
		  // Check if all required permissions are granted
    bool hasPermissions = await Permission.camera.isGranted &&
        await Permission.microphone.isGranted &&
        (await Permission.storage.isGranted ||
        await Permission.photos.isGranted);


    if (isRecording) {
            final file = await _controller.stopVideoRecording();
			setState(() {
			  isRecording = false;
			  videoPath = file.path;
			});
			final params = ShareParams(
				text: 'Great picture',
				files: [XFile(videoPath)],
			);
			await SharePlus.instance.share(params);
        if (Platform.isAndroid) {
                // Request Manage External Storage permission for Android 11 and above
                await Permission.manageExternalStorage.request();
        }

        await saveVideoToGallery(videoPath);

	  } else {
		final directory = await getApplicationDocumentsDirectory();
		final videoFile = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
		await _controller.startVideoRecording();
		setState(() {
		  isRecording = true;
		  videoPath = videoFile;
		});
	  }
		} catch (e) {
		  ScaffoldMessenger.of(context).showSnackBar(
			SnackBar(content: Text('Error during recording: $e')),
		  );
		}
	}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller),
                CustomPaint(
                  painter: FigurePainter(figureData: widget.figureData),
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: IconButton(
                    icon: Icon(
                      isRecording ? Icons.stop : Icons.videocam,
                      color: Colors.red,
                      size: 50,
                    ),
                    onPressed: _toggleRecording,
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class FigurePainter extends CustomPainter {
  final Map<String, Object> figureData;

  FigurePainter({required this.figureData});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blue // Border color
      ..style = PaintingStyle.stroke  // Ensure only the border is drawn
      ..strokeWidth = 4.0; // Border width, can be adjusted

    final String? figureType = figureData['figure'] as String?;

    if (figureType == 'circle') {
      final double centerX = figureData['centerX'] as double? ?? 0.0;
      final double centerY = figureData['centerY'] as double? ?? 0.0;
      final double radius = figureData['radius'] as double? ?? 50.0;

      canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    } else if (figureType == 'rectangle') {
      final double upperLeftX = figureData['upperLeftX'] as double? ?? 0.0;
      final double upperLeftY = figureData['upperLeftY'] as double? ?? 0.0;
      final double width = figureData['width'] as double? ?? 100.0;
      final double height = figureData['height'] as double? ?? 100.0;

      Rect rect = Rect.fromLTWH(upperLeftX, upperLeftY, width, height);
      canvas.drawRect(rect, paint);
  }
}
    @override
    bool shouldRepaint(CustomPainter oldDelegate) => false;
}

