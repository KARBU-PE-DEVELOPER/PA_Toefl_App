import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:toefl/models/auth_status.dart';
import 'package:toefl/models/regist.dart';
import 'package:toefl/routes/route_key.dart';
import 'package:toefl/exceptions/exceptions.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/widgets/form_input.dart';
import 'package:toefl/widgets/white_button.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../remote/api/user_api.dart';

class RegistPage extends StatefulWidget {
  const RegistPage({super.key});

  @override
  State<RegistPage> createState() => _RegistPageState();
}

class _RegistPageState extends State<RegistPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final userApi = UserApi();
  bool isLoading = false;

  Future<void> handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final AuthStatus val = await userApi.postRegist(
        Regist(
          name: nameController.text,
          email: emailController.text,
          password: passwordController.text,
          passwordConfirmation: confirmPasswordController.text,
        ),
      );

      if (val.isSuccess) {
        Navigator.pushNamed(
          context,
          RouteKey.otpVerification,
          arguments: {
            'isForgotOTP': false,
            'email': emailController.text,
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Email has already been registered"),
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
                      0.25, // 40% tinggi layar
                  child: Image.asset(
                    'assets/images/smile_robot.png',
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'create_account',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: HexColor(neutral10),
                      ),
                    ).tr(),
                    Text(
                      'create_account_paragraph',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: HexColor(neutral10),
                      ),
                    ).tr(),
                    const SizedBox(height: 15.0),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InputText(
                            controller: nameController,
                            title: 'label_name'.tr(),
                            hintText: "Name",
                          ),
                          const SizedBox(height: 10.0),
                          InputText(
                            controller: emailController,
                            title: "Email",
                            hintText: "Email",
                          ),
                          const SizedBox(height: 10.0),
                          InputText(
                            controller: passwordController,
                            title: "Password",
                            hintText: "Password",
                            suffixIcon: Icons.visibility_off,
                          ),
                          const SizedBox(height: 10.0),
                          InputText(
                            controller: confirmPasswordController,
                            title: 'confirm_password'.tr(),
                            hintText: "Confirm Password",
                            suffixIcon: Icons.visibility_off,
                            passwordController: passwordController,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    WhiteButton(
                      title: 'btn_register'.tr(),
                      size: MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.width * 0.125,
                      onTap: handleRegister,
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
                          'have_account'.tr(),
                          style: GoogleFonts.balooBhaijaan2(
                            color: HexColor(neutral10),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.popAndPushNamed(context, RouteKey.login);
                          },
                          child: Text(
                            'login_link',
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
