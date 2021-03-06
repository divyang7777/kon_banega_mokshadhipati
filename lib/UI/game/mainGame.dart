import 'dart:math';

import 'package:GnanG/Service/apiservice.dart';
import 'package:GnanG/UI/game/mcq.dart';
import 'package:GnanG/UI/game/title_bar.dart';
import 'package:GnanG/UI/widgets/base_state.dart';
import 'package:GnanG/constans/wsconstants.dart';
import 'package:GnanG/model/appresponse.dart';
import 'package:GnanG/model/cacheData.dart';
import 'package:GnanG/model/current_stat.dart';
import 'package:GnanG/model/question.dart';
import 'package:GnanG/model/user_score_state.dart';
import 'package:GnanG/model/validateQuestion.dart';
import 'package:GnanG/utils/app_setting_util.dart';
import 'package:GnanG/utils/app_utils.dart';
import 'package:GnanG/utils/audio_utilsdart.dart';
import 'package:GnanG/utils/response_parser.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/flame.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

import '../../colors.dart';
import '../../common.dart';
import '../../model/quizlevel.dart';
import 'pikachar.dart';

class MainGamePage extends StatefulWidget {
  final QuizLevel level;
  final bool isBonusLevel;

  MainGamePage({this.level, this.isBonusLevel = false});

  @override
  State<StatefulWidget> createState() => new MainGamePageState();
}

class MainGamePageState extends BaseState<MainGamePage> {
  List<int> hiddenOptionIndex = [];
  List<Question> questions;
  Question question;
  int currentQueIndex;
  bool isHintTaken = false;
  bool isGivenCorrectAns = false;
  int correctAnsIndex = -1;
  int selectedAnsIndex = -1;
  ApiService _api = new ApiService();
  CurrentState currentState;
  Image image;

  @override
  void initState() {
    print(widget.level);
    super.initState();
    _loadData();
  }
  AudioPlayer levelStartPlayer;
  _loadData() {
    /*AppAudioUtils.playMusic(url:'music/CHANDELIER_FALLS.mp3', volume: 0.3).then((player) {
      levelStartPlayer = player;
    });*/
    isLoading = true;
    currentState = CacheData.userState.currentState;
    print('currentState ::::::::: ');
    print(currentState);
    _loadAllQuestions();
  }

  @override
  void dispose() {
    super.dispose();
    if(levelStartPlayer != null)
      levelStartPlayer.stop();
  }

