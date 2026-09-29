import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class MangoLivingLogo extends StatelessWidget {
  const MangoLivingLogo({super.key, this.fontSize = 32});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.logo,
          height: 1.1,
        ),
        children: <InlineSpan>[
          const TextSpan(text: 'Mango'),
          const TextSpan(
            text: 'Living',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: '™',
            style: TextStyle(
              fontSize: fontSize * 0.38,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
