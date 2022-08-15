import 'package:dartz/dartz.dart';
import 'package:elaichi/data/local/local_storage_service.dart';
import 'package:elaichi/data/remote/api_service.dart';
import 'package:elaichi/domain/exceptions/auth_failure.dart';
import 'package:elaichi/domain/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Repository which manages user authentication.
class UserRepository {
  /// Constructor for authentication repository
  UserRepository({
    required LocalStorageService localStorageService,
    required APIService apiService,
  })  : _apiService = apiService,
        _localStorageService = localStorageService,
        _firebaseAuth = FirebaseAuth.instance,
        _googleSignIn = GoogleSignIn.standard() {
    getRollNumber();
  }

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final LocalStorageService _localStorageService;
  final APIService _apiService;

  String? rollNumber;

  String? zsToken;

  /// Returns the signed in user if any
  Future<Option<User?>> getSignedInUser() async =>
      optionOf<User?>(_firebaseAuth.currentUser);

  /// Handles the sign in process with [FirebaseAuth] and [GoogleSignIn].
  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();

      final googleAuthentication = await googleUser!.authentication;

      final authCrendential = GoogleAuthProvider.credential(
        accessToken: googleAuthentication.accessToken,
        idToken: googleAuthentication.idToken,
      );
      await _firebaseAuth.signInWithCredential(authCrendential);
      Splash.instance().user = _firebaseAuth.currentUser;
    } on FirebaseException catch (e) {
      throw LogInWithGoogleFailure.fromCode(e.code);
    } catch (_) {
      throw const LogInWithGoogleFailure();
    }
  }

  Future<void> saveWebMailDetails({
    required String rollNumber,
    required String password,
  }) async {
    _localStorageService.saveWebMailDetails(
      rollNumber: rollNumber,
      password: password,
    );
  }

  Future<void> logInToWebMail() async {
    final rollNumber = _localStorageService.rollNumber;
    final password = _localStorageService.password;

    if (rollNumber != null && password != null) {
      zsToken = await _apiService.logInToWebMail(
        rollNumber: rollNumber,
        password: password,
      );
      getRollNumber();
    }
  }

  void getRollNumber() {
    rollNumber = _localStorageService.rollNumber;
  }

  /// Logs out the user from the account.
  Future<void> logOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (error) {
      rethrow;
    }
  }
}