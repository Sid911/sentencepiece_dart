// ignore_for_file: non_constant_identifier_names

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
import 'package:unorm_dart/unorm_dart.dart' as unorm;

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
        if (bosID == null || eosID == null) {
          log('startID : $bosID , endID: $eosID');
        }
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
  List<List<int>> preprocessForAlBert(
      String inputString, String bos, String eos,
      {int totalTokens = 128}) {
    List<int> ids = encodeAsIds(inputString,
        bos: bos, eos: eos, totalTokens: totalTokens, raw: false);
    log(ids.toString());
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

  List<List<List<int>>> preprocessMultipleForAlBert(
      List<String> inputStrings, String bos, String eos,
      {int totalTokenPerString = 128}) {
    List<List<int>> idVec = List.empty(growable: true);

    for (int i = 0; i < inputStrings.length; i++) {
      idVec.add(encodeAsIds(inputStrings[i],
          bos: bos, eos: eos, totalTokens: totalTokenPerString, raw: false));
    }

    List<List<int>> inputMaskVec = List.empty(growable: true);

    for (int i = 0; i < inputStrings.length; i++) {
      if (idVec[i].contains(0)) {
        final zeroIndex = idVec[i].indexOf(0);
        inputMaskVec.add(List.filled(zeroIndex, 1) +
            List.filled(totalTokenPerString - zeroIndex, 0));
      } else {
        inputMaskVec.add(List.filled(totalTokenPerString, 1));
      }
    }

    return [
      idVec,
      List.filled(inputStrings.length, List.filled(totalTokenPerString, 0)),
      inputMaskVec
    ];
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

class Tokenizer {
  // Regex Strings
  late String KEEP_DELIM_NO_WHITESPACE_PATTERN;
  late String DELIM_REGEX_PATTERN;

  String CONTROL_CHAR_REGEX_PATTERN = r'\p{Cc}|\p{Cf}';
  late Map<String, int>? vocabMap;

  ///
  Tokenizer(
      {String? delimiterRegExPattern, String? keepDelimiterRegExPattern}) {
    KEEP_DELIM_NO_WHITESPACE_PATTERN = keepDelimiterRegExPattern ??
        r'[!-/]|[:-@]|[\[-`]|[{-~]|[\p{P}]|[\u{4E00}-\u{9FFF}]|[\u{3400}-\u{4DBF}]|[\u{20000}-\u{2A6DF}]|[\u{2A700}-\u{2B73F}]|[\u{2B740}-\u{2B81F}]|[\u{2B820}-\u{2CEAF}]|[\u{F900}-\u{FAFF}]|[\u{2F800}-\u{2FA1F}]';
    DELIM_REGEX_PATTERN =
        delimiterRegExPattern ?? r'\s+|' + KEEP_DELIM_NO_WHITESPACE_PATTERN;
  }

  Future<void> loadVocabFile(String vocabAssetPath) async {
    // loading vocab file
    List<String> vocab =
        (await rootBundle.loadString(vocabAssetPath)).split('\n');
    vocabMap =
        Map.fromIterables(vocab, List.generate(vocab.length, (index) => index));
    log(vocabMap!.values.toList().toString());
  }

  /// Preprocessing for Bert Models Using vocab file
  Future<List<List<int>>> perprocessUsingVocabFile(
      {required List<String> inputTexts,
      String? vocabAssetPath,
      bool lowerCase = true,
      bool keepWhiteSpace = false,
      bool preserveUnusedTokens = false,
      normalizeUTF = false}) async {
    // normalized/lowercase texts
    List<String> normTexts = List<String>.empty(growable: true);
    // Normalize and remove unwanted chars
    for (int i = 0; i < inputTexts.length; i++) {
      String tempText;
      if (lowerCase) {
        // normalize utf8 (this case 16)
        tempText = inputTexts[i]
            .replaceAll(RegExp(r'\p{Mn}|\p{Ps}|\p{Pi}', unicode: true), '');
        // Remove Control chars and format characters
        tempText.replaceAll(
            RegExp(CONTROL_CHAR_REGEX_PATTERN, unicode: true), ' ');
        if (normalizeUTF) tempText = (unorm.nfkd(tempText));
      } else {
        tempText = inputTexts[i]
            .replaceAll(RegExp(CONTROL_CHAR_REGEX_PATTERN, unicode: true), ' ');
        if (normalizeUTF) tempText = unorm.nfkc(tempText);
      }

      normTexts.add(tempText);
    }
    if (vocabAssetPath != null) {
      await loadVocabFile(vocabAssetPath);
    } else if (vocabMap == null) {
      throw Exception(
          'vocabulary not set. provide vocabulary Asset file path or use `Tokenizer.loadVocabFile()` before running this function');
    }

    return _encodeUsingVocab(normTexts);
  }

  List<List<int>> _encodeUsingVocab(List<String> normalizedTexts) {
    List<List<int>> ids = List<List<int>>.empty(growable: true);
    // loop over normalized text
    for (int i = 0; i < normalizedTexts.length; i++) {
      // List<RegExpMatch> matches =
      //     RegExp(DELIM_REGEX_PATTERN).allMatches(normalizedTexts[i]).toList();
      String currentText = normalizedTexts[i];
      List<int> idPerSentence = _recurseFindText(currentText);
      ids.add(idPerSentence);
    }
    return ids;
  }

  // flagging
  List<int> _recurseFindText(
    String text, {
    List<int>? list,
  }) {
    list ??= List<int>.empty(growable: true);
    if (vocabMap!.containsKey(text)) {
      // flag : 5210
      list.add(vocabMap![text]!);
      return list;
    } else {
      if (text.length == 1) list.add(-1);
      for (int i = 1; i < text.length; i++) {
        //ging
        if (vocabMap!.containsKey('##' + text.substring(i))) {
          //flag
          list.addAll(_recurseFindText(text));
          // ##ging : 4726
          list.add(vocabMap!['##' + text.substring(i)]!);
        }
      }
    }
    // 5210 , 4726
    return list;
  }
}
