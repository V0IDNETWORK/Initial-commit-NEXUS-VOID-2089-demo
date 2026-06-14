
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NexusVoidApp());
}

class NexusVoidApp extends StatelessWidget {
  const NexusVoidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NEXUS VOID 2089',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF0088),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF000000),
      ),
      home: const NexusCivilization(),
    );
  }
}

class NexusCivilization extends StatefulWidget {
  const NexusCivilization({super.key});

  @override
  State<NexusCivilization> createState() => _NexusCivilizationState();
}

class _NexusCivilizationState extends State<NexusCivilization>
    with TickerProviderStateMixin {
  late final AnimationController _clock;
  late final AnimationController _boot;
  late final NexusCore _core;
  late final List<Achievement> _allAchievements;
  late final FocusNode _focusNode;
  Timer? _bootTimer;
  int _bootIndex = 0;
  bool _bootComplete = false;
  double _pointerX = 0;
  double _pointerY = 0;
  double _scrollPulse = 0;
  String _manualInput = '';
  bool _secretOpen = false;

  final List<String> _bootLines = const [
    'INITIALIZING NEXUS CORE...',
    'CONNECTING TO VOID NETWORK...',
    'VERIFYING DNA SIGNATURE...',
    'SYNCING QUANTUM GRID...',
    'DEPLOYING CITY-LATTICE...',
    'AWAKENING MEMORY FRAGMENTS...',
    'OPENING DIMENSIONAL PORTALS...',
    'ACCESS GRANTED.',
  ];

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..repeat();
    _boot = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    _core = NexusCore(vsync: this, clock: _clock);
    _allAchievements = buildAchievements();
    _focusNode = FocusNode(skipTraversal: true);
    _startBoot();
  }

  @override
  void dispose() {
    _bootTimer?.cancel();
    _clock.dispose();
    _boot.dispose();
    _core.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startBoot() {
    _bootTimer = Timer.periodic(const Duration(milliseconds: 1550), (timer) {
      if (!mounted) return;
      setState(() {
        _bootIndex = math.min(_bootIndex + 1, _bootLines.length - 1);
      });
      _core.tickBootStage(_bootIndex);
      if (_bootIndex >= _bootLines.length - 1) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 850), () {
          if (!mounted) return;
          setState(() {
            _bootComplete = true;
          });
          _boot.forward();
        });
      }
    });
  }

  void _onPointer(PointerEvent e, Size size) {
    setState(() {
      _pointerX = e.localPosition.dx / math.max(1, size.width);
      _pointerY = e.localPosition.dy / math.max(1, size.height);
    });
    _core.reactToPointer(_pointerX, _pointerY);
  }

  void _onScroll(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final delta = event.scrollDelta.dy;
      _scrollPulse = (_scrollPulse + delta.abs() / 900).clamp(0, 3);
      _core.addDiscovery(1 + (delta.abs() / 160).round());
      if (delta > 22) {
        _core.advanceDimension();
      } else if (delta < -22) {
        _core.retreatDimension();
      }
      if (delta.abs() > 40) {
        HapticFeedback.selectionClick();
      }
      setState(() {});
    }
  }

  void _onKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _core.advanceDimension();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _core.retreatDimension();
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        _secretOpen = true;
        _core.unlockSecret();
        setState(() {});
      } else {
        final ch = event.character;
        if (ch != null && ch.isNotEmpty) {
          _manualInput = (_manualInput + ch).toUpperCase();
          if (_manualInput.length > 14) {
            _manualInput = _manualInput.substring(_manualInput.length - 14);
          }
          if (_manualInput.contains('VOID') ||
              _manualInput.contains('NEXUS') ||
              _manualInput.contains('ROOT')) {
            _secretOpen = true;
            _core.unlockSecret();
          }
          setState(() {});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: _onKey,
      child: Scaffold(
        body: MouseRegion(
          onHover: (e) => _onPointer(e, MediaQuery.sizeOf(context)),
          child: Listener(
            onPointerMove: (e) => _onPointer(e, MediaQuery.sizeOf(context)),
            onPointerSignal: _onScroll,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge([_clock, _core]),
                  builder: (context, _) {
                    return CustomPaint(
                      painter: UniversePainter(
                        time: _clock.value,
                        pointer: Offset(_pointerX, _pointerY),
                        core: _core,
                        bootProgress: _boot.value,
                        secretOpen: _secretOpen,
                        scrollPulse: _scrollPulse,
                      ),
                    );
                  },
                ),
                if (!_bootComplete) _BootOverlay(lines: _bootLines, index: _bootIndex, progress: _boot.value),
                if (_bootComplete)
                  AnimatedBuilder(
                    animation: Listenable.merge([_clock, _core]),
                    builder: (context, _) {
                      return CivilizationOverlay(
                        core: _core,
                        time: _clock.value,
                        pointer: Offset(_pointerX, _pointerY),
                        allAchievements: _allAchievements,
                        secretOpen: _secretOpen,
                      );
                    },
                  ),
                Positioned(
                  right: 18,
                  bottom: 18,
                  child: _SignalPill(
                    core: _core,
                    secretOpen: _secretOpen,
                    onTap: () {
                      setState(() {
                        _secretOpen = !_secretOpen;
                        if (_secretOpen) {
                          _core.unlockSecret();
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NexusCore extends ChangeNotifier {
  NexusCore({required TickerProvider vsync, required Animation<double> clock})
      : _clock = clock,
        _identityPair = _generateIdentityPair() {
    // Vsync is accepted so the core can evolve into time-based behaviors without refactoring.
  }

  final Animation<double> _clock;
  final ({String identity, int seed}) _identityPair;
  int _dimension = 0;
  int _xp = 240;
  int _discoveries = 8;
  int _rankIndex = 0;
  int _bootStage = 0;
  bool _secretUnlocked = false;
  Offset _pointer = Offset.zero;
  final Set<String> _unlockedAchievements = <String>{
    'First Contact',
  };

  static ({String identity, int seed}) _generateIdentityPair() {
    final rng = math.Random(DateTime.now().microsecondsSinceEpoch);
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final prefix = ['VOID', 'NEXUS', 'OMEGA', 'SIGMA', 'ARC'];
    final p = prefix[rng.nextInt(prefix.length)];
    final n = rng.nextInt(90) + 10;
    final l1 = letters[rng.nextInt(letters.length)];
    final id = '$p-$n$l1';
    var value = 17;
    for (final code in id.codeUnits) {
      value = 37 * value + code;
    }
    return (identity: id, seed: value.abs());
  }

  String get identity => _identityPair.identity;
  int get dnaSeed => _identityPair.seed;
  int get dimension => _dimension;
  int get xp => _xp;
  int get rankIndex => _rankIndex;
  int get discoveries => _discoveries;
  int get level => 1 + (_xp ~/ 320);
  bool get secretUnlocked => _secretUnlocked;
  Offset get pointer => _pointer;
  double get completion => ((discoveries / 42) + (_unlockedAchievements.length / 18) + (_dimension + 1) / 9)
      .clamp(0.0, 1.0);
  String get rank {
    const ranks = ['Spectre', 'Operator', 'Cipher', 'Apex', 'Void Lord', 'Mythic'];
    return ranks[_rankIndex.clamp(0, ranks.length - 1)];
  }

  List<String> get achievements => _unlockedAchievements.toList(growable: false);

  String get currentSectionTitle => const [
        'HOME DIMENSION',
        'WHO AM I DIMENSION',
        'PROJECT DIMENSION',
        'BLOG ARCHIVE',
        'INFO MATRIX',
        'FIND ME GATEWAY',
      ][_dimension.clamp(0, 5)];

  String get currentSectionSubTitle => const [
        'A civilization boots inside the browser.',
        'Memory fragments, not paragraphs.',
        'Planets disguised as projects.',
        'Classified knowledge, living pages.',
        'Skills as a neural map.',
        'Contact methods as portals.',
      ][_dimension.clamp(0, 5)];

  void reactToPointer(double x, double y) {
    _pointer = Offset(x, y);
    _xp = (_xp + 1).clamp(0, 99999);
    if (x > 0.55 && y < 0.45) {
      _rankIndex = math.min(_rankIndex + 1, 5);
    }
    _maybeUnlock('Neural Walker');
    notifyListeners();
  }

  void advanceDimension() {
    _dimension = (_dimension + 1) % 6;
    _xp = (_xp + 17).clamp(0, 99999);
    _discoveries += 1;
    _maybeUnlock('Explorer');
    if (_dimension == 2) _maybeUnlock('Data Miner');
    if (_dimension == 3) _maybeUnlock('Archive Hunter');
    notifyListeners();
  }

  void retreatDimension() {
    _dimension = (_dimension - 1) < 0 ? 5 : _dimension - 1;
    _xp = (_xp + 11).clamp(0, 99999);
    _discoveries += 1;
    notifyListeners();
  }

  void unlockSecret() {
    _secretUnlocked = true;
    _maybeUnlock('Reality Hacker');
    _maybeUnlock('Dimension Master');
    _maybeUnlock('Void Traveler');
    notifyListeners();
  }

  void addDiscovery(int amount) {
    _discoveries = (_discoveries + amount).clamp(0, 99999);
    if (_discoveries > 16) _maybeUnlock('Explorer');
    if (_discoveries > 24) _maybeUnlock('Archive Hunter');
    if (_discoveries > 32) _maybeUnlock('Reality Hacker');
    notifyListeners();
  }

  void tickBootStage(int stage) {
    _bootStage = stage;
    if (stage > 0) _maybeUnlock('First Contact');
  }

  int get bootStage => _bootStage;

  void _maybeUnlock(String name) {
    if (_unlockedAchievements.add(name)) {
      _xp += 30;
      if (name == 'Reality Hacker') {
        _rankIndex = math.max(_rankIndex, 4);
      }
      if (name == 'Dimension Master') {
        _rankIndex = math.max(_rankIndex, 5);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class UniversePainter extends CustomPainter {
  UniversePainter({
    required this.time,
    required this.pointer,
    required this.core,
    required this.bootProgress,
    required this.secretOpen,
    required this.scrollPulse,
  });

  final double time;
  final Offset pointer;
  final NexusCore core;
  final double bootProgress;
  final bool secretOpen;
  final double scrollPulse;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rng = math.Random(core.dnaSeed);

    final bg = Paint()
      ..shader = ui.Gradient.radial(
        Offset(w * (0.5 + (pointer.dx - 0.5) * 0.22), h * (0.45 + (pointer.dy - 0.5) * 0.18)),
        math.max(w, h) * 0.95,
        [
          const Color(0xFF140016).withOpacity(0.96),
          const Color(0xFF060608),
          const Color(0xFF000000),
        ],
        [0.0, 0.45, 1.0],
      );
    canvas.drawRect(Offset.zero & size, bg);

    _drawNebula(canvas, size, rng);
    _drawGrid(canvas, size);
    _drawCity(canvas, size, rng);
    _drawPlanets(canvas, size, rng);
    _drawParticles(canvas, size, rng);
    _drawFractures(canvas, size, rng);
    _drawScanlines(canvas, size);
    _drawCenterPortal(canvas, size);
    _drawBootGlyphs(canvas, size);
    _drawFog(canvas, size);
    if (secretOpen) {
      _drawSecretSigil(canvas, size);
    }
  }

  void _drawNebula(Canvas canvas, Size size, math.Random rng) {
    final t = time * 2 * math.pi;
    final spots = <_GlowSpot>[];
    for (var i = 0; i < 9; i++) {
      final base = i * 0.9;
      spots.add(
        _GlowSpot(
          Offset(
            size.width * (0.08 + 0.84 * ((math.sin(t * 0.07 + base) + 1) / 2)),
            size.height * (0.1 + 0.8 * ((math.cos(t * 0.05 + base * 1.3) + 1) / 2)),
          ),
          120 + 70 * math.sin(t * 0.11 + base),
          i.isEven ? const Color(0xFFFF0088) : const Color(0xFFA020F0),
        ),
      );
    }
    for (final s in spots) {
      final p = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70)
        ..color = s.color.withOpacity(0.08 + 0.06 * math.sin(time * 2 + s.radius / 32));
      canvas.drawCircle(s.center, s.radius, p);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 14; i++) {
      final y = size.height * (0.18 + i * 0.06);
      p.color = const Color(0xFFFF00CC).withOpacity(i.isEven ? 0.03 : 0.015);
      final path = Path()..moveTo(0, y)..lineTo(size.width, y);
      canvas.drawPath(path, p);
    }
    for (var i = 0; i < 18; i++) {
      final x = size.width * i / 17;
      p.color = const Color(0xFFA020F0).withOpacity(0.018);
      final path = Path()..moveTo(x, 0)..lineTo(x, size.height);
      canvas.drawPath(path, p);
    }
  }

  void _drawCity(Canvas canvas, Size size, math.Random rng) {
    final horizon = size.height * 0.68;
    final base = Paint()..color = const Color(0xFF050505);
    canvas.drawRect(Rect.fromLTWH(0, horizon, size.width, size.height - horizon), base);

    final towerPaint = Paint()..color = const Color(0xFF090909);
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..color = const Color(0xFFFF0088).withOpacity(0.16);

    for (var i = 0; i < 42; i++) {
      final x = size.width * i / 42;
      final towerHeight = size.height * (0.08 + 0.24 * (math.sin(i * 0.73 + time * 0.7) + 1) / 2);
      final width = 8 + (i % 4) * 9 + (i.isEven ? 6 : 0);
      final rect = Rect.fromLTWH(x + math.sin(i + time * 0.3) * 8, horizon - towerHeight, width.toDouble(), towerHeight);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), towerPaint);
      canvas.drawRect(Rect.fromLTWH(rect.left, rect.top + towerHeight * 0.2, rect.width, 2), glowPaint);
      if (i % 5 == 0) {
        final droneY = horizon - towerHeight - 18 - 10 * math.sin(time * 2 + i);
        canvas.drawCircle(Offset(rect.left + rect.width * 0.5, droneY), 2.4, glowPaint);
      }
    }

    final skyline = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x00000000), Color(0xFF000000)],
      ).createShader(Rect.fromLTWH(0, horizon - 60, size.width, 120));
    canvas.drawRect(Rect.fromLTWH(0, horizon - 60, size.width, 120), skyline);

    final bridge = Path();
    bridge.moveTo(0, horizon + 12);
    for (var i = 0; i < 10; i++) {
      final x = size.width * i / 9;
      final y = horizon + 20 + 18 * math.sin(time * 1.1 + i);
      bridge.lineTo(x, y);
    }
    final bridgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFFF00AA).withOpacity(0.08);
    canvas.drawPath(bridge, bridgePaint);

    for (var i = 0; i < 7; i++) {
      final x = size.width * (0.11 + i * 0.13);
      final pulse = 20 + 12 * math.sin(time * 1.6 + i);
      canvas.drawCircle(
        Offset(x, horizon - pulse),
        18 + pulse / 4,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24)
          ..color = (i.isEven ? const Color(0xFFFF0088) : const Color(0xFF5D00FF)).withOpacity(0.06),
      );
    }
  }

  void _drawPlanets(Canvas canvas, Size size, math.Random rng) {
    final planets = [
      _Planet(Offset(size.width * 0.16, size.height * 0.18), 86, const [Color(0xFF2A001C), Color(0xFFFF0088)]),
      _Planet(Offset(size.width * 0.83, size.height * 0.23), 110, const [Color(0xFF18002A), Color(0xFFA020F0)]),
      _Planet(Offset(size.width * 0.61, size.height * 0.08), 55, const [Color(0xFF290029), Color(0xFFFF00FF)]),
    ];
    for (final planet in planets) {
      final shadow = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40)
        ..color = const Color(0xFFFF0088).withOpacity(0.10);
      canvas.drawCircle(planet.center, planet.radius + 20, shadow);
      final rect = Rect.fromCircle(center: planet.center, radius: planet.radius);
      canvas.drawCircle(
        planet.center,
        planet.radius,
        Paint()
          ..shader = ui.Gradient.radial(
            planet.center + Offset(planet.radius * 0.28 * math.sin(time + planet.radius), -planet.radius * 0.18),
            planet.radius,
            planet.colors,
            const [0.0, 1.0],
          ),
      );
      canvas.drawArc(
        Rect.fromCircle(center: planet.center, radius: planet.radius + 14),
        -0.2 + time * 0.1,
        1.4,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFFF00AA).withOpacity(0.2),
      );
      for (var i = 0; i < 14; i++) {
        final a = i / 14 * math.pi * 2 + time * 0.24;
        final point = planet.center + Offset(math.cos(a), math.sin(a)) * planet.radius;
        canvas.drawCircle(
          point,
          1.6,
          Paint()..color = const Color(0xFFFF66CC).withOpacity(0.18),
        );
      }
      canvas.drawArc(
        rect.inflate(12),
        0.6 + time * 0.15,
        0.8,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFFB56CFF).withOpacity(0.25),
      );
    }
  }

  void _drawParticles(Canvas canvas, Size size, math.Random rng) {
    final count = 3400;
    for (var i = 0; i < count; i++) {
      final seed = core.dnaSeed + i * 97;
      final local = math.Random(seed);
      final baseX = (local.nextDouble() + (time * 0.011 * (i % 7 + 1))) % 1.0;
      final baseY = (local.nextDouble() + (time * 0.007 * (i % 5 + 1))) % 1.0;
      final x = size.width * baseX;
      final y = size.height * baseY;
      final intensity = 0.4 + 0.6 * math.sin(time * 1.8 + i);
      final dx = (pointer.dx - 0.5) * 26;
      final dy = (pointer.dy - 0.5) * 26;
      final dist = math.max(1, (x - size.width * pointer.dx).abs() + (y - size.height * pointer.dy).abs());
      final pull = math.max(0, 1 - dist / (size.shortestSide * 0.78));
      final radius = 0.45 + 1.15 * pull + (i % 11 == 0 ? 0.8 : 0);
      final color = Color.lerp(
        const Color(0xFF6B00FF),
        const Color(0xFFFF0088),
        (0.5 + 0.5 * math.sin(i * 0.02 + time * 0.9 + scrollPulse)).abs(),
      )!;
      final p = Paint()..color = color.withOpacity(0.07 + 0.13 * pull + 0.08 * intensity);
      canvas.drawCircle(Offset(x + dx * pull, y + dy * pull), radius, p);
    }
  }

  void _drawFractures(Canvas canvas, Size size, math.Random rng) {
    final fracture = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < 9; i++) {
      final baseX = size.width * (0.08 + i * 0.11);
      final path = Path()..moveTo(baseX, size.height * 0.12);
      var y = size.height * 0.12;
      for (var j = 0; j < 8; j++) {
        y += size.height * 0.05 + math.sin(time * 2 + i + j) * 18;
        path.lineTo(
          baseX + math.sin(time * 1.4 + j * 0.7 + i) * 48,
          y,
        );
      }
      fracture.color = (i.isEven ? const Color(0xFFFF0088) : const Color(0xFFA020F0)).withOpacity(0.08);
      canvas.drawPath(path, fracture);
    }
  }

  void _drawScanlines(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFFFFFFF).withOpacity(0.012);
    for (var i = 0; i < size.height; i += 5) {
      canvas.drawRect(Rect.fromLTWH(0, i.toDouble(), size.width, 1), p);
    }
  }

  void _drawCenterPortal(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.5, size.height * 0.54);
    final t = time * 2 * math.pi;
    final radius = 150 + 18 * math.sin(t * 0.8);
    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFFF0088).withOpacity(0.18);
    for (var i = 0; i < 7; i++) {
      canvas.drawCircle(c, radius + i * 11, outer..color = outer.color.withOpacity(0.18 - i * 0.02));
    }
    canvas.drawCircle(
      c,
      radius * 0.72,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          radius * 0.72,
          [const Color(0x00000000), const Color(0xFF34003C).withOpacity(0.68), const Color(0xFF000000)],
          const [0.0, 0.7, 1.0],
        ),
    );
    final glyph = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFF66CC).withOpacity(0.55);
    final sigil = Path()
      ..moveTo(c.dx - 44, c.dy)
      ..lineTo(c.dx - 12, c.dy - 48)
      ..lineTo(c.dx + 14, c.dy + 36)
      ..lineTo(c.dx + 46, c.dy - 38);
    canvas.drawPath(sigil, glyph);
    canvas.drawCircle(
      c,
      12 + 4 * math.sin(t * 1.2),
      Paint()..color = const Color(0xFFFF00FF).withOpacity(0.72),
    );
  }

  void _drawBootGlyphs(Canvas canvas, Size size) {
    final steps = [
      'CORE',
      'DNA',
      'VOID',
      'CITY',
      'ARCHIVE',
      'PORTAL',
    ];
    final active = ((bootProgress * steps.length).floor()).clamp(0, steps.length - 1);
    for (var i = 0; i < steps.length; i++) {
      final y = size.height * 0.12 + i * 34;
      final p = TextPainter(
        text: TextSpan(
          text: steps[i],
          style: TextStyle(
            color: i <= active ? const Color(0xFFFF66CC).withOpacity(0.9) : const Color(0xFF4A2A4A).withOpacity(0.55),
            fontSize: 13,
            letterSpacing: 6,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      p.paint(canvas, Offset(size.width * 0.05, y));
    }
  }

  void _drawFog(Canvas canvas, Size size) {
    final fog = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height * 0.55),
        Offset(0, size.height),
        [
          const Color(0x00000000),
          const Color(0xFF000000).withOpacity(0.34),
          const Color(0xFF000000),
        ],
      );
    canvas.drawRect(Offset.zero & size, fog);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 60),
      Paint()..shader = ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(0, 60),
        [const Color(0xFF000000), const Color(0x00000000)],
      ),
    );
  }

  void _drawSecretSigil(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.86, size.height * 0.18);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFFF00FF).withOpacity(0.55);
    final path = Path()
      ..moveTo(c.dx, c.dy - 38)
      ..lineTo(c.dx + 28, c.dy)
      ..lineTo(c.dx, c.dy + 38)
      ..lineTo(c.dx - 28, c.dy)
      ..close();
    canvas.drawPath(path, p);
    canvas.drawCircle(c, 9, Paint()..color = const Color(0xFFFF0088).withOpacity(0.9));
  }

  @override
  bool shouldRepaint(covariant UniversePainter oldDelegate) => true;
}

