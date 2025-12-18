import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _offset = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutQuart,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _offset,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _AppHeader(),
                  const SizedBox(height: 30),
                  _NavigationCard.tasks(),
                  const SizedBox(height: 16),
                  _NavigationCard.events(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'TO-DO APP',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _NavigationCard extends StatefulWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String route;
  final bool swipeRight;

  const _NavigationCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.route,
    required this.swipeRight,
  });

  factory _NavigationCard.tasks() {
    return const _NavigationCard(
      color: Color.fromARGB(255, 62, 89, 87),
      icon: Icons.task,
      title: 'Tasks',
      route: '/tasks',
      swipeRight: true,
    );
  }

  factory _NavigationCard.events() {
    return const _NavigationCard(
      color: Color.fromARGB(255, 59, 163, 155),
      icon: Icons.event,
      title: 'Events',
      route: '/events',
      swipeRight: false,
    );
  }

  @override
  State<_NavigationCard> createState() => _NavigationCardState();
}

class _NavigationCardState extends State<_NavigationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  double _xOffset = 0.0;
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _resetPosition() {
    final animation = Tween<double>(
      begin: _xOffset,
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut),
    );

    animation.addListener(() {
      setState(() => _xOffset = animation.value);
    });

    _slideCtrl.forward(from: 0);
  }

  void _navigate(double width) {
    final double target = widget.swipeRight ? width : -width;

    final animation = Tween<double>(
      begin: _xOffset,
      end: target,
    ).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut),
    );

    animation.addListener(() {
      setState(() => _xOffset = animation.value);
    });

    _slideCtrl.forward(from: 0).whenComplete(() {
      Navigator.pushNamed(context, widget.route).then((_) {
        setState(() => _xOffset = 0.0);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width * 0.88;
    const double height = 95.0;
    final double threshold = width * 0.3;

    final double hintOpacity =
    (_xOffset.abs() / threshold).clamp(0.0, 1.0);
    final double textOpacity = 1.0 - hintOpacity;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, widget.route),
      onHorizontalDragUpdate: (details) {
        setState(() {
          _xOffset += details.delta.dx;
          _xOffset = widget.swipeRight
              ? _xOffset.clamp(-width * 0.1, width)
              : _xOffset.clamp(-width, width * 0.1);
        });
      },
      onHorizontalDragEnd: (_) {
        final bool passed = widget.swipeRight
            ? _xOffset > threshold
            : _xOffset < -threshold;

        passed ? _navigate(width) : _resetPosition();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Top instruction text
          Positioned(
            top: -18,
            left: widget.swipeRight ? 12 : null,
            right: widget.swipeRight ? null : 12,
            child: Opacity(
              opacity: textOpacity,
              child: Text(
                widget.swipeRight
                    ? 'Tap or swipe →'
                    : 'Tap or ← swipe',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.color.withOpacity(0.9),
                ),
              ),
            ),
          ),

          // Background
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.85),
              borderRadius: BorderRadius.circular(14),
            ),
          ),

          // Foreground draggable card
          Transform.translate(
            offset: Offset(_xOffset, 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: _hover ? 20.0 : 10.0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: 32, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
