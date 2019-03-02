import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:GnanG/Service/apiservice.dart';
import 'package:GnanG/UI/animation/success.dart';
import 'package:GnanG/UI/imagepicker/image_input.dart';
import 'package:GnanG/UI/widgets/base_state.dart';
import 'package:GnanG/colors.dart';
import 'package:GnanG/common.dart';
import 'package:GnanG/constans/wsconstants.dart';
import 'package:GnanG/model/appresponse.dart';
import 'package:GnanG/model/cacheData.dart';
import 'package:GnanG/utils/appsharedpref.dart';
import 'package:GnanG/utils/response_parser.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

class ProfilePagePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new ProfilePagePageState();
}

class ProfilePagePageState extends BaseState<ProfilePagePage> {
  ApiService _api = new ApiService();
  Uint8List uint8listImage;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Flame.audio.play('music/bensound-epic.mp3', volume: 0.5);
  }

  _loadData() {
    setState(() {
      isOverlay = true;
    });
    CommonFunction.getUserProfileImg(context: context).then((image) {
      setState(() {
        uint8listImage = image;
        isOverlay = false;
      });
    });
  }

  @override
  Widget pageToDisplay() {
    return new Scaffold(
      backgroundColor: kQuizSurfaceWhite,
      body: BackgroundGredient(
        child: new SafeArea(
          child: new ListView(
              padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
              children: <Widget>[
                _gameBar(),
                SizedBox(
                  height: 20.0,
                ),
                _userCard(),
                SizedBox(
                  height: 20.0,
                ),
                _profileData(),
                // _bonusRoundInfo(),
                SizedBox(
                  height: 20.0,
                ),
                _bottomButtons(),
              ],
            ),
        ),
      ),
    );
  }

  Widget _gameBar() {
    return new Row(
      children: <Widget>[
        _iconButton(
          Icon(Icons.power_settings_new, color: Colors.white),
              () {
            _api.logout();
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/login_new');
          },
        ),
        new Expanded(
          child: Center(
            child: Image.asset(
              'images/logo1.png',
              height: 70.0,
            ),
          ),
        ),
        _iconButton(
          Icon(
            Icons.help_outline,
            color: Colors.white,
          ),
              () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => new SucessAnimationPage(),
              ),
            );
            // Navigator.pushNamed(context, '/rules');
          },
        ),
      ],
    );
  }

  Widget _userCard() {
    return new Container(
      height: 250,
      child: new Stack(
        children: <Widget>[
          _userDetail(),
          Positioned(
            top: 0,
            left: MediaQuery
                .of(context)
                .size
                .width / 2 - 80,
            child: _userAvatar(),
          ),
        ],
      ),
    );
  }

  _profileData() {
    return new Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      margin: EdgeInsets.symmetric(vertical: 10),
      color: Colors.grey[50],
      elevation: 4,
      child: new Padding(
        padding: EdgeInsets.all(30),
        child: new Column(
          children: <Widget>[
            Text(
              'Profile data',
              textScaleFactor: 1.5,
              style: TextStyle(
                color: kQuizMain400,
              ),
            ),
            SizedBox(height: 15),
            new Divider(),
            SizedBox(height: 15),
            titleAndData('Mobile no. : ', CacheData.userInfo.mobile),
            SizedBox(height: 15),
            titleAndData(
                'Email id : ',
                CacheData.userInfo.email != null
                    ? CacheData.userInfo.email
                    : ""),
            SizedBox(height: 15),
            titleAndData('Center : ', CacheData.userInfo.center),
          ],
        ),
      ),
    );
  }

  Widget titleAndData(String title, String data) {
    return new Column(
      children: <Widget>[
        new Row(
          children: <Widget>[
            new Container(
              width: MediaQuery
                  .of(context)
                  .size
                  .width / 3,
              child: new Text(
                title,
                textScaleFactor: 1.1,
                style: TextStyle(
                  color: kQuizMain50,
                ),
              ),
            ),
            new Text(
              data,
              overflow: TextOverflow.fade,
              textScaleFactor: 1.2,
              style: TextStyle(
                color: kQuizMain400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bonusRoundInfo() {
    return Card(
      elevation: 5.0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            Text(
              'Next Game',
              textScaleFactor: 1.5,
              style: TextStyle(color: kQuizMain400),
            ),
            SizedBox(
              height: 30.0,
            ),
            Row(
              children: <Widget>[
                _bonusData(Icons.access_time, 'Tommorrow', '07:00 pm'),
                CustomVerticalDivider(height: 80.0),
                _bonusData(Icons.monetization_on, 'Points', '\$200'),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _bottomButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _button(
          'Leaderboard',
          Icons.poll,
              () {
            Navigator.pushNamed(context, '/leaderboard');
          },
        ),
        SizedBox(width: 10.0),
        _button(
          'Play Puzzle',
          Icons.play_circle_filled,
              () {
            Navigator.pushNamed(context, '/gameOf15');
          },
        ),
      ],
    );
  }

  Widget _button(String btnLable, icon, Function clickEvent) {
    return Expanded(
      child: RaisedButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        ),
        elevation: 10.0,
        padding: EdgeInsets.all(12.0),
        onPressed: clickEvent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: kQuizSurfaceWhite),
            SizedBox(width: 10),
            Text(
              btnLable,
              style: TextStyle(
                color: kQuizSurfaceWhite,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _bonusData(icon, String title, String value) {
    return Expanded(
      child: Column(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.access_time),
            onPressed: () {
              print(' ----> SHOW USER DATA ! <----');
              CommonFunction.alertDialog(
                  context: context, msg: CacheData.userState.toString());
            },
            // size: 40.0,
            color: kQuizBrown900,
          ),
          SizedBox(
            height: 10.0,
          ),
          Text(
            title,
            style: TextStyle(
              color: kQuizMain50,
            ),
          ),
          SizedBox(height: 5.0),
          Text(
            value,
            textScaleFactor: 1.5,
            style: TextStyle(color: kQuizMain400),
          ),
        ],
      ),
    );
  }

  Widget _userDetail() {
    return Card(
      margin: EdgeInsets.fromLTRB(5, 50, 5, 0),
      elevation: 5.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30.0),
      ),
      color: Colors.grey[50],
      child: Padding(
        padding: EdgeInsets.all(10.0),
        child: new Column(
          children: <Widget>[
            new SizedBox(
              height: 50,
            ),
            new Text(
              CacheData.userInfo.name,
              textScaleFactor: 1.5,
              style: TextStyle(
                fontWeight: FontWeight.w200,
                color: kQuizMain400,
              ),
            ),
            new SizedBox(
              height: 30,
            ),
            new Row(
              children: <Widget>[
                _scoreData(
                    'Points', '\$' + CacheData.userState.totalscore.toString()),
                CustomVerticalDivider(height: 60),
                _scoreData('Lives', CacheData.userState.lives.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreData(String title, String value) {
    return new Expanded(
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(color: kQuizMain50),
            ),
            SizedBox(height: 5.0),
            Text(
              value,
              textScaleFactor: 2,
              style: TextStyle(color: kQuizMain400),
            )
          ],
        ),
      ),
    );
  }

  Widget _iconButton(Icon icon, Function clickEvent) {
    return new RaisedButton(
      onPressed: clickEvent,
      child: icon,
      shape: new CircleBorder(),
      elevation: 5.0,
      padding: const EdgeInsets.all(10.0),
    );
  }

  Widget _userAvatar() {
    return ImageInput(onImagePicked: onImagePicked, base64Image: uint8listImage);
  }

  void onImagePicked(File image) async {
    setState(() {
      isOverlay = true;
    });
    try {
      Response res = await _api.uploadProfilePicture(mhtId: CacheData.userInfo.mhtId, file: image);
      AppResponse appResponse = ResponseParser.parseResponse(context: context, res: res);
      if (appResponse.status == WSConstant.SUCCESS_CODE) {
        setState(() {
          uint8listImage = image.readAsBytesSync();
        });
        await AppSharedPrefUtil.saveProfileImage(base64Encode(image.readAsBytesSync()));
      }
    } catch(error) {
      print("Error while uploading Profile Picture:" + error);
    }
    setState(() {
      isOverlay = false;
    });
  }


}