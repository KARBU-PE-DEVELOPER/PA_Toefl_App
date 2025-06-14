import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:toefl/models/profile.dart';
import 'package:toefl/remote/api/profile_api.dart';
import 'package:toefl/remote/local/shared_pref/onboarding_shared_preferences.dart';
import 'package:toefl/routes/route_key.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:flutter/services.dart'; // tambahkan import ini
import 'package:toefl/widgets/blue_button.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

import '../../remote/api/user_api.dart';

class OtpVerification extends StatefulWidget {
  const OtpVerification(
      {super.key, this.isForgotOTP = false, required this.email});

  final bool isForgotOTP;
  final String email;

  @override
  State<OtpVerification> createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> {
  UserApi userApi = UserApi();
  late List<TextEditingController?> controls;
  var otp = "";
  var isLoading = false;
  var resendTimer = 59;
  Timer? _resendCountdown;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  changeTime() {
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        resendTimer--;
      });
      if (resendTimer > 0) {
        changeTime();
      }
    });
  }

  void _startResendTimer() {
    _resendCountdown = Timer.periodic(Duration(seconds: 1), (timer) {
      if (resendTimer == 0) {
        timer.cancel();
      } else {
        setState(() {
          resendTimer--;
        });
      }
    });
  }

  List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    _resendCountdown?.cancel();
    super.dispose();
  }

  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(4, (index) {
        return SizedBox(
          width: 60,
          child: KeyboardListener(
            focusNode: FocusNode(), // listener khusus keyboard
            onKeyEvent: (event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace &&
                  _controllers[index].text.isEmpty) {
                setState(() {
                  for (var c in _controllers) {
                    c.clear();
                  }
                  otp = "";
                });
                FocusScope.of(context).requestFocus(_focusNodes[0]);
              }
            },

            child: TextFormField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: GoogleFonts.balooBhaijaan2(
                  fontSize: 20, fontWeight: FontWeight.bold),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                counterText: "",
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: HexColor(mariner700)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: HexColor(mariner700), width: 2),
                ),
              ),

              onChanged: (value) {
                if (value.length > 1) {
                  // Kalau user paste atau ketik 2 angka sekaligus
                  List<String> chars = value.split('');
                  _controllers[index].text = chars[0];
                  if (index + 1 < 4) {
                    _controllers[index + 1].text = chars[1];
                    FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                  } else {
                    FocusScope.of(context).unfocus();
                  }
                } else if (value.length == 1) {
                  if (index < 3) {
                    FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                  } else {
                    FocusScope.of(context).unfocus();
                  }
                }

                setState(() {
                  otp = _controllers.map((c) => c.text).join();
                });
              },

              onTap: () {
                _controllers[index].selection = TextSelection.fromPosition(
                  TextPosition(offset: _controllers[index].text.length),
                );
              },
              // onEditingComplete: () {
              //   FocusScope.of(context).unfocus();
              //   _controllers[index].selection = TextSelection.fromPosition(
              //     TextPosition(offset: _controllers[index].text.length),
              //   );
              // },
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: InkWell(
          borderRadius: BorderRadius.circular(40),
          child: const Icon(
            Icons.chevron_left_rounded,
            size: 30,
          ),
          onTap: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              // Added Expanded here
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      "OTP Verification",
                      style: GoogleFonts.balooBhaijaan2(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.balooBhaijaan2(
                            fontSize: 14,
                            color: HexColor(neutral70),
                          ),
                          children: [
                            const TextSpan(
                              text:
                                  "Please enter the 4-digit code sent to your email ",
                            ),
                            TextSpan(
                              text: " ${widget.email} ",
                              style: GoogleFonts.balooBhaijaan2(
                                  fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(
                              text: " for verification.",
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 60,
                    ),
                    // OtpTextField(
                    //   cursorColor: HexColor(neutral90),
                    //   numberOfFields: 4,
                    //   contentPadding: const EdgeInsets.symmetric(vertical: 30),
                    //   margin: const EdgeInsets.symmetric(horizontal: 10),
                    //   textStyle: const TextStyle(
                    //       fontWeight: FontWeight.w500, fontSize: 20),
                    //   fieldWidth: 65.0,
                    //   showFieldAsBox: true,
                    //   keyboardType: const TextInputType.numberWithOptions(
                    //       decimal: false, signed: false),
                    //   borderRadius: BorderRadius.circular(10),
                    //   borderColor: HexColor(mariner700),
                    //   focusedBorderColor: HexColor(mariner700),
                    //   inputFormatters: [
                    //     FilteringTextInputFormatter.digitsOnly,
                    //     LengthLimitingTextInputFormatter(1)
                    //   ],
                    //   // handleControllers: (controllers) {
                    //   //   controls = controllers;
                    //   //   for (var ctrl in controls) {
                    //   //     ctrl?.addListener(() {
                    //   //       final text = ctrl?.text ?? '';
                    //   //       final filtered =
                    //   //           text.replaceAll(RegExp(r'[^0-9]'), '');

                    //   //       if (filtered.length > 1) {
                    //   //         ctrl?.text = filtered[0];
                    //   //         ctrl?.selection =
                    //   //             TextSelection.collapsed(offset: 1);
                    //   //       } else if (text != filtered) {
                    //   //         ctrl?.value = TextEditingValue(
                    //   //           text: filtered,
                    //   //           selection: TextSelection.collapsed(
                    //   //               offset: filtered.length),
                    //   //         );

                    //   //         ctrl?.selection = TextSelection.collapsed(
                    //   //             offset: filtered.length);
                    //   //       }
                    //   //     });
                    //   //   }
                    //   // },
                    //   onCodeChanged: (String value) {
                    //     setState(() {
                    //       otp = controls.map((c) => c?.text ?? '').join();
                    //     });
                    //   },
                    // ),
                    SizedBox(
                      height: 60,
                      child: _buildOtpFields(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            isLoading
                ? CircularProgressIndicator(
                    color: HexColor(mariner700),
                  )
                : BlueButton(
                    isDisabled: otp.length < 4,
                    title: "Verify",
                    onTap: () async {
                      if (otp.length < 4) return;
                      setState(() {
                        isLoading = true;
                      });
                      final isVerified = widget.isForgotOTP
                          ? await userApi.verifyForgot(otp)
                          : await userApi.verifyOtp(otp);

                      setState(() {
                        isLoading = false;
                      });

                      if (isVerified.isVerified) {
                        if (widget.isForgotOTP) {
                          Navigator.pushNamed(context, RouteKey.resetPassword,
                              arguments: false);
                        } else {
                          Profile user = await ProfileApi().getProfile();
                          Navigator.popUntil(context, (route) => route.isFirst);
                          Navigator.pushNamed(context, RouteKey.main);
                          if (user.targetScore == 0) {
                            Navigator.pushNamed(context, RouteKey.setGoal);
                          }
                        }
                      }
                    }),
            const SizedBox(height: 15.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn’t receive code? ",
                  style: GoogleFonts.balooBhaijaan2(
                    color: HexColor(neutral50),
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (resendTimer > 0) return;
                    if (widget.isForgotOTP) {
                      userApi.forgotPassword(widget.email);
                    } else {
                      userApi.getOtp();
                    }
                    setState(() {
                      resendTimer = 59;
                      changeTime();
                    });
                  },
                  child: Text(
                    resendTimer > 0 ? "Resend (00:$resendTimer)" : "Resend",
                    style: GoogleFonts.balooBhaijaan2(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
