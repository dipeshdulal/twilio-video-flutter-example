import 'dart:async';
import 'dart:io';

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

  Room? _room;

  LocalVideoTrack? _localVideoTrack;

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
    if (_localVideoTrack == null) {
      try {
        print("connect me to a room");
        final capturer = CameraCapturer(CameraSource.FRONT_CAMERA);
        _localVideoTrack = LocalVideoTrack(true, capturer);

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
                          return Container(child: _localVideoTrack!.widget());
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
