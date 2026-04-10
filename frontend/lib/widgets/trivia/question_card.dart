import 'package:flutter/material.dart';
import '../../models/question.dart';

class QuestionCard extends StatelessWidget {
  final Question question;

  const QuestionCard({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          question.text,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}