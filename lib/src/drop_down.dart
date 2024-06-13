import 'package:drop_down_list/model/selected_list_item.dart';
import 'package:flutter/material.dart';

import 'app_text_field.dart';

typedef SelectedItemsCallBack = Function(List<SelectedListItem> selectedItems);

typedef ListItemBuilder = Widget Function(SelectedListItem item);

typedef BottomSheetListener = bool Function(DraggableScrollableNotification draggableScrollableNotification);

class DropDown {
  /// This will give the list of data.
  final List<SelectedListItem> data;

  /// This will give the call back to the selected items from list.
  final SelectedItemsCallBack? selectedItems;

  /// [listItemBuilder] will give [SelectedListItem] as a function parameter and you can return your own widget based on that item.
  final ListItemBuilder? listItemBuilder;

  /// This will give selection choice for single or multiple for list.
  final bool enableMultipleSelection;

  /// This gives the bottom sheet title.
  final Widget? bottomSheetTitle;

  /// You can set your custom submit button when the multiple selection is enabled.
  final Widget? submitButtonChild;

  /// [searchWidget] is use to show the text box for the searching.
  /// If you are passing your own widget then you must have to add [TextEditingController] for the [TextFormField].
  final TextFormField? searchWidget;

  /// [isSearchVisible] flag use to manage the search widget visibility
  /// by default it is [True] so widget will be visible.
  final bool isSearchVisible;

  /// [isSelectAllVisible] flag use to manage the select all widget visibility.
  /// by default it is [True] so widget will be visible.
  /// Required [enableMultipleSelection] to be true.
  final bool isSelectAllVisible;

  /// [selectAllText] is use to show the text into the select all widget.
  /// Required [enableMultipleSelection] and [isSelectAllVisible] to be true.
  final String selectAllText;

  /// [deselectAllText] is use to show the text into the deselect all widget.
  /// Required [enableMultipleSelection] and [isSelectAllVisible] to be true.
  final String deselectAllText;

  /// This will set the background color to the dropdown.
  final Color dropDownBackgroundColor;

  /// [searchHintText] is use to show the hint text into the search widget.
  /// by default it is [Search] text.
  final String? searchHintText;

  /// [isDismissible] Specifies whether the bottom sheet will be dismissed when user taps on the scrim.
  /// If true, the bottom sheet will be dismissed when user taps on the scrim.
  /// by default it is [True].
  final bool isDismissible;

  /// [bottomSheetListener] that listens for BottomSheet bubbling up the tree.
  final BottomSheetListener? bottomSheetListener;

  /// Specifies whether a modal bottom sheet should be displayed using the root navigator.
  /// by default it is [False].
  final bool useRootNavigator;

  DropDown({
    Key? key,
    required this.data,
    this.selectedItems,
    this.listItemBuilder,
    this.enableMultipleSelection = false,
    this.bottomSheetTitle,
    this.isDismissible = true,
    this.submitButtonChild,
    this.searchWidget,
    this.searchHintText = 'Search',
    this.isSearchVisible = true,
    this.isSelectAllVisible = true,
    this.selectAllText = 'Select All',
    this.deselectAllText = 'Deselect All',
    this.dropDownBackgroundColor = Colors.transparent,
    this.bottomSheetListener,
    this.useRootNavigator = false,
  });
}

class DropDownState {
  DropDown dropDown;

  DropDownState(this.dropDown);

  /// This gives the bottom sheet widget.
  void showModal(context) {
    showModalBottomSheet(
      useRootNavigator: dropDown.useRootNavigator,
      isScrollControlled: true,
      enableDrag: dropDown.isDismissible,
      isDismissible: dropDown.isDismissible,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
      ),
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MainBody(dropDown: dropDown);
          },
        );
      },
    );
  }
}

/// This is main class to display the bottom sheet body.
class MainBody extends StatefulWidget {
  final DropDown dropDown;

  const MainBody({required this.dropDown, super.key});

  @override
  State<MainBody> createState() => _MainBodyState();
}

