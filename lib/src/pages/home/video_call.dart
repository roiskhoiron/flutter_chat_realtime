import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../main.dart';
import '../../services/socket_service.dart';

class VideoCall extends StatefulWidget {
  const VideoCall({Key? key}) : super(key: key);

  @override
  _VideoCallState createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  var ringing = true;
  MediaStream? _localStream;
  RTCPeerConnection? pc;
  var socket = injector.get<SocketService>().socket;
  var room = injector.get<SocketService>().room;

  @override
  void initState() {
    // TODO: implement initState
    init();
    super.initState();
  }

  Future init() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    await connectSocket();
    await joinRoom();
  }

  /// konfigurasi [IO.Socket] client dan setup Listener event
  Future connectSocket() async {
    socket.onConnect((data) => print('연결 완료 !'));

    socket.on('joined', (data) {
      _sendOffer();
    });

    socket.on('pre-offer', (data) => {
      print('panggilan masuk')
    });

    socket.on('offer', (data) async {
      data = jsonDecode(data);
      await _gotOffer(RTCSessionDescription(data['sdp'], data['type']));
      await _sendAnswer();
    });

    socket.on('answer', (data) {
      data = jsonDecode(data);
      _gotAnswer(RTCSessionDescription(data['sdp'], data['type']));
    });

    socket.on('ice', (data) {
      data = jsonDecode(data);
      _gotIce(RTCIceCandidate(
          data['candidate'], data['sdpMid'], data['sdpMLineIndex']));
    });
  }

  Future exitRoom() async {
    pc!.close();
    socket.emit('pre-offer-answer', {'callerId': 'callerId', 'type':'typeID'});
    Get.back();
  }


  /// melakukan request join ke [IO.Socket]
  /// room dengan properti configurasi
  /// aturan SDP dan pear-connection
  Future joinRoom() async {
    final config = {
      'iceServers': [
        {"url": "stun:stun.l.google.com:19302"},
      ]
    };

    final sdpConstraints = {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': []
    };

    pc = await createPeerConnection(
        config, sdpConstraints); // initiialisasi pear-connection

    pc!.onIceCandidate = (ice) {
      _sendIce(ice);
    };

    pc!.onAddStream = (stream) {
      _remoteRenderer.srcObject =
          stream; // jika terdapat data yang masuk melalui peer-connection maka akan di render langsung
    };

    final mediaConstraints = {
      'audio': true,
      'video': {'facingMode': 'user'}
    };

    _localStream = await Helper.openCamera(
        mediaConstraints); // [_localStream] digunakan untuk menerima transmisi data stream dari media [CAMERA, AUDIO]

    _localStream!.getTracks().forEach((track) {
      pc!.addTrack(track,
          _localStream!); // Media Stream yang terecord tracknya di serahkan kepada pearconnection sehingga pear-connection sudah memiliki data yang terekam secara stream
    });

    _localRenderer.srcObject = _localStream; // RTC Video local dimuat disini

    socket.emit('pre-offer', room);

    setState(() {});
  }


  Future _sendPreOffer() async {
    print('send pre-offer');
    socket.emit('pre-offer', {'caller': 'callerID', 'callee':'callee'});
  }

  /// jika ada yang berhasil join dalam room maka saya akan mengirimkan
  /// peer-connection kita ke orang baru itu
  Future _sendOffer() async {
    print('send offer');
    var offer = await pc!.createOffer();
    pc!.setLocalDescription(offer);
    socket
        .emit('offer', {'offer': jsonEncode(offer.toMap()), 'roomName': room});
  }

  /// ketika ada penwaran pairing peer connection maka kita akan mersepon dengan
  /// mengenalkan penjelasakn koneksi dan konfigurasi dari user lawan tsb
  Future _gotOffer(RTCSessionDescription offer) async {
    print('got offer');
    pc!.setRemoteDescription(offer);
  }

  /// memberikan jawaban dengan mengirim kembali deskripsi dan konfigurasi peer
  /// connection yang kita miliki
  Future _sendAnswer() async {
    print('send answer');
    var answer = await pc!.createAnswer();
    pc!.setLocalDescription(answer);
    socket.emit(
        'answer', {'answer': jsonEncode(answer.toMap()), 'roomName': room});
  }

  /// mendapatkan konfigurasi peer-connection dan kofigurasi lawan pairing kita
  /// sehingga bisa kita init ke [REMOTE] peer-connection kita
  Future _gotAnswer(RTCSessionDescription answer) async {
    print('got answer');
    pc!.setRemoteDescription(answer);
  }

  /// ketika pear connection ber hasil di ini dengan [createPeerConnection()] kita
  /// akan menjelaskan protokol dan perutean yang kita miliki kepada lawan pairing
  /// agar WebRTC dapat mengkomunikasikan kita dengan perangkat jarak jauh.
  Future _sendIce(RTCIceCandidate ice) async {
    socket.emit('ice', {'answer': jsonEncode(ice.toMap()), 'roomName': room});
  }

  /// ketika kita berhasil mengetahui pear connection lawan kita
  /// akan menginisialkan protokol dan perutean yang lawan miliki kepada
  /// peer-connection kita saat ini,
  /// agar WebRTC dapat mengkomunikasikan kita dengan perangkat jarak jauh.
  Future _gotIce(RTCIceCandidate ice) async {
    pc!.addCandidate(ice);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      home: Row(
        children: [
          Expanded(child: RTCVideoView(_localRenderer)),
          Expanded(child: RTCVideoView(_remoteRenderer)),
        ],
      ),
    );
  }
}
