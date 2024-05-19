import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_crud_app/screens/admin/admin_screen.dart';
import 'package:flutter_firebase_crud_app/screens/home_screen/home_screen.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  AuthModel? currentUser;

  Future<void> login(String username, String password) async {
    CollectionReference authRef =
        FirebaseFirestore.instance.collection('auths');
    QuerySnapshot querySnapshot = await authRef
        .where('username', isEqualTo: username)
        .where('password', isEqualTo: password)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      AuthModel loggedInUser =
          AuthModel.fromFirestore(querySnapshot.docs.first);
      currentUser = loggedInUser;
    } else {
      currentUser = null;
    }
  }

  Future<void> register(String username, String password) async {
    CollectionReference authRef =
        FirebaseFirestore.instance.collection('auths');
    DocumentReference docRef = authRef.doc();
    QuerySnapshot querySnapshot =
        await authRef.where('username', isEqualTo: username).get();
    if (querySnapshot.docs.isEmpty) {
      AuthModel authModel = AuthModel(
        id: docRef.id,
        username: username,
        password: password,
        timestamp: Timestamp.now(),
      );
      await docRef.set(authModel.toJson());
    }
  }
}

class AuthModel {
  var username = "";
  var password = "";
  var repassword = "";
  var role = "USER";
  var id = "";
  var timestamp = Timestamp.now();

  AuthModel(
      {this.id = "",
      this.username = "",
      this.password = "",
      this.repassword = "",
      this.role = "USER",
      required this.timestamp});

  Map<String, dynamic> toJson() {
    return {
      "username": username,
      "password": password,
      "id": id,
      "role": role,
      "timestamp": timestamp
    };
  }

  factory AuthModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AuthModel(
      id: doc.id,
      username: data['username'] ?? '',
      role: data['role'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
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

var userLogin = AuthModel(timestamp: Timestamp.now());

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  var isRegister = false;
  var isLoading = false;
  late AuthModel authModel;
  var timestamp = Timestamp.now();
  String? errorPassword;
  String? errorUserName;

  @override
  void initState() {
    super.initState();
    authModel = AuthModel(timestamp: timestamp);
  }

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

  Widget _renderContent(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Image.asset(
            'assets/login.png',
            fit: BoxFit.cover,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(25),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                        hintText: "Tên người dùng",
                        labelText: "Tên người dùng",
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
                      hintText: "Mật khẩu",
                      labelText: "Mật khẩu",
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
                            hintText: "Đặt lại mật khẩu",
                            labelText: "Đặt lại mật khẩu",
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
                      child: Text(isRegister ? "Đăng kí" : "Đăng nhập"),
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
                      child: Text(isRegister ? "Đăng nhập" : "Đăng kí"))
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void validateForm(BuildContext context) {
    var isValidated = true;
    if (isRegister && authModel.password != authModel.repassword) {
      isValidated = false;
      setState(() {
        errorPassword = "Mật khẩu không khớp";
      });
    } else {
      setState(() {
        errorPassword = null;
      });
    }

    if (isValidated) {
      loading(true);
      if (isRegister) {
        AuthService()
            .register(authModel.username, authModel.password)
            .then((_) {
          loginUser(context);
        }).catchError((error) {
          // Handle error
          loading(false);
        });
      } else {
        loginUser(context);
      }
    }
  }

  Future<void> loginUser(BuildContext context) async {
    AuthService().login(authModel.username, authModel.password).then((_) {
      if (AuthService().currentUser != null) {
        AuthModel loggedInUser = AuthService().currentUser!;
        if (loggedInUser.role == "admin") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminScreen()),
          );
        } else {
          userLogin = loggedInUser;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      } else {
        final scaffold = ScaffoldMessenger.of(context);
        scaffold.showSnackBar(
          SnackBar(
            content: Text('Tên người dùng hoặc mật khẩu không chính xác.'),
          ),
        );
        loading(false);
      }
    }).catchError((error) {
      // Handle error
      loading(false);
    });
  }

  showSnapBar(BuildContext context, String msg) {
    final snackBar = SnackBar(
      content: Text(msg),
      action: SnackBarAction(
        label: 'Hoàn tác',
        onPressed: () {},
      ),
    );
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
