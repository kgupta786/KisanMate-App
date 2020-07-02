import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
// import 'package:random_string/random_string.dart';
import 'package:http/http.dart' as http;
// import 'fire'
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:splashscreen/splashscreen.dart';

void main(List<String> args) {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: splashApp(), title: 'KisanMate');
  }
}

class splashApp extends StatefulWidget {
  @override
  _splashAppState createState() => _splashAppState();
}

class _splashAppState extends State<splashApp> {
  @override
  Widget build(BuildContext context) {
    // return SplashScreen(seconds: 8,)

    return SplashScreen(
      title: new Text(
        'KisanMate',
        style: new TextStyle(
            // fontWeight: FontWeight.bold,
            fontSize: 40.0,
            fontFamily: 'Googlefont',
            color: Colors.grey),
      ),
      seconds: 9,
      navigateAfterSeconds: MyHome(),
      image: new Image.asset('fonts/lp.gif'),
      backgroundColor: Colors.white,
      styleTextUnderTheLoader: new TextStyle(),
      photoSize: 200.0,
      onClick: () => print("Flutter Egypt"),
      loaderColor: Colors.white,
    );
  }
}

class MyHome extends StatefulWidget {
  @override
  _MyHomeState createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  File imagefile;
  bool _isLoading = false;
  bool iscontent = false;
  double nitrogen;
  double chlorocontent;
  Future getimage(bool iscamera) async {
    File image;
    if (iscamera) {
      image = await ImagePicker.pickImage(source: ImageSource.gallery);
    }

    setState(() {
      imagefile = image;
    });
  }