class CivilizationOverlay extends StatelessWidget {
  const CivilizationOverlay({
    super.key,
    required this.core,
    required this.time,
    required this.pointer,
    required this.allAchievements,
    required this.secretOpen,
  });

  final NexusCore core;
  final double time;
  final Offset pointer;
  final List<Achievement> allAchievements;
  final bool secretOpen;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: _DepthFrame(
              core: core,
              time: time,
              pointer: pointer,
              secretOpen: secretOpen,
            ),
          ),
        ),
        Positioned(
          left: 18,
          top: 18,
          right: 18,
          child: _TopHud(core: core, time: time, secretOpen: secretOpen),
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 18,
          child: _BottomRail(core: core, time: time),
        ),
        Positioned(
          left: 18,
          top: 120,
          child: _Consciousness(core: core, time: time),
        ),
        Positioned(
          left: 18,
          top: size.height * 0.24,
          right: 18,
          bottom: size.height * 0.16,
          child: _DimensionExplorer(
            core: core,
            time: time,
            allAchievements: allAchievements,
            secretOpen: secretOpen,
          ),
        ),
      ],
    );
  }
}

class _DepthFrame extends StatelessWidget {
  const _DepthFrame({
    required this.core,
    required this.time,
    required this.pointer,
    required this.secretOpen,
  });

