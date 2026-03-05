import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../../core/enums/user_role.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in with Email and Password
  Future<UserModel?> loginWithEmailPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password,
      );
      
      User? user = credential.user;
      if (user != null) {
        // Fetch user document from Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
            return UserModel.fromMap(userDoc.data() as Map<String, dynamic>, userDoc.id);
        } else {
            throw Exception('User data not found in database.');
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password provided for that user.');
      }
      throw Exception('Login Failed: ${e.message}');
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  // Register Student
  Future<UserModel?> registerStudent(String name, String email, String password, String collegeId) async {
      try {
        // Check whitelist in Firestore
        // Path: whitelist/{section_id}/emails/{email_formatted}
        // Firebase document IDs cannot contain '.', so replace '.' with '_'
        String formattedEmail = email.replaceAll('.', '_');
        
        DocumentReference emailRef = _firestore
            .collection('whitelist')
            .doc(collegeId) // assuming collegeId == sectionId for registration
            .collection('emails')
            .doc(formattedEmail);
            
        DocumentSnapshot emailDoc = await emailRef.get();
        
        if (!emailDoc.exists) {
            throw Exception('Your email is not registered. Contact your college admin.');
        }
        
        Map<String, dynamic> emailData = emailDoc.data() as Map<String, dynamic>;
        
        if (emailData['is_registered'] == true) {
             throw Exception('Account already exists. Please login.');
        }
        
        // If email found and is_registered is false, create Firebase Auth account
        UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        User? user = credential.user;
        if (user != null) {
            // Create UserModel
            UserModel newUser = UserModel(
               uid: user.uid,
               name: name,
               email: email,
               role: UserRole.student,
               collegeTrust: emailData['college'],
               sectionId: emailData['section_id'] ?? collegeId,
               joinedSections: [emailData['section_id'] ?? collegeId],
               defaultChannels: [],
               joinedChannels: [],
            );
            
            // Create Firestore users document
            await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
            
            // Update whitelist is_registered to true
            await emailRef.update({'is_registered': true});
            
            return newUser;
        }
        return null;
        
      } on FirebaseAuthException catch (e) {
         if (e.code == 'weak-password') {
            throw Exception('The password provided is too weak.');
         } else if (e.code == 'email-already-in-use') {
             throw Exception('The account already exists for that email.');
         }
         throw Exception('Registration Failed: ${e.message}');
      } catch (e) {
          throw Exception(e.toString().replaceAll('Exception: ', ''));
      }
  }

  // Check current user status
  User? getCurrentUser() {
    return _auth.currentUser;
  }
  
  // Get current UserModel from Firestore
  Future<UserModel?> getCurrentUserModel() async {
      User? user = _auth.currentUser;
      if (user != null) {
          try {
            DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
            if (doc.exists) {
                return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            }
          } catch (e) {
             print("Error fetching user model: $e");
          }
      }
      return null;
  }

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
