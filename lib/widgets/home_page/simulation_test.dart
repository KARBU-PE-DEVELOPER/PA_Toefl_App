import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toefl/routes/route_key.dart';
import 'package:toefl/widgets/home_page/try_card.dart';

class SimulationTestWidget extends StatelessWidget {
  SimulationTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      return Container(
          height: MediaQuery.of(context).size.height / 5,
          width: constraint.maxWidth / 1,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: null,
                  //   () => Navigator.of(context).pushNamed(
                  // RouteKey.simulationpage,
                  // arguments: {
                  //   "type": "test", // Mengirim tipe "test"
                  // },
                  // ),
                  child: Opacity(
                    opacity: 0.5, // Add opacity to show it's disabled
                    child: TryCard(
                      isBgLight: false,
                      title: "Under Develop",
                      icon: "assets/images/medali.svg",
                      subtitle: "A test that contains\n140 questions",
                      child: Positioned(
                          bottom: -(constraint.maxWidth / 4.5),
                          child: SvgPicture.asset(
                            fit: BoxFit.contain,
                            "assets/images/avatar_featured2.svg",
                            width: constraint.maxWidth / 2.8,
                          )),
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Navigator.of(context).pushNamed(
                    RouteKey.simulationpage,
                    arguments: {
                      "type": "simulation", // Mengirim tipe "test"
                    },
                  ),
                  child: TryCard(
                    title: "Simulation",
                    icon: "assets/images/pesawat.svg",
                    subtitle:
                        "Simulation of 140 questions with identical questions \nfor all users.",
                    child: Positioned(
                        bottom: -(constraint.maxWidth / 4.5),
                        right: -(constraint.maxWidth / 8),
                        child: SvgPicture.asset(
                          fit: BoxFit.cover,
                          "assets/images/avatar_featured1.svg",
                          width: constraint.maxWidth / 2.6,
                        )),
                  ),
                )
              ],
            ),
          ));
    });
  }
}
