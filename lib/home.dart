import 'dart:async';
import 'dart:io';
import "dart:math" as math;

import 'package:flutter/material.dart';
import 'package:twilio_programmable_video/twilio_programmable_video.dart';
import 'package:twilio_video_example/config.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<Room> _completer = Completer<Room>();
  Widget? _remoteParticipantWidget;

  bool _isFrontCamera = true;
  bool _isAudioMuted = false;
  bool _isVideoMuted = false;

  Room? _room;
  CameraCapturer? _capturer;
  LocalVideoTrack? _localVideoTrack;
  LocalAudioTrack? _localAudioTrack;

  _remoteVideoTrack(RemoteVideoTrackSubscriptionEvent evt) {
    setState(() {
      _remoteParticipantWidget = evt.remoteVideoTrack.widget();
    });
  }

  _onConnected(Room? room) {
    print("Connected to ${room?.name}");
    if (room != null) {
      if (room.remoteParticipants.length > 0) {
        room.remoteParticipants.first.onVideoTrackSubscribed
            .listen(_remoteVideoTrack);
      }
      _completer.complete(room);
    }
  }

  _onConnectFailure(RoomConnectFailureEvent event) {
    print("Failed to connect to room ${event.room.name} ");
    print(event.exception.toString());
    _completer.completeError(event.exception.toString());
  }

  _onParticipantConnected(RoomParticipantConnectedEvent roomEvent) {
    print("remote particiant has connected to the room");
    roomEvent.remoteParticipant.onVideoTrackSubscribed
        .listen(_remoteVideoTrack);
  }

  Future<Room?> _connectToRoom() async {
    if (_localVideoTrack == null && _localVideoTrack == null) {
      try {
        print("connect me to a room");
        _capturer = CameraCapturer(CameraSource.FRONT_CAMERA);
        _localVideoTrack = LocalVideoTrack(true, _capturer!);
        _localAudioTrack = LocalAudioTrack(true, "local-audio-trak");

        String accessKey = "";
        if (Platform.isAndroid) {
          accessKey = AppConfig.androidAccessKey;
        }
        if (Platform.isIOS) {
          accessKey = AppConfig.iosAccessKey;
        }

        final connectOptions = ConnectOptions(
          accessKey,
          roomName: "Test Room",
          preferredAudioCodecs: [OpusCodec()],
          preferredVideoCodecs: [H264Codec()],
          audioTracks: [_localAudioTrack!],
          videoTracks: [_localVideoTrack!],
          enableAutomaticSubscription: true,
        );
        _room = await TwilioProgrammableVideo.connect(connectOptions);
        _room?.onConnected.listen(_onConnected);
        _room?.onConnectFailure.listen(_onConnectFailure);
        _room?.onParticipantConnected.listen(_onParticipantConnected);
      } catch (e) {
        print("we got error: ");
        print(e);
      }
    }

    return _completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_call_outlined,
              size: 40,
            ),
            SizedBox(width: 10),
            Text("Twilio Video"),
          ],
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => _connectToRoom(),
                  child: Text("Join Room"),
                ),
              ],
            ),
            Expanded(
              child: Container(
                child: Stack(
                  children: [
                    FutureBuilder(
                      future: _completer.future,
                      builder: (context, AsyncSnapshot<Room> snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                                "error occurred while establishing connection"),
                          );
                        }
                        if (snapshot.hasData) {
                          return Container(
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(
                                  _isFrontCamera ? math.pi : 0),
                              child: _localVideoTrack!.widget(mirror: false),
                            ),
                          );
                        }
                        return Container();
                      },
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: SizedBox(
                        height: 150,
                        width: 150,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _remoteParticipantWidget,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Container(
                        child: Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                _capturer?.switchCamera();
                                setState(() {
                                  _isFrontCamera = !_isFrontCamera;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                shape: CircleBorder(),
                                padding: const EdgeInsets.all(10),
                              ),
                              child: Icon(Icons.switch_camera),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _localAudioTrack?.enable(!_isVideoMuted);
                                setState(() {
                                  _isAudioMuted = !_isAudioMuted;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                shape: CircleBorder(),
                                padding: const EdgeInsets.all(10),
                                primary:
                                    _isAudioMuted ? Colors.red : Colors.blue,
                              ),
                              child: Icon(
                                  _isAudioMuted ? Icons.mic_off : Icons.mic),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _localVideoTrack?.enable(!_isVideoMuted);
                                setState(() {
                                  _isVideoMuted = !_isVideoMuted;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                shape: CircleBorder(),
                                padding: const EdgeInsets.all(10),
                                primary:
                                    _isVideoMuted ? Colors.red : Colors.blue,
                              ),
                              child: Icon(_isVideoMuted
                                  ? Icons.videocam_off
                                  : Icons.videocam),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
