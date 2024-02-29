import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import './membar_db.dart';
import './membar.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'membars',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'MemBars'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? imagePath;
  List<Membar> memBars = [];
  String barcodeReaderResult = '';
  int tapedCard = 0;
  bool someCardWasClicked = false;

  Map<Color, int> colorToIndexMap = {
    Color(0xffbbb3cb): 0,
    Color(0xffcb9ca4): 1,
    Color(0xff9dc9c8): 2,
    Color(0xffe4b975): 3,
    Color(0xffc2cc99): 4,
    Color(0xffa2cdcc): 5,
    Color(0xffb0bcbc): 6,
  };

  Map<int, Color> indexToColorMap = {
    0: Color(0xffbbb3cb),
    1: Color(0xffcb9ca4),
    2: Color(0xff9dc9c8),
    3: Color(0xffe4b975),
    4: Color(0xffc2cc99),
    5: Color(0xffa2cdcc),
    6: Color(0xffb0bcbc),
  };

  final MembarDatabaseHelper membarDatabaseHelper = MembarDatabaseHelper();
  final TextEditingController shopNameController = TextEditingController();

  int getColorIndex(Color color) {
    final index = colorToIndexMap[color];
    return index ?? 0;
  }

  Color getColorByIndex(int index) {
    final color = indexToColorMap[index];
    return color ?? Colors.white; // Return null if index not found
  }

  @override
  void initState() {
    super.initState();
    _loadMembars();
  }

  Future<void> _loadMembars() async {
    List<Membar> loadedMembars = await membarDatabaseHelper.getMembars();
    setState(() {
      loadedMembars.sort((a, b) => b.tapCount.compareTo(a.tapCount));
      memBars = loadedMembars;
    });
  }

// Function to select an image from the gallery
  Future<File?> selectImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