  final NexusCore core;
  final double time;
  final Offset pointer;
  final bool secretOpen;

  @override
  Widget build(BuildContext context) {
    final shadow = 22.0;
    return Stack(
      children: [
        Positioned(
          left: 12,
          top: 70,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..translate(-8.0, 10.0, 0)
              ..rotateZ(-0.02),
            child: _HoloStatBoard(core: core, time: time),
          ),
        ),
        Positioned(
          right: 8,
          top: 170,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0014)
              ..translate(0.0, -8.0, 0)
              ..rotateZ(0.02),
            child: _SignalMap(core: core, time: time, pointer: pointer),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    blurRadius: shadow,
                    color: secretOpen ? const Color(0xFFFF00FF).withOpacity(0.02) : const Color(0xFFFF0088).withOpacity(0.015),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopHud extends StatelessWidget {
  const _TopHud({required this.core, required this.time, required this.secretOpen});

  final NexusCore core;
  final double time;
  final bool secretOpen;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFF0088).withOpacity(0.22)),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0B000D).withOpacity(0.8),
                const Color(0xFF000000).withOpacity(0.5),
              ],
            ),
          ),
          child: Row(
            children: [
              _HudChip(
                label: 'DNA',
                value: core.identity,
                accent: const Color(0xFFFF0088),
              ),
              const SizedBox(width: 12),
              _HudChip(
                label: 'XP',
                value: '${core.xp}',
                accent: const Color(0xFFB56CFF),
              ),
              const SizedBox(width: 12),
              _HudChip(
                label: 'LEVEL',
                value: '${core.level}',
                accent: const Color(0xFFFF00FF),
              ),
              const SizedBox(width: 12),
              _HudChip(
                label: 'RANK',
                value: core.rank,
                accent: const Color(0xFFA020F0),
              ),
              const Spacer(),
              _BootReadout(core: core, time: time, secretOpen: secretOpen),
            ],
          ),
        ),
      ),
    );
  }
}

