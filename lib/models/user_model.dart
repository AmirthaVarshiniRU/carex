class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? phoneNumber;
  final bool emailVerified;
  final List<String> authProviders;
  final Map<String, dynamic>? additionalData;
  final Map<String, bool>? connectedAccounts;
  final Map<String, bool>? privacySettings;
  final String? role;
  final String? currentMood;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.phoneNumber,
    this.emailVerified = false,
    this.authProviders = const [],
    this.additionalData,
    this.connectedAccounts,
    this.privacySettings,
    this.role,
    this.currentMood,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      email: json['email'],
      displayName: json['displayName'],
      photoURL: json['photoURL'],
      phoneNumber: json['phoneNumber'],
      emailVerified: json['emailVerified'] ?? false,
      authProviders: List<String>.from(json['authProviders'] ?? []),
      additionalData: json['additionalData'],
      connectedAccounts: json['connectedAccounts'] != null 
          ? Map<String, bool>.from(json['connectedAccounts']) 
          : null,
      privacySettings: json['privacySettings'] != null 
          ? Map<String, bool>.from(json['privacySettings']) 
          : null,
      role: json['role'],
      currentMood: json['currentMood'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'emailVerified': emailVerified,
      'authProviders': authProviders,
      'additionalData': additionalData,
      'connectedAccounts': connectedAccounts,
      'privacySettings': privacySettings,
      'role': role,
      'currentMood': currentMood,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    bool? emailVerified,
    Map<String, dynamic>? additionalData,
    Map<String, bool>? connectedAccounts,
    Map<String, bool>? privacySettings,
    String? role,
    String? currentMood,
  }) {
    return UserModel(
      uid: this.uid,
      email: this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emailVerified: emailVerified ?? this.emailVerified,
      authProviders: this.authProviders,
      additionalData: additionalData ?? this.additionalData,
      connectedAccounts: connectedAccounts ?? this.connectedAccounts,
      privacySettings: privacySettings ?? this.privacySettings,
      role: role ?? this.role,
      currentMood: currentMood ?? this.currentMood,
    );
  }
}
