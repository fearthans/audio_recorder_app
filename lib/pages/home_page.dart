import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AudioRecorder audioRecorder = AudioRecorder();
  final AudioPlayer audioPlayer = AudioPlayer();

  List<String> recordings = [];
  String? currentRecording;
  bool isRecording = false, isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
    audioPlayer.positionStream.listen((position) {
      if (audioPlayer.playing && currentRecording != null) {
        setState(() {});
      }
    });
  }

  Future<void> _loadRecordings() async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory(p.join(appDocumentsDir.path, "Recordings"));
    if (await recordingsDir.exists()) {
      setState(() {
        recordings = recordingsDir
            .listSync()
            .map((file) => file.path)
            .where((path) => path.endsWith('.wav'))
            .toList();
      });
    } else {
      await recordingsDir.create();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Voice Recorder"),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      floatingActionButton: _recordingButton(),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Recordings",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          if (recordings.isEmpty)
            const Center(
              child: Text(
                "No Recordings Found. :(",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          if (recordings.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: recordings.length,
                itemBuilder: (context, index) {
                  return _buildRecordingTile(recordings[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordingTile(String path) {
    bool isSelected = currentRecording == path;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: isSelected ? Colors.blue.shade100 : Colors.white,
      child: ListTile(
        leading: Icon(Icons.audiotrack, color: Colors.blueAccent),
        title: Text(
          p.basename(path),
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.blueAccent : Colors.black,
          ),
        ),
        subtitle: Text(
          "26 Jan 2021 - 04:34 PM", // Placeholder for date/time
          style: TextStyle(fontSize: 12, color: isSelected ? Colors.blueAccent : Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              IconButton(
                icon: Icon(Icons.play_arrow, color: Colors.blueAccent),
                onPressed: () {
                  if (isPlaying && currentRecording == path) {
                    audioPlayer.stop();
                    setState(() {
                      isPlaying = false;
                      currentRecording = null;
                    });
                  } else {
                    _playRecording(path);
                  }
                },
              ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                _deleteRecording(path);
              },
            ),
          ],
        ),
        onTap: () async {
          if (currentRecording == path && isPlaying) {
            await audioPlayer.stop();
            setState(() {
              isPlaying = false;
              currentRecording = null;
            });
          } else {
            setState(() {
              currentRecording = path;
              isPlaying = true;
            });
            await _playRecording(path);
          }
        },
      ),
    );
  }

  Future<void> _playRecording(String path) async {
    await audioPlayer.setFilePath(path);
    await audioPlayer.play();
    setState(() {
      isPlaying = true;
    });
  }

  Future<void> _deleteRecording(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      setState(() {
        recordings.remove(path);
        if (currentRecording == path) {
          currentRecording = null;
          isPlaying = false;
        }
      });
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Widget _recordingButton() {
    return FloatingActionButton(
      onPressed: () async {
        if (isRecording) {
          String? filePath = await audioRecorder.stop();
          if (filePath != null) {
            setState(() {
              isRecording = false;
              recordings.add(filePath);
              currentRecording = filePath;
            });
            // Optionally start playing the new recording
            await _playRecording(filePath);
          }
        } else {
          if (await audioRecorder.hasPermission()) {
            final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
            final recordingsDir = Directory(p.join(appDocumentsDir.path, "Recordings"));
            final String filePath = p.join(
              recordingsDir.path,
              "recording_${DateTime.now().millisecondsSinceEpoch}.wav",
            );
            await audioRecorder.start(
              const RecordConfig(),
              path: filePath,
            );
            setState(() {
              isRecording = true;
              currentRecording = null;
            });
          }
        }
      },
      backgroundColor: isRecording ? Colors.red : Colors.blueAccent,
      child: Icon(
        isRecording ? Icons.stop : Icons.mic,
        color: Colors.white,
      ),
    );
  }
}
