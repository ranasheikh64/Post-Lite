import 'package:flutter/material.dart';
import '../../../../app/data/providers/http_headers_provider.dart';

class TableFieldAutocompleteItem extends StatelessWidget {
  final dynamic option;
  final VoidCallback onTap;

  const TableFieldAutocompleteItem({
    super.key,
    required this.option,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHeader = option is HeaderSuggestion;
    final title = isHeader
        ? option.key
        : (option is MapEntry ? '{{${option.key}}}' : option.toString());
    final sub = isHeader
        ? option.description
        : (option is MapEntry ? option.value.toString() : '');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (isHeader)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2D3E),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'header',
                      style: TextStyle(
                        color: Color(0xFFFFB400),
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (sub.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