  _loadAllQuestions() async {
    image = await CommonFunction.getUserProfileImg(context: context);
    Response res;
    if (widget.isBonusLevel) {
      res = await _api.getBonusQuestion(mhtId: CacheData.userInfo.mhtId);
    } else {
      res = await _api.getQuestions(
          level: widget.level.levelIndex, from: currentState.questionSt);
    }
    AppResponse appResponse =
        ResponseParser.parseResponse(context: context, res: res);
    if (appResponse.status == 200) {
      bool isLoadQuestion = true;
      if (widget.isBonusLevel) {
        if (isBonusCompleted(appResponse)) {
          isLoadQuestion = false;
          isLoading = false;
        }
      }
      if (isLoadQuestion) {
        questions = Question.fromJsonArray(appResponse.data);
        print(questions);
        setState(() {
          if (questions.length > 0) {
            question = questions.getRange(0, 1).first;
            currentQueIndex = 0;
          } else {
            CommonFunction.alertDialog(
                context: context,
                msg: 'There are no questions',
                barrierDismissible: false,
                doneButtonFn: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                });
          }
          isLoading = false;
        });
      }
    }
  }

  bool isBonusCompleted(AppResponse appResponse) {
    if (appResponse.data is Map && appResponse.data['msg'] != null) {
      AppAudioUtils.stopMusic(levelStartPlayer);
      CommonFunction.alertDialog(
          context: context,
          type: "success",
          msg: appResponse.data['msg'],
          barrierDismissible: false,
          doneButtonFn: () {
            Navigator.pop(context);
            Navigator.pop(context);
          });
      return true;
    }
    return false;
  }

  void onOKButtonClick(bool isCompletedLevel) {
    Navigator.pop(context);
    setState(() {
      if (!isCompletedLevel) {
        _loadNextQuestion();
      } else {
        Navigator.pushReplacementNamed(context, '/level');
      }
    });
  }

  _loadNextQuestion() async {
    if (currentQueIndex < questions.length - 1) {
      setState(() {
        _reInitForQuestion();
        currentQueIndex++;
        question =
            questions.getRange(currentQueIndex, currentQueIndex + 1).first;
      });
    } else {
      AudioPlayer audioPlayer = await AppAudioUtils.playMusic(url: "music/level/levelCompleted.WAV");
      CommonFunction.alertDialog(
          context: context,
          msg: (widget.isBonusLevel)
              ? "All Questions of Daily Bonus are completed !!"
              : widget.level.name + ' level is completed !! ',
          barrierDismissible: false,
          type: 'success',
          playSound: false,
          doneButtonFn: () async {
            AppAudioUtils.stopMusic(audioPlayer);
            Navigator.pop(context);
            setState(() {
              isOverlay = true;
            });
            bool result = await CommonFunction.loadUserState(context, CacheData.userInfo.mhtId);
            setState(() {
              isOverlay = false;
            });
            if (result) {
              Navigator.pop(context);
            }
          });
    }
  }

  _reInitForQuestion() {
    hiddenOptionIndex = [];
    isHintTaken = false;
  }

  void onAnswerGiven(bool isGivenCorrectAns) {
    try {
      print('Inside onAnswerGiven' + isGivenCorrectAns.toString());
      setState(() {});
      if (widget.isBonusLevel) {
        _loadNextQuestion();
      } else {
        if (isGivenCorrectAns) {
          _loadNextQuestion();
        } else {
          if (CacheData.userState.lives == 1) {
            CommonFunction.alertDialog(
              context: context,
              type: 'success',
              playSound: false,
              msg: 'You have only 1 Life remaining. Now you can access hint.',
              barrierDismissible: false,
            );
          }
          if (CacheData.userState.lives == 0) {
            AppAudioUtils.playMusic(url: "music/game/gameEnd.WAV");
            CommonFunction.alertDialog(
                context: context,
                msg: 'Game-over',
                playSound: false,
                barrierDismissible: false,
                doneButtonFn: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                });
          }
        }
      }
    } catch (err) {
      print('CATCH VALIDATE QUESTION :: ');
      print(err);
      CommonFunction.displayErrorDialog(
        context: context,
        msg: err.toString(),
      );
    }
  }

  @override
  Widget pageToDisplay() {
    return new Scaffold(
      body: new BackgroundGredient(
        child: SafeArea(
          child: new Container(
//            padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
            padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: new Column(
              children: <Widget>[
                GameTitleBar(
                  title:
                      (widget.isBonusLevel) ? "Daily Bonus" : widget.level.name,
                  questionNumber: question != null ? question.questionSt : 1,
                  totalQuestion: getTotalQuestion(),
                ),
                SizedBox(
                  height: 15,
                ),
                Expanded(
                    child: question != null
                        ? question.questionType == "MCQ"
                            ? new MCQ(
                                question, validateAnswer, hiddenOptionIndex)
                            : new Pikachar(
                                question.question,
                                question.jumbledata,
                                question.pikacharAnswer,
                                validateAnswer)
                        : new Container())
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          !widget.isBonusLevel ? _buildbottomNavigationBar() : null,
      floatingActionButtonLocation: widget.isBonusLevel
          ? FloatingActionButtonLocation.endFloat
          : FloatingActionButtonLocation.centerDocked,
      floatingActionButton: widget.isBonusLevel
          ? getFloatingActionButtonForBonus()
          : getFloatingButForNonBonus(),
    );
  }

  Widget getFloatingButForNonBonus() {
    return CacheData.userState.lives <= 1
        ? FloatingActionButton.extended(
            backgroundColor: kQuizMain500,
            icon: Icon(Icons.help_outline),
            label: Text('Get Hint'),
            onPressed: _getHint,
          )
        : null;
  }

  Widget getFloatingActionButtonForBonus() {
    return question.score != null
        ? FloatingActionButton(
            backgroundColor: kQuizSurfaceWhite,
            child: Text(
              question.score.toString(),
              style: TextStyle(
                color: kQuizMain400,
                fontSize: 25,
              ),
            ),
            onPressed: () {
              //AppUtils.showInSnackBar(context, "You can get " + question.score.toString() + " score by giving correct answer on this question.");
              CommonFunction.alertDialog(
                context: context,
                msg: "You can get " + question.score.toString() + " score by giving correct answer on this question.",
                barrierDismissible: false,
                type: 'info',
                playSound: false,
                displayImage: false
              );
            },
          )
        : null;
  }

  int getTotalQuestion() {
    if (widget.isBonusLevel) {
      return questions
          .getRange(questions.length - 1, questions.length)
          .first
          .questionSt;
    }
    int totalQuestion = -1;
    List<QuizLevel> levelInfos = CacheData.userState.quizLevels;
    for (final quizLevel in levelInfos) {
      if (quizLevel.levelIndex == CacheData.userState.currentState.level) {
        totalQuestion = quizLevel.totalQuestions;
        break;
      }
    }

    return totalQuestion;
  }

  void validateAnswer({String answer}) async {
    setState(() {
      isOverlay = true;
    });
    Response res = await _api.validateAnswer(
      questionId: question.questionId,
      mhtId: CacheData.userInfo.mhtId,
      answer: answer,
      level: CacheData.userState.currentState.level,
    );
    setState(() {
      isOverlay = false;
    });
    AppResponse appResponse = ResponseParser.parseResponse(context: context, res: res);
    if (appResponse.status == WSConstant.SUCCESS_CODE) {
      ValidateQuestion validateQuestion = ValidateQuestion.fromJson(appResponse.data);
      setState(() {
        isGivenCorrectAns = true;
        validateQuestion.updateSessionScore();
      });
      if (validateQuestion.answerStatus) {
        CommonFunction.alertDialog(
          context: context,
          msg: 'Your answer is correct !!',
          type: 'success',
          barrierDismissible: false,
          doneButtonFn: onAnswerStatusDialogOK,
        );
      } else {
        isGivenCorrectAns = false;
        CommonFunction.alertDialog(
          context: context,
          msg: 'Your answer is wrong !!',
          barrierDismissible: false,
          doneButtonFn: onAnswerStatusDialogOK,
        );
      }
    }
  }


  void onAnswerStatusDialogOK() {
    Navigator.pop(context);
    onAnswerGiven(isGivenCorrectAns);
  }

  Widget _buildbottomNavigationBar() {
    return BottomAppBar(
      color: kQuizMain400,
      elevation: 10.0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(
              child: IconButton(
                icon: Icon(
                  Icons.menu,
                  color: kQuizBackgroundWhite,
                ),
                onPressed: () {
                  showModalBottomSheet(
                      builder: (BuildContext context) => _bottomDrawer(),
                      context: context);
                },
              ),
            ),
            Container(
              child: Row(
                children: <Widget>[
                  Text(
                    'Lives : ',
                    style: TextStyle(color: kQuizBackgroundWhite),
                  ),
                  Container(
                    height: 25,
                    child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: CacheData.userState.lives,
                      itemBuilder: (BuildContext context, int index) {
                        return Icon(
                          Icons.account_circle,
                          color: kQuizBackgroundWhite,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _getHint() async {
    // CommonFunction.loadUserState(context, CacheData.userInfo.mhtId);
    try {
      bool isApiFailed = false;
      if (!isHintTaken) {
        setState(() {
          isOverlay = true;
        });
        Response res = await _api.hintTaken(questionId: question.questionId, mhtId: CacheData.userInfo.mhtId);
        AppResponse appResponse = ResponseParser.parseResponse(context: context, res: res);
        if (appResponse.status == WSConstant.SUCCESS_CODE) {
          UserScoreState userScoreState = UserScoreState.fromJson(appResponse.data);
          setState(() {
            userScoreState.updateSessionScore();
          });
          SharedPreferences pref = await SharedPreferences.getInstance();
          pref.setString('user_info', res.body);
          print('FROM HINT :: ');
          print(res.body);
          isHintTaken = true;
        } else {
          isApiFailed = true;
        }
      }
      if (!isApiFailed) {
        AudioPlayer audioPlayer = await AppAudioUtils.playMusic(url: 'music/hint.WAV', volume: 2.6);
        CommonFunction.alertDialog(
            context: context,
            msg: question.reference,
            type: 'success',
            doneButtonText: 'Okay',
            title: 'Here is your hint ...',
            playSound: false,
            doneButtonFn: () {
              AppAudioUtils.stopMusic(audioPlayer);
              Navigator.pop(context);
            },
            barrierDismissible: false,
        );
      }
    } catch (err) {
      print('CATCH IN HINT :: ');
      print(err);
      CommonFunction.displayErrorDialog(context: context, msg: err.toString());
    }
    setState(() {
      isOverlay = false;
    });
  }

  Widget _bottomDrawer() {
    return Drawer(
      elevation: 10.0,
      child: ListView(
        children: <Widget>[
          SizedBox(
            height: 30.0,
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: kQuizMain400,
              child: Center(
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kQuizMain50,
                    image: DecorationImage(
                      fit: BoxFit.fill,
                      image: image.image,
                    ),
                  ),
                ),
              ),
              maxRadius: 30.0,
            ),
            title: Text(
              CacheData.userInfo.name,
              textScaleFactor: 1.3,
            ),
            subtitle: Text(
              CacheData.userInfo.email + '\n' + CacheData.userInfo.mobile,
              style: TextStyle(color: kQuizMain50, height: 1.3),
            ),
//            dense: true,
            // trailing: Row(
            //   mainAxisSize: MainAxisSize.min,
            //   children: <Widget>[
            //     Text(
            //       2.toString(),
            //       textScaleFactor: 2,
            //     ),
            //     Text(
            //       getOrdinalOfNumber(2),
            //       style: TextStyle(height: 2),
            //     ),
            //   ],
            // ),
            contentPadding: EdgeInsets.symmetric(horizontal: 25),
          ),
          SizedBox(
            height: 20.0,
          ),
          Divider(
            color: kQuizMain50,
          ),
          SizedBox(
            height: 10.0,
          ),
          Container(
            child: new Center(
              child: Text(
                'Life-Lines',
                textScaleFactor: 1.5,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CacheData.userState.lives > 1 ? Text('\nWill be available only \nwhen your 1 life is left.', textScaleFactor: 1.2,) : new Container(),
              (question.questionType != 'MCQ' && CacheData.userState.lives <= 1) ? Text('\nFill in the blanks will \nnot have any lifelines.',textScaleFactor: 1.2,) : new Container(),
              (question.questionType == 'MCQ' && CacheData.userState.lives <= 1 && !CacheData.userState.currentState.fifty_fifty) ? Text('\nYou have already used \nlifeline in this level.',textScaleFactor: 1.2,) : new Container(),
            ],
          ),
          SizedBox(
            height: 30.0,
          ),
          new Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              (question.questionType == 'MCQ' && CacheData.userState.currentState.fifty_fifty != null
                  && CacheData.userState.currentState.fifty_fifty && CacheData.userState.lives <= 1) ?
                  lifeline(Icons.star_half, '50 - 50', _fiftyFifty)
                  : new Container(),
            ],
          ),
          SizedBox(
            height: 20.0,
          ),
          Divider(
            color: kQuizMain50,
          ),
          SizedBox(
            height: 20.0,
          ),
          /*new Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              SizedBox(width: 20),
              Text(
                'How to play ?',
                style: TextStyle(
                  color: kQuizMain50,
                ),
              ),
              Text(
                'Terms and conditions',
                style: TextStyle(
                  color: kQuizMain50,
                ),
              ),
              SizedBox(width: 20),
            ],
          ),*/
          /*SizedBox(
            height: 20,
          )*/
        ],
      ),
    );
  }

  _phoneAFriend() {
    /*if (platform.isAndroid) {
      AndroidIntent intent = AndroidIntent(
        action: 'action_view',
        data: 'https://play.google.com/store/apps/details?'
            'id=com.google.android.apps.myapp',
        arguments: {'authAccount': currentUserEmail},
      );
      await intent.launch();
    }*/
    try {
      Platform.isIOS ? launch("telprompt:4141") : launch("tel:");
      print('Phone a Friend');
      Navigator.pop(context);
    } catch (err) {
      print('CATCH IN HINT :: ');
      print(err);
      CommonFunction.displayErrorDialog(context: context, msg: err.toString());
    }
  }

  _fiftyFifty() async {
    try {
      Navigator.pop(context);
      bool isApiFailed = false;
      if (!isHintTaken) {
        setState(() {
          isOverlay = true;
        });
        Response res = await _api.fiftyFifty(
          mht_id: CacheData.userInfo.mhtId,
          level: CacheData.userState.currentState.level,
        );
        AppResponse appResponse = ResponseParser.parseResponse(context: context, res: res);
        if (appResponse.status == WSConstant.SUCCESS_CODE) {
          UserScoreState userScoreState = UserScoreState.fromJson(appResponse.data);
          setState(() {
            userScoreState.updateSessionScore();
            CacheData.userState.currentState.fifty_fifty = false;
          });
          SharedPreferences pref = await SharedPreferences.getInstance();
          pref.setString('user_info', res.body);
          print('FROM HINT :: ');
          print(res.body);
          isHintTaken = true;
        } else {
          isApiFailed = true;
        }
      }
      if (!isApiFailed) {
        AppAudioUtils.playMusic(url: 'music/hint.WAV', volume: 2.6);
        var rng = new Random();
        while (hiddenOptionIndex.length < 2) {
          int temp = rng.nextInt(3);
          if (temp != question.answerIndex &&
              hiddenOptionIndex.indexOf(temp) == -1) {
            setState(() {
              hiddenOptionIndex.add(temp);
            });
          }
        }
      }
    } catch (err) {
      print('CATCH IN HINT :: ');
      print(err);
      CommonFunction.displayErrorDialog(context: context, msg: err.toString());
    }
    setState(() {
      isOverlay = false;
    });
  }

  Widget lifeline(IconData icon, String lifelineName, Function fn) {
    return Expanded(
      child: Column(
        children: <Widget>[
          FlatButton(
            color: Colors.red.shade100,
            padding: EdgeInsets.all(15),
            shape: CircleBorder(),
            child: Icon(
              icon,
              size: 30,
            ),
            onPressed: fn,
          ),
          SizedBox(height: 20),
          Text(
            lifelineName,
            textScaleFactor: 1.1,
          ),
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
}