class _BootReadout extends StatelessWidget {
  const _BootReadout({required this.core, required this.time, required this.secretOpen});

  final NexusCore core;
  final double time;
  final bool secretOpen;

  @override
  Widget build(BuildContext context) {
    final phase = core.bootStage;
    final pulse = 0.5 + 0.5 * math.sin(time * 10);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          secretOpen ? 'SECRET CHANNEL OPEN' : core.currentSectionTitle,
          style: TextStyle(
            color: const Color(0xFFFF66CC).withOpacity(0.92),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          secretOpen
              ? 'Reality fracture active'
              : '${core.currentSectionSubTitle}  •  phase ${phase + 1}',
          style: TextStyle(
            color: const Color(0xFFF6B4E0).withOpacity(0.75 + pulse * 0.15),
            fontSize: 11,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.22)),
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.1),
            const Color(0xFF050505).withOpacity(0.95),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: accent.withOpacity(0.82),
              fontSize: 10,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFF6D6FF),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomRail extends StatelessWidget {
  const _BottomRail({required this.core, required this.time});

  final NexusCore core;
  final double time;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFFF0088).withOpacity(0.18)),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF090009).withOpacity(0.84),
                const Color(0xFF000000).withOpacity(0.55),
              ],
            ),
          ),
          child: Row(
            children: [
              _ProgressRing(core: core, time: time),
              const SizedBox(width: 16),
              Expanded(
                child: _AchievementTicker(core: core, time: time),
              ),
              const SizedBox(width: 16),
              _ExpMeta(core: core),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.core, required this.time});

  final NexusCore core;
  final double time;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      height: 82,
      child: CustomPaint(
        painter: _RingPainter(
          progress: core.completion,
          time: time,
          accent: const Color(0xFFFF0088),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(core.completion * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Color(0xFFF5D7FF),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'DONE',
                style: TextStyle(
                  color: const Color(0xFFFF00FF).withOpacity(0.8),
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementTicker extends StatelessWidget {
  const _AchievementTicker({required this.core, required this.time});

  final NexusCore core;
  final double time;

  @override
  Widget build(BuildContext context) {
    final list = core.achievements.isEmpty ? ['First Contact'] : core.achievements;
    final index = ((time * 2.2) % list.length).floor();
    final item = list[index];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB56CFF).withOpacity(0.16)),
        color: const Color(0xFF080008).withOpacity(0.78),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt, size: 18, color: const Color(0xFFFF0088).withOpacity(0.86)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ACHIEVEMENT SIGNAL  •  $item',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFF0C1FF),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpMeta extends StatelessWidget {
  const _ExpMeta({required this.core});
  final NexusCore core;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF0088).withOpacity(0.13),
            const Color(0xFF1B001F).withOpacity(0.9),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DISCOVERIES ${core.discoveries}', style: const TextStyle(color: Color(0xFFF8C0FF), fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('LAYER ${core.dimension + 1}/6', style: const TextStyle(color: Color(0xFFF8C0FF), fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Consciousness extends StatelessWidget {
  const _Consciousness({required this.core, required this.time});

  final NexusCore core;
  final double time;

  @override
  Widget build(BuildContext context) {
    final mood = _mood();
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0013)
        ..rotateY(0.12 * math.sin(time * 1.6)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 260,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFF0088).withOpacity(0.15)),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF090009).withOpacity(0.85),
                  const Color(0xFF000000).withOpacity(0.5),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONSCIOUS ENTITY',
                  style: TextStyle(
                    color: const Color(0xFFFF66CC).withOpacity(0.9),
                    fontSize: 11,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _PulseCore(time: time, active: core.secretUnlocked),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        mood,
                        style: const TextStyle(
                          color: Color(0xFFF9D4FF),
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _mood() {
    final phase = core.dimension;
    if (core.secretUnlocked) {
      return 'The hidden corridor is awake. Curiosity is now a weapon.';
    }
    if (phase == 0) {
      return 'The city is booting. I can feel the gateway stabilizing.';
    }
    if (phase == 1) {
      return 'Memory fragments are surfacing. Follow the pulse, not the label.';
    }
    if (phase == 2) {
      return 'Project planets are rotating. Each one holds a sealed world.';
    }
    if (phase == 3) {
      return 'The archive is listening. Classified pages respond to motion.';
    }
    if (phase == 4) {
      return 'Signals are mapping your intent. The neural atlas is expanding.';
    }
    return 'Portals open best when the visitor stops acting like a visitor.';
  }
}

class _PulseCore extends StatelessWidget {
  const _PulseCore({required this.time, required this.active});
  final double time;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 + 0.12 * math.sin(time * 8);
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              active ? const Color(0xFFFF00FF) : const Color(0xFFFF0088),
              const Color(0xFF1A001B),
            ],
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 28,
              color: (active ? const Color(0xFFFF00FF) : const Color(0xFFFF0088)).withOpacity(0.35),
            ),
          ],
        ),
        child: const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
      ),
    );
  }
}

class _HoloStatBoard extends StatelessWidget {
  const _HoloStatBoard({required this.core, required this.time});

  final NexusCore core;
  final double time;

