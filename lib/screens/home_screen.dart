import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'login_screen.dart';
import 'account_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ParseObject> _persons = [];
  bool _isLoading = false;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  ParseObject? _selectedPerson;
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _fetchPersons();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user != null) {
      setState(() {
        _currentUsername = user.username;
      });
    }
  }

  Future<void> _fetchPersons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await ParseUser.currentUser() as ParseUser?;
      if (user == null) return;

      final query = QueryBuilder<ParseObject>(ParseObject('Persons'))
        ..whereEqualTo('userName', user.username)
        ..orderByAscending('lastName');

      final ParseResponse response = await query.query();

      if (response.success && response.results != null) {
        setState(() {
          _persons = response.results as List<ParseObject>;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.error?.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
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

  Future<void> _addPerson() async {
    final firstName = _capitalizeName(_firstNameController.text.trim());
    final lastName = _capitalizeName(_lastNameController.text.trim());
    final age = int.tryParse(_ageController.text.trim());
    final user = await ParseUser.currentUser() as ParseUser?;

    if (firstName.isEmpty || lastName.isEmpty || age == null || age <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid details')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final person = ParseObject('Persons')
        ..set('firstName', firstName)
        ..set('lastName', lastName)
        ..set('age', age)
        ..set('userName', user?.username);
        
      final response = await person.save();

      if (response.success) {
        _firstNameController.clear();
        _lastNameController.clear();
        _ageController.clear();
        await _fetchPersons();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Person added successfully')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.error?.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
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

  Future<void> _updatePerson() async {
    if (_selectedPerson == null) return;

    final firstName = _capitalizeName(_firstNameController.text.trim());
    final lastName = _capitalizeName(_lastNameController.text.trim());
    final age = int.tryParse(_ageController.text.trim());

    if (firstName.isEmpty || lastName.isEmpty || age == null || age <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid details')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _selectedPerson!
        ..set('firstName', firstName)
        ..set('lastName', lastName)
        ..set('age', age);
      final response = await _selectedPerson!.save();

      if (response.success) {
        _firstNameController.clear();
        _lastNameController.clear();
        _ageController.clear();
        setState(() {
          _selectedPerson = null;
        });
        await _fetchPersons();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Person updated successfully')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.error?.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
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

  Future<void> _deletePerson(String objectId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final person = ParseObject('Persons')..objectId = objectId;
      final response = await person.delete();

      if (response.success) {
        await _fetchPersons();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Person deleted successfully')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.error?.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
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

  void _showDeleteConfirmation(ParseObject person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this person?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deletePerson(person.objectId!);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog({ParseObject? person}) {
    if (person != null) {
      _selectedPerson = person;
      _firstNameController.text = person.get<String>('firstName') ?? '';
      _lastNameController.text = person.get<String>('lastName') ?? '';
      _ageController.text = person.get<int>('age')?.toString() ?? '';
    }

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(person == null ? 'Add Person' : 'Edit Person'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter first name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter last name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter age';
                      }
                      final age = int.tryParse(value);
                      if (age == null) {
                        return 'Please enter a valid number';
                      }
                      if (age <= 0) {
                        return 'Age must be positive';
                      }
                      if (age > 120) {
                        return 'Please enter a realistic age';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (person != null) {
                  _firstNameController.clear();
                  _lastNameController.clear();
                  _ageController.clear();
                  setState(() {
                    _selectedPerson = null;
                  });
                }
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  if (person == null) {
                    await _addPerson();
                  } else {
                    await _updatePerson();
                  }
                }
              },
              child: Text(person == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      final user = await ParseUser.currentUser() as ParseUser?;
      if (user != null) {
        await user.logout();
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  String _capitalizeName(String name) {
    if (name.isEmpty) return name;
    return name.trim()[0].toUpperCase() + 
          name.trim().substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentUsername != null ? 'Welcome, $_currentUsername' : 'Persons'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPersons,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountSettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPersons,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _persons.isEmpty
                ? const Center(child: Text('No persons found'))
                : ListView.builder(
                    itemCount: _persons.length,
                    itemBuilder: (context, index) {
                      final person = _persons[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(
                              '${person.get<String>('firstName')} ${person.get<String>('lastName')}'),
                          subtitle: Text(
                              'Age: ${person.get<int>('age')?.toString() ?? ''}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _showAddEditDialog(person: person),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _showDeleteConfirmation(person),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}