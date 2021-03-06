import 'dart:io';

import 'package:GnanG/UI/imagepicker/image_picker_handler.dart';
import 'package:GnanG/UI/widgets/hero_image.dart';
import 'package:GnanG/colors.dart';
import 'package:flutter/material.dart';

class ImageInput extends StatefulWidget {

  Function onImagePicked;
  Image image;
  ImageInput({@required this.image, this.onImagePicked});
  @override
  _ImageInputState createState() => new _ImageInputState();
}

class _ImageInputState extends State<ImageInput>
    with TickerProviderStateMixin, ImagePickerListener {
  AnimationController _controller;
  ImagePickerHandler imagePicker;
  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    imagePicker = new ImagePickerHandler(this, _controller);
    imagePicker.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        new Center(
            child: new Stack(
          children: <Widget>[
            _buildProfilePicture(),
            new Center(
              child: new GestureDetector(
                onTap: () => imagePicker.showDialog(context),
                child: _buildCamera(),
              ),
            ),
          ],
        )),
      ],
    );
  }

  _buildCamera() {
    return Container(
        width: 100.0,
        height: 100.0,
        alignment: Alignment.bottomRight,
        child: CircleAvatar(
          maxRadius: 17,
          child: new Container(
            decoration: new BoxDecoration(

            ),
            child: Image(
              height: 27,
              width: 27,
              image: AssetImage('images/photo_camera.png'),
            ),
          ),
        ));
  }

  _buildProfilePicture() {
    return CircleAvatar(
      maxRadius: 48,
      child: HeroImage(image: widget.image),
      backgroundColor: kQuizBrown900,
    );
  }


  @override
  userImage(File _image) async {
    if(_image != null)
      if(widget.onImagePicked != null)
        widget.onImagePicked(_image);
  }
}
