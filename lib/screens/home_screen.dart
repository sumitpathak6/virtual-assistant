import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:virtual_assistant/api/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  TextEditingController userInputTextEditingController =
      TextEditingController();
  final SpeechToText speechToTextInstance = SpeechToText();
  String recordedAudioText = '';
  final flutterTts = FlutterTts();
  bool isLoading = false;
  String modeOpenAI = 'chat';
  String imageUrlFromOpenAI = '';
  String answerTextFromOpenAI = '';

  bool speakFRIDAY = true;

  void initializeSpeechToText() async {
    await speechToTextInstance.initialize();
    setState(() {});
  }

  void startListeningNow() async {
    FocusScope.of(context).unfocus();
    await speechToTextInstance.listen(onResult: onSpeechToTextResult);

    setState(() {});
  }

  void stopListeningNow() async {
    await speechToTextInstance.stop();

    setState(() {});
  }

  void onSpeechToTextResult(SpeechRecognitionResult recognitionResult) {
    recordedAudioText = recognitionResult.recognizedWords;

    speechToTextInstance.isListening ? null : (recordedAudioText);

    print("Speech Result = ");
    print(recordedAudioText);
  }

  Future<void> sendRequestToOpenAI(String userInput) async {
    stopListeningNow();

    setState(() {
      isLoading = true;
    });

    await ApiService().requestOpenAI(userInput, modeOpenAI, 2000).then((value) {
      setState(() {
        isLoading = false;
      });

      if (value.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'API Key you are/were using is expired or it is not working anymore.'),
          ),
        );
      }
      userInputTextEditingController.clear();

      final resposneAvailable = jsonDecode(value.body);

      if (modeOpenAI == 'chat') {
        setState(() {
          answerTextFromOpenAI = utf8.decode(
              resposneAvailable['choices'][0]['text'].toString().codeUnits);

          print('ChatGPT ChatBot');
          print(answerTextFromOpenAI);
        });

        if (speakFRIDAY) {
          systemSpeak(answerTextFromOpenAI);
        }
      } else {
        setState(() {
          imageUrlFromOpenAI = resposneAvailable['data'][0]['url'];
          print('Generated Dale-E Image Url:');
          print(imageUrlFromOpenAI);
        });
      }
    }).catchError(
      (errorMessage) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error :$errorMessage',
            ),
          ),
        );
      },
    );

    ;
  }

  @override
  void initState() {
    super.initState();
    initializeSpeechToText();
    initTextToSpeech();
  }

  Future<void> initTextToSpeech() async {
    await flutterTts.setSharedInstance(true);
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  Future<void> systemSpeak(String content) async {
    await flutterTts.speak(content);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          if (!isLoading) {
            setState(() {
              speakFRIDAY = !speakFRIDAY;
            });
          }
          flutterTts.stop();
        },
        child: speakFRIDAY
            ? Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset("assets/sound.png"),
              )
            : Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset("assets/mute.png"),
              ),
      ),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
            colors: [Colors.purpleAccent.shade100, Colors.deepPurple],
          )),
        ),
        title: Image.asset(
          "assets/logo.png",
          width: 140,
        ),
        titleSpacing: 10,
        elevation: 4,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4, top: 4),
            child: InkWell(
              onTap: () {
                setState(() {
                  modeOpenAI = 'chat';
                });
              },
              child: Icon(
                Icons.chat,
                size: 40,
                color: modeOpenAI == 'chat' ? Colors.white : Colors.grey,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 4),
            child: InkWell(
              onTap: () {
                setState(() {
                  modeOpenAI = 'image';
                });
              },
              child: Icon(
                Icons.image,
                size: 40,
                color: modeOpenAI == 'image' ? Colors.white : Colors.grey,
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(
                height: 40,
              ),
              Center(
                child: InkWell(
                  onTap: () {
                    speechToTextInstance.isListening
                        ? stopListeningNow()
                        : startListeningNow();
                  },
                  child: speechToTextInstance.isListening
                      ? Center(
                          child: LoadingAnimationWidget.beat(
                              color: speechToTextInstance.isListening
                                  ? Colors.deepPurple
                                  : isLoading
                                      ? Colors.deepPurple[400]!
                                      : Colors.deepPurple[200]!,
                              size: 300),
                        )
                      : Image.asset(
                          "assets/assistant_icon.png",
                          height: 300,
                          width: 300,
                        ),
                ),
              ),
              const SizedBox(
                height: 50,
              ),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: TextField(
                        controller: userInputTextEditingController,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'How can I help you?'),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  InkWell(
                    onTap: () {
                      if (userInputTextEditingController.text.isNotEmpty) {
                        sendRequestToOpenAI(
                            userInputTextEditingController.text.toString());
                      }
                    },
                    child: AnimatedContainer(
                      padding: const EdgeInsets.all(15),
                      decoration: const BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: Colors.deepPurpleAccent),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.bounceInOut,
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 24,
              ),
              modeOpenAI == 'chat'
                  ? SelectableText(
                      answerTextFromOpenAI,
                      style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    )
                  : modeOpenAI == 'image' && imageUrlFromOpenAI.isNotEmpty
                      ? Column(
                          children: [
                            Image.network(imageUrlFromOpenAI),
                            const SizedBox(
                              height: 14,
                            ),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple),
                              child: const Text(
                                'Download',
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          ],
                        )
                      : Container()
            ],
          ),
        ),
      ),
    );
  }
}
