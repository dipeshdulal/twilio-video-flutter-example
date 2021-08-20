import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twilio_programmable_video/twilio_programmable_video.dart';

const accessKey =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImN0eSI6InR3aWxpby1mcGE7dj0xIn0.eyJqdGkiOiJTSzIwM2M5NmFhYmNmNjQ1OTUwOTJlYWNiZWY2NzBlODQ0LTE2Mjk0NjA0NDUiLCJncmFudHMiOnsiaWRlbnRpdHkiOiJEaXBlc2giLCJ2aWRlbyI6e319LCJpYXQiOjE2Mjk0NjA0NDUsImV4cCI6MTYyOTQ2NDA0NSwiaXNzIjoiU0syMDNjOTZhYWJjZjY0NTk1MDkyZWFjYmVmNjcwZTg0NCIsInN1YiI6IkFDNWQ0YTRkY2Y0ODI4Njg3NTNhNGVlZWE5MDYyYWI1ODQifQ.oljI1T7oP-1iAcQ2Dj23feUg-5jgiTsmZqrn2kWEjZU";

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

  _onConnected(Room? room) {
    print("Connected to ${room?.name}");
    if (room != null) {
      _completer.complete(room);
    }
  }

  _onConnectFailure(RoomConnectFailureEvent event) {
    print("Failed to connect to room ${event.room.name} with ");
    _completer.completeError(event.exception.toString());
  }

  _onParticipantConnected(RoomParticipantConnectedEvent roomEvent) {
    print("remote particiant has connected to the room");
    roomEvent.remoteParticipant.onVideoTrackSubscribed.listen(
      (RemoteVideoTrackSubscriptionEvent evt) {
        setState(() {
          _remoteParticipantWidget = evt.remoteVideoTrack.widget();
        });
      },
    );
  }

  Future<Room?> _connectToRoom() async {
    if (_localVideoTrack == null) {
      try {
        print("connect me to a room");
        final capturer = CameraCapturer(CameraSource.FRONT_CAMERA);
        _localVideoTrack = LocalVideoTrack(true, capturer);
        final connectOptions = ConnectOptions(accessKey,
            roomName: "Test Room",
            preferredAudioCodecs: [OpusCodec()],
            preferredVideoCodecs: [H264Codec()],
            audioTracks: [LocalAudioTrack(true, "LocalAudioTrack")],
            videoTracks: [_localVideoTrack!]);
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
            TextField(
              decoration: InputDecoration(
                labelText: "Room Id",
              ),
            ),
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
                      child: SizedBox(
                        height: 200,
                        width: 200,
                        child: _remoteParticipantWidget,
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
