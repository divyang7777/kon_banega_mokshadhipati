import 'dart:io';

import 'package:GnanG/utils/audio_utilsdart.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:GnanG/Service/apiservice.dart';
import 'package:GnanG/UI/puzzle/data/result.dart';
import 'package:GnanG/UI/puzzle/play_games.dart';
import 'package:GnanG/UI/puzzle/widgets/game/material/page.dart';
import 'package:GnanG/UI/puzzle/widgets/game/material/victory.dart';
import 'package:GnanG/UI/puzzle/widgets/game/presenter/main.dart';
import 'package:GnanG/constans/wsconstants.dart';
import 'package:GnanG/model/appresponse.dart';
import 'package:GnanG/model/cacheData.dart';
import 'package:GnanG/model/user_score_state.dart';
import 'package:GnanG/utils/response_parser.dart';

class GamePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //_puzzleCompletedApiCall(context);
    final rootWidget = _buildRoot(context);
    return GamePresenterWidget(
      child: rootWidget,
      onSolve: (result) {
        _submitResult(context, result);
        _puzzleCompletedApiCall(context);
        _showVictoryDialog(context, result);
      },
    );
  }

  Widget _buildRoot(BuildContext context) {
    return GameMaterialPage();
  }

  void _puzzleCompletedApiCall(context) async {
    ApiService _api = ApiService();

    try {
      Response res = await _api.puzzleCompleted(
          mhtId: CacheData.userInfo.mhtId,
          puzzle_name: WSConstant.PUZZLE_NAME_GAME_OF_15,
          puzzle_type: WSConstant.PUZZLE_TYPE_GAME_OF_15_3);
      print('----> $res inside page.dart <----');
      AppResponse appResponse =
          ResponseParser.parseResponse(res: res, context: context);

      if (appResponse.status == WSConstant.SUCCESS_CODE) {
        UserScoreState userDATA = UserScoreState.fromJson(appResponse.data);
        print('----> $userDATA inside page.dart <----');
        userDATA.updateSessionScore();
        // UserScoreState.fromJson(appResponse.data).updateSessionScore();
      }
    } catch (e) {}
  }

  void _showVictoryDialog(BuildContext context, Result result) {
//    if (Platform.isIOS) {
//      showCupertinoDialog(
//        context: context,
//        builder: (context) => Text(''),
//      );
//    } else {
      AppAudioUtils.playMusic(url: "music/level/levelCompleted.WAV");
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => GameVictoryDialog(result: result),
      );
//    }
  }

  void _submitResult(BuildContext context, Result result) {
    final playGames = PlayGamesContainer.of(context);
    playGames.submitScore(
      key: PlayGames.getLeaderboardOfSize(result.size),
      time: result.time,
    );
  }
}
