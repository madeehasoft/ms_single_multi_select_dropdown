import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ------------------ CONTROLLER ------------------
/// Controller for managing focus and selection state of [MsDropSingleMultiSelector].
///
/// Provides access to selected items, focus control, and input text.
class MsDropController {
  /// Focus node used to manage keyboard focus for the dropdown.
  final FocusNode focusNode = FocusNode();

  /// Currently selected item in single-select mode.
  MsClass? selectedSingle;

  /// Currently selected items in multi-select mode.
  List<MsClass> selectedMulti = [];

  /// Text input from the search field.
  String text = "";

  /// Optional callback to notify the widget to rebuild
  VoidCallback? notifyClear;

  /// Requests focus for the dropdown input field.
  void requestFocus() => focusNode.requestFocus();

  /// Removes focus from the dropdown input field.
  void unfocus() => focusNode.unfocus();

  /// Disposes the focus node.
  void dispose() => focusNode.dispose();

  /// Returns true if any item is selected.
  bool get isSelected => selectedSingle != null || selectedMulti.isNotEmpty;

  /// ------------------ CLEAR ------------------
  void clear() {
    selectedSingle = null;
    selectedMulti.clear();
    text = "";

    // Notify the widget to rebuild
    notifyClear?.call();
  }

  /// Programmatically select a single item and update the widget
  void selectSingleItem(MsClass item) {
    selectedSingle = item;
    text = item.name;
    notifyClear?.call(); // triggers UI refresh
  }

  /// Programmatically select multiple items
  // void selectMultiItems(List<MsClass> items) {
  //   selectedMulti = items;
  //   text = 'Selected Item (${items.length})';
  //   notifyClear?.call(); // triggers UI refresh
  // }

  void selectMultiItems(List<MsClass> items) {
    selectedMulti = items;
    selectedSingle = null;
    //text = 'Selected Item (${items.length})';
    notifyClear?.call(); // 🔔 triggers _onControllerClear
  }
}

/// ------------------ MODEL ------------------
/// Represents a selectable item in the dropdown.
///
/// Includes optional prefix and suffix codes for categorization or metadata.
class MsClass {
  /// Prefix code used for grouping or filtering.
  final String? prefixCode;

  /// Display name of the item.
  final String name;

  /// Suffix code used for additional metadata.
  final String? suffixCode;

  /// Creates a new [MsClass] with the given prefix, name, and suffix.
  const MsClass({
    this.prefixCode,
    required this.name,
    this.suffixCode,
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
/// A customizable dropdown widget supporting single and multi-select modes.
///
/// Includes keyboard navigation, search, and styling options.
class MsDropSingleMultiSelector extends StatefulWidget {
  /// List of items to display in the dropdown.
  final List<MsClass> items;

  /// Enables multi-select mode if true.
  final bool multiSelect;

  /// Callback when a single item is selected.
  final void Function(MsClass?)? onChangedSingle;

  /// Callback when multiple items are selected.
  final void Function(List<MsClass>)? onChangedMulti;

  /// Callback when Enter is pressed in single-select mode.
  final void Function(MsClass?)? onSubmittedSingle;

  /// Callback when Enter is pressed in multi-select mode.
  final void Function(List<MsClass>)? onSubmittedMulti;

  /// Callback when clear icon is tapped
  final VoidCallback? onClearTapped;

  /// Optional controller to manage focus and selection externally.
  final MsDropController? controller;

  /// Width of the dropdown trigger widget.
  final dynamic dropdownWidth;

  /// Width of the dropdown menu.
  final dynamic dropdownMenuWidth;

  /// Height for the input field.
  final double? dropdownHeight;

  /// Style for the text field input.
  final TextStyle? searchFieldStyle;

  /// Style for dropdown items.
  final TextStyle? dropdownItemStyle;

  /// Style for prefix text in dropdown items.
  final TextStyle? dropdownItemPrefixStyle;

  /// Style for suffix text in dropdown items.
  final TextStyle? dropdownItemSuffixStyle;

  /// Style for the trigger button text.
  final TextStyle? buttonTextStyle;

  /// Style for the trigger button.
  final ButtonStyle? buttonStyle;

  /// Hint text for the input field.
  final String? searchFieldHint;

  /// Icon shown for search functionality.
  final Icon? searchIcon;

  /// Icon shown for opening the dropdown menu.
  final Icon? menuIcon;

  /// Icon shown for clearing the selection.
  final Icon? clearIcon;

  /// Background color of the text field.
  final Color? searchFieldBackgroundColor;

  /// Background color for highlighted dropdown items.
  final Color? dropdownItemHighlightColor;

  /// Background color of the dropdown menu.
  final Color? dropdownBackgroundColor;

  /// showPrefixCode.
  final bool showPrefixCode;

  /// showSuffixCode.
  final bool showSuffixCode;

  /// Creates a new [MsDropSingleMultiSelector] widget.
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
    this.searchFieldStyle,
    this.dropdownItemStyle,
    this.buttonTextStyle,
    this.buttonStyle,
    this.dropdownItemPrefixStyle,
    this.dropdownItemSuffixStyle,
    this.searchFieldHint,
    this.searchIcon,
    this.menuIcon,
    this.clearIcon,
    this.searchFieldBackgroundColor,
    this.dropdownItemHighlightColor,
    this.dropdownBackgroundColor,
    this.dropdownHeight,
    this.onClearTapped,
    this.showPrefixCode = false,
    this.showSuffixCode = false,
  });

  @override
  State<MsDropSingleMultiSelector> createState() =>
      _MsDropSingleMultiSelectorState();
}

class _MsDropSingleMultiSelectorState extends State<MsDropSingleMultiSelector> {
  bool isOpen = false;
  bool get hasSelected {
    if (widget.multiSelect) return selectedMulti.isNotEmpty;
    return selectedSingle != null;
  }

