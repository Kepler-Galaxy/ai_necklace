import 'package:flutter/material.dart';

class EmptySummaryWidget extends StatefulWidget {
  const EmptySummaryWidget({super.key});

  @override
  State<EmptySummaryWidget> createState() => _EmptySummaryWidgetState();
}

class _EmptySummaryWidgetState extends State<EmptySummaryWidget> {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 200.0),
      child: Text(
        'No daily summary generated yet.',
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }
}