// Function to save an image to the app's documents directory
  Future<File> saveImage(File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = File('${appDir.path}/$fileName');
    await savedImage.writeAsBytes(await imageFile.readAsBytes());
    return savedImage;
  }

  Future<void> selectAndSaveImage() async {
    final pickedFile = await selectImage();
    if (pickedFile != null) {
      final savedImage = await saveImage(pickedFile);
      // Update the image path variable
      setState(() {
        imagePath = savedImage.path;
      });
    }
  }

  Future<void> insertMembar(selectedColor) async {
    final newMembar = Membar.withAutoIncrement(
        tapCount: 0,
        shopName: shopNameController.text,
        memo: 'testmemo',
        date: 'testdate',
        color: getColorIndex(selectedColor),
        picPath: imagePath,
        barcodeData: barcodeReaderResult != '' ? barcodeReaderResult : null);
    print('==========');
    print(newMembar);

    print('PicPath: ${newMembar.picPath}');
    print('barcodeData: ${newMembar.barcodeData}');

    await membarDatabaseHelper.insertMembar(newMembar);
    // Retrieve updated membars list from the database
    List<Membar> updatedMemBars = await membarDatabaseHelper.getMembars();

    setState(() {
      memBars = updatedMemBars;
    });
  }

  void resetForms() {
    imagePath = null;
    shopNameController.text = '';
    barcodeReaderResult = '';
  }

  Barcode getBarCodeType(String? barcodeReaderResult) {
    if (barcodeReaderResult == null) {
      // Handle the case where barcodeReaderResult is null
      return Barcode
          .ean13(); // or any other default value or error handling mechanism
    }

    if (barcodeReaderResult
        .split('')
        .every((char) => char == '.' || char.toUpperCase() == char)) {
      return Barcode.code128();
    } else if (barcodeReaderResult.length == 13) {
      return Barcode.ean13();
    } else {
      // Handle the case where the barcode type cannot be determined
      return Barcode
          .ean13(); // or any other default value or error handling mechanism
    }
  }

  void showAddMembarDialog(
      BuildContext context, double screenHeight, double screenWidth) {
    Color selectedColor = Colors.white;
    var barcodeType;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return AlertDialog(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: screenHeight * 0.05,
                  ),
                  const Text('Add A New',
                      style: TextStyle(
                          // color: Colors.white,
                          fontSize: 20,
                          fontStyle: FontStyle.normal,
                          fontFamily: 'Open-Sans')),
                  const Text('Member Card',
                      style: TextStyle(
                          // color: Colors.white,
                          fontSize: 20,
                          fontStyle: FontStyle.normal,
                          fontFamily: 'Open-Sans')),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  height: screenHeight * 0.5,
                  width: screenWidth,
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.02),
                      SizedBox(
                        width: screenWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Shop Name:',
                                style: TextStyle(
                                    // color: Colors.white,
                                    fontSize: 15,
                                    fontStyle: FontStyle.normal,
                                    fontFamily: 'Open-Sans')),
                            Padding(
                              padding:
                                  EdgeInsets.only(left: screenWidth * 0.05),
                              child: TextFormField(
                                controller: shopNameController,
                                decoration: const InputDecoration(
                                  hintText: 'Input...',
                                  border: InputBorder.none,
                                ),
                                style: const TextStyle(fontSize: 13),
                                onChanged: (value) {
                                  // Handle the input text change here if needed
                                },
                              ),
                            )
                          ],
                        ),
                      ),

                      const Divider(height: 5, thickness: 2),
                      SizedBox(height: screenHeight * 0.015),
                      SizedBox(
                        // color: Colors.red,
                        width: screenWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pick A Color',
                                style: TextStyle(
                                    // color: Colors.white,
                                    fontSize: 15,
                                    fontStyle: FontStyle.normal,
                                    fontFamily: 'Open-Sans')),
                            SizedBox(height: screenHeight * 0.01),
                            Row(
                              children: [
                                Flexible(
                                  child: ClickableCircles(
                                    screenWidth,
                                    onSelectedChanged: (color) {
                                      setState(() {
                                        selectedColor = color;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // const Divider(height: 10, thickness: 2),
                      SizedBox(
                        height: screenHeight * 0.02,
                      ),
                      Expanded(
                        child: Container(
                          child: Container(
                            width: screenWidth,
                            child: Center(
                                child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      var res = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const SimpleBarcodeScannerPage(),
                                        ),
                                      );
                                      setState(() {
                                        if (res is String) {
                                          barcodeReaderResult = res;
                                          barcodeType = getBarCodeType(
                                              barcodeReaderResult);
                                          print(
                                              '====== code length: ${barcodeReaderResult}');
                                          print(
                                              '====== code length: ${barcodeReaderResult.length}');
                                        }
                                      });
                                    },
                                    child: const Text('Open Scanner'),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      await selectAndSaveImage();
                                      setState(() {});
                                    },
                                    child: const Text('or PIC',
                                        style: TextStyle(
                                          fontSize: 13,
                                          decoration: TextDecoration
                                              .underline, // Add underline decoration
                                        )),
                                  ),
                                  if (barcodeReaderResult.isNotEmpty)
                                    BarcodeWidget(
                                      barcode: barcodeType,
                                      data: barcodeReaderResult,
                                      errorBuilder: (context, error) =>
                                          Center(child: Text(error)),
                                    ),
                                  if (imagePath != null)
                                    Image.file(File(imagePath!))
                                ],
                              ),
                            )),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () async {
                    await insertMembar(selectedColor);
                    // resetForms();
                    Navigator.of(context).pop();
                  },
                  child: const Text('ADD'),
                )
              ],
            );
          },
        );
      },
    ).then((value) => resetForms());
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    String dayOfTheWeek = getDayOfTheWeek(now);
    double bigFont = 20;
    double smallFont = 15;
    double dateFontSize = 10;

    // Define a ScrollController
    final ScrollController scrollController = ScrollController();

    return Scaffold(
      backgroundColor: const Color(0xffc3d3be),
      body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
                color: const Color(0xffc3d3be),
                height: screenHeight,
                width: screenWidth * 0.95,
                child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    controller: scrollController,
                    slivers: <Widget>[
                      SliverAppBar(
                        backgroundColor: const Color(0xffc3d3be),
                        // when it fades out, it will fade to the specify color
                        onStretchTrigger: () async {
                          // Triggers when stretching
                        },
                        stretchTriggerOffset: 300.0,
                        expandedHeight: screenHeight * 0.25,
                        flexibleSpace: FlexibleSpaceBar(
                          // title: const Text('MemBars'),
                          background: Container(
                            color: const Color(0xffc3d3be),
                            child: SingleChildScrollView(
                              child: Column(
                                // crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: screenHeight * 0.06,
                                  ),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: screenWidth * 0.05,
                                      ),
                                      SizedBox(
                                        // color: Colors.red,
                                        width: screenWidth * 0.5,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              dayOfTheWeek,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: screenWidth * 0.06,
                                                  fontStyle: FontStyle.normal,
                                                  fontFamily: 'Open-Sans'),
                                            ),
                                            Text(
                                                formattedDate
                                                    .substring(5, 10)
                                                    .replaceAll('-', '/'),
                                                style: TextStyle(
                                                    height: 1,
                                                    color: Colors.white,
                                                    fontSize:
                                                        screenWidth * 0.13,
                                                    fontWeight: FontWeight.w300,
                                                    fontFamily: 'Open-Sans')),
                                            Text(formattedDate.substring(0, 4),
                                                style: TextStyle(
                                                    height: 1,
                                                    color: Colors.white,
                                                    fontSize:
                                                        screenWidth * 0.16,
                                                    fontWeight: FontWeight.w300,
                                                    fontFamily: 'Open-Sans')),
                                          ],
                                        ),
                                      ),

                                      // left Date section
                                      SizedBox(
                                        height: screenHeight * 0.2,
                                        child: const VerticalDivider(
                                          color: Colors.white,
                                          thickness:
                                              1, // Adjust the thickness of the line as needed
                                        ),
                                      ),
                                      SizedBox(
                                        width: screenWidth * 0.01,
                                      ),
                                      // right statistics section
                                      SizedBox(
                                        height: screenHeight * 0.25,
                                        width: screenWidth * 0.3,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Spacer(),
                                            Text(
                                              'Total cards: ${memBars.length.toString()}',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: screenWidth * 0.03,
                                                  fontStyle: FontStyle.normal,
                                                  fontFamily: 'Open-Sans'),
                                            ),
                                            const Spacer(),
                                            Text.rich(TextSpan(children: [
                                              TextSpan(
                                                text: 'Most ',
                                                style: TextStyle(
                                                  height: 1,
                                                  color: Colors.white,
                                                  fontSize: screenWidth * 0.03,
                                                  // Adjust the size of the first line
                                                  fontWeight: FontWeight.w300,
                                                  fontFamily: 'Open-Sans',
                                                ),
                                              ),
                                              TextSpan(
                                                text: 'Frequently',
                                                style: TextStyle(
                                                  height: 1,
                                                  color: Colors.white,
                                                  fontSize: screenWidth * 0.02,
                                                  fontWeight: FontWeight.w300,
                                                  fontFamily: 'Open-Sans',
                                                ),
                                              ),
                                              TextSpan(
                                                text: '\nused card: ',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: screenWidth * 0.02,
                                                  // Adjust the size of the first line
                                                  fontWeight: FontWeight.w300,
                                                  fontFamily: 'Open-Sans',
                                                ),
                                              ),
                                              TextSpan(
                                                text: getMostFrequentlyUsedCard(
                                                    memBars),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: smallFont,
                                                  // Adjust the size of the second line
                                                  fontWeight: FontWeight.w300,
                                                  fontFamily: 'Open-Sans',
                                                ),
                                              ),
                                            ])),
                                            const Spacer(),
                                            Text.rich(TextSpan(children: [
                                              TextSpan(
                                                text: 'Least ',
                                                style: TextStyle(
                                                  height: 1,
                                                  color: Colors.white,
                                                  fontSize: screenWidth * 0.03,
                                                  // Adjust the size of the first line
                                                  fontWeight: FontWeight.w300,
                                                  fontFamily: 'Open-Sans',
                                                ),
                                              ),
                                              TextSpan(
                                                text: 'Frequently',
                                                style: TextStyle(
                                                  height: 1,
                                                  color: Colors.white,
                                                  fontSize: screenWidth * 0.02,
                                                  fontWeight: FontWeight.w300,
                                                  fontFamily: 'Open-Sans',
                                                ),
                                              ),
                                              TextSpan(
                                                text: '\nused card: ',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: screenWidth * 0.02,
                                                  // Adjust the size of the first line
                                                  fontWeight: FontWeight.w300,
                                                  fontFamily: 'Open-Sans',
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    getLeastFrequentlyUsedCard(
                                                        memBars),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: smallFont,
                                                  // Adjust the size of the second line
                                                  fontWeight: FontWeight.w300,
                                                  fontFamily: 'Open-Sans',
                                                ),
                                              ),
                                            ])),
                                            const Spacer(),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            print(
                                '====== barcode data: ${memBars[index].barcodeData}');
                            return displayThisCard(
                                    someCardWasClicked, tapedCard, index)
                                ? Dismissible(
                                    key: Key(memBars[index].id.toString()),
                                    direction: DismissDirection.startToEnd,
                                    confirmDismiss: (direction) async {
                                      return await showDeleteConfirmationDialog(
                                          context);
                                    },
                                    onDismissed: (direction) async {
                                      await membarDatabaseHelper
                                          .deleteMembar(memBars[index].id ?? 0);
                                      setState(() {
                                        memBars.removeAt(index);
                                      });
                                    },
                                    child: GestureDetector(
                                      onTap: () async {
                                        // Scroll the tapped card to the top
                                        scrollController.animateTo(
                                          0,
                                          // screenHeight * 0.2 = card height
                                          duration:
                                              const Duration(milliseconds: 500),
                                          curve: Curves.easeInOut,
                                        );

                                        // Increment the tapCount by one
                                        memBars[index].tapCount++;
                                        tapedCard = index;
                                        someCardWasClicked = true;

                                        // Update the tapCount in the database
                                        if (memBars[index].id != null) {
                                          await membarDatabaseHelper
                                              .updateTapCount(
                                                  memBars[index].id!,
                                                  memBars[index].tapCount);

                                          // Update tapped state of this card and reset others
                                          setState(() {});
                                        }
                                      },
                                      child: Card(
                                        elevation: 2.5,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20.0),
                                        ),
                                        color: getColorByIndex(
                                            memBars[index].color),
                                        child: SizedBox(
                                            height: tapedCard == index &&
                                                    someCardWasClicked
                                                ? screenHeight * 0.3
                                                : screenHeight * 0.2,
                                            child: Column(
                                              children: [
                                                SizedBox(
                                                    height:
                                                        screenHeight * 0.02),
                                                Text(
                                                    '${memBars[index].shopName} ${memBars[index].tapCount}'),
                                                SizedBox(
                                                  height: tapedCard == index &&
                                                          someCardWasClicked
                                                      ? screenHeight * 0.04
                                                      : screenHeight * 0.02,
                                                ),
                                                Row(
                                                  children: [
                                                    const Spacer(),
                                                    if (displayBarcodePic(
                                                        index))
                                                      SizedBox(
                                                        // width: screenWidth * 0.85,
                                                        height:
                                                            screenHeight * 0.1,
                                                        child: Image.file(File(
                                                            memBars[index]
                                                                .picPath!)),
                                                      )
                                                    else if (displayBarcodeByGenerator(
                                                        index))
                                                      SizedBox(
                                                          height: screenHeight *
                                                              0.1,
                                                          child: BarcodeWidget(
                                                            barcode: getBarCodeType(
                                                                memBars[index]
                                                                    .barcodeData),
                                                            data: memBars[index]
                                                                .barcodeData!,
                                                            errorBuilder: (context,
                                                                    error) =>
                                                                Center(
                                                                    child: Text(
                                                                        error)),
                                                          ))
                                                    else
                                                      const Icon(Icons
                                                          .image_not_supported),
                                                    const Spacer()
                                                  ],
                                                ),
                                                const Spacer(),
                                                if (tapedCard == index &&
                                                    someCardWasClicked)
                                                  GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        someCardWasClicked =
                                                            false;
                                                      });
                                                    },
                                                    child: const Icon(
                                                        Icons.close_outlined),
                                                  ),
                                                SizedBox(
                                                  height: screenHeight * 0.02,
                                                )
                                              ],
                                            )),
                                      ),
                                    ))
                                : const SizedBox();
                          },
                          childCount: memBars.length,
                        ),
                      ),
                    ]))
          ],
        ),
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddMembarDialog(context, screenHeight, screenWidth);
        },
        tooltip: 'Pick Image',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  // Function to show a confirmation dialog
  Future<bool> showDeleteConfirmationDialog(BuildContext context) async {
    var result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: const Text("Are you sure you want to delete this item?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
    print('====== result: ${result}');
    return result ?? false;
  }

  bool displayThisCard(bool someWasClicked, int tapedCard, int index) {
    return !someWasClicked || tapedCard == index;
  }

  bool displayBarcodePic(int index) {
    print('path: ${memBars[index].picPath}');
    return memBars[index].picPath != null && memBars[index].picPath!.isNotEmpty;
  }

  bool displayBarcodeByGenerator(int index) {
    return memBars[index].picPath == null &&
        memBars[index].barcodeData != null &&
        memBars[index].barcodeData!.isNotEmpty;
  }

  int findIndexById(int id) {
    for (int i = 0; i < memBars.length; i++) {
      if (memBars[i].id == id) {
        return i; // Return the index if the id matches
      }
    }
    return -1; // Return -1 if the id is not found in the list
  }

  String getMostFrequentlyUsedCard(List<Membar> memBars) {
    // Create a copy of the memBars list
    List<Membar> sortedMemBars = List.from(memBars);

    // Sort the memBars list based on tapCount in descending order
    sortedMemBars.sort((a, b) => b.tapCount.compareTo(a.tapCount));

    // Check if the memBars list is not empty
    if (sortedMemBars.isNotEmpty) {
      // Return the shopName of the first element (most frequently used card)
      return sortedMemBars[0].shopName;
    } else {
      // Return 'Nan' if the memBars list is empty
      return 'NaN';
    }
  }

  String getLeastFrequentlyUsedCard(List<Membar> memBars) {
    // Create a copy of the memBars list
    List<Membar> sortedMemBars = List.from(memBars);

    // Sort the memBars list based on tapCount in descending order
    sortedMemBars.sort((a, b) => b.tapCount.compareTo(a.tapCount));

    // Check if the memBars list is not empty
    if (sortedMemBars.isNotEmpty) {
      // Return the shopName of the first element (most frequently used card)
      return sortedMemBars[memBars.length - 1].shopName;
    } else {
      // Return 'Nan' if the memBars list is empty
      return 'NaN';
    }
  }

  String getDayOfTheWeek(DateTime now) {
    // Get day of the week as an integer (1-7)
    int dayOfWeek = now.weekday;

    // Map the integer to the corresponding day name
    String dayName = '';
    switch (dayOfWeek) {
      case 1:
        dayName = 'Monday';
        break;
      case 2:
        dayName = 'Tuesday';
        break;
      case 3:
        dayName = 'Wednesday';
        break;
      case 4:
        dayName = 'Thursday';
        break;
      case 5:
        dayName = 'Friday';
        break;
      case 6:
        dayName = 'Saturday';
        break;
      case 7:
        dayName = 'Sunday';
        break;
    }
    return dayName;
  }
}

