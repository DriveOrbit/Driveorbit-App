import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DraggableNotificationCircle extends StatefulWidget {
  final int notificationCount;
  final Function onDragComplete;
  final bool showIndicator;

  const DraggableNotificationCircle({
    Key? key,
    required this.notificationCount,
    required this.onDragComplete,
    this.showIndicator = true,
  }) : super(key: key);

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

  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize pulse animation if we have notifications
    if (widget.notificationCount > 0) {
      _pulseController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );

      _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(
          parent: _pulseController!,
          curve: Curves.easeInOut,
        ),
      );

      // Repeat the animation
      _pulseController!.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DraggableNotificationCircle oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle changes in notification count or visibility
    if (oldWidget.notificationCount != widget.notificationCount ||
        oldWidget.showIndicator != widget.showIndicator) {
      // Clean up controller if we have no notifications or indicator shouldn't be shown
      if ((widget.notificationCount == 0 || !widget.showIndicator) &&
          _pulseController != null) {
        _pulseController?.dispose();
        _pulseController = null;
        _pulseAnimation = null;
      }
      // Create controller if we now have notifications and should show them
      else if (widget.notificationCount > 0 &&
          widget.showIndicator &&
          _pulseController == null) {
        _pulseController = AnimationController(
          duration: const Duration(milliseconds: 1500),
          vsync: this,
        );

        _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
          CurvedAnimation(
            parent: _pulseController!,
            curve: Curves.easeInOut,
          ),
        );

        _pulseController!.repeat(reverse: true);
      }
    }
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
          child: Transform.translate(
            offset: Offset(_dragX, _dragY),
            child: _pulseController != null && _pulseAnimation != null
                ? AnimatedBuilder(
                    animation: _pulseController!,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation!.value,
                        child: _buildNotificationCircle(),
                      );
                    },
                  )
                : _buildNotificationCircle(),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCircle() {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D6BF8), Color(0xFF5856D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D6BF8).withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.notifications,
            color: Colors.white,
            size: 24, // Explicit size for better visibility
          ),
          if (widget.notificationCount > 0)
            Positioned(
              right: 10.w,
              top: 10.h,
              child: Container(
                padding: EdgeInsets.all(4.r),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
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
                borderRadius: BorderRadius.circular(25.r),
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
