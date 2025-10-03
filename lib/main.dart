import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

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

class CameraHome extends StatelessWidget {
  final List<CameraDescription> cameras;

  const CameraHome({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text('Open'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CameraPreviewScreen(cameras: cameras),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CameraPreviewScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraPreviewScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraPreviewScreenState createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  CameraDescription? _selectedCamera;

  @override
  void initState() {
    super.initState();
    _selectedCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras.first,
    );
    _initializeCamera(_selectedCamera!);
  }

  void _initializeCamera(CameraDescription camera) {
    _controller = CameraController(camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onCameraSwitch(CameraDescription? newCamera) {
    if (newCamera == null || newCamera == _selectedCamera) return;

    setState(() {
      _selectedCamera = newCamera;
      _controller.dispose();
      _initializeCamera(newCamera);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Preview'),
        actions: [
          DropdownButton<CameraDescription>(
            value: _selectedCamera,
            onChanged: _onCameraSwitch,
            items: widget.cameras.map((CameraDescription camera) {
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
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}