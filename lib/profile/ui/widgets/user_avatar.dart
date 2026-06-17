// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:q_kics/providers/profile_provider.dart';

// class UserAvatar extends StatelessWidget {
//   final double radius;

//   const UserAvatar({super.key, required this.radius});

//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<ProfileProvider>();
//     final profile = provider.profile;

//     final imageUrl = profile?.profilePicture;
//     final version = provider.imageVersion;

//     final initial =
//         profile?.username.isNotEmpty == true
//             ? profile!.username[0].toUpperCase()
//             : 'U';

//     if (imageUrl == null || imageUrl.isEmpty) {
//       return CircleAvatar(
//         radius: radius,
//         backgroundColor:
//             Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
//         child: Text(
//           initial,
//           style: TextStyle(
//             fontSize: radius * 1.1,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       );
//     }

//     return CircleAvatar(
//       radius: radius,
//       child: ClipOval(
//         child: CachedNetworkImage(
//           imageUrl: '$imageUrl?v=$version', // ✅ SAFE CACHE BUST
//           width: radius * 2,
//           height: radius * 2,
//           fit: BoxFit.cover,
//         ),
//       ),
//     );
//   }
// }