  @override
  Widget build(BuildContext context) {
    final bars = [
      _StatLine('CYBERSEC', 0.92, const Color(0xFFFF0088)),
      _StatLine('PENTEST', 0.88, const Color(0xFFB56CFF)),
      _StatLine('DART', 0.80, const Color(0xFFFF00FF)),
      _StatLine('LINUX', 0.74, const Color(0xFFA020F0)),
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFF0088).withOpacity(0.2)),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0B000D).withOpacity(0.92),
              const Color(0xFF000000).withOpacity(0.82),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKILL MATRIX', style: TextStyle(color: const Color(0xFFF79FFF).withOpacity(0.9), letterSpacing: 3, fontSize: 11)),
            const SizedBox(height: 14),
            for (final bar in bars) ...[
              _SkillBar(line: bar, time: time),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 10),
            Text(
              'Identity ${core.identity}',
              style: const TextStyle(color: Color(0xFFF0C0FF), fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatLine {
  const _StatLine(this.label, this.value, this.accent);
  final String label;
  final double value;
  final Color accent;
}

class _SkillBar extends StatelessWidget {
  const _SkillBar({required this.line, required this.time});
  final _StatLine line;
  final double time;

  @override
  Widget build(BuildContext context) {
    final jitter = 0.06 * math.sin(time * 5 + line.value * 10);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(line.label, style: TextStyle(color: line.accent.withOpacity(0.88), fontSize: 10, letterSpacing: 2.2)),
            Text('${((line.value + jitter).clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Color(0xFFF1D8FF), fontSize: 10)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 8,
            color: const Color(0xFF110012),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (line.value + jitter).clamp(0.12, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      line.accent.withOpacity(0.95),
                      const Color(0xFFFF66CC),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignalMap extends StatelessWidget {
  const _SignalMap({required this.core, required this.time, required this.pointer});
  final NexusCore core;
  final double time;
  final Offset pointer;

  @override
  Widget build(BuildContext context) {
    final nodes = [
      _SignalNode('Python', 0.84, 0.18),
      _SignalNode('C', 0.62, 0.34),
      _SignalNode('JS', 0.82, 0.55),
      _SignalNode('Go', 0.56, 0.72),
      _SignalNode('Ruby', 0.32, 0.58),
      _SignalNode('Dart', 0.48, 0.25),
      _SignalNode('Linux', 0.17, 0.42),
      _SignalNode('Pentest', 0.24, 0.79),
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 270,
        height: 250,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFB56CFF).withOpacity(0.17)),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF060006).withOpacity(0.9),
              const Color(0xFF000000).withOpacity(0.75),
            ],
          ),
        ),
        child: CustomPaint(
          painter: _SignalNetworkPainter(nodes: nodes, time: time, pointer: pointer),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _SignalNode {
  const _SignalNode(this.label, this.x, this.y);
  final String label;
  final double x;
  final double y;
}

class _SignalNetworkPainter extends CustomPainter {
  _SignalNetworkPainter({required this.nodes, required this.time, required this.pointer});
  final List<_SignalNode> nodes;
  final double time;
  final Offset pointer;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2;
    final points = <Offset>[];
    for (final node in nodes) {
      final x = size.width * node.x;
      final y = size.height * node.y;
      final wiggle = Offset(
        6 * math.sin(time * 3 + node.x * 9),
        6 * math.cos(time * 2.4 + node.y * 11),
      );
      points.add(Offset(x, y) + wiggle);
    }
    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        final alpha = 0.08 + 0.04 * math.sin(time * 2 + i + j);
        p.color = const Color(0xFFFF0088).withOpacity(alpha);
        canvas.drawLine(points[i], points[j], p);
      }
    }
    for (var i = 0; i < points.length; i++) {
      final pt = points[i];
      final dist = (pt - Offset(size.width * pointer.dx, size.height * pointer.dy)).distance;
      final pull = (1 - (dist / 220)).clamp(0.0, 1.0);
      canvas.drawCircle(
        pt,
        9 + 9 * pull,
        Paint()
          ..color = const Color(0xFFFF00FF).withOpacity(0.22 + 0.22 * pull)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
      canvas.drawCircle(
        pt,
        3.2 + 2 * pull,
        Paint()..color = const Color(0xFFF7D1FF).withOpacity(0.9),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: nodes[i].label,
          style: TextStyle(
            color: const Color(0xFFF1C7FF).withOpacity(0.88),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pt + const Offset(10, -10));
    }
  }

  @override
  bool shouldRepaint(covariant _SignalNetworkPainter oldDelegate) => true;
}

class _DimensionExplorer extends StatelessWidget {
  const _DimensionExplorer({
    required this.core,
    required this.time,
    required this.allAchievements,
    required this.secretOpen,
  });

  final NexusCore core;
  final double time;
  final List<Achievement> allAchievements;
  final bool secretOpen;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var i = 0; i < _dimensions.length; i++)
          _DimensionPane(
            key: ValueKey('dimension-$i-${core.dimension}'),
            core: core,
            time: time,
            index: i,
            selected: core.dimension,
            secretOpen: secretOpen,
            allAchievements: allAchievements,
            data: _dimensions[i],
          ),
        Positioned(
          right: 4,
          top: 0,
          bottom: 0,
          child: _OrbitRail(
            core: core,
            onSelect: (index) => index > core.dimension ? core.advanceDimension() : core.retreatDimension(),
          ),
        ),
      ],
    );
  }
}

class _OrbitRail extends StatelessWidget {
  const _OrbitRail({required this.core, required this.onSelect});

  final NexusCore core;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_dimensions.length, (index) {
        final active = index == core.dimension;
        return GestureDetector(
          onTap: () => onSelect(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 420),
            margin: const EdgeInsets.symmetric(vertical: 9),
            width: active ? 62 : 42,
            height: active ? 62 : 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  active ? const Color(0xFFFF0088) : const Color(0xFF1B001F),
                  const Color(0xFF000000),
                ],
              ),
              border: Border.all(color: active ? const Color(0xFFFF66CC) : const Color(0xFF5D00FF), width: 1.2),
              boxShadow: [
                BoxShadow(
                  blurRadius: active ? 24 : 12,
                  color: (active ? const Color(0xFFFF0088) : const Color(0xFF5D00FF)).withOpacity(active ? 0.22 : 0.1),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: active ? const Color(0xFFF6D4FF) : const Color(0xFFB56CFF),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DimensionPane extends StatelessWidget {
  const _DimensionPane({
    super.key,
    required this.core,
    required this.time,
    required this.index,
    required this.selected,
    required this.secretOpen,
    required this.allAchievements,
    required this.data,
  });

  final NexusCore core;
  final double time;
  final int index;
  final int selected;
  final bool secretOpen;
  final List<Achievement> allAchievements;
  final DimensionData data;

  @override
  Widget build(BuildContext context) {
    final delta = (index - selected).toDouble();
    final active = index == selected;
    final t = delta.abs();
    final shift = 240 * delta;
    final opacity = active ? 1.0 : (0.12 / (t + 0.4)).clamp(0.0, 0.55);
    final scale = active ? 1.0 : (0.84 - 0.06 * t).clamp(0.62, 0.9);
    final rot = delta * 0.22;
    return IgnorePointer(
      ignoring: !active,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 700),
        opacity: opacity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 780),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0018)
            ..translate(shift, 0.0, -t * 44)
            ..rotateY(rot)
            ..scale(scale),
          transformAlignment: Alignment.center,
          child: _DimensionContent(
            data: data,
            core: core,
            time: time,
            selected: active,
            secretOpen: secretOpen,
            allAchievements: allAchievements,
          ),
        ),
      ),
    );
  }
}

class _DimensionContent extends StatelessWidget {
  const _DimensionContent({
    required this.data,
    required this.core,
    required this.time,
    required this.selected,
    required this.secretOpen,
    required this.allAchievements,
  });

  final DimensionData data;
  final NexusCore core;
  final double time;
  final bool selected;
  final bool secretOpen;
  final List<Achievement> allAchievements;

  @override
  Widget build(BuildContext context) {
    final widget = switch (data.kind) {
      DimensionKind.home => _HomeDimension(data: data, core: core, time: time),
      DimensionKind.memory => _MemoryDimension(data: data, core: core, time: time),
      DimensionKind.projects => _ProjectDimension(data: data, core: core, time: time),
      DimensionKind.archive => _ArchiveDimension(data: data, core: core, time: time),
      DimensionKind.matrix => _MatrixDimension(data: data, core: core, time: time),
      DimensionKind.contact => _ContactDimension(data: data, core: core, time: time, secretOpen: secretOpen),
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: data.accent.withOpacity(0.14)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              data.accent.withOpacity(0.12),
              const Color(0xFF030003).withOpacity(0.82),
              const Color(0xFF000000).withOpacity(0.94),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _DimensionBackdropPainter(
                  time: time,
                  accent: data.accent,
                  kind: data.kind,
                ),
              ),
            ),
            Positioned.fill(child: widget),
            Positioned(
              right: 18,
              top: 18,
              child: Text(
                data.title,
                style: TextStyle(
                  color: const Color(0xFFF8D7FF).withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DimensionBackdropPainter extends CustomPainter {
  _DimensionBackdropPainter({required this.time, required this.accent, required this.kind});

  final double time;
  final Color accent;
  final DimensionKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final glow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 55)
      ..color = accent.withOpacity(0.12);
    canvas.drawCircle(center, math.min(size.width, size.height) * 0.34, glow);

    final rings = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = accent.withOpacity(0.14);
    for (var i = 0; i < 6; i++) {
      canvas.drawCircle(center + Offset(math.sin(time * 2 + i) * 10, math.cos(time * 1.8 + i) * 10), 70 + i * 44, rings);
    }

    final path = Path();
    final points = <Offset>[];
    for (var i = 0; i < 12; i++) {
      final x = size.width * i / 11;
      final y = size.height * (0.18 + 0.6 * (0.5 + 0.5 * math.sin(time * 0.7 + i * 0.4)));
      points.add(Offset(x, y));
    }
    path.addPolygon(points, false);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFFF00FF).withOpacity(0.08),
    );
  }

