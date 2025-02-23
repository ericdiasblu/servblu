import 'package:flutter/material.dart';
import 'package:servblu/screens/login_signup/enter_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // supabase setup
  await Supabase.initialize(
      url: "https://lrwbtpghgmshdtqotsyj.supabase.co",
      anonKey:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxyd2J0cGdoZ21zaGR0cW90c3lqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk5NTk1OTIsImV4cCI6MjA1NTUzNTU5Mn0.Z53Q-wnvj2ABiASl_FH0tddCdN7dVFqWCeYALruqsC8");
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: EnterScreen(),
  ));
}