  Future getDownloadUrl(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    // String fileId = randomAlpha(5);

    StorageReference reference =
        FirebaseStorage.instance.ref().child("myimage.jpg");
    StorageUploadTask uploadTask = reference.putFile(imagefile);
    StorageTaskSnapshot taskSnapshot = await uploadTask.onComplete;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();

    final Map<String, dynamic> requestData = {"image": downloadUrl};
    var url = "https://kisanconect.herokuapp.com/predict";
    final http.Response response =
        await http.post(url, body: json.encode(requestData), headers: {
      'Content-Type': 'application/json',
    });

    final Map<String, dynamic> responseData = json.decode(response.body);
    print(responseData);

    //  print(downloadUrl);
    if (responseData['Prediction'] != null) {
      setState(() {
        _isLoading = false;
        iscontent = true;
        String wtcontent = "";
        if (responseData['Color_Prediction'] == 'Light Yellow') {
          responseData['Color_Prediction'] = "Yellow";
        } else if (responseData['Color_Prediction'] == 'Yellow') {
          responseData['Color_Prediction'] = "Yellowish Green";
        }

        if (responseData['Color_Prediction'] == "Yellow") {
          wtcontent = "Below 50%";
        } else if (responseData['Color_Prediction'] == "Yellowish Green") {
          wtcontent = "50-65%";
        } else if (responseData['Color_Prediction'] == "Light Green") {
          wtcontent = "65-70%";
        } else if (responseData['Color_Prediction'] == "Green") {
          wtcontent = "70-80%";
        } else if (responseData['Color_Prediction'] == "Dark Green") {
          wtcontent = "80-90%";
        }

        double Rvalue = double.parse(responseData['Rval']);
        double Bvalue = double.parse(responseData['Bval']);
        double Gvalue = double.parse(responseData['Gval']);
        chlorocontent = Gvalue - (Rvalue / 4) - (Bvalue / 4);

        double avgr = Rvalue / 255;
        double avgb = Bvalue / 255;
        double avgg = Gvalue / 255;

        double hue = 0;
        double sat = 0;
        double br = 0;

        double maxval = max(avgr, max(avgb, avgg));
        double minval = min(avgr, min(avgb, avgg));

        if (maxval == avgr) {
          hue = ((avgg - avgb) / (maxval - minval)) * 60;
        } else if (maxval == avgb) {
          hue = (((avgr - avgg) / (maxval - minval)) + 4) * 60;
        } else if (maxval == avgg) {
          hue = (((avgb - avgr) / (maxval - minval)) + 2) * 60;
        }
        sat = (maxval - minval) / maxval;
        br = maxval;
        nitrogen = ((hue - 60) / 60 + (1 - sat) + (1 - br)) / 3;
        // if (nitrogen < 0) {
        //   nitrogen = 0;
        // }
        // if (chlorocontent < 0) {
        //   chlorocontent = 0;
        // }
        showModalBottomSheet(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25), topRight: Radius.circular(25)),
            ),
            backgroundColor: Colors.white,
            context: context,
            builder: (context) {
              return Container(
                  height: 550,
                  child: Column(
                    children: <Widget>[
                      Container(
                        child: Text(
                          "Predicted Results",
                          style:
                              TextStyle(fontSize: 25, fontFamily: 'Googlefont'),
                          textAlign: TextAlign.center,
                        ),
                        margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                      ),
                      Divider(
                        color: Colors.grey,
                        thickness: 1,
                        indent: 20,
                        endIndent: 20,
                      ),
                      ListTile(
                        title: Row(
                          children: <Widget>[
                            Text('Predicted Disease: ',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Googlefont',
                                    fontWeight: FontWeight.bold)),
                            Text(responseData['Prediction'],
                                style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Googlefont',
                                    color: Colors.grey))
                          ],
                        ),
                        leading: Icon(Icons.bug_report),
                      ),
                      ListTile(
                        title: Row(
                          children: <Widget>[
                            Text('Color Intensity: ',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Googlefont',
                                    fontWeight: FontWeight.bold)),
                            Text(responseData['Color_Prediction'],
                                style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Googlefont',
                                    color: Colors.grey))
                          ],
                        ),
                        leading: Icon(Icons.filter_vintage),
                      ),
                      ListTile(
                        title: Row(
                          children: <Widget>[
                            Text('Chlorophyll Content: ',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Googlefont',
                                    fontWeight: FontWeight.bold)),
                            Text(chlorocontent.round().toString() + " %",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Googlefont',
                                    color: Colors.grey))
                          ],
                        ),
                        leading: Icon(Icons.flare),
                      ),
                      ListTile(
                        title: Row(
                          children: <Widget>[
                            Text('Required Nitrogen Content: ',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Googlefont',
                                    fontWeight: FontWeight.bold)),
                            Text(
                                (4 + nitrogen).toString().substring(0, 6) +
                                    " %",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Googlefont',
                                    color: Colors.grey))
                          ],
                        ),
                        leading: Icon(Icons.bubble_chart),
                      ),
                      ListTile(
                        title: Row(
                          children: <Widget>[
                            Text('Present Moisture Content: ',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Googlefont',
                                    fontWeight: FontWeight.bold)),
                            Text(wtcontent,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Googlefont',
                                    color: Colors.grey))
                          ],
                        ),
                        leading: Icon(Icons.format_color_reset),
                      ),
                      Container(
                        child: ListTile(
                          onTap: () {
                            launch("https://www.google.com/search?q=" +
                                "treatment+for+" +
                                responseData["Prediction"]);
                          },
                          title: Text(
                            'Search for Remedies',
                            style: TextStyle(
                                fontFamily: 'Googlefont',
                                fontSize: 20,
                                color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          trailing: Icon(
                            Icons.arrow_forward,
                            color: Colors.grey,
                            size: 30,
                          ),
                        ),
                        margin:
                            EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color: Colors.blue,
                                style: BorderStyle.solid,
                                width: 3),
                            color: Colors.grey.withOpacity(0.1)),
                      ),
                    ],
                  ));
            });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: Text('KisanMate',
              style: TextStyle(fontFamily: 'Googlefont', fontSize: 25)),
          backgroundColor: Colors.purple[900],
        ),
        body: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.amber[100].withOpacity(0.15),
                Colors.amber[100]
              ], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: <Widget>[
              imagefile == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                          Container(
                              margin: EdgeInsets.fromLTRB(0, 100, 0, 0),
                              child: Icon(
                                Icons.local_florist,
                                size: 250,
                                color: Colors.purple[900].withOpacity(0.3),
                              )),
                          Container(
                              child: Text('No image is selected',
                                  style: TextStyle(
                                      fontSize: 35,
                                      fontFamily: 'Googlefont',
                                      color:
                                          Colors.purple[900].withOpacity(0.3)),
                                  textAlign: TextAlign.center)),
                        ])
                  : Column(children: <Widget>[
                      Container(
                        margin: EdgeInsets.fromLTRB(50, 55, 50, 25),
                        width: 300,
                        height: 300,
                        child: ClipRRect(
                            child: Container(
                              child: Image.file(
                                imagefile,
                                fit: BoxFit.cover,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(150)),
                      )
                    ]),
              imagefile == null
                  ? Container(
                      child: ListTile(
                        leading: IconButton(
                            icon: Icon(
                              Icons.camera,
                              size: 35,
                              color: Colors.white,
                            ),
                            onPressed: null),
                        title: Text(
                          'Click the image',
                          style: TextStyle(
                              fontFamily: 'Googlefont',
                              fontSize: 25,
                              color: Colors.white),
                        ),
                        onTap: () {
                          getimage(true);
                        },
                      ),
                      margin: EdgeInsets.fromLTRB(40, 40, 40, 0),
                      decoration: BoxDecoration(
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 1,
                              offset: Offset(0, 2),
                            ),
                          ],
                          gradient: LinearGradient(
                              colors: [
                                Colors.brown.withOpacity(0.3),
                                Colors.brown.withOpacity(0.8),
                                Colors.brown[700]
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(10)),
                    )
                  : Container(
                      child: ListTile(
                        leading: IconButton(
                            icon: Icon(
                              Icons.camera,
                              size: 35,
                              color: Colors.white,
                            ),
                            onPressed: null),
                        trailing: IconButton(
                            icon: Icon(
                              Icons.arrow_forward_ios,
                              size: 35,
                              color: Colors.white,
                            ),
                            onPressed: null),
                        title: Text(
                          'Click Another Image',
                          style: TextStyle(
                              fontFamily: 'Googlefont',
                              fontSize: 21,
                              color: Colors.white),
                        ),
                        onTap: () {
                          setState(() {
                            imagefile = null;
                            iscontent = false;
                            _isLoading = false;
                            chlorocontent = 0;
                            nitrogen = 0;
                          });
                        },
                      ),
                      margin: EdgeInsets.fromLTRB(20, 40, 20, 0),
                      decoration: BoxDecoration(
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 1,
                              offset: Offset(0, 2),
                            ),
                          ],
                          gradient: LinearGradient(
                              colors: [
                                Colors.brown.withOpacity(0.3),
                                Colors.brown.withOpacity(0.8),
                                Colors.brown[700]
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(10)),
                    ),
              imagefile == null
                  ? Container()
                  : _isLoading == true
                      ? Container(
                          margin: EdgeInsets.fromLTRB(0, 30, 0, 0),
                          child: Column(
                            children: <Widget>[
                              CircularProgressIndicator(),
                              Container(
                                  margin: EdgeInsets.fromLTRB(0, 30, 0, 0),
                                  width: double.infinity,
                                  child: Text(
                                    'Fetching the results! Please wait...',
                                    style: TextStyle(
                                        fontFamily: 'Googlefont', fontSize: 20),
                                    textAlign: TextAlign.center,
                                  ))
                            ],
                          ))
                      : Container(
                          width: 350,
                          margin: EdgeInsets.fromLTRB(0, 30, 0, 0),
                          child: ListTile(
                            leading: IconButton(
                                icon: Icon(
                                  Icons.format_list_numbered,
                                  size: 35,
                                  color: Colors.white,
                                ),
                                onPressed: null),
                            title: Text(
                              'Go To Results',
                              style: TextStyle(
                                  fontSize: 23,
                                  fontFamily: 'Googlefont',
                                  color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            trailing: IconButton(
                                icon: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 35,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  getDownloadUrl(context);
                                  // showsheet();
                                  // showsheet();
                                }),
                          ),
                          decoration: BoxDecoration(
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 1,
                                  offset: Offset(0, 2),
                                ),
                              ],
                              gradient: LinearGradient(
                                  colors: [
                                    Colors.purple[900].withOpacity(0.3),
                                    Colors.purple[900].withOpacity(0.5),
                                    Colors.purple[900].withOpacity(0.8),
                                    Colors.purple[900]
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(10)),
                        )
            ],
          ),
        ));
  }
}
