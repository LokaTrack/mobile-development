import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color activeColor;
  final Color inactiveColor;
  final double height;
  final BorderRadius borderRadius;

  const ProgressBar({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.activeColor,
    this.inactiveColor = Colors.grey,
    this.height = 6.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(3.0)),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final segmentWidth = maxWidth / totalPages;
        final activeWidth = segmentWidth * (currentPage + 1);

        return Container(
          width: maxWidth,
          height: height,
          decoration: BoxDecoration(
            color: inactiveColor.withOpacity(0.2),
            borderRadius: borderRadius,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: activeWidth,
                height: height,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: borderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
