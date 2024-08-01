import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CustomDropdown extends StatefulWidget {
  final String? initialValue;
  final List<DropdownMenuItem<String>> items;
  final Function(String?)? onChanged;

  const CustomDropdown({
    Key? key,
    this.initialValue,
    required this.items,
    this.onChanged,
  }) : super(key: key);

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: DropdownButtonFormField<String>(
        value: _selectedValue,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.diamond, color: Colors.black54),
          hintText: 'User Type',
          hintStyle: const TextStyle(color: Colors.black45, fontSize: 18),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(30),
          ),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(30),
          ),
          filled: true,
          fillColor: const Color(0xFFedf0f8),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 20,
          ),
        ),
        items: widget.items,
        onChanged: (newValue) {
          setState(() {
            _selectedValue = newValue;
          });
          if (widget.onChanged != null) {
            widget.onChanged!(newValue);
          }
        },
      ),
    );
  }
}
