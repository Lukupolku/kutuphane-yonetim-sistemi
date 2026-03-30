import 'package:flutter/material.dart';
import '../theme.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final ValueChanged<double>? onChanged;
  final double starSize;

  const RatingWidget({
    super.key,
    required this.rating,
    this.onChanged,
    this.starSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = i + 1.0;
        final halfValue = i + 0.5;

        IconData icon;
        Color color;

        if (rating >= starValue) {
          icon = Icons.star_rounded;
          color = Colors.amber.shade700;
        } else if (rating >= halfValue) {
          icon = Icons.star_half_rounded;
          color = Colors.amber.shade700;
        } else {
          icon = Icons.star_border_rounded;
          color = MebColors.border;
        }

        return GestureDetector(
          onTap: onChanged != null
              ? () {
                  // Toggle: tap same star removes rating, tap full gives half
                  if (rating == starValue) {
                    onChanged!(halfValue);
                  } else if (rating == halfValue) {
                    onChanged!(0);
                  } else {
                    onChanged!(starValue);
                  }
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(icon, size: starSize, color: color),
          ),
        );
      }),
    );
  }
}
