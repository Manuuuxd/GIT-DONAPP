import 'package:flutter/material.dart';
import 'package:donapp_android/screens/Usuario/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:donapp_android/screens/ubicaciones.dart';
import 'package:donapp_android/CONFIG/api_config.dart';

import '../colours/app_colors.dart';
import 'avatar/avatar_editor_screen.dart';
import 'avatar/avatar_model.dart';
import 'avatar/avatar_preview.dart';
import 'avatar/avatar_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  User? _currentUser;
  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';

  List<String> _sexoOptions = [];
  String? _selectedSexo;
  List<String> _tipoSangreOptions = [];
  String? _selectedTipoSangre;
  List<String> _regiones = [];
  String? _selectedRegion;
  List<String> _provincias = [];
  String? _selectedProvincia;
  List<String> _comunas = [];
  String? _selectedComuna;
  List<Ubicacion> _allUbicaciones = [];

  late TextEditingController _nombreController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _loadAllData();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _fetchProfileChoices();
      await _loadUbicaciones();
      await _fetchCurrentUserData();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar los datos: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchProfileChoices() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.get(
      Uri.parse(ApiConfig.endpoint("api/users/profile/choices/")),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _sexoOptions = (data['sexo'] as Map).keys.cast<String>().toList();
        _tipoSangreOptions = (data['tipo_sangre'] as Map).keys.cast<String>().toList();
      });
    } else {
      throw Exception('Failed to load profile choices.');
    }
  }

  Future<void> _loadUbicaciones() async {
    final ubicacionLoader = Ubicacion('', '', '');
    _allUbicaciones = await ubicacionLoader.cargarUbicaciones();
    setState(() {
      _regiones = _allUbicaciones.map((u) => u.region).toSet().toList();
    });
  }

  Future<void> _fetchCurrentUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null) {
      setState(() {
        _errorMessage = 'Authentication token not found.';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint("api/users/me/")),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final userData = User.fromJson(json.decode(response.body));
        setState(() {
          _currentUser = userData;
          _nombreController.text = _currentUser?.profile?.nombre ?? '';
          _usernameController.text = _currentUser?.username ?? '';
          _emailController.text = _currentUser?.email ?? '';

          final currentSexo = _currentUser?.profile?.sexo;
          _selectedSexo = _sexoOptions.contains(currentSexo) ? currentSexo : null;
          
          final currentTipoSangre = _currentUser?.profile?.tipoSangre;
          _selectedTipoSangre = _tipoSangreOptions.contains(currentTipoSangre) ? currentTipoSangre : null;
          
          final currentRegion = _currentUser?.profile?.region;
          _selectedRegion = _regiones.contains(currentRegion) ? currentRegion : null;

          if (_selectedRegion != null) {
            _updateProvincias(_selectedRegion);
            final currentProvincia = _currentUser?.profile?.provincia;
            _selectedProvincia = _provincias.contains(currentProvincia) ? currentProvincia : null;

            if (_selectedProvincia != null) {
              _updateComunas(_selectedProvincia);
              final currentComuna = _currentUser?.profile?.comuna;
              _selectedComuna = _comunas.contains(currentComuna) ? currentComuna : null;
            }
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load user data.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _updateProvincias(String? region) {
    if (region != null && _allUbicaciones.isNotEmpty) {
      final provincias = _allUbicaciones
          .where((u) => u.region == region)
          .map((u) => u.provincia)
          .toSet()
          .toList();
      setState(() {
        _provincias = provincias;
        _selectedProvincia = null;
        _comunas = [];
        _selectedComuna = null;
      });
    }
  }

  void _updateComunas(String? provincia) {
    if (provincia != null && _allUbicaciones.isNotEmpty) {
      final comunas = _allUbicaciones
          .where((u) => u.provincia == provincia)
          .map((u) => u.comuna)
          .toSet()
          .toList();
      setState(() {
        _comunas = comunas;
        _selectedComuna = null;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
        _errorMessage = '';
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication token not found.';
          _isSaving = false;
        });
        return;
      }

      final updatedData = {
        'nombre': _nombreController.text,
        'sexo': _selectedSexo,
        'region': _selectedRegion,
        'provincia': _selectedProvincia,
        'comuna': _selectedComuna,
        'tipo_sangre': _selectedTipoSangre,
      };

      try {
        final response = await http.put(
          Uri.parse(ApiConfig.endpoint("api/users/me/profile/")),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(updatedData),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado con éxito')),
          );
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _errorMessage = 'Failed to update profile: ${response.body}';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error: $e';
        });
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _nombreController,
                      label: 'Nombre Completo',
                      icon: Icons.person_outline,
                      enabled: !_isSaving,
                    ),
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Nombre de usuario',
                      icon: Icons.person,
                      enabled: !_isSaving,
                    ),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      enabled: !_isSaving,
                      validator: (value) {
                        if (value == null || value.isEmpty || !value.contains('@')) {
                          return 'Por favor, ingrese un email válido';
                        }
                        return null;
                      },
                    ),
                    _buildDropdownField(
                      label: 'Sexo',
                      icon: Icons.wc_outlined,
                      value: _selectedSexo,
                      items: _sexoOptions,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedSexo = newValue;
                        });
                      },
                    ),
                    _buildDropdownField(
                      label: 'Tipo de Sangre',
                      icon: Icons.bloodtype,
                      value: _selectedTipoSangre,
                      items: _tipoSangreOptions,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedTipoSangre = newValue;
                        });
                      },
                    ),
                    _buildDropdownField(
                      label: 'Región',
                      icon: Icons.location_on_outlined,
                      value: _selectedRegion,
                      items: _regiones,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRegion = newValue;
                          _updateProvincias(newValue);
                        });
                      },
                    ),
                    _buildDropdownField(
                      label: 'Provincia',
                      icon: Icons.location_city_outlined,
                      value: _selectedProvincia,
                      items: _provincias,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedProvincia = newValue;
                          _updateComunas(newValue);
                        });
                      },
                    ),
                    _buildDropdownField(
                      label: 'Comuna',
                      icon: Icons.location_on,
                      value: _selectedComuna,
                      items: _comunas,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedComuna = newValue;
                        });
                      },
                    ),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 28),
                    FutureBuilder<AvatarData>(
                      future: AvatarService.load(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final avatarData = snapshot.data;

                        if (avatarData == null) {
                          return const Text('No se pudo cargar el avatar');
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 🧍 Avatar a la izquierda
                              AvatarPreview(data: avatarData, size: 80),

                              const SizedBox(width: 20),

                              // ✨ Texto y botón a la derecha
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Personaliza tu avatar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton.icon(
                                      onPressed: _isSaving
                                          ? null
                                          : () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const AvatarEditorScreen()),
                                        );
                                        if (result == true) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Avatar actualizado con éxito'),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                          setState(() {}); // 🔁 recargar el FutureBuilder
                                        }
                                      },
                                      icon: const Icon(Icons.brush_rounded, size: 22),
                                      label: const Text(
                                        'Editar Avatar',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.customBlue[400],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        shadowColor: AppColors.customBlue[300],
                                        elevation: 4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final dropdownItems = items.map<DropdownMenuItem<String>>((String item) {
      return DropdownMenuItem<String>(
        value: item,
        child: Text(
          item,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        value: value,
        items: dropdownItems,
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, seleccione una opción';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(

      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Guardar Cambios',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
      ),
    );
  }
}