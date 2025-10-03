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

class CameraHome extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraHome({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraHomeState createState() => _CameraHomeState();
}

class _CameraHomeState extends State<CameraHome> {
  late CameraDescription selectedCamera;
  String selectedFigure = 'circle'; // Default selection is circle
  TextEditingController centerXController = TextEditingController();
  TextEditingController centerYController = TextEditingController();
  TextEditingController radiusController = TextEditingController();
  TextEditingController upperLeftXController = TextEditingController();
  TextEditingController upperLeftYController = TextEditingController();
  TextEditingController widthController = TextEditingController();
  TextEditingController heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedCamera = widget.cameras.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Picker Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Camera selection dropdown
            DropdownButton<CameraDescription>(
              value: selectedCamera,
              onChanged: (CameraDescription? newCamera) {
                setState(() {
                  selectedCamera = newCamera!;
                });
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
            
            // Figure Picker
            FigurePicker(
              selectedFigure: selectedFigure,
              onFigureChanged: (String value) {
                setState(() {
                  selectedFigure = value;
                });
              },
            ),
            
            // Text fields for Circle or Rectangle input
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
            
            ElevatedButton(
              child: const Text('Open'),
              onPressed: () {
                // Collect figure data
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
    return Column(
      children: <Widget>[
        // Radio buttons for Circle and Rectangle
        Row(
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
        ),
      ],
    );
  }
}

class CameraPreviewScreen extends StatefulWidget {
  final CameraDescription camera;
  final Map<String, Object> figureData;  // Changed from Map<String, double>

  const CameraPreviewScreen({Key? key, required this.camera, required this.figureData}) : super(key: key);

  @override
  _CameraPreviewScreenState createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Preview')),
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
  final Map<String, Object> figureData;  // Changed from Map<String, double>

  FigurePainter({required this.figureData});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    if (figureData['figure'] == 'circle') {
      final double centerX = figureData['centerX'] as double? ?? 0.0;
      final double centerY = figureData['centerY'] as double? ?? 0.0;
      final double radius = figureData['radius'] as double? ?? 50.0;      
	  canvas.drawCircle(
        Offset(figureData['centerX']!, figureData['centerY']!),
        figureData['radius']!,
        paint,
      );
    } else if (figureData['figure'] == 'rectangle') {
      final double upperLeftX = figureData['upperLeftX'] as double? ?? 0.0;
      final double upperLeftY = figureData['upperLeftY'] as double? ?? 0.0;
      final double width = figureData['width'] as double? ?? 100.0;
      final double height = figureData['height'] as double? ?? 100.0;      
	  final Rect rect = Rect.fromLTWH(
        figureData['upperLeftX']!,
        figureData['upperLeftY']!,
        figureData['width']!,
        figureData['height']!,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
 //