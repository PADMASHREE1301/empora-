class UserModel {
  final String? id;
  final String name;
  final String email;
  final String? phone;
  final String? company;
  final String? avatar;
  final String? token;
  final String role;
  final String membershipStatus;
  final String? membershipPlan;
  final DateTime? membershipEndDate;
  final bool isMember;
  final bool isAdmin;
  final bool founderProfileComplete; // ← NEW

  UserModel({
    this.id,
    required this.name,
    required this.email,
    this.phone,
    this.company,
    this.avatar,
    this.token,
    this.role = 'free',
    this.membershipStatus = 'inactive',
    this.membershipPlan,
    this.membershipEndDate,
    this.isMember = false,
    this.isAdmin = false,
    this.founderProfileComplete = false, // ← NEW
  });

  bool get isFree => role == 'free';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // founderProfile.isComplete comes nested from backend /api/auth/me
    final fp = json['founderProfile'];
    final fpComplete = fp is Map ? (fp['isComplete'] == true) : false;

    return UserModel(
      id:               json['_id']  as String? ?? json['id'] as String?,
      name:             json['name']  as String? ?? '',
      email:            json['email'] as String? ?? '',
      phone:            json['phone'] as String?,
      company:          json['company'] as String?,
      avatar:           json['avatar'] as String?,
      token:            json['token'] as String?,
      role:             json['role']             as String? ?? 'free',
      membershipStatus: json['membershipStatus'] as String? ?? 'inactive',
      membershipPlan:   json['membershipPlan']   as String?,
      membershipEndDate: json['membershipEndDate'] != null
          ? DateTime.tryParse(json['membershipEndDate'].toString())
          : null,
      isMember:               json['isMember'] as bool? ?? false,
      isAdmin:                json['isAdmin']  as bool? ?? false,
      founderProfileComplete: fpComplete,        // ← NEW
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id':                    id,
      'name':                   name,
      'email':                  email,
      'phone':                  phone,
      'company':                company,
      'avatar':                 avatar,
      'token':                  token,
      'role':                   role,
      'membershipStatus':       membershipStatus,
      'membershipPlan':         membershipPlan,
      'isMember':               isMember,
      'isAdmin':                isAdmin,
      'founderProfileComplete': founderProfileComplete,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? company,
    String? avatar,
    String? token,
    String? role,
    String? membershipStatus,
    String? membershipPlan,
    DateTime? membershipEndDate,
    bool? isMember,
    bool? isAdmin,
    bool? founderProfileComplete, // ← NEW
  }) {
    return UserModel(
      id:                     id      ?? this.id,
      name:                   name    ?? this.name,
      email:                  email   ?? this.email,
      phone:                  phone   ?? this.phone,
      company:                company ?? this.company,
      avatar:                 avatar  ?? this.avatar,
      token:                  token   ?? this.token,
      role:                   role              ?? this.role,
      membershipStatus:       membershipStatus  ?? this.membershipStatus,
      membershipPlan:         membershipPlan    ?? this.membershipPlan,
      membershipEndDate:      membershipEndDate ?? this.membershipEndDate,
      isMember:               isMember          ?? this.isMember,
      isAdmin:                isAdmin           ?? this.isAdmin,
      founderProfileComplete: founderProfileComplete ?? this.founderProfileComplete,
    );
  }
}