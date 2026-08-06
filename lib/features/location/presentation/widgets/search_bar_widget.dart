import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';

class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onSearch;

  const SearchBarWidget({super.key, required this.onSearch});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalisation.of(context)!;
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      autofocus: true,
      decoration: InputDecoration(
        hintText: l10n.locationSearchHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _hasText
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.onSearch('');
                },
              )
            : null,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
