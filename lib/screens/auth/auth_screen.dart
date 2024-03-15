import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_crud_app/screens/home_screen/home_screen.dart';

class AuthModel {
  var username = "";
  var password = "";
  var repassword = "";
  var role = "USER";
  var id = "";

  AuthModel(
      {this.id = "",
      this.username = "",
      this.password = "",
      this.repassword = "",
      this.role = "USER"});

  Map<String, dynamic> toJson(String id) {
    return {"username": username, "password": password, "id": id, "role": role};
  }

  factory AuthModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AuthModel(
      id: doc.id,
      username: data['username'] ?? '',
      role: data['role'] ?? '',
    );
  }

  getRoleIdFilter() {
    if (role == "USER") {
      return id;
    } else {
      return null;
    }
  }
}

var userLogin = AuthModel();

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  var isRegister = false;
  var isLoading = false;
  var authModel = AuthModel();
  String? errorPassword;
  String? errorUserName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Stack(
          children: [
            _renderContent(context),
            isLoading ? const ProgressIndicatorExample() : Container(),
          ],
        ),
      ),
    );
  }

  loading(bool value) {
    setState(() {
      isLoading = value;
    });
  }

  Column _renderContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                    hintText: "User Name",
                    labelText: "User Name",
                    errorText: errorUserName),
                onChanged: (value) {
                  authModel.username = value;
                },
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                decoration: InputDecoration(
                  hintText: "Password",
                  labelText: "Password",
                  errorText: errorPassword,
                ),
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                onChanged: (value) {
                  authModel.password = value;
                },
              ),
              isRegister
                  ? TextField(
                      decoration: InputDecoration(
                        hintText: "Re Password",
                        labelText: "Re Password",
                        errorText: errorPassword,
                      ),
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      onChanged: (value) {
                        authModel.repassword = value;
                      },
                    )
                  : Container(),
              isRegister
                  ? const SizedBox(
                      height: 10,
                    )
                  : Container(),
              const SizedBox(
                height: 50,
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.amber,
                ),
                child: TextButton(
                  onPressed: () {
                    validateForm(context);
                  },
                  child: Text(isRegister ? "Register" : "Login"),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              TextButton(
                  onPressed: () {
                    setState(() {
                      isRegister = !isRegister;
                    });
                  },
                  child: Text(isRegister ? "Login" : "Register"))
            ],
          ),
        ),
      ],
    );
  }

  void validateForm(BuildContext context) {
    var isValidated = true;
    // Todo validate
    if (isValidated) {
      loading(true);
      if (isRegister) {
        registerUser(context);
      } else {
        loginUser(context);
      }
    }
  }

  Future<void> loginUser(BuildContext context) async {
    CollectionReference authRef =
        FirebaseFirestore.instance.collection('auths');
    QuerySnapshot querySnapshot = await authRef
        .where('username', isEqualTo: authModel.username)
        .where('password', isEqualTo: authModel.password)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      print('Get User Success');
      userLogin = AuthModel.fromFirestore(querySnapshot.docs.first);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      print('User with the same name already exists.');
      showSnapBar(context, 'Username or password wrong.');
    }
    loading(false);
  }

  Future<void> registerUser(BuildContext context) async {
    CollectionReference authRef =
        FirebaseFirestore.instance.collection('auths');

    // Check if the user name already exists
    QuerySnapshot querySnapshot =
        await authRef.where('username', isEqualTo: authModel.username).get();
    if (querySnapshot.docs.isEmpty) {
      // Add a new document with the user name as the document ID
      // Add a new document with a generated ID
      DocumentReference docRef =
          authRef.doc(); // Firestore will generate a unique ID
      await docRef.set(authModel.toJson(docRef.id));
      print('User register successfully.');
      showSnapBar(context, 'User register successfully.');
      setState(() {
        isRegister = false;
      });
    } else {
      print('User with the same name already exists.');
      showSnapBar(context, 'User with the same name already exists.');
    }
    loading(false);
  }

  showSnapBar(BuildContext context, String msg) {
    final snackBar = SnackBar(
      content: Text(msg),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          // Some code to undo the change.
        },
      ),
    );

    // Find the ScaffoldMessenger in the widget tree
    // and use it to show a SnackBar.
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

class ProgressIndicatorExample extends StatefulWidget {
  const ProgressIndicatorExample({super.key});

  @override
  State<ProgressIndicatorExample> createState() =>
      _ProgressIndicatorExampleState();
}

class _ProgressIndicatorExampleState extends State<ProgressIndicatorExample>
    with TickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    controller = AnimationController(
      /// [AnimationController]s can be created with `vsync: this` because of
      /// [TickerProviderStateMixin].
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        setState(() {});
      });
    controller.repeat(reverse: true);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.1),
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(
            value: controller.value,
            semanticsLabel: 'loading progress',
          ),
        ],
      ),
    );
  }
}
