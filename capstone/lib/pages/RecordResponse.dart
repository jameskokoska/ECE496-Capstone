import 'dart:io';

import 'package:camera/camera.dart';
import 'package:capstone/colors.dart';
import 'package:capstone/database/tables.dart';
import 'package:capstone/main.dart';
import 'package:capstone/pages/PlayBackVideo.dart';
import 'package:capstone/struct/databaseGlobal.dart';
import 'package:capstone/widgets/TextFont.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../widgets/Snackbar.dart';

class RecordResponse extends StatefulWidget {
  const RecordResponse({
    required this.responseId,
    required this.response,
    required this.user,
    required this.initialFilePathIfComplete,
    super.key,
  });
  final String responseId;
  final String response;
  final User user;
  final String? initialFilePathIfComplete;

  @override
  State<RecordResponse> createState() => _RecordResponseState();
}

class _RecordResponseState extends State<RecordResponse> {
  bool _isLoading = true;
  bool _isRecording = false;
  String? recordingPath;
  late CameraController _cameraController;
  late String currentResponseId = widget.responseId;
  late User currentUser = widget.user;

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      await _initCamera();
      if (widget.initialFilePathIfComplete != null) {
        setState(() {
          recordingPath = widget.initialFilePathIfComplete;
        });
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  _initCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front);
    _cameraController = CameraController(front, ResolutionPreset.max);
    await _cameraController.initialize();
    setState(() => _isLoading = false);
  }

  Future<void> _recordVideo() async {
    if (_isRecording) {
      final file = await _cameraController.stopVideoRecording();
      setState(() {
        recordingPath = file.path;
        _isRecording = false;
      });
    } else {
      await _cameraController.prepareForVideoRecording();
      await _cameraController.startVideoRecording();
      setState(() => _isRecording = true);
    }
  }

  Future<void> _deleteVideo() async {
    try {
      deleteVideo(null, recordingPath!);
      setState(() {
        recordingPath = null;
      });
      return;
    } catch (e) {
      showCupertinoSnackBar(context: context, message: e.toString());
      return;
    }
  }

  Future<void> _saveNewRecording() async {
    User user = currentUser.copyWith(recordings: {
      ...currentUser.recordings,
      currentResponseId: recordingPath ?? ""
    });
    await database.createOrUpdateUser(user);
  }

  void _restartRecording() async {
    await _deleteVideo();
    await _recordVideo();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (recordingPath != null) _saveNewRecording();
        return true;
      },
      child: CupertinoPageScaffold(
        child: Stack(
          children: [
            _isLoading
                ? Container(
                    color: getColor(context, "white"),
                    child: const Center(
                      child: CupertinoActivityIndicator(),
                    ),
                  )
                : recordingPath != null
                    ? PlayBackVideo(filePath: recordingPath!, isLooping: true)
                    : CameraPreview(_cameraController),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Center(
                      child: HintText(
                        text: "Please say:",
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: TextFont(
                          text: widget.response,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          textAlign: TextAlign.center,
                          maxLines: 50,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        recordingPath == null
                            ? const SizedBox.shrink()
                            : CupertinoButton(
                                color: getColor(context, "lightDark"),
                                borderRadius: BorderRadius.circular(50),
                                minSize: 50,
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  _restartRecording();
                                },
                                child: Icon(
                                  CupertinoIcons.restart,
                                  color: getColor(context, "black"),
                                ),
                              ),
                        const SizedBox(width: 15),
                        Center(
                          child: CupertinoButton(
                            color: recordingPath != null
                                ? getColor(context, "completeGreen")
                                : _isRecording
                                    ? getColor(context, "red")
                                    : Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(50),
                            minSize: 70,
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              if (recordingPath != null) {
                                _saveNewRecording();
                                Navigator.pop(context);
                              } else if (recordingPath == null) {
                                _recordVideo();
                              } else {
                                _restartRecording();
                              }
                            },
                            child: Icon(
                              recordingPath != null
                                  ? CupertinoIcons.check_mark
                                  : _isRecording
                                      ? CupertinoIcons.stop_fill
                                      : CupertinoIcons.circle_filled,
                              color: recordingPath != null
                                  ? Color(0xFFF0F0F0)
                                  : _isRecording
                                      ? Color(0xFFF0F0F0)
                                      : getColor(context, "red"),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        recordingPath == null
                            ? const SizedBox.shrink()
                            : CupertinoButton(
                                color: getColor(context, "lightDark"),
                                borderRadius: BorderRadius.circular(50),
                                minSize: 50,
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  _deleteVideo();
                                },
                                child: Icon(
                                  CupertinoIcons.delete,
                                  color: getColor(context, "black"),
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            DraggableOverlay(
              initialOffset: Offset(
                  appStateSettings["overlay-position-x"] == "-1"
                      ? 0
                      : double.parse(appStateSettings["overlay-position-x"]),
                  appStateSettings["overlay-position-y"] == "-1"
                      ? (MediaQuery.of(context).size.width <
                                  MediaQuery.of(context).size.height
                              ? MediaQuery.of(context).size.width
                              : MediaQuery.of(context).size.height) /
                          2
                      : double.parse(appStateSettings["overlay-position-y"])),
              child: Container(
                width: MediaQuery.of(context).size.width <
                        MediaQuery.of(context).size.height
                    ? MediaQuery.of(context).size.width
                    : MediaQuery.of(context).size.height,
                height: MediaQuery.of(context).size.width <
                        MediaQuery.of(context).size.height
                    ? MediaQuery.of(context).size.width
                    : MediaQuery.of(context).size.height,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/PersonOutline.png'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DraggableOverlay extends StatefulWidget {
  const DraggableOverlay(
      {super.key, required this.child, required this.initialOffset});

  final Widget child;
  final Offset initialOffset;

  @override
  State<DraggableOverlay> createState() => _DraggableOverlayState();
}

class _DraggableOverlayState extends State<DraggableOverlay> {
  Offset position = const Offset(0, 0);
  @override
  void initState() {
    position = widget.initialOffset;
    setState(() {});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Draggable(
        feedback: widget.child,
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: widget.child,
        ),
        onDragEnd: (details) {
          setState(() => position = details.offset);
          print(position.dx);
          print(position.dy);
          updateSettings("overlay-position-x", (position.dx).toString());
          updateSettings("overlay-position-y", (position.dy).toString());
        },
        child: widget.child,
      ),
    );
  }
}

Future<bool> deleteVideo(context, String recordingPath) async {
  if (context == null) {
    final file = File(recordingPath);
    await file.delete();
    debugPrint("Deleted $recordingPath");
    return true;
  } else {
    bool result = await confirmDelete(context, "Delete recording?");
    if (result == true) {
      final file = File(recordingPath);
      await file.delete();
      showCupertinoSnackBar(context: context, message: "Deleted recording.");
      debugPrint("Deleted$recordingPath");
      return true;
    } else {
      return false;
    }
  }
}

Future<bool> confirmDelete(context, String message) async {
  bool result = await showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(message),
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result;
}
