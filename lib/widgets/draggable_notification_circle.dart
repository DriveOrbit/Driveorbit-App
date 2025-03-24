import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DraggableNotificationCircle extends StatefulWidget {
  final int notificationCount;
  final Function onDragComplete;
  final bool showIndicator;

  const DraggableNotificationCircle({
    super.key,
    required this.notificationCount,
    required this.onDragComplete,
    this.showIndicator = true,
  });

  @override
  State<DraggableNotificationCircle> createState() =>
      _DraggableNotificationCircleState();
}

class _DraggableNotificationCircleState
    extends State<DraggableNotificationCircle>
    with SingleTickerProviderStateMixin {
  double _dragX = 0;
  double _dragY = 0;
  bool _isDragging = false;
  final double _maxDragDistance = 100.0;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller with a longer duration for smoother animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Pulse animation (grow and shrink) - fixed to ensure values stay within [0.0, 1.0]
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.08), weight: 1),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.08, end: 0.96), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 0.96, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
    ));

    // Subtle rotation animation - keep within smaller angle range
    _rotateAnimation = Tween<double>(begin: -0.03, end: 0.03).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Color animation for the glow effect
    _colorAnimation = ColorTween(
      begin: const Color(0xFF6D6BF8).withOpacity(0.4),
      end: const Color(0xFF5856D6).withOpacity(0.7),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Fixed bounce animation to prevent range errors
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: -3.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start the animation and repeat it
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // This will be called when the circle is tapped directly
  void _handleTap() {
    widget.onDragComplete();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showIndicator || widget.notificationCount == 0) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 15.w,
      top: MediaQuery.of(context).size.height * 0.35,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleTap,
          onPanStart: (_) {
            setState(() => _isDragging = true);
          },
          onPanUpdate: (details) {
            setState(() {
              _dragX = details.delta.dx > 0 ? details.delta.dx : 0;
              _dragY = details.delta.dy;

              // Make it easier to trigger - just 50% of the original threshold
              if (_dragX > _maxDragDistance * 0.5) {
                widget.onDragComplete();
                _isDragging = false;
                _dragX = 0;
                _dragY = 0;
              }
            });
          },
          onPanEnd: (_) {
            setState(() {
              _isDragging = false;
              _dragX = 0;
              _dragY = 0;
            });
          },
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_dragX, _bounceAnimation.value + _dragY),
                child: Transform.rotate(
                  angle: _rotateAnimation.value,
                  child: Transform.scale(
                    scale: _pulseAnimation.value,
                    child: _buildNotificationCircle(
                      _colorAnimation.value ??
                          const Color(0xFF6D6BF8).withOpacity(0.5),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCircle(Color shadowColor) {
    return Container(
      width: 55.w,
      height: 55.w,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D6BF8), Color(0xFF5856D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(27.5.r),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.notifications,
            color: Colors.white,
            size: 26.sp,
          ),
          if (widget.notificationCount > 0)
            Positioned(
              right: 10.w,
              top: 10.h,
              child: Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
                constraints: BoxConstraints(
                  minWidth: 16.w,
                  minHeight: 16.w,
                ),
                child: Text(
                  widget.notificationCount > 9
                      ? '9+'
                      : '${widget.notificationCount}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          if (_isDragging)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(27.5.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 14.sp,
                  ),
                  SizedBox(width: 2.w),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white.withOpacity(0.7),
                    size: 14.sp,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
