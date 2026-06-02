// import 'package:admin/controllers/menu_app_controller.dart';
// import 'package:admin/responsive.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';


// class Header extends StatelessWidget {
//   const Header({
//     Key? key,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         if (!Responsive.isDesktop(context))
//           IconButton(
//             icon: Icon(Icons.menu),
//             onPressed: context.read<MenuAppController>().controlMenu,
//           ),
//         if (!Responsive.isMobile(context))
//           Text(
//             "Dashboard",
//             style: Theme.of(context).textTheme.titleLarge,
//           ),
//         if (!Responsive.isMobile(context))
//           Spacer(flex: Responsive.isDesktop(context) ? 2 : 1),
//         // Expanded(child: SearchField()),
//       ],
//     );
//   }
// }

// // class SearchField extends StatelessWidget {
// //   const SearchField({
// //     Key? key,
// //   }) : super(key: key);

// //   @override
// //   Widget build(BuildContext context) {
// //     return TextField(
// //       decoration: InputDecoration(
// //         hintText: "Search",
// //         fillColor: secondaryColor,
// //         filled: true,
// //         border: OutlineInputBorder(
// //           borderSide: BorderSide.none,
// //           borderRadius: const BorderRadius.all(Radius.circular(10)),
// //         ),
// //         suffixIcon: InkWell(
// //           onTap: () {},
// //           child: Container(
// //             padding: EdgeInsets.all(defaultPadding * 0.75),
// //             margin: EdgeInsets.symmetric(horizontal: defaultPadding / 2),
// //             decoration: BoxDecoration(
// //               color: primaryColor,
// //               borderRadius: const BorderRadius.all(Radius.circular(10)),
// //             ),
// //             child: SvgPicture.asset("assets/icons/Search.svg"),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