  String get searchFieldHint => widget.searchFieldHint ?? "Search...";

  TextStyle get searchFieldStyle =>
      widget.searchFieldStyle ??
      const TextStyle(fontSize: 14, color: Colors.black);

  TextStyle get dropdownItemStyle =>
      widget.dropdownItemStyle ??
      const TextStyle(fontSize: 14, color: Colors.black87);

  TextStyle get dropdownItemPrefixStyle =>
      widget.dropdownItemPrefixStyle ??
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

// ✅ Listen for controller clear
    if (widget.controller != null) {
      widget.controller!.notifyClear = _onControllerClear;
    }

    // _focusNode.addListener(() {
    //   if (_focusNode.hasFocus) {
    //     _showOverlay();
    //   } else {
    //     //if (!mouseOverDropdown) _removeOverlay();
    //   }
    // });
  }

  // ------------------ HELPER METHOD ------------------
  // void _onControllerClear() {
  //   setState(() {
  //     selectedSingle = null;
  //     selectedMulti.clear();
  //     _searchCtrl.clear();
  //     applyFilter("");
  //     highlighted = filtered.isNotEmpty ? 0 : -1;
  //   });

  //   _overlayEntry?.markNeedsBuild();
  // }

  void _onControllerClear() {
    setState(() {
      // 🟢 Sync local widget state with controller state
      selectedSingle = widget.controller?.selectedSingle;
      selectedMulti = widget.controller?.selectedMulti.toSet() ?? {};

      // 🟢 Update search text from controller
      _searchCtrl.text = widget.controller?.text ?? "";

      // 🟢 Apply filter based on current text
      applyFilter(widget.controller?.text ?? "");
      highlighted = filtered.isNotEmpty ? 0 : -1;
    });

    // 🟢 Rebuild dropdown overlay if visible
    _overlayEntry?.markNeedsBuild();
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
  // void _showOverlay() {
  //   _overlayEntry ??= _createOverlay();
  //   Overlay.of(context).insert(_overlayEntry!);
  // }

//   void _showOverlay() {
//   // 🔥 Always restore items if search text is empty
//   if (_searchCtrl.text.isEmpty) {
//     filtered = List.from(widget.items);
//     highlighted = filtered.isNotEmpty ? 0 : -1;
//   }

//   _overlayEntry ??= _createOverlay();
//   Overlay.of(context).insert(_overlayEntry!);
// }

  void _showOverlay() {
    // -------------------------------------------
    // ⭐ Restore highlight to last selected item
    // -------------------------------------------
    if (widget.multiSelect && selectedMulti.isNotEmpty) {
      final last = selectedMulti.last;

      final index = filtered.indexOf(last);
      if (index != -1) highlighted = index;
    } else {
      highlighted = filtered.isNotEmpty ? 0 : -1;
    }

    // keep existing reset logic
    if (_searchCtrl.text.isEmpty) {
      filtered = List.from(widget.items);
    }

    _overlayEntry ??= _createOverlay();
    Overlay.of(context).insert(_overlayEntry!);

    // ⭐ ensure scroll jumps to highlighted
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToHighlighted());
  }

  // void _removeOverlay() {
  //   _overlayEntry?.remove();
  //   _overlayEntry = null;
  //   if (selectedMulti.isNotEmpty) {
  //   _searchCtrl.text = 'Selected Item (${selectedMulti.length})';
  //   } else{
  //     _searchCtrl.text = '';
  //   }

