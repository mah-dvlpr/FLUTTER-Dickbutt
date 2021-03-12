import 'dart:async';
import 'dart:ui' as ui;
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:image/image.dart' as img_lib;

class Point {
  DateTime dateTime;
  Offset position;
  double speed;

  Point(this.position, this.speed) : dateTime = DateTime.now();

  void updatePoint(PointPhysics physics) {
    if (DateTime.now().difference(dateTime).inMilliseconds < 16) {
      return;
    }
    dateTime = DateTime.now();

    speed += physics.gravity;
    position = Offset(position.dx, position.dy + speed);
  }
}

enum PointPhysicsType { Default }

abstract class PointPhysics {
  final double gravity;

  PointPhysics._({@required this.gravity});

  factory PointPhysics(final PointPhysicsType type) {
    switch (type) {
      default:
        return PointPhysicsDefault();
    }
  }
}

class PointPhysicsDefault extends PointPhysics {
  @override
  PointPhysicsDefault() : super._(gravity: 0.5);
}

class DickButtPaintable {
  DateTime dateTime;
  final fill = Paint()..color = Colors.blue..style = PaintingStyle.fill;
  final stroke = Paint()..style= PaintingStyle.stroke..strokeWidth = 10;
  final rainbowColors = <MaterialColor>[
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
  ];
  ui.Image image;
  Queue<Point> points;

  DickButtPaintable() : points = Queue(), dateTime = DateTime.now();

  void update() {
    for (final _point in points) {
      _point.updatePoint(PointPhysics(PointPhysicsType.Default));
    }
  }

  void add(Point point) {
    if (DateTime.now().difference(dateTime).inMilliseconds < 16) {
      return;
    }
    dateTime = DateTime.now();
    
    if (points.length > 50) {
      points.removeLast();
    }
    points.addFirst(point);
  }
}

class DickButtPainter extends CustomPainter {
  DickButtPaintable _paintable;

  DickButtPainter(this._paintable);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(ui.Rect.largest, Paint()..color = Colors.white);
    var paint = Paint()..style= PaintingStyle.stroke..strokeWidth = 10;

    if (_paintable != null &&
        _paintable.points != null &&
        _paintable.points.isNotEmpty) {
      for (int i = _paintable.points.length - 1; i > 0; --i) {
        for (int j = 0; j < 6; ++j) {
          paint.color = _paintable.rainbowColors[j];
          var newOffsetStart = Offset(
              _paintable.points.elementAt(i).position.dx,
              _paintable.points.elementAt(i).position.dy +
                  _paintable.stroke.strokeWidth * (3 - j));
          var newOffsetEnd = Offset(
              _paintable.points.elementAt(i - 1).position.dx,
              _paintable.points.elementAt(i - 1).position.dy +
                  _paintable.stroke.strokeWidth * (3 - j));
          canvas.drawLine(newOffsetStart, newOffsetEnd, paint);
        }
      }

      var pos = _paintable.points.first.position -
          Offset(_paintable.image.width.toDouble(),
              _paintable.image.height.toDouble());
      canvas.drawImage(_paintable.image, pos, _paintable.fill);
    }
  }

  @override
  bool shouldRepaint(DickButtPainter oldDelegate) {
    return true;
  }
}

class DickButtAnimation extends StatefulWidget {
  @override
  _DickButtAnimationState createState() => _DickButtAnimationState();
}

class _DickButtAnimationState extends State<DickButtAnimation>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  bool _listenerAdded;
  StreamController<DickButtPaintable> _streamController;

  ui.Image _image;
  Future<bool> _imageFuture;
  DickButtPaintable _paintable;

  _DickButtAnimationState() : super() {
    _imageFuture = _loadImage('assets/images/dickbutt.png', 100, 100);
    _listenerAdded = false;

    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));

    _streamController = StreamController();
    _paintable = DickButtPaintable();

    _animationController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _imageFuture,
      builder: (_, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            if (!_listenerAdded) {
              _animationController.addListener(_updateFrame);
              _paintable.image = _image;
              _listenerAdded = !_listenerAdded;
            }
            return GestureDetector(
              onPanUpdate: _setPosition,
              onPanStart: _setPosition,
              onLongPress: _setPosition2,
              child: StreamBuilder(
                stream: _streamController.stream,
                builder: (_, snapshot) => CustomPaint(
                  painter: DickButtPainter(snapshot.data),
                  willChange: true,
                ),
              ),
            );
          default:
            return Center(
              child: Text(
                'Loading...',
                textDirection: TextDirection.ltr,
              ),
            );
        }
      },
    );
  }

  Future<bool> _loadImage(String imageAssetPath, int height, int width) async {
    final ByteData assetImageByteData = await rootBundle.load(imageAssetPath);
    img_lib.Image baseSizeImage =
        img_lib.decodeImage(assetImageByteData.buffer.asUint8List());
    img_lib.Image resizeImage =
        img_lib.copyResize(baseSizeImage, height: height, width: width);
    ui.Codec codec =
        await ui.instantiateImageCodec(img_lib.encodePng(resizeImage));
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    _image = frameInfo.image;
    return true;
  }

  void _updateFrame() {
    _paintable.update();
    _streamController.add(_paintable);
  }

  void _setPosition(dynamic details) {
    _paintable.add(Point(details.localPosition, 0));
  }

  void _setPosition2() {
    _paintable.add(Point(_paintable.points.first.position, 0));
  }
}
