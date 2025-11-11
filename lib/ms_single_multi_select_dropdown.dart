import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ------------------ CONTROLLER ------------------
class MsDropController {
  final FocusNode focusNode = FocusNode();

  MsClass? selectedSingle;
  List<MsClass> selectedMulti = [];

  void requestFocus() => focusNode.requestFocus();
  void unfocus() => focusNode.unfocus();
  void dispose() => focusNode.dispose();

  bool get isSelected => selectedSingle != null || selectedMulti.isNotEmpty;
}

/// ------------------ MODEL ------------------
class MsClass {
  final String prefixCode;
  final String name;
  final String suffixCode;

  const MsClass({
    required this.prefixCode,
    required this.name,
    required this.suffixCode,
  });

  @override
  bool operator ==(Object other) =>
      other is MsClass &&
      prefixCode == other.prefixCode &&
      name == other.name &&
      suffixCode == other.suffixCode;

  @override
  int get hashCode => prefixCode.hashCode ^ name.hashCode ^ suffixCode.hashCode;
}

/// ------------------ MAIN WIDGET ------------------
class MsDropSingleMultiSelector extends StatefulWidget {
  final List<MsClass> items;
  final bool multiSelect;

  /// Called when single item changes
  final void Function(MsClass?)? onChangedSingle;

  /// Called when multi-select items change
  final void Function(List<MsClass>)? onChangedMulti;

  /// Called on Enter / submit to propagate to form
  final void Function(MsClass?)? onSubmittedSingle;
  final void Function(List<MsClass>)? onSubmittedMulti;

  final MsDropController? controller;

  final dynamic dropdownWidth;
  final dynamic dropdownMenuWidth;

  // Customization
  final TextStyle? textFieldStyle;
  final TextStyle? dropdownItemStyle;
  final TextStyle? dropdownItemPrefixStyle;
  final TextStyle? dropdownItemSuffixStyle;
  final TextStyle? buttonTextStyle;
  final ButtonStyle? buttonStyle;
  final String? textFieldHint;

  const MsDropSingleMultiSelector({
    super.key,
    required this.items,
    this.multiSelect = false,
    this.onChangedSingle,
    this.onChangedMulti,
    this.onSubmittedSingle,
    this.onSubmittedMulti,
    this.controller,
    this.dropdownWidth,
    this.dropdownMenuWidth,
    this.textFieldStyle,
    this.dropdownItemStyle,
    this.buttonTextStyle,
    this.buttonStyle,
    this.dropdownItemPrefixStyle,
    this.dropdownItemSuffixStyle,
    this.textFieldHint,
  });

  @override
  State<MsDropSingleMultiSelector> createState() => _MsDropSingleMultiSelectorState();
}

class _MsDropSingleMultiSelectorState extends State<MsDropSingleMultiSelector> {
  String get textFieldHint => widget.textFieldHint ?? "Search...";

  TextStyle get textFieldStyle =>
      widget.textFieldStyle ??
      const TextStyle(fontSize: 14, color: Colors.black);

  TextStyle get dropdownItemStyle =>
      widget.dropdownItemPrefixStyle ??
      const TextStyle(fontSize: 14, color: Colors.black87);

  TextStyle get dropdownItemPrefixStyle =>
      widget.dropdownItemStyle ??
      const TextStyle(fontSize: 14, color: Colors.black87);

  TextStyle get dropdownItemSufixStyle =>
      widget.dropdownItemSuffixStyle ??
      const TextStyle(fontSize: 14, color: Colors.black87);

  TextStyle get buttonTextStyle =>
      widget.buttonTextStyle ??
      const TextStyle(fontSize: 14, color: Colors.black87);

