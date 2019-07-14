import 'dart:async';
import 'dart:math';

import 'package:GnanG/Service/apiservice.dart';
import 'package:GnanG/UI/game/mcq.dart';
import 'package:GnanG/UI/game/time_based_ui.dart';
import 'package:GnanG/UI/game/title_bar.dart';
import 'package:GnanG/UI/widgets/base_state.dart';
import 'package:GnanG/constans/appconstant.dart';
import 'package:GnanG/constans/wsconstants.dart';
import 'package:GnanG/main.dart';
import 'package:GnanG/model/appresponse.dart';
import 'package:GnanG/model/cacheData.dart';
import 'package:GnanG/model/current_stat.dart';
import 'package:GnanG/model/question.dart';
import 'package:GnanG/model/user_level.dart';
import 'package:GnanG/model/user_score_state.dart';
import 'package:GnanG/model/validateQuestion.dart';
import 'package:GnanG/utils/audio_utilsdart.dart';
import 'package:GnanG/utils/response_parser.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_circular_chart/flutter_circular_chart.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../colors.dart';
import '../../common.dart';
import '../../model/quizlevel.dart';
import 'pikachar.dart';

final GlobalKey<AnimatedCircularChartState> _chartKey =
    new GlobalKey<AnimatedCircularChartState>();

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
  ValueNotifier<bool> isReset = new ValueNotifier(false);
  bool isTimeBasedLevel = false;
  UserLevel userLevel;

  Timer _timer;
  int _timeInSeconds = 0; // question timer
  double _remaining = 100; // do not edit
  double _step = 0; // do not edit

  @override
  void initState() {
    print(widget.level);
    super.initState();
    AppConstant.POPUP_COUNT = 0;
    if (widget.level != null && widget.level.levelType == 'TIME_BASED') {
      isTimeBasedLevel = true;
    }
    _loadData();
  }

  void closeAllPopup() {
    for (int i = 0; i < AppConstant.POPUP_COUNT; i++) {
      Navigator.pop(context);
    }
    AppConstant.POPUP_COUNT = 0;
  }

  AudioPlayer levelStartPlayer;

  _loadData() {
    /*AppAudioUtils.playMusic(url:'music/CHANDELIER_FALLS.mp3', volume: 0.3).then((player) {
      levelStartPlayer = player;
    });*/
    isLoading = true;
    // currentState = CacheData.userState.currentState;
    print('currentState ::::::::: ');
    print(currentState);
    if (widget.isBonusLevel) {
      _loadAllQuestions();
    } else {
      getCurruntLevelQuestionState();
    }
  }

  getCurruntLevelQuestionState() async {
    Map<String, dynamic> reqData = {
      'mht_id': CacheData.userInfo.mhtId,
      'level': widget.level.levelIndex
    };
    Response res = await _api.postApi(url: '/check_user_level', data: reqData);
    AppResponse appResponse =
        ResponseParser.parseResponse(context: context, res: res);
    if (appResponse.status == 200) {
      print('===========>');
      userLevel = UserLevel.fromJson(appResponse.data['results']);
      print(appResponse.data['results']);
      _loadAllQuestions(
        levelIndex: userLevel.level,
        questionState: widget.level.levelType == 'TIME_BASED'
            ? userLevel.questionReadSt
            : userLevel.questionSt,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (levelStartPlayer != null) levelStartPlayer.stop();
    if (_timer != null) _timer.cancel();
    CommonFunction.loadUserState(context, CacheData.userInfo.mhtId);
    main();
  }

  _loadAllQuestions({int levelIndex, int questionState}) async {
    print('****** ==> ');
    print(levelIndex);
    print(questionState);
    Response res;
    if (widget.isBonusLevel) {
      res = await _api.getBonusQuestion(mhtId: CacheData.userInfo.mhtId);
    } else {
      res = await _api.getQuestions(
          level: levelIndex,
          from: widget.level.levelType == 'TIME_BASED'
              ? questionState + 1
              : questionState);
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
    print('****************');
    print(currentQueIndex);
    print(questions.length);
    if (currentQueIndex < questions.length - 1) {
      setState(() {
        _reInitForQuestion();
        currentQueIndex++;
        question =
            questions.getRange(currentQueIndex, currentQueIndex + 1).first;
      });
      if (!widget.isBonusLevel && widget.level.levelType == 'TIME_BASED') {
        _resetTimer();
        _markReadQuestion();
      }
    } else {
      AudioPlayer audioPlayer =
          await AppAudioUtils.playMusic(url: "music/level/levelCompleted.WAV");
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
            setState(() {
              isOverlay = true;
            });
            bool result = await CommonFunction.loadUserState(
                context, CacheData.userInfo.mhtId);
            setState(() {
              isOverlay = false;
            });
            if (result) {
              exitLevel();
              //Navigator.pop(context);
            }
          });
    }
  }

  _resetTimer() {
    _timer.cancel();
    _remaining = 100;
    startTimer();
  }

  _reInitForQuestion() {
    hiddenOptionIndex = [];
    isHintTaken = false;
  }

  Future<bool> loadUserState() async {
    setState(() {
      isOverlay = true;
    });
    bool result =
        await CommonFunction.loadUserState(context, CacheData.userInfo.mhtId);
    setState(() {
      isOverlay = false;
    });
    return result;
  }

  void onAnswerGivenTimebased(bool isGivenCorrectAns) {
    _loadNextQuestion();
  }

  void onAnswerGivenNonTimeBased(bool isGivenCorrectAns) {
    setState(() {});
    if (widget.isBonusLevel) {
      _loadNextQuestion();
    } else {
      if (isGivenCorrectAns) {
        _loadNextQuestion();
      }
    }
  }

  void onAnswerGiven(bool isGivenCorrectAns) {
    try {
      print('Inside onAnswerGiven' + isGivenCorrectAns.toString());
      if (isTimeBasedLevel)
        onAnswerGivenTimebased(isGivenCorrectAns);
      else
        onAnswerGivenNonTimeBased(isGivenCorrectAns);
    } catch (err) {
      print('CATCH VALIDATE QUESTION :: ');
      print(err);
      CommonFunction.displayErrorDialog(
        context: context,
        msg: err.toString(),
      );
    }
  }

  _markReadQuestion() async {
    try {
      Response res = await _api.markReadQuestion(
        level: question.level,
        mhtId: CacheData.userInfo.mhtId,
        questionId: question.questionId,
        questionSt: question.questionSt,
      );
      AppResponse appResponse =
          ResponseParser.parseResponse(context: context, res: res);
      if (appResponse.status == WSConstant.SUCCESS_CODE) {
        print('ReadQuestion :: ');
        print(appResponse.data);
        // CacheData.userState.currentState.questionReadSt =
        //     appResponse.data['question_read_st'];
      }
    } catch (err) {
      _timer.cancel();
      CommonFunction.alertDialog(
        context: context,
        msg: err.toString(),
        doneButtonFn: exitLevel,
        type: 'error',
      );
    }
  }

  void timeOverDialog({String msg = 'Time\'s up !!'}) {
    _timer.cancel();
    CommonFunction.alertDialog(
      context: context,
      msg: msg,
      type: 'error',
      showCancelButton: true,
      barrierDismissible: false,
      cancelButtonText: 'Exit',
      doneCancelFn: exitLevel,
      doneButtonText: 'Next Que.',
      doneButtonFn: nextQuestion,
    );
  }

  void exitLevel() {
    Navigator.pop(context); // For current popup
    closeAllPopup();
    Navigator.pop(context); // For exit game screen
  }

  nextQuestion() {
    Navigator.pop(context);
    closeAllPopup();
    _loadNextQuestion();
  }

  void startTimer() {
    _timeInSeconds = question != null ? question.timeLimit : 0;
    _step = 100 / _timeInSeconds;
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) => setState(() {
            if (mounted) {
              if (_timeInSeconds < 1) {
                timeOverDialog();
                timer.cancel();
              } else {
                _remaining = _remaining - _step;
                _chartKey.currentState.updateData(
                  <CircularStackEntry>[
                    new CircularStackEntry(
                      <CircularSegmentEntry>[
                        new CircularSegmentEntry(
                            _timeInSeconds == 1 ? 0 : _remaining, kQuizMain400,
                            rankKey: 'completed'),
                        new CircularSegmentEntry(
                            100, kQuizMain400.withAlpha(50),
                            rankKey: 'remaining'),
                      ],
                      rankKey: 'progress',
                    ),
                  ],
                );
                _timeInSeconds = _timeInSeconds - 1;
              }
            }
          }),
    );
  }

  @override
  Widget pageToDisplay() {
    Widget _timeIndicator = new AnimatedCircularChart(
      key: _chartKey,
      size: const Size(100.0, 100.0),
      edgeStyle: SegmentEdgeStyle.round,
      holeRadius: 25,
      initialChartData: <CircularStackEntry>[
        new CircularStackEntry(
          <CircularSegmentEntry>[
            new CircularSegmentEntry(
              0,
              kQuizMain400,
              rankKey: 'completed',
            ),
            new CircularSegmentEntry(
              100,
              kQuizMain400.withAlpha(50),
              rankKey: 'remaining',
            ),
          ],
          rankKey: 'progress',
        ),
      ],
      chartType: CircularChartType.Radial,
      percentageValues: true,
      holeLabel: "$_timeInSeconds",
      labelStyle: new TextStyle(
        color: Colors.blueGrey[600],
        fontWeight: FontWeight.bold,
        fontSize: 30.0,
      ),
    );

    return question != null
        ? new Scaffold(
            body: new BackgroundGredient(
              child: widget.isBonusLevel ||
                      widget.level.levelType != 'TIME_BASED'
                  ? SafeArea(
                      child: new Container(
                        padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
                        child: new Column(
                          children: <Widget>[
                            GameTitleBar(
                              title: (widget.isBonusLevel)
                                  ? "Daily Bonus"
                                  : widget.level.name,
                              questionNumber:
                                  question != null ? question.questionSt : 1,
                              totalQuestion: getTotalQuestion(),
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            Expanded(
                              child: question != null
                                  ? question.questionType == "MCQ"
                                      ? new MCQ(question, validateAnswer,
                                          hiddenOptionIndex)
                                      : new Pikachar(
                                          question.question,
                                          question.jumbledata,
                                          question.pikacharAnswer,
                                          validateAnswer)
                                  : new Container(),
                            ),
                          ],
                        ),
                      ),
                    )
                  : TimeBasedUI(
                      title: (widget.isBonusLevel)
                          ? "Daily Bonus"
                          : widget.level.name,
                      questionNumber:
                          question != null ? question.questionSt : 1,
                      totalQuestion: getTotalQuestion(),
                      timeLimit: question != null ? question.timeLimit : 0,
                      loadNextQuestion: _loadNextQuestion,
                      questionInfo: question,
                      timeIndicator: _timeIndicator,
                      timer: startTimer,
                      timeOverDialog: timeOverDialog,
                      gameUI: question != null
                          ? question.questionType == "MCQ"
                              ? new MCQ(
                                  question, validateAnswer, hiddenOptionIndex)
                              : new Pikachar(
                                  question.question,
                                  question.jumbledata,
                                  question.pikacharAnswer,
                                  validateAnswer)
                          : new Container(),
                      markRead: _markReadQuestion,
                    ),
            ),
            floatingActionButtonLocation: widget.isBonusLevel
                ? FloatingActionButtonLocation.endFloat
                : FloatingActionButtonLocation.centerDocked,
            floatingActionButton: widget.isBonusLevel
                ? getFloatingActionButtonForBonus()
                : getFloatingButForNonBonus(),
          )
        : new Scaffold(
            body: Container(),
          );
  }

  Widget getFloatingButForNonBonus() {
    return FloatingActionButton.extended(
      backgroundColor: kQuizMain500,
      icon: Icon(Icons.help_outline),
      label: Text('Get Hint'),
      onPressed: _getHint,
    );
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
                  msg: "You can get " +
                      question.score.toString() +
                      " points by giving correct answer of this question.",
                  barrierDismissible: false,
                  type: 'info',
                  playSound: false,
                  displayImage: false);
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
    return userLevel.totalQuestions;
  }

  void validateAnswer({String answer}) async {
    setState(() {
      isOverlay = true;
    });
    Response res = await _api.validateAnswer(
      questionId: question.questionId,
      mhtId: CacheData.userInfo.mhtId,
      answer: answer,
      level: userLevel.level,
    );
    setState(() {
      isOverlay = false;
    });
    AppResponse appResponse =
        ResponseParser.parseResponse(context: context, res: res);
    if (appResponse.status == WSConstant.SUCCESS_CODE) {
      if (isTimeBasedLevel) _timer.cancel();
      ValidateQuestion validateQuestion =
          ValidateQuestion.fromJson(appResponse.data);
      setState(() {
        isGivenCorrectAns = true;
        validateQuestion.updateSessionScore();
      });
      if (validateQuestion.answerStatus) {
        CommonFunction.alertDialog(
          context: context,
          msg: 'Your answer is correct !!',
          type: 'success',
          doneButtonText: isTimeBasedLevel ? 'Next Que.' : 'Okay',
          showCancelButton: isTimeBasedLevel,
          cancelButtonText: isTimeBasedLevel ? 'Exit' : 'Okay',
          doneCancelFn: exitLevel,
          barrierDismissible: false,
          doneButtonFn: () {
            Navigator.pop(context);
            onAnswerGiven(isGivenCorrectAns);
          },
        );
      } else {
        isGivenCorrectAns = false;
        CommonFunction.alertDialog(
          context: context,
          msg: 'Your answer is wrong !!',
          //type: isTimeBasedLevel ? 'info' : 'error',
          type: 'error',
          doneButtonText: isTimeBasedLevel ? 'Next Que.' : 'Okay',
          showCancelButton: isTimeBasedLevel,
          barrierDismissible: false,
          doneCancelFn: exitLevel,
          cancelButtonText: isTimeBasedLevel ? 'Exit' : 'Okay',
          doneButtonFn: () {
            Navigator.pop(context);
            onAnswerGiven(isGivenCorrectAns);
          },
        );
      }
    }
  }

  void _getHint() async {
    AudioPlayer audioPlayer =
        await AppAudioUtils.playMusic(url: 'music/hint.WAV', volume: 2.6);
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
