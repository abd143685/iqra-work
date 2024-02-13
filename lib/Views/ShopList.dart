import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:order_booking_shop/API/DatabaseOutputs.dart';
import 'package:order_booking_shop/Views/HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../API/Globals.dart';
import '../Databases/DBHelper.dart';
import '../Models/loginModel.dart';

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void initState() {
    super.initState();
    DatabaseOutputs outputs = DatabaseOutputs();
    outputs.initializeData();
  }

  final dblogin = DBHelper();

  _login() async {
    var response = await dblogin.login(
      Users(user_id: _emailController.text, password: _passwordController.text, user_name: ''),
    );

    if (response == true) {
      // Retrieve authentication token
      String authToken = await getAuthToken(_emailController.text, _passwordController.text);

      if (authToken.isNotEmpty) {
        // Store the token securely (consider using flutter_secure_storage)
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('authToken', authToken);

        var userName = await dblogin.getUserName(_emailController.text);
        var userCity = await dblogin.getUserCity(_emailController.text);

        if (userName != null && userCity != null) {
          print('User Name: $userName, City: $userCity');
        } else {
          print('Failed to fetch user name or city');
        }

        userNames = userName!;
        userCitys = userCity!;
        userId = _emailController.text;

        Fluttertoast.showToast(msg: "Successfully logged in", toastLength: Toast.LENGTH_LONG);

        Map<String, dynamic> dataToPass = {
          'userName': userNames,
        };

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => HomePage(),
            settings: RouteSettings(arguments: dataToPass),
          ),
        );
      } else {
        Fluttertoast.showToast(msg: "Failed to retrieve authentication token", toastLength: Toast.LENGTH_LONG);
      }
    } else {
      Fluttertoast.showToast(msg: "Failed login", toastLength: Toast.LENGTH_LONG);
    }
  }

  Future<String> getAuthToken(String username, String password) async {
    try {
      var response = await http.post(
        Uri.parse('https://apex.oracle.com/pls/apex/muhammad_usman/oauth/token'),
        body: {
          'yxeRFdCC0wjh1BYjXu1HFw..': username,
          'KG-oKSMmf4DhqtFNmVtpMw..': password,
        },
      );

      if (response.statusCode == 200) {
        var token = jsonDecode(response.body)['token'];
        return token;
      } else {
        throw Exception('Failed to get authentication token');
      }
    } catch (e) {
      throw Exception('Error getting authentication token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Center(
                      child: Image.asset(
                        'assets/images/p1.png',
                        width: 250.0,
                        height: 250.0,
                      ),
                    ),
                    SizedBox(height: 0.0),
                    Center(
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.brown,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        side: BorderSide(color: Colors.white, width: 1),
                      ),
                      child: Container(
                        width: 300,
                        child: TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'User ID',
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Container(
                              margin: EdgeInsets.all(1.0),
                              padding: EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Icon(
                                Icons.person,
                                color: Colors.black,
                              ),
                            ),
                            contentPadding: EdgeInsets.all(12.0),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.green, width: 0),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 0),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20.0),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        side: BorderSide(color: Colors.white, width: 1),
                      ),
                      child: Container(
                        width: 300,
                        child: TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Container(
                              margin: EdgeInsets.all(1.0),
                              padding: EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Icon(
                                Icons.lock,
                                color: Colors.black,
                              ),
                            ),
                            contentPadding: EdgeInsets.all(12.0),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 1),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 1),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20.0),
                    Container(
                      height: 40,
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          _login();
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black, backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Login',
                              style: TextStyle(fontSize: 18),
                            ),
                            Icon(Icons.arrow_forward),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 30.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              '',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Image.asset(
                              'assets/images/b1.png',
                              width: 23.0,
                              height: 23.0,
                            ),
                            Text(
                              'MetaXperts',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '03456699233',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 6,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ),
        );
    }
}