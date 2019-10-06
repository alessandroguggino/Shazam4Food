import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shazam4Food',
      theme: ThemeData.dark(
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraController _cameraController;
  bool _loading = false;
  bool _itsPizza;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shazam 4 Food'),
        leading: Icon(Icons.sentiment_very_satisfied )
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black38,
        onPressed: () => _elaborateImage(context),
        child: Icon(
            Icons.camera_alt,
            color: Colors.white
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      backgroundColor: Colors.black38,
      body: Column(
        children: <Widget>[
          AnimatedContainer(
            width: double.infinity,
            height: 40.0,
            color: _itsPizza == null
                ? Colors.black38
                : _itsPizza == true ? Colors.green : Colors.red,
            curve: Curves.bounceIn,
            child: Padding(
              padding: const EdgeInsets.only(top: 0.0),
              child: Center(
                child: Text(
                  _itsPizza == null
                      ? ""
                      : _itsPizza == true ? "È UNA PIZZA!" : "NON È UNA PIZZA!",
                  style: Theme.of(context).textTheme.display1,
                ),
              ),
            ),
            duration: Duration(milliseconds: 50),
          ),
          Center(
            child: _isReady()
                ? AspectRatio(
              aspectRatio: _cameraController.value.aspectRatio,
              child: _loading
                  ? Center(child: CircularProgressIndicator(),)
                  : CameraPreview(_cameraController),)
                : SizedBox(),
          ),
        ],
      ),
    );
  }

  Future _elaborateImage(BuildContext context) async {
    final path = (await getTemporaryDirectory()).path + DateTime.now().toString();
    await _cameraController.takePicture(path);
    final FirebaseVisionImage visionImage = FirebaseVisionImage.fromFilePath(path);
    final LabelDetector labelDetector = FirebaseVision.instance.labelDetector();
    List<Label> labels = await labelDetector.detectInImage(visionImage);

    // print labels for debugging purpose
    labels.forEach((l) => print(l.label));

    setState(() {
      // search for "Xfood label"
      _itsPizza = labels.where((label) => label.label == 'Pizza').isNotEmpty;
      _loading = false;
    });
  }

  bool _isReady() =>
      _cameraController != null && _cameraController.value.isInitialized;

  @override
  void initState() {
    super.initState();

    availableCameras().then((cameras) async {
      _cameraController = new CameraController(
        cameras[0],
        ResolutionPreset.medium,
      );
      await _cameraController.initialize();
      setState(() {});
    }).catchError((error) {
      print("Error $error");
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}