class _MainBodyState extends State<MainBody> {
  /// This list will set when the list of data is not available.
  List<SelectedListItem> mainList = [];

  @override
  void initState() {
    super.initState();
    mainList = widget.dropDown.data;
    _setSearchWidgetListener();
  }

  @override
  Widget build(BuildContext context) {
    final isSelectAll = mainList.fold(true, (p, e) => p && (e.isSelected ?? false));
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: widget.dropDown.bottomSheetListener,
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.13,
        maxChildSize: 0.9,
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// Bottom sheet title text
                    Expanded(child: widget.dropDown.bottomSheetTitle ?? Container()),

                    /// Done button
                    Visibility(
                      visible: widget.dropDown.enableMultipleSelection,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Material(
                          child: ElevatedButton(
                            onPressed: () {
                              List<SelectedListItem> selectedList =
                                  widget.dropDown.data.where((element) => element.isSelected ?? false).toList();
                              List<SelectedListItem> selectedNameList = [];

                              for (var element in selectedList) {
                                selectedNameList.add(element);
                              }

                              widget.dropDown.selectedItems?.call(selectedNameList);
                              _onUnFocusKeyboardAndPop();
                            },
                            child: widget.dropDown.submitButtonChild ?? const Text('Done'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// A [TextField] that displays a list of suggestions as the user types with clear button.
              Visibility(
                visible: widget.dropDown.isSearchVisible,
                child: widget.dropDown.searchWidget ??
                    AppTextField(
                      dropDown: widget.dropDown,
                      onTextChanged: _buildSearchList,
                      searchHintText: widget.dropDown.searchHintText,
                    ),
              ),

              /// Listview (list of data with check box for multiple selection & on tile tap single selection)
              if (widget.dropDown.enableMultipleSelection && widget.dropDown.isSelectAllVisible) Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextButton(
                    onPressed: () => setState(() {
                      for (var element in mainList) {
                        if (isSelectAll) {
                          element.isSelected = false;
                        } else {
                          element.isSelected = true;
                        }
                      }
                    }),
                    child: Text(
                        isSelectAll
                            ? widget.dropDown.deselectAllText : widget.dropDown.selectAllText
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: mainList.length,
                  itemBuilder: (context, index) {
                    bool isSelected = mainList[index].isSelected ?? false;
                    return InkWell(
                      onTap: widget.dropDown.enableMultipleSelection
                          ? null
                          : () {
                              widget.dropDown.selectedItems?.call([mainList[index]]);
                              _onUnFocusKeyboardAndPop();
                            },
                      child: Container(
                        color: widget.dropDown.dropDownBackgroundColor,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                          child: ListTile(
                            title: widget.dropDown.listItemBuilder?.call(mainList[index]) ??
                                Text(
                                  mainList[index].name,
                                ),
                            trailing: widget.dropDown.enableMultipleSelection
                                ? GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        mainList[index].isSelected = !isSelected;
                                      });
                                    },
                                    child: isSelected
                                        ? const Icon(Icons.check_box)
                                        : const Icon(Icons.check_box_outline_blank),
                                  )
                                : const SizedBox(
                                    height: 0.0,
                                    width: 0.0,
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// This helps when search enabled & show the filtered data in list.
  _buildSearchList(String userSearchTerm) {
    final results = widget.dropDown.data
        .where((element) => element.name.toLowerCase().contains(userSearchTerm.toLowerCase()))
        .toList();
    if (userSearchTerm.isEmpty) {
      mainList = widget.dropDown.data;
    } else {
      mainList = results;
    }
    setState(() {});
  }

  /// This helps to UnFocus the keyboard & pop from the bottom sheet.
  _onUnFocusKeyboardAndPop() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop();
  }

  void _setSearchWidgetListener() {
    TextFormField? searchField = widget.dropDown.searchWidget;
    searchField?.controller?.addListener(() {
      _buildSearchList(searchField.controller?.text ?? '');
    });
  }
}