class ClickableCircles extends StatefulWidget {
  final void Function(Color) onSelectedChanged;
  double screenWidth;

  ClickableCircles(this.screenWidth,
      {super.key, required this.onSelectedChanged});

  @override
  State<StatefulWidget> createState() => _ClickableCirclesState();
}

class _ClickableCirclesState extends State<ClickableCircles> {
  int selectedIndex = -1;
  Color color1 = Colors.black;
  Color color2 = Colors.green;

  Map<Color, int> colorToIndexMap = {
    Color(0xffbbb3cb): 0,
    Color(0xffcb9ca4): 1,
    Color(0xff9dc9c8): 2,
    Color(0xffe4b975): 3,
    Color(0xffc2cc99): 4,
    Color(0xffa2cdcc): 5,
    Color(0xffb0bcbc): 6,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: widget.screenWidth,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: colorToIndexMap.entries
                .map((entry) {
                  return [
                    buildColorColumn(entry.key, entry.value),
                    SizedBox(width: widget.screenWidth * 0.02)
                  ];
                })
                .expand((element) => element)
                .toList(),
          ),
        ));
  }

  Widget buildColorColumn(Color color, int index) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              selectedIndex = index;
              widget.onSelectedChanged(color);
            });
          },
          child: Stack(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              if (selectedIndex == index)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        )
      ],
    );
  }
}