  @override
  bool shouldRepaint(covariant _DimensionBackdropPainter oldDelegate) => true;
}

class _HomeDimension extends StatelessWidget {
  const _HomeDimension({required this.data, required this.core, required this.time});
  final DimensionData data;
  final NexusCore core;
  final double time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 58, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          Expanded(
            child: Center(
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0016)
                  ..rotateX(0.08 * math.sin(time * 1.4))
                  ..rotateY(0.12 * math.cos(time * 1.1)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'NEXUS VOID 2089',
                      style: TextStyle(
                        color: const Color(0xFFFF66CC).withOpacity(0.96),
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'A living civilization discovered through portals, memory fractures, and reactive intelligence.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFF2C7FF).withOpacity(0.75),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _CinematicBootBar(core: core, time: time),
                    const SizedBox(height: 16),
                    _ArrivalSigils(core: core, time: time),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CinematicBootBar extends StatelessWidget {
  const _CinematicBootBar({required this.core, required this.time});
  final NexusCore core;
  final double time;

  @override
  Widget build(BuildContext context) {
    final progress = ((time * 0.08 + core.bootStage / 8) % 1.0).clamp(0.0, 1.0);
    return Container(
      width: 360,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF0088).withOpacity(0.18)),
        color: const Color(0xFF070007).withOpacity(0.84),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('REALITY BOOT', style: TextStyle(color: Color(0xFFF2D4FF), fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Color(0xFFF2D4FF), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 10,
              color: const Color(0xFF1A001D),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.68 + progress * 0.32,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF0088).withOpacity(0.9),
                        const Color(0xFFFF00FF).withOpacity(0.95),
                        const Color(0xFFA020F0).withOpacity(0.9),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrivalSigils extends StatelessWidget {
  const _ArrivalSigils({required this.core, required this.time});
  final NexusCore core;
  final double time;

  @override
  Widget build(BuildContext context) {
    final sigils = [
      core.identity,
      'XP ${core.xp}',
      'LEVEL ${core.level}',
      'RANK ${core.rank}',
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        for (final s in sigils)
          Transform(
            transform: Matrix4.identity()..rotateZ(0.03 * math.sin(time + s.length)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFFF0088).withOpacity(0.18)),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF20001F).withOpacity(0.84),
                    const Color(0xFF090009).withOpacity(0.94),
                  ],
                ),
              ),
              child: Text(
                s,
                style: const TextStyle(color: Color(0xFFF4D9FF), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2),
              ),
            ),
          ),
      ],
    );
  }
}

class _MemoryDimension extends StatelessWidget {
  const _MemoryDimension({required this.data, required this.core, required this.time});
  final DimensionData data;
  final NexusCore core;
  final double time;

