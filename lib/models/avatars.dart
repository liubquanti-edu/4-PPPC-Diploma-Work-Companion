import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CachedAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const CachedAvatar({
    Key? key,
    this.imageUrl,
    this.radius = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: const AssetImage('assets/img/noavatar.png'),
      );
    }

    return CircleAvatar(
      radius: radius,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) => const CircularProgressIndicator(),
          errorWidget: (context, url, error) => 
              Image.asset('assets/img/noavatar.png', fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String userId;
  final double radius;

  const UserAvatar({
    Key? key,
    required this.userId,
    this.radius = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CachedAvatar(radius: radius);
        final avatarUrl = (snapshot.data?.data() as Map<String, dynamic>?)?['avatar'] as String?;
        return CachedAvatar(
          imageUrl: avatarUrl,
          radius: radius,
        );
      },
    );
  }
}