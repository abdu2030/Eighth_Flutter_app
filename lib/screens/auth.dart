import 'dart:io';
import 'package:chat_app/core/service/storage_service.dart';
import 'package:chat_app/widget/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

final _firebase = FirebaseAuth.instance;
final _firestore = FirebaseFirestore.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  var _isLoggin = true;
  var _enterdEmail = '';
  var _enteredPassword = '';
  var _enteredUsername = '';
  File? _selectedImage;
  bool _isLoading = false;

  final _form = GlobalKey<FormState>();

  void _submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid || !_isLoggin && _selectedImage == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!_isLoggin && _selectedImage == null
              ? 'Please select a profile image'
              : 'Please fill all fields correctly'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _form.currentState!.save();

    try {
      setState(() => _isLoading = true);

      if (_isLoggin) {
        // LOGIN
        await _firebase.signInWithEmailAndPassword(
          email: _enterdEmail,
          password: _enteredPassword,
        );
      } else {
        // SIGN UP
        // Step 1: Create user account
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
          email: _enterdEmail,
          password: _enteredPassword,
        );

        // Step 2: Upload image to Cloudinary
        String? imageUrl;
        if (_selectedImage != null) {
          print('📤 Uploading image to Cloudinary...');
          imageUrl = await StorageService.uploadFile(_selectedImage!.path);

          if (imageUrl == null) {
            if (!mounted) return;
            throw Exception('Failed to upload image');
          }
          print('✅ Image uploaded: $imageUrl');
        }

        // Step 3: Save user data to Firestore
        await _firestore
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({
          'uid': userCredentials.user!.uid,
          'email': _enterdEmail,
          'username': _enteredUsername,
          'image_url': imageUrl ?? '', // Save Cloudinary URL
          'created_at': FieldValue.serverTimestamp(),
        });

        print('✅ User data saved to Firestore');
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'Authentication failed',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                width: 200,
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                margin: EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Image Picker (only for signup)
                          if (!_isLoggin)
                            UserImagePicker(
                              onPickImage: (pickedImage) {
                                _selectedImage = pickedImage;
                              },
                            ),

                          // Username field (only for signup)
                          if (!_isLoggin) ...[
                            TextFormField(
                              enableSuggestions: false,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.person),
                                
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a username';
                                }
                                if (value.trim().length < 3) {
                                  return 'Username must be at least 3 characters';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredUsername = value!;
                              },
                            ),
                            SizedBox(height: 12),
                          ],

                          // Email field
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains('@')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enterdEmail = value!;
                            },
                          ),
                          SizedBox(height: 12),

                          // Password field
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.trim().length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredPassword = value!;
                            },
                          ),
                          SizedBox(height: 12),

                          // Submit button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(_isLoggin ? "Login" : "Sign Up"),
                          ),

                          // Toggle login/signup
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _isLoggin = !_isLoggin;
                                      _selectedImage = null;
                                    });
                                  },
                            child: Text(
                              _isLoggin
                                  ? "Create an account"
                                  : "I already have an account.",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}