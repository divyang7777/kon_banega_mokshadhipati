class LeaderList {
  List<Leaders> leaders;
  int userRank;

  LeaderList({this.leaders, this.userRank});

  LeaderList.fromJson(Map<String, dynamic> json) {
    if (json['leaders'] != null) {
      leaders = new List<Leaders>();
      json['leaders'].forEach((v) {
        leaders.add(new Leaders.fromJson(v));
      });
    }
    userRank = json['userRank'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.leaders != null) {
      data['leaders'] = this.leaders.map((v) => v.toJson()).toList();
    }
    data['userRank'] = this.userRank;
    return data;
  }
}

class Leaders {
  int lives;
  bool isactive;
  String mobile;
  String name;
  String email;
  int mhtId;
  String center;
  int bonus;
  int questionId;
  int totalscore;
  String updatedAt;
  String createdAt;
  String img;
  Leaders(
      {this.lives,
      this.isactive,
      this.mobile,
      this.name,
      this.email,
      this.mhtId,
      this.center,
      this.bonus,
      this.questionId,
      this.totalscore,
      this.updatedAt,
      this.createdAt,
      this.img});

  Leaders.fromJson(Map<String, dynamic> json) {
    lives = json['lives'];
    isactive = json['isactive'];
    mobile = json['mobile'];
    name = json['name'];
    email = json['email'];
    mhtId = json['mht_id'];
    center = json['center'];
    bonus = json['bonus'];
    questionId = json['question_id'];
    totalscore = json['totalscore'];
    updatedAt = json['updatedAt'];
    createdAt = json['createdAt'];
    //img = json['img'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lives'] = this.lives;
    data['isactive'] = this.isactive;
    data['mobile'] = this.mobile;
    data['name'] = this.name;
    data['email'] = this.email;
    data['mht_id'] = this.mhtId;
    data['center'] = this.center;
    data['bonus'] = this.bonus;
    data['question_id'] = this.questionId;
    data['totalscore'] = this.totalscore;
    data['updatedAt'] = this.updatedAt;
    data['createdAt'] = this.createdAt;
    data['img'] = this.img;
    return data;
  }
}