  ButtonStyle get buttonStyle =>
      widget.buttonStyle ??
      ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      );

  late FocusNode _focusNode;
  late FocusNode _keyboardNode;
  late TextEditingController _searchCtrl;

  List<MsClass> filtered = [];
  Set<MsClass> selectedMulti = {};
  MsClass? selectedSingle;
  int highlighted = 0;

  OverlayEntry? _overlayEntry;
  bool mouseOverDropdown = false;

  final LayerLink _layerLink = LayerLink();
  final ScrollController listController = ScrollController();
  static const double itemHeight = 48;

  @override
  void initState() {
    super.initState();

    _focusNode = widget.controller?.focusNode ?? FocusNode();
    _keyboardNode = FocusNode();
    _searchCtrl = TextEditingController();

    filtered = List.from(widget.items);

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showOverlay();
      } else {
        //if (!mouseOverDropdown) _removeOverlay();
      }
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) _focusNode.dispose();
    _keyboardNode.dispose();
    _searchCtrl.dispose();
    listController.dispose();
    _removeOverlay();
    super.dispose();
  }

  /// ------------------ Overlay ------------------
  void _showOverlay() {
    _overlayEntry ??= _createOverlay();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlay() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    double getDropdownHeight() {
      const double minHeight = 60;
      const double defaultMaxHeight = 300;
      const double multiSelectButtonsHeight = 50;
      const double extraPadding = 16;

      // Space available below the text field
      final renderBox = context.findRenderObject() as RenderBox;
      final offset = renderBox.localToGlobal(Offset.zero);
      final screenHeight = MediaQuery.of(context).size.height;
      final availableSpaceBelow =
          screenHeight - offset.dy - renderBox.size.height - 8; // 8px padding
      double maxHeight = availableSpaceBelow.clamp(minHeight, defaultMaxHeight);

      // Base height for items
      double itemsHeight = filtered.isNotEmpty
          ? filtered.length * itemHeight + extraPadding
          : minHeight; // Ensure some height if no results

      // Add multi-select buttons height if multiSelect is true
      if (widget.multiSelect) {
        itemsHeight += multiSelectButtonsHeight;
        // Ensure buttons row is always visible even when no results
        if (filtered.isEmpty)
          itemsHeight = multiSelectButtonsHeight + extraPadding;
      }

      // Final height: not exceeding max available space
      return itemsHeight.clamp(minHeight, maxHeight);
    }

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // Tap anywhere outside the dropdown
          _focusNode.unfocus();
          _removeOverlay();
        },
        child: Stack(
          children: [
            Positioned(
              width: widget.dropdownMenuWidth ??
                  size.width, // use custom width if provided
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + 4),
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: getDropdownHeight(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(child: buildDropdownList()),
                        if (widget.multiSelect)
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
  setState(() {
    selectedMulti.clear();
    widget.controller?.selectedMulti.clear();
    widget.onChangedMulti?.call([]);

    // ✅ Reset search text
    _searchCtrl.clear();

    // ✅ Show all items again
    filtered = List.from(widget.items);

    // ✅ Highlight first item
    highlighted = filtered.isNotEmpty ? 0 : -1;
  });

  // ✅ Rebuild dropdown list
  _overlayEntry?.markNeedsBuild();

  // ✅ Optional: keep focus in TextField
  //_focusNode.requestFocus();
},

                                  child: Text(
                                    "Clear All",
                                    style: buttonTextStyle,
                                  ),
                                ),
                                //const SizedBox(width: 5),
                                ElevatedButton(
                                  onPressed: selectedMulti.isEmpty
                                      ? null
                                      : showSelectedDialog,
                                  child: Text(
                                    "View Selected (${selectedMulti.length})",
                                    style: buttonTextStyle,
                                  ),
                                ),
                                //const Spacer(),
                                ElevatedButton(
                                  onPressed: () {
                                    _focusNode.unfocus();
                                    _removeOverlay();
                                  },
                                  child: Text("Done", style: buttonTextStyle),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ------------------ Dropdown List ------------------
  Widget buildDropdownList() {
    if (filtered.isEmpty) {
      return const Center(child: Text("No results"));
    }

    return ListView.builder(
      controller: listController,
      itemExtent: itemHeight,
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final e = filtered[i];
        final bool isHighlighted = i == highlighted;
        final bool isSelected = widget.multiSelect
            ? selectedMulti.contains(e)
            : selectedSingle == e;

        return InkWell(
          // onTap: () {
          //   if (widget.multiSelect) {
          //     toggleMulti(e);
          //   //  _focusNode.requestFocus();
          //   } else {
          //     selectSingle(e);
          //     widget.onSubmittedSingle?.call(selectedSingle);
          //   }
          // },
          onTap: () {
            if (widget.multiSelect) {
              toggleMulti(e);

              WidgetsBinding.instance.addPostFrameCallback((_) {
                //_focusNode.requestFocus();
              });
            } else {
              selectSingle(e);
              widget.onSubmittedSingle?.call(selectedSingle);
            }
          },

          child: Container(
            color: isHighlighted ? Colors.blue.shade100 : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                if (widget.multiSelect)
                  Icon(
                    isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                  ),
                if (widget.multiSelect) const SizedBox(width: 8),
                Text(e.prefixCode, style: dropdownItemPrefixStyle),
                const SizedBox(width: 6),
                Expanded(child: Text(e.name, style: dropdownItemStyle)),
                const SizedBox(width: 6),
                Text(e.suffixCode, style: dropdownItemSufixStyle),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ------------------ Keyboard Support ------------------
  KeyEventResult handleRawKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (filtered.isEmpty) return KeyEventResult.ignored;

    final data = event.logicalKey;

    if (data == LogicalKeyboardKey.arrowDown) {
      setState(() {
        highlighted = (highlighted + 1).clamp(0, filtered.length - 1);
      });
      scrollToHighlighted();
      _overlayEntry?.markNeedsBuild();
      return KeyEventResult.handled;
    }

    if (data == LogicalKeyboardKey.arrowUp) {
      setState(() {
        highlighted = (highlighted - 1).clamp(0, filtered.length - 1);
      });
      scrollToHighlighted();
      _overlayEntry?.markNeedsBuild();
      return KeyEventResult.handled;
    }

    if (data == LogicalKeyboardKey.enter ||
        data == LogicalKeyboardKey.numpadEnter) {
      if (highlighted >= 0 && highlighted < filtered.length) {
        final item = filtered[highlighted];
        if (widget.multiSelect) {
          //toggleMulti(item);
          _focusNode.unfocus();
          _removeOverlay();
          widget.onSubmittedMulti?.call(selectedMulti.toList());
        } else {
          selectSingle(item);
          _focusNode.unfocus();
          _removeOverlay();
          widget.onSubmittedSingle?.call(selectedSingle);
        }
      }
      return KeyEventResult.handled;
    }

    if (data == LogicalKeyboardKey.controlLeft ||
        data == LogicalKeyboardKey.controlRight) {
      if (highlighted >= 0 && highlighted < filtered.length) {
        final item = filtered[highlighted];
        if (widget.multiSelect) {
          toggleMulti(item);
          //widget.onSubmittedMulti?.call(selectedMulti.toList());
        }
      }
      return KeyEventResult.handled;
    }

    if (data == LogicalKeyboardKey.escape) {
      setState(() {
        if (widget.multiSelect) {
          selectedMulti.clear();
          _searchCtrl.clear();
          widget.controller?.selectedMulti.clear();
          widget.onChangedMulti?.call([]);
        } else {
          selectedSingle = null;
          _searchCtrl.clear();
          widget.controller?.selectedSingle = null;
          widget.onChangedSingle?.call(null);
        }
        _focusNode.unfocus();
        _removeOverlay();
      });
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void scrollToHighlighted() {
    if (!listController.hasClients) return;
    final double target = (highlighted * itemHeight).clamp(
      0.0,
      listController.position.maxScrollExtent,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!listController.hasClients) return;
      listController.animateTo(
        target,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
      );
    });
  }

  /// ------------------ Selection ------------------
  void toggleMulti(MsClass item) {
    setState(() {
      if (selectedMulti.contains(item)) {
        selectedMulti.remove(item);
      } else {
        selectedMulti.add(item);
      }
      widget.controller?.selectedMulti = selectedMulti.toList();
      widget.onChangedMulti?.call(selectedMulti.toList());

      _searchCtrl.text = 'Selected Item (${selectedMulti.length})';
      _searchCtrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _searchCtrl.text.length,
      );

      _overlayEntry?.markNeedsBuild();
    });
  }

  void selectSingle(MsClass item) {
    setState(() {
      selectedSingle = item;
      _searchCtrl.text = item.name;
      _searchCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchCtrl.text.length),
      );
      widget.controller?.selectedSingle = item;
      widget.onChangedSingle?.call(item);

      _focusNode.unfocus();
      _removeOverlay();
    });
  }

  void showSelectedDialog() {
    _removeOverlay(); // Close the dropdown first

    showDialog(
      context: context,
      builder: (context) {
        final selectedList = selectedMulti.toList();
        final screenSize = MediaQuery.of(context).size;

        // Width: 60% of screen width
        final dialogWidth = screenSize.width * 0.6;

        // Height: itemHeight * number of items + padding, capped at 60% of screen height
        const double itemHeight = 56; // CheckboxListTile default height
        const double padding = 24; // padding + title + actions
        final maxHeight = screenSize.height * 0.6;

        final calculatedHeight = (selectedList.length * itemHeight + padding)
            .clamp(100.0, maxHeight)
            .toDouble(); // <-- cast to double

        return AlertDialog(
          title: const Text("Selected Items"),
          content: SizedBox(
            width: dialogWidth,
            height: calculatedHeight,
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: selectedList.length,
                itemBuilder: (context, index) {
                  final item = selectedList[index];
                  return CheckboxListTile(
                    value: true,
                    title: Text(
                      '${item.prefixCode} ${item.name} ${item.suffixCode}',
                    ),
                    onChanged: (_) {
                      setState(() {
                        selectedMulti.remove(item);
                        widget.controller?.selectedMulti =
                            selectedMulti.toList();
                        widget.onChangedMulti?.call(selectedMulti.toList());
                        // _searchCtrl.text = selectedMulti
                        //     .map((e) => e.name)
                        //     .join(', ');
                        _searchCtrl.text =
                            'Selected Item (${selectedMulti.length})';
                        _searchCtrl.selection = TextSelection.fromPosition(
                          TextPosition(offset: _searchCtrl.text.length),
                        );
                      });

                      // Refresh dialog to reflect changes
                      Navigator.of(context).pop();
                      showSelectedDialog();
                    },
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              // onPressed: () {
              //   Navigator.of(context).pop();
              //   _focusNode.requestFocus();
              //   _keyboardNode.requestFocus();
              //   if (filtered.isNotEmpty) highlighted = 0;
              //   _overlayEntry?.markNeedsBuild();
              // },
              onPressed: () {
                Navigator.of(context).pop();

                // Delay focus OR selection until dialog fully closes
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // ✅ Focus the search TextField
                  _focusNode.requestFocus();

                  // ✅ Select ALL text inside TextField
                  _searchCtrl.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _searchCtrl.text.length,
                  );

                  // ✅ Reset highlighted item
                  if (filtered.isNotEmpty) highlighted = 0;

                  // ✅ Rebuild overlay dropdown
                  _overlayEntry?.markNeedsBuild();
                });
              },

              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  /// ------------------ Widget Build ------------------
  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardNode,
      onKeyEvent: handleRawKey,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: SizedBox(
          width: widget.dropdownWidth ?? double.infinity, // set width here
          child: TextField(
            controller: _searchCtrl,
            focusNode: _focusNode,
            style: textFieldStyle,
            onChanged: (v) {
              setState(() {
                applyFilter(v);
                _overlayEntry?.markNeedsBuild();
              });
            },
            onSubmitted: (v) {
              if (widget.multiSelect) {
                //widget.onSubmittedMulti?.call(selectedMulti.toList());
              } else {
                widget.onSubmittedSingle?.call(selectedSingle);
              }
            },
            decoration: InputDecoration(
              hintText: textFieldHint,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: const Icon(Icons.menu_open_rounded),
            ),
          ),
        ),
      ),
    );
  }

  void applyFilter(String q) {
    final qq = q.toLowerCase();
    filtered = widget.items
        .where(
          (e) =>
              e.name.toLowerCase().contains(qq) ||
              e.prefixCode.toLowerCase().contains(qq) ||
              e.suffixCode.toLowerCase().contains(qq),
        )
        .toList();

    highlighted = filtered.isNotEmpty ? 0 : -1;
    scrollToHighlighted();
  }
}