  // }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;

    if (widget.multiSelect) {
      // Multi-select mode
      if (selectedMulti.isNotEmpty) {
        _searchCtrl.text = 'Selected Item (${selectedMulti.length})';
      } else {
        _searchCtrl.text = '';
      }
    } else {
      // Single-select mode
      if (selectedSingle != null) {
        _searchCtrl.text = selectedSingle!.name;
      } else {
        _searchCtrl.text = '';
      }
    }

    // Reset filtered items for next open
    filtered = List.from(widget.items);
    highlighted = filtered.isNotEmpty ? 0 : -1;
    setState(() => isOpen = false);
  }

  OverlayEntry _createOverlay() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    double getDropdownHeight() {
      const double minHeight = 60;
      const double defaultMaxHeight = 300;
      const double multiSelectButtonsHeight = 48;
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
        if (filtered.isEmpty) {
          itemsHeight = multiSelectButtonsHeight + extraPadding;
        }
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
                  color: widget.dropdownBackgroundColor ?? Colors.white, // NEW
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
                            child:
                                // Row(
                                //                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                //                             children: [

                                //                               ElevatedButton(
                                //                                   style: ElevatedButton.styleFrom(
                                //   //fixedSize: const Size(100, 100), // Square size: 100x100
                                //   shape: RoundedRectangleBorder(
                                //     borderRadius: BorderRadiusGeometry.all(Radius.circular(5)) // No rounded corners
                                //   ),
                                //   elevation: 8, // Optional: controls shadow depth
                                //  // backgroundColor: Colors.blue, // Optional: button color
                                // ),
                                //                                 onPressed: () {
                                //                                   setState(() {
                                //                                     selectedMulti.clear();
                                //                                     widget.controller?.selectedMulti.clear();
                                //                                     widget.onChangedMulti?.call([]);

                                //                                     // ✅ Reset search text
                                //                                     _searchCtrl.clear();
                                //                                     widget.controller?.text = ""; // ✅ update

                                //                                     // ✅ Show all items again
                                //                                     filtered = List.from(widget.items);

                                //                                     // ✅ Highlight first item
                                //                                     highlighted =
                                //                                         filtered.isNotEmpty ? 0 : -1;
                                //                                   });

                                //                                   // ✅ Rebuild dropdown list
                                //                                   _overlayEntry?.markNeedsBuild();

                                //                                   // ✅ Optional: keep focus in TextField
                                //                                   //_focusNode.requestFocus();
                                //                                 },
                                //                                 child: Text(
                                //                                   "Clear All",
                                //                                   style: buttonTextStyle,
                                //                                 ),
                                //                               ),
                                //                               //const SizedBox(width: 5),
                                //                               ElevatedButton(
                                //                                 style: ElevatedButton.styleFrom(
                                //   //fixedSize: const Size(100, 100), // Square size: 100x100
                                //   shape: RoundedRectangleBorder(
                                //     borderRadius: BorderRadiusGeometry.all(Radius.circular(5)) // No rounded corners
                                //   ),
                                //   elevation: 8, // Optional: controls shadow depth
                                //  // backgroundColor: Colors.blue, // Optional: button color
                                // ),
                                //                                 onPressed: selectedMulti.isEmpty
                                //                                     ? null
                                //                                     : showSelectedDialog,
                                //                                 child: Text(
                                //                                   "View (${selectedMulti.length})",
                                //                                   style: buttonTextStyle,
                                //                                 ),
                                //                               ),
                                //                               //const Spacer(),
                                //                               ElevatedButton(
                                //                                 style: ElevatedButton.styleFrom(
                                //   //fixedSize: const Size(100, 100), // Square size: 100x100
                                //   shape: RoundedRectangleBorder(
                                //     borderRadius: BorderRadiusGeometry.all(Radius.circular(5)) // No rounded corners
                                //   ),
                                //   elevation: 8, // Optional: controls shadow depth
                                //  // backgroundColor: Colors.blue, // Optional: button color
                                // ),
                                //                                 onPressed: () {
                                //                                   _focusNode.unfocus();
                                //                                   _removeOverlay();
                                //                                 },
                                //                                 child: Text("Done", style: buttonTextStyle),
                                //                               ),
                                //                             ],
                                //                           ),

                                Wrap(
                              spacing: 8, // horizontal space between buttons
                              runSpacing: 8, // vertical space when wrapped
                              alignment: WrapAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: const RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    elevation: 8,
                                  ),
                                  onPressed: () {
                                    final areAllVisibleSelected =
                                        filtered.isNotEmpty &&
                                            filtered.every((item) =>
                                                selectedMulti.contains(item));

                                    setState(() {
                                      if (areAllVisibleSelected) {
                                        // UNCHECK ALL (visible)
                                        selectedMulti.removeWhere(
                                            (e) => filtered.contains(e));
                                      } else {
                                        // CHECK ALL (visible)
                                        selectedMulti.addAll(filtered);
                                      }

                                      // Sync with controller
                                      widget.controller?.selectedMulti =
                                          selectedMulti.toList();
                                      widget.onChangedMulti
                                          ?.call(selectedMulti.toList());

                                      // Update text
                                      // _searchCtrl.text = 'Selected Item (${selectedMulti.length})';
                                      // widget.controller?.text = _searchCtrl.text;
                                      _searchCtrl.selection = TextSelection(
                                        baseOffset: 0,
                                        extentOffset: _searchCtrl.text.length,
                                      );
                                    });

                                    // Delay focus OR selection until dialog fully closes
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      // ✅ Focus the search TextField
                                      _focusNode.requestFocus();
                                    });

                                    _overlayEntry?.markNeedsBuild();
                                  },
                                  child: Text(
                                    filtered.isNotEmpty &&
                                            filtered.every((item) =>
                                                selectedMulti.contains(item))
                                        ? "Uncheck All"
                                        : "Check All",
                                    style: buttonTextStyle,
                                  ),
                                ),

                                // VIEW
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: const RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    elevation: 8,
                                  ),
                                  onPressed: selectedMulti.isEmpty
                                      ? null
                                      : showSelectedDialog,
                                  child: Text("View (${selectedMulti.length})",
                                      style: buttonTextStyle),
                                ),

                                // DONE
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: const RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    elevation: 8,
                                  ),
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

          // onTap: () {
          //   if (widget.multiSelect) {
          //     toggleMulti(e);

          //     WidgetsBinding.instance.addPostFrameCallback((_) {
          //       //_focusNode.requestFocus();
          //     });
          //   } else {
          //     selectSingle(e);
          //     widget.onSubmittedSingle?.call(selectedSingle);
          //   }
          // },

          onTap: () {
            if (widget.multiSelect) {
              toggleMulti(e);

              setState(() {
                highlighted = i; // ⭐ Highlight the clicked item
              });

              // ⭐ Return keyboard focus to the search box
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _focusNode.requestFocus();
              });

              _overlayEntry?.markNeedsBuild();
            } else {
              selectSingle(e);
              widget.onSubmittedSingle?.call(selectedSingle);
            }
          },

          child: Container(
              color: isHighlighted
                  ? widget.dropdownItemHighlightColor ?? Colors.blue.shade100
                  : widget.dropdownBackgroundColor ?? Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  if (widget.showPrefixCode)
                    Text(e.prefixCode ?? "", style: dropdownItemPrefixStyle),
                  if (widget.showPrefixCode) const SizedBox(width: 6),
                  Expanded(child: Text(e.name, style: dropdownItemStyle)),
                  if (widget.showSuffixCode) const SizedBox(width: 6),
                  if (widget.showSuffixCode)
                    Text(e.suffixCode ?? "", style: dropdownItemSufixStyle),
                  if (widget.multiSelect) const SizedBox(width: 8),
                  if (widget.multiSelect)
                    Icon(
                      isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                    ),
                ],
              )

              // Row(
              //   children: [
              //     Text(e.prefixCode ?? "", style: dropdownItemPrefixStyle),
              //     const SizedBox(width: 6),
              //     Expanded(child: Text(e.name, style: dropdownItemStyle)),
              //     const SizedBox(width: 6),
              //     Text(e.suffixCode ?? "", style: dropdownItemSufixStyle),
              //     if (widget.multiSelect) const SizedBox(width: 8),
              //     if (widget.multiSelect)
              //       Icon(
              //         isSelected
              //             ? Icons.check_box
              //             : Icons.check_box_outline_blank,
              //       ),
              //   ],
              // ),
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
          widget.controller?.text = ""; // ✅ update
          widget.controller?.selectedMulti.clear();
          widget.onChangedMulti?.call([]);
        } else {
          selectedSingle = null;
          _searchCtrl.clear();
          widget.controller?.text = ""; // ✅ update
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
  // void toggleMulti(MsClass item) {
  //   setState(() {
  //     if (selectedMulti.contains(item)) {
  //       selectedMulti.remove(item);
  //     } else {
  //       selectedMulti.add(item);
  //     }
  //     widget.controller?.selectedMulti = selectedMulti.toList();
  //     widget.onChangedMulti?.call(selectedMulti.toList());

  //    // _searchCtrl.text = 'Selected Item (${selectedMulti.length})';
  //     widget.controller?.text = _searchCtrl.text; // ✅ update
  //     _searchCtrl.selection = TextSelection(
  //       baseOffset: 0,
  //       extentOffset: _searchCtrl.text.length,
  //     );

  //     _overlayEntry?.markNeedsBuild();
  //   });
  // }

  void toggleMulti(MsClass item) {
    setState(() {
      if (selectedMulti.contains(item)) {
        selectedMulti.remove(item);
      } else {
        selectedMulti.add(item);
      }

      // Sync controller
      widget.controller?.selectedMulti = selectedMulti.toList();
      widget.onChangedMulti?.call(selectedMulti.toList());

      // 🔥 If NOTHING is selected → CLEAR text + SHOW ALL ITEMS
      if (selectedMulti.isEmpty) {
        _searchCtrl.clear();
        widget.controller?.text = "";

        // Reset list to ALL items
        filtered = List.from(widget.items);

        // Reset highlight
        highlighted = filtered.isNotEmpty ? 0 : -1;

        // 🔥 Keep focus
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNode.requestFocus();
        });
      } else {
        // Keep the existing text, or you can rebuild UI:
        // _searchCtrl.text = "Selected Item (${selectedMulti.length})";
      }
    });

    _overlayEntry?.markNeedsBuild();
  }

  void selectSingle(MsClass item) {
    setState(() {
      selectedSingle = item;
      _searchCtrl.text = item.name;
      widget.controller?.text = _searchCtrl.text; // ✅ update
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

                        // _searchCtrl.text =
                        //     'Selected Item (${selectedMulti.length})';
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
          height: widget.dropdownHeight ?? 45, // set width here
          width: widget.dropdownWidth ?? double.infinity, // set width here
          child: TextField(
            controller: _searchCtrl,
            focusNode: _focusNode,
            style: searchFieldStyle,
            onChanged: (v) {
              setState(() {
                widget.controller?.text = v; // ✅ update parent controller
                applyFilter(v);
                if (_overlayEntry == null) {
                  _showOverlay();
                } else {
                  _overlayEntry?.markNeedsBuild();
                }
              });
            },
            decoration: InputDecoration(
              hintText: searchFieldHint,
              border: const OutlineInputBorder(),
              filled: true, // ✅ important
              fillColor: widget.searchFieldBackgroundColor ??
                  Colors.white, // use parent color or default

              contentPadding: EdgeInsets.zero, // will auto-center
              prefixIcon: widget.searchIcon ?? const Icon(Icons.search),

              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ CLEAR ICON (only visible when selected something)
                  if (hasSelected)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (widget.multiSelect) {
                              selectedMulti.clear();
                              widget.controller?.selectedMulti.clear();
                              widget.onChangedMulti?.call([]);
                            } else {
                              selectedSingle = null;
                              widget.controller?.selectedSingle = null;
                              widget.onChangedSingle?.call(null);
                            }

                            _searchCtrl.clear();
                            widget.controller?.text = ""; // ✅ update
                            applyFilter("");
                          });

                          _overlayEntry?.markNeedsBuild();

                          // Notify main page
                          widget.onClearTapped?.call(); // ✅ NEW

                          // ✅ ALWAYS FOCUS
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _focusNode.requestFocus();
                          });
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: widget.clearIcon ??
                              const Icon(Icons.clear, size: 23),
                        ),
                      ),
                    ),

                  /// ✅ DROPDOWN ICON (ROTATING)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        if (_overlayEntry == null) {
                          _showOverlay();
                          setState(() => isOpen = true); // ⭐ rotates icon
                        } else {
                          _removeOverlay();
                          setState(() => isOpen = false); // ⭐ rotate back
                        }

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _focusNode.requestFocus();
                        });
                      },
                      child: AnimatedRotation(
                        duration: Duration(milliseconds: 450),
                        curve: Curves.easeInOut,
                        turns: isOpen ? 0.50 : 0.0, // ⭐ 180° rotation

                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: widget.menuIcon ??
                              const Icon(Icons.arrow_drop_down, size: 23),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void applyFilter(String q) {
    final qq = q.toLowerCase();
    filtered = widget.items
        .where((e) =>
            e.name.toLowerCase().contains(qq) ||
            (e.prefixCode ?? "").toLowerCase().contains(qq) ||
            (e.suffixCode ?? "").toLowerCase().contains(qq))
        .toList();

    highlighted = filtered.isNotEmpty ? 0 : -1;
    scrollToHighlighted();
  }
}
