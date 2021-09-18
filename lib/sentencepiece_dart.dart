/*
   Copyright 2021 Siddharth Sinha

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
import 'dart:async';
import 'dart:developer';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart' show ByteData, MethodChannel, rootBundle;
import 'package:path_provider/path_provider.dart';

typedef SPMInit = Pointer<Void> Function();
typedef SPMInitNative = Pointer<Void> Function();

typedef SPMDestroy = void Function(Pointer<Void>);
typedef SPMDestroyNative = Void Function(Pointer<Void>);

typedef LoadModel = void Function(Pointer<Void>, Pointer<Utf8>);
typedef LoadModelNative = Void Function(Pointer<Void>, Pointer<Utf8>);

typedef EncodeAsIds = Int32Array Function(Pointer<Void>, Pointer<Utf8>);
typedef EncodeAsIdsNative = Int32Array Function(Pointer<Void>, Pointer<Utf8>);

typedef CheckModeLoaded = int Function(Pointer<Void>);
typedef CheckModeLoadedNative = Int32 Function(Pointer<Void>);

typedef PieceToID = int Function(Pointer<Void>, Pointer<Utf8>);
typedef PieceToIDNative = Int32 Function(Pointer<Void>, Pointer<Utf8>);

typedef IDToPiece = Pointer<Utf8> Function(Pointer<Void>, int);
typedef IDToPieceNative = Pointer<Utf8> Function(Pointer<Void>, Int32);

class Int32Array extends Struct {
  external Pointer<Int32> data;
  @Int32()
  external int len;
}

/// Intermediate Sentencepiece Class for ffi interface with C++ shared lib.
///
/// Note : Use [SentencePiece] Class if possible
class SentencepieceDartInterface {
  static final DynamicLibrary _nativelib =
      DynamicLibrary.open("libsentencepiece.so");

  static SPMInit init = _nativelib
      .lookup<NativeFunction<SPMInitNative>>('sentencepieceInit')
      .asFunction();

  static SPMDestroy destroy = _nativelib
      .lookup<NativeFunction<SPMDestroyNative>>('sentencepieceDestroy')
      .asFunction();

  static LoadModel loadModelFile = _nativelib
      .lookup<NativeFunction<LoadModelNative>>('loadModelFile')
      .asFunction();

  static EncodeAsIds encodeAsIds = _nativelib
      .lookup<NativeFunction<EncodeAsIdsNative>>("encodeAsIds")
      .asFunction();

  static CheckModeLoaded checkModelLoaded = _nativelib
      .lookup<NativeFunction<CheckModeLoadedNative>>("checkModelLoaded")
      .asFunction();

  static PieceToID pieceToID = _nativelib
      .lookup<NativeFunction<PieceToIDNative>>('pieceToID')
      .asFunction();

  static IDToPiece idToPiece = _nativelib
      .lookup<NativeFunction<IDToPieceNative>>('idToPiece')
      .asFunction();
  static const MethodChannel _channel = MethodChannel('sentencepiece_dart');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}

/// Sentencepiece Class
class Sentencepiece {
  /// Absolute Path to the Sentencepiece model
  final String spmModelPath;

  /// Pointer to the Sentencepiece Processor from native library
  late Pointer<Void> _nativeInstance;

  /// SentencePiece Class Constructor
  ///
  /// Example:
  ///
  /// ```
  /// late Sentencepiece spm;
  /// ...
  /// Sentencepiece.saveAssetToApplicationDirectory(
  ///       inputAssetPath: "assets/30kclean.model",
  ///       relativeOutputPath: "30kclean.model",
  ///     ).then((value) {
  ///       setState(() {
  ///         modelPath = value;
  ///         spm = Sentencepiece(value);
  ///         show = true;
  ///       });
  ///     });
  ///```
  Sentencepiece(this.spmModelPath) {
    _nativeInstance = SentencepieceDartInterface.init();
    Pointer<Utf8> pathRef = spmModelPath.toNativeUtf8();
    try {
      SentencepieceDartInterface.loadModelFile(_nativeInstance, pathRef);
      if (SentencepieceDartInterface.checkModelLoaded(_nativeInstance) != 1) {
        log("Untracked Error after loading the model file $spmModelPath \nMake sure to load from an absolute disk path rather than just 'assets/file' ");
      }
    } catch (ex, stacktrace) {
      log("Error after loading the model file $spmModelPath \nMake sure to load from an absolute disk path rather than just 'assets/file' ",
          stackTrace: stacktrace);
      rethrow;
    }
  }

  /// Closes the Sentencepiece Processor in Native. (Frees memory manually)
  void close() {
    SentencepieceDartInterface.destroy(_nativeInstance);
  }

  /// Encodes a preprocessed [inputString] to ids.
  ///
  /// Note : The function does not pre-process the [inputString] in any way, make sure to
  ///   - convert string to lowercase
  ///   - remove any stop character (punctuation) which isn't needed
  List<int> encodeAsIds(String inputString,
      {String? bos, String? eos, int totalTokens = 128, bool raw = true}) {
    int? bosID, eosID;

    bool idsProvided = (bos != null) && (eos != null);
    final input = inputString.toNativeUtf8();
    try {
      if (idsProvided) {
        bosID = SentencepieceDartInterface.pieceToID(
            _nativeInstance, bos.toNativeUtf8());
        eosID = SentencepieceDartInterface.pieceToID(
            _nativeInstance, eos.toNativeUtf8());
      }
      Int32Array res =
          SentencepieceDartInterface.encodeAsIds(_nativeInstance, input);
      List<int> temp = [];
      for (var i = 0; i < res.len; i++) {
        temp.add(res.data.elementAt(i).value);
      }
      malloc.free(input);
      if (raw) {
        if (idsProvided) {
          temp.add(eosID!);
          temp.insert(0, bosID!);
        }
        return temp;
      } else {
        if (bosID == null || eosID == null)
          log('startID : $bosID , endID: $eosID');
        if (temp.length <= totalTokens - 2) {
          temp.add(eosID!);
          temp.insert(0, bosID!);
          temp.addAll(List.filled(totalTokens - temp.length, 0));
          return temp;
        } else {
          temp.removeRange(126, temp.length);
          temp.add(eosID!);
          temp.insert(0, bosID!);
          return temp;
        }
      }
    } catch (ex, stacktrace) {
      log("Error while encoding", stackTrace: stacktrace);
      rethrow;
    }
  }

  /// Preprocesses a **single line** for a bert based model.
  /// ---
  /// **[bos]** : **B**eginning **O**f **S**entence token
  ///
  ///   Example: `[CLS]` for ALBERT and some BERT models
  ///
  /// **[eos]** : **E**nd **O**f **S**entence token
  ///
  ///   Example: `[SEP]` for ALBERT and some BERT models
  ///
  /// **[totalTokens]** : Total Number of tokens Expected by a Bert model
  ///
  /// -------
  ///
  /// Returns List of len = 3 as follows `[ word_ids, segment , mask ]`
  List<List<int>> preprocessForBert(String inputString, String bos, String eos,
      {int totalTokens = 128}) {
    List<int>? ids = encodeAsIds(inputString,
        bos: bos, eos: eos, totalTokens: totalTokens, raw: false);
    List<int> inputMasks;
    if (ids.contains(0)) {
      final zeroIndex = ids.indexOf(0);
      inputMasks =
          List.filled(zeroIndex, 1) + List.filled(totalTokens - zeroIndex, 0);
    } else {
      inputMasks = List.filled(totalTokens, 1);
    }
    return [ids, List.filled(totalTokens, 0), inputMasks];
  }

  /// Saves asset at [inputAssetPath] to relative path of application Directory at [relativeOutputPath]
  /// Example:
  ///
  /// ```
  /// final AbsoluteModelPathFuture = Sentencepiece.saveAssetToApplicationDirectory(
  ///       inputAssetPath: "assets/30kclean.model",
  ///       relativeOutputPath: "30kclean.model",
  ///)
  static Future<String> saveAssetToApplicationDirectory(
      {required String inputAssetPath,
      required String relativeOutputPath}) async {
    Directory directory = await getApplicationDocumentsDirectory();
    String dbPath = directory.path + "/" + relativeOutputPath;
    if (FileSystemEntity.typeSync(dbPath) == FileSystemEntityType.notFound) {
      ByteData data = await rootBundle.load(inputAssetPath);
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(dbPath).writeAsBytes(bytes);
    }
    return dbPath;
  }
}
