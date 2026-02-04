import 'package:flutter/material.dart';
import '../models.dart';
class StarRating extends StatefulWidget {
  final FieldModel field;
  final Function(String, dynamic) onValueChanged;
  const StarRating({
    super.key,
    required this.field,
    required this.onValueChanged,
  });
  @override
  State<StarRating> createState() => _StarRatingState();
}
class _StarRatingState extends State<StarRating> {
  int _rating = 0;
  @override
  void initState() {
    super.initState();
    _rating = int.tryParse(widget.field.fieldValue ?? '0') ?? 0;
  }
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return IconButton(
          onPressed: widget.field.isReadOnly
              ? null
              : () {
                  setState(() {
                    _rating = index + 1;
                  });
                  widget.onValueChanged(widget.field.fieldId, _rating.toString());
                },
          icon: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
        );
      }),
    );
  }
}