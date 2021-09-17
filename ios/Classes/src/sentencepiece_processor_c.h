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
#include "sentencepiece_processor.h"
#include <stdint.h>
#include <vector>

struct StringArray
{
	char** data;
	int size;
};
struct Int32Array 
{
	int* data;
	int len;
};
/// <summary>
/// Helper funciton for creating new StringArray struct.
/// </summary>
/// <param name="cstring"> : char** pointer</param>
/// <param name="len"> : total number of char* (strings)</param>
/// <returns></returns>
StringArray createStringArray(char** cstring, int len) {
	StringArray s;
	s.data = cstring;
	s.size = len;
	return s;
}

/// <summary>
/// Helper funciton for creating new Int32Array struct.
/// </summary>
/// <param name="arr"> : int* array pointer </param>
/// <param name="len"> : total number of elements</param>
/// <returns></returns>
Int32Array createInt32Array(int* arr, int len) {
	Int32Array a;
	a.data = arr;
	a.len = len;
	return a;
}

extern "C"{
	/// <summary>
	/// Initializes the Sentencepiece Processor object and returns a pointer to it.
	/// 
	/// Note : [sentencepieceDestroy] should be used to free up the memmory after usage
	/// </summary>
	/// <returns> handle to Sentencepiece Processor object</returns>
	void* sentencepieceInit();
	/// <summary>
	///  Destroys the Sentencepiece Processor object to ensure memory safety.
	/// </summary>
	/// <param name="processorhandle"> : Pointer to the stored 'sentecepiece Processor' object.</param>
	void sentencepieceDestroy(void* processorhandle);
	/// <summary>
	/// Check using [checkModelLoaded] after this to ensure that the model file is loaded. Uses loadOrDie
	/// function which causes hard crash if handled incorrectly.
	/// </summary>
	/// <param name="processorhandle"> : Pointer to the stored 'sentecepiece Processor' object.</param>
	/// <param name="filename"> : Absolute path for the Sentencepiece model file</param>
	void loadModelFile(void* processorhandle, char* filename);
	/// <summary>
	/// Checks if the sentencepieceProcessor is ready for encode and decode.
	/// </summary>
	/// <param name="processorhandle"> : Pointer to the stored 'sentecepiece Processor' object.</param>
	/// <returns>Returns 1 if ready else return 0</returns>
	int checkModelLoaded(void* processorhandle);
	/// <summary>
	/// Resets the Vocabulary.
	/// </summary>
	/// <param name="processorhandle"> : Pointer to the stored 'sentecepiece Processor' object.</param>
	void resetVocabulary(void* processorhandle);
	/// <summary>
	///	Encodes input based on loaded model file as Ids. Preprocess the sentences 
	/// (add start and end tokens, turn to lowercase, remove punctuation if required)
	/// before passing to this.
	/// </summary>
	/// <param name="processorhandle"> : Pointer to the stored 'sentecepiece Processor' object.</param>
	/// <returns>Returns Int32Array struct which includes array of ids.</returns>
	struct Int32Array encodeAsIds(void* processorhandle, char* input);
	/// <summary>
	///	Encodes input based on loaded model file as pieces. Preprocess the sentences 
	/// (add start and end tokens, turn to lowercase, remove punctuation if required)
	/// before passing to this.
	/// </summary>
	/// <param name="processorhandle"> : Pointer to the stored 'sentecepiece Processor' object.</param>
	/// <returns>Returns StringArray struct.</returns>
	struct StringArray encodeAsPieces(void* processorhandle, char* input);

}