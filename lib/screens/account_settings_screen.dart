import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'login_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  _AccountSettingsScreenState createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _showPasswordFields = false;
  ParseUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = await ParseUser.currentUser() as ParseUser?;
      if (user != null) {
        setState(() {
          _currentUser = user;
          _usernameController.text = user.username ?? '';
          _emailController.text = user.get<String>('email') ?? '';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateAccount() async {
    if (_currentUser == null) return;

    final username = _usernameController.text.trim().toLowerCase();
    final email = _emailController.text.trim().toLowerCase();

    if (username.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username and email cannot be empty')),
      );
      return;
    }

    if (username.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username must be at least 3 characters')),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final oldUsername = _currentUser!.username!;
      final shouldUpdateUsername = username != oldUsername;

      // Check if username is already taken
      if (shouldUpdateUsername) {
        final usernameQuery = QueryBuilder<ParseUser>(ParseUser.forQuery())
          ..whereEqualTo('username', username);
        final usernameResponse = await usernameQuery.query();
        
        if (usernameResponse.success && usernameResponse.results != null && usernameResponse.results!.isNotEmpty) {
          throw Exception('Username already taken');
        }
      }

      // Check if email is already used
      if (email != _currentUser!.get<String>('email')) {
        final emailQuery = QueryBuilder<ParseUser>(ParseUser.forQuery())
          ..whereEqualTo('email', email);
        final emailResponse = await emailQuery.query();
        
        if (emailResponse.success && emailResponse.results != null && emailResponse.results!.isNotEmpty) {
          throw Exception('Email already in use');
        }
      }

      // Update all associated Persons records if username changed
      if (shouldUpdateUsername) {
        final personsQuery = QueryBuilder<ParseObject>(ParseObject('Persons'))
          ..whereEqualTo('userName', oldUsername);
        
        final personsResponse = await personsQuery.query();
        
        if (personsResponse.success && personsResponse.results != null) {
          for (final person in personsResponse.results as List<ParseObject>) {
            person.set('userName', username);
            await person.save();
          }
        }
      }

      // Update the user account
      _currentUser!
        ..username = username
        ..set('email', email);

      final response = await _currentUser!.save();

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account updated successfully')),
        );
      } else {
        throw Exception(response.error?.message ?? 'Failed to update account');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updatePassword() async {
    if (_currentUser == null) return;

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all password fields')),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Verify current password first
      final loginResponse = await ParseUser(_currentUser!.username!, currentPassword, null).login();

      if (!loginResponse.success) {
        throw Exception('Current password is incorrect');
      }

      // Update password
      _currentUser!.set('password', newPassword);
      final response = await _currentUser!.save();

      if (response.success) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        setState(() {
          _showPasswordFields = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
      } else {
        throw Exception(response.error?.message ?? 'Failed to update password');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAccount() async {
    if (_currentUser == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (!shouldDelete) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Delete all associated persons
      bool hasMore = true;
      int limit = 100; // Process in chunks of 100 to avoid timeout
      
      while (hasMore) {
        final personsQuery = QueryBuilder<ParseObject>(ParseObject('Persons'))
          ..whereEqualTo('userName', _currentUser!.username)
          ..setLimit(limit);
        
        final personsResponse = await personsQuery.query();
        
        if (personsResponse.success && personsResponse.results != null) {
          final persons = personsResponse.results as List<ParseObject>;
          
          for (final person in persons) {
            await person.delete();
          }
          
          // Check if we've processed all records
          hasMore = persons.length == limit;
        } else {
          hasMore = false;
        }
      }

      // Delete user account
      final response = await _currentUser!.delete();

      if (response.success) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account and all associated data deleted successfully')),
        );
      } else {
        throw Exception(response.error?.message ?? 'Failed to delete account');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? const Center(child: Text('No user data available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _currentUser!.username ?? 'No username',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        _currentUser!.get<String>('email') ?? 'No email',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _updateAccount,
                        child: const Text('Update Account'),
                      ),
                      const SizedBox(height: 30),
                      if (!_showPasswordFields)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showPasswordFields = true;
                            });
                          },
                          child: const Text('Change Password'),
                        ),
                      if (_showPasswordFields) ...[
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Current Password',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'New Password (min 6 chars)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirm New Password',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _updatePassword,
                                child: const Text('Update Password'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showPasswordFields = false;
                                  _currentPasswordController.clear();
                                  _newPasswordController.clear();
                                  _confirmPasswordController.clear();
                                });
                              },
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 40),
                      OutlinedButton(
                        onPressed: _deleteAccount,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Delete Account'),
                      ),
                    ],
                  ),
                ),
    );
  }
}