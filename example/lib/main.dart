import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ms_single_multi_select_dropdown/ms_single_multi_select_dropdown.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Madeehasoft® Dropdown Demo',
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final MsDropController multyController = MsDropController();
  final MsDropController singleController = MsDropController();
  FocusNode useridFTB = FocusNode();
  List<MsClass> cities = [];

  @override
  void initState() {
    super.initState();
    // cities = List.generate(
    //   500,
    //   (i) => MsClass(
    //     prefixCode: 'Prefix Code ${i.toString().padLeft(3, '0')}',
    //     name: 'City Name $i',
    //     suffixCode: 'Suffix Code $i',
    //   ),
    // );
    loadCitiesFromJson();
  }

  @override
  void dispose() {
    singleController.dispose();
    multyController.dispose();
    super.dispose();
  }

  Future<void> loadCitiesFromJson() async {
    final String response = await rootBundle.loadString('assets/cities.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      cities = data
          .map(
            (item) => MsClass(
              //Both prefix & suffix are optional
              prefixCode: item['prefixCode'],
              name: item['name'],
              suffixCode: item['suffixCode'],
            ),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Madeehasoft® Single Or Multiple Drop-Down Selector Example',
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: 10,
            children: [
              cities.isNotEmpty
                  ? MsDropSingleMultiSelector(
                      textFieldBackgroundColor: Colors.yellow[100],

                      // dropdownBackgroundColor: const Color.fromARGB(
                      //   255,
                      //   255,
                      //   252,
                      //   212,
                      // ), // dropdown background

                      // dropdownItemHighlightColor: Colors.green.shade200,
                      clearIcon: Icon(
                        Icons.close_rounded,
                        color: Colors.red,
                        weight: 100,
                      ),
                      dropdownItemPrefixStyle: TextStyle(color: Colors.red),
                      dropdownItemStyle: TextStyle(
                        color: const Color.fromARGB(255, 28, 137, 46),
                        fontWeight: FontWeight.bold,
                      ),
                      dropdownItemSuffixStyle: TextStyle(
                        color: const Color.fromARGB(255, 49, 8, 235),
                      ),
                      textFieldStyle: TextStyle(fontWeight: FontWeight.bold),

                      textFieldHint: "Search Single...",
                      items: cities,
                      controller: singleController,
                      dropdownWidth: 400, // fixed width for dropdown
                      dropdownHeight: 40,
                      multiSelect: false,
                      onSubmittedSingle: (v) {
                        log("Submitted: ${v?.name}");

                        multyController.requestFocus();
                      },
                    )
                  : Container(),

              //============================================================
              cities.isNotEmpty
                  ? MsDropSingleMultiSelector(
                      textFieldBackgroundColor: const Color.fromARGB(
                        255,
                        255,
                        231,
                        211,
                      ), // set the background color here
                      controller: multyController,
                      items: cities,
                      multiSelect: true,
                      buttonTextStyle: TextStyle(
                        color: const Color.fromARGB(255, 167, 26, 26),
                        fontWeight: FontWeight.bold,
                      ),
                      textFieldStyle: TextStyle(fontWeight: FontWeight.bold),
                      textFieldHint: "Search Multiple...",
                      dropdownWidth: 400, // fixed width for dropdown
                      //controller: MsDropController,
                      onChangedMulti: (selected) {
                        if (selected.isNotEmpty) {
                          log(
                            "Selected items: ${selected.map((c) => c.name).join(', ')}",
                          );
                        } else {
                          log("Selected items: none");
                        }
                      },

                      onSubmittedMulti: (v) {
                        singleController.requestFocus();
                      },
                    )
                  : Container(),

              SizedBox(height: 10),

              ElevatedButton(
                onPressed: () {
                  log(multyController.text);

                  if (multyController.isSelected ||
                      singleController.isSelected) {
                    if (!singleController.isSelected) {
                      _showToast(
                        context,
                        'Selected items: ${multyController.selectedMulti.map((c) => c.name).join(', ')}',
                      );
                    } else {
                      _showToast(
                        context,
                        'Selected item: ${singleController.selectedSingle?.name ?? 'None'}',
                      );
                    }
                  } else {
                    _showToast(context, 'No selection made');
                  }
                },
                child: Text('Check Select Or Not Search'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _showToast(BuildContext context, value) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1300),
        content: const Text('Message'),
        action: SnackBarAction(
          label: value,
          onPressed: scaffold.hideCurrentSnackBar,
        ),
      ),
    );
  }
}
