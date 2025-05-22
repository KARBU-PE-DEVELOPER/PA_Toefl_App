import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:toefl/exceptions/exceptions.dart';
import 'package:toefl/models/auth_status.dart';
import 'package:toefl/models/login.dart';
import 'package:toefl/remote/api/user_api.dart';
import 'package:toefl/routes/route_key.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toefl/widgets/form_input.dart';
import 'package:flutter/widgets.dart';
import 'package:toefl/widgets/white_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  late final FocusNode _emailFocusNode;
  late final FocusNode _passwordFocusNode;
  final userApi = UserApi();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }
  

  Future<void> handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final AuthStatus val = await userApi.postLogin(
        Login(
          email: emailController.text,
          password: passwordController.text,
        ),
      );

      if (val.isSuccess) {
        if (val.isVerified) {
          Navigator.popAndPushNamed(context, RouteKey.main);
        } else {
          Navigator.pushNamed(context, RouteKey.otpVerification, arguments: {
            'isForgotOTP': false,
            'email': emailController.text,
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Wrong email or password"),
            backgroundColor: HexColor(colorError),
          ),
        );
      }
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: HexColor(colorError),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("An unexpected error occurred"),
          backgroundColor: HexColor(colorError),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HexColor(mariner700),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                color: HexColor(neutral20),
                shadowColor: Colors.black,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(60),
                    bottomRight: Radius.circular(60),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height *
                      0.4, // 40% tinggi layar
                  child: Image.asset(
                    'assets/images/login_page.png',
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'welcome_heading',
                      style: GoogleFonts.balooBhaijaan2(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: HexColor(neutral10),
                      ),
                    ).tr(),
                    Text(
                      'welcome_paragraph',
                      style: GoogleFonts.balooBhaijaan2(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: HexColor(neutral10),
                      ),
                    ).tr(),
                    const SizedBox(height: 15),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InputText(
                            controller: emailController,
                            title: "Email",
                            hintText: "Email",
                            suffixIcon: null,
                            focusNode: _emailFocusNode,
                          ),
                          const SizedBox(height: 15.0),
                          InputText(
                            controller: passwordController,
                            title: "Password",
                            hintText: "Password",
                            
                            suffixIcon: Icons.visibility_off,
                            focusNode: _passwordFocusNode,
                          ),
                          const SizedBox(height: 6.0),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                    context, RouteKey.forgotPassword,
                                    arguments: emailController.text);
                              },
                              child: Text(
                                'forgot_password',
                                style: GoogleFonts.balooBhaijaan2(
                                  color: HexColor(neutral10),
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                ),
                              ).tr(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 25),
                    WhiteButton(
                      title: 'btn_login'.tr(),
                      size: MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.height * 0.06,
                      onTap: handleLogin,
                      child: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      HexColor(mariner700)),
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 15.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'new_account',
                          style: GoogleFonts.balooBhaijaan2(
                            color: HexColor(neutral10),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ).tr(),
                        GestureDetector(
                          onTap: () {
                            Navigator.popAndPushNamed(context, RouteKey.regist);
                          },
                          child: Text(
                            'register_link',
                            style: GoogleFonts.balooBhaijaan2(
                              color: HexColor(neutral20),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                              decorationThickness: 2.0,
                            ),
                          ).tr(),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
