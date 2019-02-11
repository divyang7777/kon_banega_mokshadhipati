import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart';
import 'package:kon_banega_mokshadhipati/Service/apiservice.dart';
import 'package:kon_banega_mokshadhipati/common.dart';
import 'package:kon_banega_mokshadhipati/constans/wsconstants.dart';
import 'package:kon_banega_mokshadhipati/model/appresponse.dart';
import 'package:kon_banega_mokshadhipati/model/cacheData.dart';
import 'package:kon_banega_mokshadhipati/model/leaders.dart';
import 'package:kon_banega_mokshadhipati/utils/response_parser.dart';

import '../colors.dart';

class LeaderBoard extends StatefulWidget {
  @override
  LeaderBoardState createState() => new LeaderBoardState();
}

class LeaderBoardState extends State<LeaderBoard> {
  
  ApiService _api = new ApiService();
  
  List<Leaders> leaderList;
  int _userRank = 0;

  @override
  void initState() {
    super.initState();
    _loadLeadersAndRank();
  }

  _loadLeadersAndRank() async {
    try {
      Response res = await _api.getApi(url: '/leaders');
      AppResponse appResponse =
          ResponseParser.parseResponse(context: context, res: res);
      if (appResponse.status == WSConstant.SUCCESS_CODE) {
        LeaderList leaders = LeaderList.fromJson(appResponse.data);
        setState(() {
          leaderList = leaders.leaders;
          print(leaderList);
          _userRank = leaders.userRank;
        });
      }
    } catch (err) {
      CommonFunction.displayErrorDialog(context: context, msg: err.toString());
    }
  }

  Widget _buildLeaderRow(int rank, String name, int points, IconData icon,
      String imagePath, int mhtId) {
    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Text(
                rank.toString(),
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),
              CacheData.userInfo.mhtId == mhtId
                  ? Padding(
                      padding: EdgeInsets.fromLTRB(18, 0, 12, 0),
                      child: CircleAvatar(
                        backgroundColor: kQuizBrown900,
                        minRadius: 25,
                        child: CircleAvatar(
                          minRadius: 22,
                          backgroundImage: AssetImage(imagePath),
                        ),
                      ),
                    )
                  : Container(
                      padding: EdgeInsets.fromLTRB(18, 0, 12, 0),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kQuizMain50,
                          image: DecorationImage(
                            fit: BoxFit.fill,
                            image: AssetImage(imagePath),
                          ),
                        ),
                      ),
                    ),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(fontSize: 18),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(0, 0, 6, 0),
                child: Text(
                  points.toString(),
                  style: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
        new Divider(),
      ],
    );
  }

  Widget _buildCityRow(int rank, String name, int points, IconData icon,
      String imagePath, int mhtId) {
    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Text(
                rank.toString(),
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(18, 0, 12, 0),
                child: CircleAvatar(
                  backgroundColor: kQuizBrown900,
                  minRadius: 25,
                  child: new Text(name[0]),
                ),
              ),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(fontSize: 18),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(0, 0, 6, 0),
                child: Text(
                  points.toString(),
                  style: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
        new Divider(),
      ],
    );
  }

  Widget _buildUserRow(int rank, int points, String picPath) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Expanded(
            flex: 33,
            child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Rank(rank: _userRank),
                  Text(
                    getOrdinalOfNumber(_userRank),
                    style: TextStyle(
                      color: kQuizSurfaceWhite,
                    ),
                  )
                ],
              ),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kQuizMain50,
              image: DecorationImage(
                fit: BoxFit.fill,
                image: AssetImage('images/face.jpg'),
              ),
            ),
          ),
          Expanded(
            flex: 33,
            child: Container(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    points.toString(),
                    style: TextStyle(
                      fontSize: 32,
                      color: kQuizSurfaceWhite,
                    ),
                  ),
                  Text(
                    'pts',
                    style: TextStyle(
                      textBaseline: TextBaseline.alphabetic,
                      color: kQuizSurfaceWhite,
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  String getOrdinalOfNumber(int n) {
    int j = n % 10;
    int k = n % 100;
    if (j == 1 && k != 11) {
      return "st";
    }
    if (j == 2 && k != 12) {
      return "nd";
    }
    if (j == 3 && k != 13) {
      return "rd";
    }
    return "th";
  }

  @override
  Widget build(BuildContext context) {
    Widget topSection = Container(
      child: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(16),
            child: Text(
              'Players',
              style: TextStyle(
                fontSize: 25,
                color: kQuizSurfaceWhite,
              ),
            ),
          ),
          _buildUserRow(1, CacheData.userState.totalscore, 'image/face.jpg')
        ],
      ),
    );
    Scaffold playerTab = leaderList != null
        ? new Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
            child: topSection, preferredSize: Size(100, 100)),
        backgroundColor: kQuizMain400,
      ),
      body: ListView.builder(
        itemCount: leaderList.length,
        itemBuilder: (BuildContext context, int index) {
          return _buildLeaderRow(
            index + 1,
            leaderList[index].name,
            leaderList[index].totalscore,
            Icons.face,
            'images/rank2.jpg',
            leaderList[index].mhtId,
          );
        },
      ),
    )
        : new Scaffold(
      body: new Center(
        child: CircularProgressIndicator(),
      ),
    );
    Scaffold cityTab = leaderList != null
        ? new Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
            child: topSection, preferredSize: Size(100, 100)),
        backgroundColor: kQuizMain400,
      ),
      body: ListView.builder(
        itemCount: leaderList.length,
        itemBuilder: (BuildContext context, int index) {
          return _buildCityRow(
            index + 1,
            leaderList[index].name,
            leaderList[index].totalscore,
            Icons.face,
            'images/rank2.jpg',
            leaderList[index].mhtId,
          );
        },
      ),
    )
        : new Scaffold(
      body: new Center(
        child: CircularProgressIndicator(),
      ),
    );
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.directions_car)),
                Tab(icon: Icon(Icons.directions_transit))
              ],
            ),
            title: Text('LeaderBoard'),
          ),
          body: TabBarView(
            children: [
              //Icon(Icons.directions_car),
              playerTab,
              cityTab
            ],
          ),
        ),
      ),
    );
  }
}

class Rank extends StatelessWidget {
  Rank({Key key, this.rank: 0}) : super(key: key);

  final int rank;

  Widget build(BuildContext context) {
    return Text(
      rank.toString(),
      style: TextStyle(fontSize: 32, color: Colors.white),
    );
  }
}

class TabPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.directions_car)),
                Tab(icon: Icon(Icons.directions_transit))
              ],
            ),
            title: Text('Tabs Demo'),
          ),
          body: TabBarView(
            children: [
              Icon(Icons.directions_car),
              Icon(Icons.directions_transit)
            ],
          ),
        ),
      ),
    );
  }
}