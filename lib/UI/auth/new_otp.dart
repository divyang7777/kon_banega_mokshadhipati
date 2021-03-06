import 'package:GnanG/UI/auth/register_new.dart';
import 'package:GnanG/UI/widgets/base_state.dart';
import 'package:GnanG/model/signupsession.dart';
import 'package:flutter/material.dart';

import '../../Service/apiservice.dart';
import '../../colors.dart';
import '../../common.dart';

class OtpVerifyPage extends StatefulWidget {
  final int otp;
  final bool fromForgotPassword;
  final UserData userData;

  OtpVerifyPage({this.otp, this.userData, this.fromForgotPassword = false});
  @override
  State<StatefulWidget> createState() => new OtpVerifyPageState();
}

class OtpVerifyPageState extends BaseState<OtpVerifyPage> {
  final _formKey = GlobalKey<FormState>();
  CommonFunction cf = new CommonFunction();
  bool _autoValidate = false;
  ApiService _api = new ApiService();
  String _otp;

  @override
  Widget pageToDisplay() {
    return new Form(
      key: _formKey,
      autovalidate: _autoValidate,
      child: new Scaffold(
        backgroundColor: kBackgroundGrediant1,
        body: SafeArea(
          child: new ListView(
            padding: EdgeInsets.symmetric(horizontal: 30.0),
            children: <Widget>[
              new SizedBox(height: 20.0),
              new Column(
                children: <Widget>[
                  new Image.asset(
                    'images/logo1.png',
                    height: 200,
                  ),
                  new SizedBox(height: 5.0),
                  new Text(
                    'VERIFY OTP',
                    textScaleFactor: 1.5,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              new SizedBox(
                height: 50.0,
              ),
              new AccentColorOverride(
                color: kQuizBrown900,
                child: new TextFormField(
                  validator: CommonFunction.otpValidation,
                  decoration: InputDecoration(
                    labelText: 'OTP',
                    hintText: 'Enter OTP',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: kQuizBrown900,
                    ),
                    filled: true,
                  ),
                  onSaved: (String value) {
                    _otp = value;
                  },
                  keyboardType: TextInputType.numberWithOptions(),
                ),
              ),
              new SizedBox(height: 20.0),
              new RaisedButton(
                child: Text(
                  'VERIFY',
                  style: TextStyle(color: Colors.white),
                ),
                elevation: 4.0,
                padding: EdgeInsets.all(20.0),
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      if (_otp == widget.otp.toString()) {
        Navigator.pop(context);
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => new RegisterPage2(
                userData: widget.userData,
                fromForgotPassword: widget.fromForgotPassword),
          ),
        );
      } else {
        CommonFunction.alertDialog(
          context: context,
          msg: "OTP is not valid, Please try again.",
        );
      }
    } else {
      _autoValidate = true;
    }
  }
}