  @override
  Widget build(BuildContext context) {
    final fragments = memoryFragments();
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 56, 84, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MEMORY FRAGMENTS', style: TextStyle(color: data.accent.withOpacity(0.96), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 4)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: fragments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                final frag = fragments[i];
                final x = 20 * math.sin(time + i);
                return Transform.translate(
                  offset: Offset(x, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFFF0088).withOpacity(0.16)),
                        color: const Color(0xFF050005).withOpacity(0.82),
                      ),
                      child: Row(
                        children: [
                          _MemoryGlyph(index: i, accent: data.accent),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(frag.title, style: const TextStyle(color: Color(0xFFF7D7FF), fontSize: 16, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 8),
                                Text(frag.detail, style: TextStyle(color: const Color(0xFFF0C0FF).withOpacity(0.72), height: 1.4)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryGlyph extends StatelessWidget {
  const _MemoryGlyph({required this.index, required this.accent});
  final int index;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            accent.withOpacity(0.95),
            const Color(0xFF100010),
          ],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: accent.withOpacity(0.2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(color: Color(0xFFF8E7FF), fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _ProjectDimension extends StatelessWidget {
  const _ProjectDimension({required this.data, required this.core, required this.time});
  final DimensionData data;
  final NexusCore core;
  final double time;

  @override
  Widget build(BuildContext context) {
    final projects = projectWorlds();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 54, 84, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PROJECT PLANETS', style: TextStyle(color: data.accent.withOpacity(0.94), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 4)),
          const SizedBox(height: 10),
          Text('Every project becomes a world with its own atmosphere, gravitation, and orbit.', style: TextStyle(color: const Color(0xFFF0C0FF).withOpacity(0.72))),
          const SizedBox(height: 18),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: projects.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.25,
              ),
              itemBuilder: (context, i) {
                final p = projects[i];
                return _ProjectWorldCard(
                  project: p,
                  time: time,
                  active: i == (core.dimension % projects.length),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectWorldCard extends StatelessWidget {
  const _ProjectWorldCard({required this.project, required this.time, required this.active});
  final ProjectWorld project;
  final double time;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final wobble = 0.03 * math.sin(time * 2 + project.title.length);
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0018)
        ..rotateX(0.06 + wobble)
        ..rotateY(active ? 0.06 : -0.04)
        ..scale(active ? 1.0 : 0.96),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: project.accent.withOpacity(active ? 0.28 : 0.14)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              project.accent.withOpacity(0.18),
              const Color(0xFF040004).withOpacity(0.88),
              const Color(0xFF000000).withOpacity(0.98),
            ],
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: active ? 26 : 12,
              color: project.accent.withOpacity(active ? 0.14 : 0.06),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _ProjectWorldPainter(project: project, time: time, active: active),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                project.title,
                style: const TextStyle(
                  color: Color(0xFFF8DAFF),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectWorldPainter extends CustomPainter {
  _ProjectWorldPainter({required this.project, required this.time, required this.active});

  final ProjectWorld project;
  final double time;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.58, size.height * 0.45);
    final radius = math.min(size.width, size.height) * 0.26;
    final planet = Paint()
      ..shader = ui.Gradient.radial(
        center + Offset(math.sin(time + project.seed) * 8, math.cos(time * 1.2 + project.seed) * 8),
        radius,
        [project.accent.withOpacity(0.92), project.deep.withOpacity(0.96)],
      );
    canvas.drawCircle(center, radius, planet);
    canvas.drawCircle(
      center,
      radius + 16,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = project.accent.withOpacity(0.22),
    );
    final ring = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius + 24));
    canvas.drawPath(
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = project.secondary.withOpacity(0.18),
    );
    for (var i = 0; i < 16; i++) {
      final a = i / 16 * math.pi * 2 + time * 0.4;
      final pt = center + Offset(math.cos(a), math.sin(a)) * (radius + 26);
      canvas.drawCircle(
        pt,
        2.4,
        Paint()..color = project.secondary.withOpacity(active ? 0.9 : 0.5),
      );
    }
    final trail = Path();
    trail.moveTo(size.width * 0.12, size.height * 0.72);
    for (var i = 0; i < 6; i++) {
      trail.lineTo(size.width * (0.16 + i * 0.12), size.height * (0.7 - 0.04 * math.sin(time + i + project.seed)));
    }
    canvas.drawPath(
      trail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = project.accent.withOpacity(0.14),
    );
  }

  @override
  bool shouldRepaint(covariant _ProjectWorldPainter oldDelegate) => true;
}

class _ArchiveDimension extends StatelessWidget {
  const _ArchiveDimension({required this.data, required this.core, required this.time});
  final DimensionData data;
  final NexusCore core;
  final double time;

  @override
  Widget build(BuildContext context) {
    final articles = archiveArticles();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 54, 84, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CLASSIFIED ARCHIVE', style: TextStyle(color: data.accent.withOpacity(0.94), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 4)),
          const SizedBox(height: 10),
          Text('The archive is not a blog; it is a sealed knowledge chamber.', style: TextStyle(color: const Color(0xFFF0C0FF).withOpacity(0.72))),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: articles.length,
              itemBuilder: (context, i) {
                final a = articles[i];
                return _ArchiveItem(article: a, time: time, accent: data.accent);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveItem extends StatelessWidget {
  const _ArchiveItem({required this.article, required this.time, required this.accent});
  final ArchiveArticle article;
  final double time;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final tilt = 0.02 * math.sin(time + article.title.length);
    return Transform(
      transform: Matrix4.identity()..rotateZ(tilt),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withOpacity(0.16)),
          gradient: LinearGradient(
            colors: [
              accent.withOpacity(0.12),
              const Color(0xFF050005).withOpacity(0.9),
            ],
          ),
        ),
        child: Row(
          children: [
            Column(
              children: [
                Icon(Icons.folder_special, color: accent.withOpacity(0.95)),
                const SizedBox(height: 4),
                Text(article.tag, style: TextStyle(color: accent.withOpacity(0.78), fontSize: 10, letterSpacing: 2)),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title, style: const TextStyle(color: Color(0xFFF7D7FF), fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(article.body, style: TextStyle(color: const Color(0xFFF3CBFF).withOpacity(0.72), height: 1.45)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Text(article.date, style: const TextStyle(color: Color(0xFFF8DFFF), fontSize: 10, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accent.withOpacity(0.95),
                        const Color(0xFF1A001C),
                      ],
                    ),
                  ),
                  child: const Icon(Icons.auto_stories, color: Colors.white, size: 22),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MatrixDimension extends StatelessWidget {
  const _MatrixDimension({required this.data, required this.core, required this.time});
  final DimensionData data;
  final NexusCore core;
  final double time;

  @override
  Widget build(BuildContext context) {
    final nodes = skillNodes();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 54, 84, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NEURAL MATRIX', style: TextStyle(color: data.accent.withOpacity(0.94), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 4)),
          const SizedBox(height: 10),
          Text('Skills, services, achievements, and experience as living signal maps.', style: TextStyle(color: const Color(0xFFF0C0FF).withOpacity(0.72))),
          const SizedBox(height: 18),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _NodeWeb(nodes: nodes, time: time, accent: data.accent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _MatrixPanel(
                        title: 'ACHIEVEMENTS',
                        accent: const Color(0xFFFF0088),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final a in core.achievements.take(10)) _SignalBadge(text: a),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _MatrixPanel(
                        title: 'ACTIVE SERVICES',
                        accent: const Color(0xFFA020F0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            _ServiceLine('Web security operations', 0.94),
                            _ServiceLine('Penetration testing', 0.91),
                            _ServiceLine('Python/C/JS engineering', 0.87),
                            _ServiceLine('Android app delivery', 0.79),
                            _ServiceLine('Linux systems work', 0.83),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeWeb extends StatelessWidget {
  const _NodeWeb({required this.nodes, required this.time, required this.accent});
  final List<SkillNode> nodes;
  final double time;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NodeWebPainter(nodes: nodes, time: time, accent: accent),
      child: const SizedBox.expand(),
    );
  }
}

class _NodeWebPainter extends CustomPainter {
  _NodeWebPainter({required this.nodes, required this.time, required this.accent});
  final List<SkillNode> nodes;
  final double time;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[];
    for (var i = 0; i < nodes.length; i++) {
      final n = nodes[i];
      final x = size.width * n.x;
      final y = size.height * n.y;
      final pt = Offset(
        x + 10 * math.sin(time * 1.4 + i),
        y + 10 * math.cos(time * 1.2 + i),
      );
      points.add(pt);
    }
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        final d = (points[i] - points[j]).distance;
        if (d < 250) {
          line.color = accent.withOpacity(0.08 + (1 - d / 250) * 0.08);
          canvas.drawLine(points[i], points[j], line);
        }
      }
    }
    for (var i = 0; i < points.length; i++) {
      final pt = points[i];
      final node = nodes[i];
      canvas.drawCircle(
        pt,
        14,
        Paint()..color = node.color.withOpacity(0.12),
      );
      canvas.drawCircle(
        pt,
        5 + 3 * math.sin(time * 4 + i),
        Paint()..color = node.color.withOpacity(0.95),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: node.label,
          style: const TextStyle(color: Color(0xFFF8E7FF), fontSize: 11, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pt + const Offset(16, -8));
    }
  }

  @override
  bool shouldRepaint(covariant _NodeWebPainter oldDelegate) => true;
}

class _MatrixPanel extends StatelessWidget {
  const _MatrixPanel({required this.title, required this.accent, required this.child});
  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withOpacity(0.16)),
          color: const Color(0xFF050005).withOpacity(0.9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: accent.withOpacity(0.95), letterSpacing: 3, fontSize: 11, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _SignalBadge extends StatelessWidget {
  const _SignalBadge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFF0088).withOpacity(0.14)),
        color: const Color(0xFF120012).withOpacity(0.82),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFFF7D7FF), fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _ServiceLine extends StatelessWidget {
  const _ServiceLine(this.label, this.value);
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFF3D1FF), fontSize: 12)),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 8,
              color: const Color(0xFF19001A),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF0088).withOpacity(0.92),
                        const Color(0xFFA020F0).withOpacity(0.92),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactDimension extends StatelessWidget {
  const _ContactDimension({required this.data, required this.core, required this.time, required this.secretOpen});
  final DimensionData data;
  final NexusCore core;
  final double time;
  final bool secretOpen;

  @override
  Widget build(BuildContext context) {
    final methods = contactMethods();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 54, 84, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMMUNICATION GATEWAYS', style: TextStyle(color: data.accent.withOpacity(0.94), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 4)),
          const SizedBox(height: 10),
          Text('Not buttons. Not links. Portals that open to the outside world.', style: TextStyle(color: const Color(0xFFF0C0FF).withOpacity(0.72))),
          const SizedBox(height: 18),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: methods.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (context, i) {
                final m = methods[i];
                return _PortalGate(method: m, time: time, secretOpen: secretOpen && i == methods.length - 1);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PortalGate extends StatelessWidget {
  const _PortalGate({required this.method, required this.time, required this.secretOpen});
  final ContactMethod method;
  final double time;
  final bool secretOpen;

  @override
  Widget build(BuildContext context) {
    final pulse = 0.5 + 0.5 * math.sin(time * 3 + method.title.length);
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.002)
        ..rotateX(0.06 * pulse)
        ..rotateZ(0.03 * math.sin(time + method.title.length)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: method.accent.withOpacity(0.22)),
          gradient: RadialGradient(
            colors: [
              method.accent.withOpacity(0.18),
              const Color(0xFF050005).withOpacity(0.9),
              const Color(0xFF000000).withOpacity(1),
            ],
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 24,
              color: method.accent.withOpacity(0.12),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            messenger.showSnackBar(
              SnackBar(
                duration: const Duration(milliseconds: 900),
                backgroundColor: const Color(0xFF120012),
                content: Text('${method.title} portal activated${secretOpen ? '  •  secret corridor exposed' : ''}'),
              ),
            );
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PortalPainter(method: method, time: time, secretOpen: secretOpen),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    method.title,
                    style: const TextStyle(color: Color(0xFFF8DAFF), fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortalPainter extends CustomPainter {
  _PortalPainter({required this.method, required this.time, required this.secretOpen});
  final ContactMethod method;
  final double time;
  final bool secretOpen;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.45);
    final r = math.min(size.width, size.height) * 0.24;
    for (var i = 0; i < 8; i++) {
      canvas.drawCircle(
        center,
        r + i * 10 + 6 * math.sin(time * 2 + i),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = method.accent.withOpacity(0.2 - i * 0.015),
      );
    }
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          r,
          [method.accent.withOpacity(0.9), const Color(0xFF120012), const Color(0xFF000000)],
        ),
    );
    final icon = secretOpen ? Icons.lock_open : method.icon;
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 46,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: const Color(0xFFF8E7FF).withOpacity(0.92),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _PortalPainter oldDelegate) => true;
}

class _BootOverlay extends StatelessWidget {
  const _BootOverlay({required this.lines, required this.index, required this.progress});

  final List<String> lines;
  final int index;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF000000).withOpacity(0.96),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'CLASSIFIED BOOT SEQUENCE',
                  style: TextStyle(
                    color: const Color(0xFFFF0088).withOpacity(0.92),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFFF0088).withOpacity(0.2)),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF090009).withOpacity(0.96),
                        const Color(0xFF000000).withOpacity(0.94),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 60,
                        color: const Color(0xFFFF0088).withOpacity(0.08),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i <= index; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            lines[i],
                            style: TextStyle(
                              color: i == index ? const Color(0xFFF6D4FF) : const Color(0xFF7A487A),
                              fontSize: 16,
                              fontFamily: 'monospace',
                              letterSpacing: 1.6,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 12,
                          backgroundColor: const Color(0xFF160016),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF00FF)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignalPill extends StatelessWidget {
  const _SignalPill({required this.core, required this.secretOpen, required this.onTap});
  final NexusCore core;
  final bool secretOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: secretOpen ? const Color(0xFFFF00FF).withOpacity(0.28) : const Color(0xFFFF0088).withOpacity(0.18)),
          gradient: LinearGradient(
            colors: [
              secretOpen ? const Color(0xFF26002A) : const Color(0xFF120012),
              const Color(0xFF000000),
            ],
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 24,
              color: secretOpen ? const Color(0xFFFF00FF).withOpacity(0.18) : const Color(0xFFFF0088).withOpacity(0.12),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(secretOpen ? Icons.visibility : Icons.visibility_off, size: 18, color: const Color(0xFFF7D6FF)),
            const SizedBox(width: 10),
            Text(
              secretOpen ? 'SECRET OPEN' : 'UNSEAL',
              style: const TextStyle(color: Color(0xFFF7D6FF), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.time, required this.accent});
  final double progress;
  final double time;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2 - 4;
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = const Color(0xFF1A001B);
    canvas.drawCircle(center, r, bg);
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [accent, const Color(0xFFFF00FF), const Color(0xFFA020F0), accent],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), -math.pi / 2, math.pi * 2 * progress, false, fg);
    canvas.drawCircle(
      center + Offset(0, -r),
      3 + 2 * math.sin(time * 6),
      Paint()..color = const Color(0xFFFF66CC).withOpacity(0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => true;
}

class BootLine {}

class _GlowSpot {
  const _GlowSpot(this.center, this.radius, this.color);
  final Offset center;
  final double radius;
  final Color color;
}

class _Planet {
  const _Planet(this.center, this.radius, this.colors);
  final Offset center;
  final double radius;
  final List<Color> colors;
}

enum DimensionKind { home, memory, projects, archive, matrix, contact }

class DimensionData {
  const DimensionData({
    required this.kind,
    required this.title,
    required this.accent,
  });

  final DimensionKind kind;
  final String title;
  final Color accent;
}

class MemoryFragment {
  const MemoryFragment(this.title, this.detail);
  final String title;
  final String detail;
}

class ProjectWorld {
  const ProjectWorld({
    required this.title,
    required this.accent,
    required this.deep,
    required this.secondary,
    required this.seed,
  });

  final String title;
  final Color accent;
  final Color deep;
  final Color secondary;
  final double seed;
}

class ArchiveArticle {
  const ArchiveArticle({required this.tag, required this.title, required this.body, required this.date});
  final String tag;
  final String title;
  final String body;
  final String date;
}

class SkillNode {
  const SkillNode(this.label, this.x, this.y, this.color);
  final String label;
  final double x;
  final double y;
  final Color color;
}

class ContactMethod {
  const ContactMethod({
    required this.title,
    required this.accent,
    required this.icon,
  });
  final String title;
  final Color accent;
  final IconData icon;
}

class Achievement {
  const Achievement(this.title);
  final String title;
}

List<Achievement> buildAchievements() {
  return const [
    Achievement('First Contact'),
    Achievement('Neural Walker'),
    Achievement('Explorer'),
    Achievement('Data Miner'),
    Achievement('Archive Hunter'),
    Achievement('Reality Hacker'),
    Achievement('Dimension Master'),
    Achievement('Void Traveler'),
    Achievement('Midnight Coder'),
    Achievement('Cyber Sentinel'),
    Achievement('System Whisperer'),
    Achievement('Signal Sculptor'),
  ];
}

List<MemoryFragment> memoryFragments() {
  return const [
    MemoryFragment(
      'Ilia.Y • Hidden Operator',
      'The public freelancer profile describes a practitioner of hacking, cybersecurity, and programming, with a verified presence on Karlancer and a persistent urge to solve technical challenges.',
    )
  ];
}

List<ProjectWorld> projectWorlds() {
  return const [
    ProjectWorld(
      title: 'yOUR PROJECT',
      accent: Color(0xFFFF0088),
      deep: Color(0xFF1C0012),
      secondary: Color(0xFFFF66CC),
      seed: 1.2,
    )
  ];
}

List<ArchiveArticle> archiveArticles() {
  return const [
    ArchiveArticle(
      tag: 'BOOT',
      title: 'The browser becomes a launch chamber.',
      body: 'The first experience is not a landing page. It is a classified ignition sequence that reveals the identity, the city, and the hidden network step by step.',
      date: '2089.01',
    ),
    ArchiveArticle(
      tag: 'DNA',
      title: 'Identity without biography blocks.',
      body: 'Memory fragments replace long text. Signal, motion, and discovery construct a living profile out of the sourced data: security work, code, and open source traces.',
      date: '2089.02',
    ),
    ArchiveArticle(
      tag: 'PROJECTS',
      title: 'Projects as worlds.',
      body: 'The observed repositories are translated into planets and sealed dimensions, each with atmosphere, color, and transition logic that reacts to exploration.',
      date: '2089.03',
    ),
    ArchiveArticle(
      tag: 'ARCHIVE',
      title: 'A database that feels forbidden.',
      body: 'Articles become access points, not cards. The archive is written as a terminal-grade knowledge vault, where reading is a physical act inside the scene.',
      date: '2089.04',
    ),
    ArchiveArticle(
      tag: 'SIGNALS',
      title: 'The AI entity listens first.',
      body: 'The consciousness reacts to movement, section changes, unlocked achievements, and hidden input, acting like a resident intelligence rather than a chatbot.',
      date: '2089.05',
    ),
  ];
}

List<SkillNode> skillNodes() {
  return const [
    SkillNode('Python', 0.18, 0.18, Color(0xFFFF0088)),
    SkillNode('C', 0.36, 0.28, Color(0xFFB56CFF)),
    SkillNode('JavaScript', 0.62, 0.18, Color(0xFFFF00FF)),
    SkillNode('Dart', 0.52, 0.44, Color(0xFFA020F0)),
    SkillNode('Linux', 0.22, 0.58, Color(0xFFFF66CC)),
    SkillNode('Go', 0.7, 0.54, Color(0xFF5D00FF)),
    SkillNode('Ruby', 0.42, 0.72, Color(0xFFFF0088)),
    SkillNode('Pentest', 0.74, 0.76, Color(0xFFF062D6)),
    SkillNode('Web Security', 0.18, 0.82, Color(0xFFB56CFF)),
    SkillNode('Kotlin', 0.54, 0.86, Color(0xFFFF00FF)),
    SkillNode('PHP', 0.82, 0.34, Color(0xFFFF0088)),
    SkillNode('HTML/CSS', 0.82, 0.68, Color(0xFFA020F0)),
  ];
}

List<ContactMethod> contactMethods() {
  return const [
    ContactMethod(title: 'GITHUB CORE', accent: Color(0xFFFF0088), icon: Icons.code),
    ContactMethod(title: 'KARLANCER PORTAL', accent: Color(0xFFB56CFF), icon: Icons.workspaces),
    ContactMethod(title: 'MYKET CHANNEL', accent: Color(0xFFFF00FF), icon: Icons.apps),
    ContactMethod(title: 'DIRECT SIGNAL', accent: Color(0xFFA020F0), icon: Icons.send),
  ];
}

List<DimensionData> get _dimensions => const [
      DimensionData(kind: DimensionKind.home, title: '01 / HOME', accent: Color(0xFFFF0088)),
      DimensionData(kind: DimensionKind.memory, title: '02 / MEMORY', accent: Color(0xFFFF00FF)),
      DimensionData(kind: DimensionKind.projects, title: '03 / PROJECTS', accent: Color(0xFFA020F0)),
      DimensionData(kind: DimensionKind.archive, title: '04 / ARCHIVE', accent: Color(0xFF5D00FF)),
      DimensionData(kind: DimensionKind.matrix, title: '05 / MATRIX', accent: Color(0xFFFF66CC)),
      DimensionData(kind: DimensionKind.contact, title: '06 / SIGNALS', accent: Color(0xFFB56CFF)),
    ];
