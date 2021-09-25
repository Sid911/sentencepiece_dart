import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart' show PlatformException;
import 'package:sentencepiece_dart/sentencepiece_dart.dart';
// ignore: unused_import
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String stuff = 'Plugin example app';
  bool show = false;
  late String platformVersion;
  late String modelPath;
  late Sentencepiece? spm;
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // await Sentencepiece.saveAssetToApplicationDirectory(
    //   inputAssetPath: "assets/30kclean.model",
    //   relativeOutputPath: "30kclean.model",
    // ).then((value) {
    //   setState(() {
    //     modelPath = value;
    //     spm = Sentencepiece(value);
    //     show = true;
    //   });
    // });
    //  albert thingy

    // ignore: unused_local_variable
    final List<String> sentences = [
      "My phone fell down the building".toLowerCase(),
      "It is warm today".toLowerCase(),
      "Today is a hot day".toLowerCase(),
      "I went to grandpa's home".toLowerCase(),
      "I found some old tools".toLowerCase(),
      "Where is my phone?".toLowerCase(),
      "How old are you?".toLowerCase(),
      "What is your age?".toLowerCase(),
      "I am 16 years old".toLowerCase()
    ];

    /// Note : This sentence does not represent a normal sentence, a normal sentence needs to be preprocessed.
    /// 1. convert to lowercase (sentencepiece requires this)
    /// 2. remove punctuation marks
    /// 3. separate sentences

    // get the encodings note (debug mode builds take 20x more time to encode than even profile mode)
    // var res = spm!.preprocessForAlBert("this is a test", "[CLS]", "[SEP]");
    // // start tflite interpreter
    // final options = InterpreterOptions()..useNnApiForAndroid = true;
    // final interpreter = await Interpreter.fromAsset(
    //     'lite-model_albert_lite_base_squadv1_metadata_1.tflite',
    //     options: options);
    // final outputTensors = interpreter.getOutputTensors();
    // interpreter.allocateTensors();
    // final inputTensors = interpreter.getInputTensors();
    // // Sets the features to
    // inputTensors[0].setTo(res);
    // // Run the model
    // interpreter.invoke();
    // stopwatch.stop();
    // log("time taken for model to run : ${stopwatch.elapsedMilliseconds}");
    //
    // final result = outputTensors[0].data.buffer.asFloat32List().toList();
    // log(result.toString());
    final tokenizer = Tokenizer();
    await tokenizer.loadVocabFile("assets/vocab.txt");
    Stopwatch stopwatch = Stopwatch()..start();
    final result = await tokenizer
        .preprocessUsingVocabFile(inputTexts: ['This is a test 32434']);
    stopwatch.stop();
    log(stopwatch.elapsedMilliseconds.toString());
    log(result.toString());
    try {
      platformVersion = await SentencepieceDartInterface.platformVersion ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text(_platformVersion),
        ),
      ),
    );
  }
}
