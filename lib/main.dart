import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AutoRamos Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        primaryColor: const Color(0xFF1A237E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A237E),
          foregroundColor: Colors.white,
          elevation: 4,
          centerTitle: true,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFF6B35),
        ),
        cardTheme: const CardThemeData(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      home: const CarListPage(),
    );
  }
}

class CarController extends GetxController {
  var cars = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var isSaving = false.obs;

  final String baseUrl = 'https://dxdljgmfjtvcopmpayck.supabase.co';
  final String apiUrl =
      'https://dxdljgmfjtvcopmpayck.supabase.co/rest/v1/carros';
  final String storageUrl =
      'https://dxdljgmfjtvcopmpayck.supabase.co/storage/v1/object/autos';
  final String apiKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR4ZGxqZ21manR2Y29wbXBheWNrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYzMDI1NzYsImV4cCI6MjA3MTg3ODU3Nn0.pKMgs19lxRqx-1-R0KkQq-CJMHPTO78C8FvtjC7yHT8';

  @override
  void onInit() {
    fetchCars();
    super.onInit();
  }

  Future<void> fetchCars() async {
    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse('$apiUrl?select=*'),
        headers: {'apikey': apiKey, 'Authorization': 'Bearer $apiKey'},
      );
      if (response.statusCode == 200) {
        cars.value = List<Map<String, dynamic>>.from(
          json.decode(response.body),
        );
        // Debug: imprimir la estructura de los datos
        if (cars.isNotEmpty) {
          print('Estructura del primer auto: ${cars.first}');
          print('Campos disponibles: ${cars.first.keys.toList()}');
        }
      } else {
        Get.snackbar('Error', 'No se pudo obtener la lista de autos');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error de conexión: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> uploadImageToStorage(
    dynamic imageFile,
    String fileName,
  ) async {
    try {
      Uint8List imageBytes;

      if (kIsWeb) {
        // Para web
        if (imageFile is Uint8List) {
          imageBytes = imageFile;
        } else {
          throw Exception('Formato de imagen no válido para web');
        }
      } else {
        // Para móvil
        if (imageFile is File) {
          imageBytes = await imageFile.readAsBytes();
        } else {
          throw Exception('Formato de imagen no válido para móvil');
        }
      }

      final uploadUrl = '$baseUrl/storage/v1/object/autos/$fileName';

      final response = await http.post(
        Uri.parse(uploadUrl),
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'image/jpeg',
          'x-upsert': 'true',
        },
        body: imageBytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return '$baseUrl/storage/v1/object/public/autos/$fileName';
      } else {
        print(
          'Error al subir imagen: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    }
  }

  Future<bool> saveCar({
    required String marca,
    required String modelo,
    required String color,
    dynamic imageFile,
  }) async {
    isSaving.value = true;
    try {
      String? imageUrl;

      // Subir imagen si existe
      if (imageFile != null) {
        final fileName = '${const Uuid().v4()}.jpg';
        imageUrl = await uploadImageToStorage(imageFile, fileName);

        if (imageUrl == null) {
          Get.snackbar('Error', 'No se pudo subir la imagen');
          return false;
        }
      }

      // Crear el objeto para enviar
      final carData = {
        'marca': marca,
        'modelo': modelo,
        'color': color,
        if (imageUrl != null) 'foto': imageUrl,
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: json.encode(carData),
      );

      if (response.statusCode == 201) {
        Get.snackbar(
          'Éxito',
          'Auto registrado correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Actualizar la lista
        await fetchCars();
        return true;
      } else {
        print('Error al guardar: ${response.statusCode} - ${response.body}');
        Get.snackbar('Error', 'No se pudo registrar el auto');
        return false;
      }
    } catch (e) {
      print('Error: $e');
      Get.snackbar('Error', 'Error de conexión: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updateCar({
    required int idVehiculo,
    required String marca,
    required String modelo,
    required String color,
    dynamic imageFile,
    String? existingImageUrl,
  }) async {
    isSaving.value = true;
    try {
      print('Starting updateCar with ID: $idVehiculo');
      String? imageUrl = existingImageUrl;

      // Subir nueva imagen si se seleccionó una
      if (imageFile != null) {
        final fileName = '${const Uuid().v4()}.jpg';
        imageUrl = await uploadImageToStorage(imageFile, fileName);

        if (imageUrl == null) {
          Get.snackbar('Error', 'No se pudo subir la imagen');
          return false;
        }
      }

      // Crear el objeto para enviar
      final carData = {
        'marca': marca,
        'modelo': modelo,
        'color': color,
        if (imageUrl != null) 'foto': imageUrl,
      };

      final response = await http.patch(
        Uri.parse('$apiUrl?id_vehiculo=eq.$idVehiculo'),
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: json.encode(carData),
      );

      print('Update URL: $apiUrl?id_vehiculo=eq.$idVehiculo');
      print('Update response: ${response.statusCode} - ${response.body}');
      print('Update data: ${json.encode(carData)}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        Get.snackbar(
          'Éxito',
          'Auto actualizado correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Actualizar la lista
        await fetchCars();
        return true;
      } else {
        print('Error al actualizar: ${response.statusCode} - ${response.body}');
        Get.snackbar('Error', 'No se pudo actualizar el auto');
        return false;
      }
    } catch (e) {
      print('Error: $e');
      Get.snackbar('Error', 'Error de conexión: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteCar(int idVehiculo) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl?id_vehiculo=eq.$idVehiculo'),
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      print('Delete URL: $apiUrl?id_vehiculo=eq.$idVehiculo');
      print('Delete response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 204) {
        Get.snackbar(
          'Éxito',
          'Auto eliminado correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Actualizar la lista
        await fetchCars();
        return true;
      } else {
        print('Error al eliminar: ${response.statusCode} - ${response.body}');
        Get.snackbar(
          'Error',
          'No se pudo eliminar el auto. Código: ${response.statusCode}',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      print('Error: $e');
      Get.snackbar('Error', 'Error de conexión: $e');
      return false;
    }
  }
}

class CarListPage extends StatefulWidget {
  const CarListPage({Key? key}) : super(key: key);

  @override
  State<CarListPage> createState() => _CarListPageState();
}

class _CarListPageState extends State<CarListPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmation(BuildContext context, Map<String, dynamic> car) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Estás seguro de que quieres eliminar el ${car['modelo']} ${car['marca']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final controller = Get.find<CarController>();
                print('Deleting car with ID: ${car['id_vehiculo']}');
                await controller.deleteCar(car['id_vehiculo']);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _getFilteredCars(
    List<Map<String, dynamic>> cars,
    String query,
  ) {
    if (query.isEmpty) {
      return cars;
    }

    return cars.where((car) {
      final marca = car['marca']?.toString().toLowerCase() ?? '';
      final modelo = car['modelo']?.toString().toLowerCase() ?? '';
      final color = car['color']?.toString().toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();

      return marca.contains(searchQuery) ||
          modelo.contains(searchQuery) ||
          color.contains(searchQuery);
    }).toList();
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(text);
    }

    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();

    if (!textLower.contains(queryLower)) {
      return Text(text);
    }

    final startIndex = textLower.indexOf(queryLower);
    final endIndex = startIndex + query.length;

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          if (startIndex > 0) TextSpan(text: text.substring(0, startIndex)),
          TextSpan(
            text: text.substring(startIndex, endIndex),
            style: const TextStyle(
              backgroundColor: Color(0xFFFFEB3B),
              fontWeight: FontWeight.bold,
            ),
          ),
          if (endIndex < text.length) TextSpan(text: text.substring(endIndex)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CarController controller = Get.put(CarController());

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Buscar por marca, modelo o color...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'AutoRamos Pro',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.clear : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.cars.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay vehículos en inventario',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Agrega tu primer vehículo usando el botón +',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final filteredCars = _getFilteredCars(
          controller.cars,
          _searchController.text,
        );

        if (filteredCars.isEmpty && _searchController.text.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No se encontraron vehículos',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Intenta con otros términos de búsqueda',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Mostrar información de búsqueda
            if (_searchController.text.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF1A237E).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: const Color(0xFF1A237E),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mostrando ${filteredCars.length} resultado${filteredCars.length != 1 ? 's' : ''} para "${_searchController.text}"',
                        style: const TextStyle(
                          color: Color(0xFF1A237E),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.clear,
                          size: 18,
                          color: Color(0xFF1A237E),
                        ),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),

            // Lista de vehículos
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: filteredCars.length,
                itemBuilder: (context, index) {
                  final car = filteredCars[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.grey[50]!],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: car['foto'] != null
                                ? Image.network(
                                    car['foto'],
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                Icons.directions_car,
                                                size: 30,
                                                color: Colors.grey,
                                              ),
                                            ),
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.directions_car,
                                      size: 30,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                          ),
                        ),
                        title: _buildHighlightedText(
                          '${car['marca']} ${car['modelo']}'.toUpperCase(),
                          _searchController.text,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.palette,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                _buildHighlightedText(
                                  car['color'] ?? 'Color no especificado',
                                  _searchController.text,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: Colors.green[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Disponible para venta',
                                  style: TextStyle(
                                    color: Colors.green[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[100],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: Color(0xFF1A237E),
                                ),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    builder: (context) =>
                                        EditCarModal(car: car),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  _showDeleteConfirmation(context, car);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => const AddCarModal(),
          );
        },
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Agregar Vehículo'),
      ),
    );
  }
}

class AddCarModal extends StatefulWidget {
  const AddCarModal({Key? key}) : super(key: key);

  @override
  State<AddCarModal> createState() => _AddCarModalState();
}

class _AddCarModalState extends State<AddCarModal> {
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final CarController controller = Get.find<CarController>();

  dynamic _selectedImageFile;

  @override
  void dispose() {
    _marcaController.dispose();
    _modeloController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        // Para web usar file_picker
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null) {
          setState(() {
            _selectedImageFile = result.files.first.bytes;
          });
        }
      } else {
        // Para móvil usar image_picker
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 600,
          imageQuality: 80,
        );

        if (image != null) {
          setState(() {
            _selectedImageFile = File(image.path);
          });
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo seleccionar la imagen');
    }
  }

  Future<void> _saveCar() async {
    // Validaciones
    if (_marcaController.text.trim().isEmpty ||
        _modeloController.text.trim().isEmpty ||
        _colorController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Por favor completa todos los campos',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    bool success = await controller.saveCar(
      marca: _marcaController.text.trim(),
      modelo: _modeloController.text.trim(),
      color: _colorController.text.trim(),
      imageFile: _selectedImageFile,
    );

    if (success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF5F7FA)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Header mejorado
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1A237E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Registrar Nuevo Vehículo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Contenido
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección de foto mejorada
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF1A237E),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: _selectedImageFile != null
                                ? (kIsWeb
                                      ? Image.memory(
                                          _selectedImageFile as Uint8List,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          _selectedImageFile as File,
                                          fit: BoxFit.cover,
                                        ))
                                : Container(
                                    color: Colors.grey[100],
                                    child: const Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 50,
                                      color: Color(0xFF1A237E),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: Text(
                            _selectedImageFile != null
                                ? 'Cambiar Foto'
                                : 'Agregar Foto',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Campos del formulario con diseño comercial
                  const Text(
                    'Información del Vehículo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildCommercialTextField(
                    controller: _marcaController,
                    label: 'Marca del Vehículo',
                    icon: Icons.branding_watermark,
                    hint: 'Ej: Toyota, Honda, Ford',
                  ),
                  const SizedBox(height: 16),

                  _buildCommercialTextField(
                    controller: _modeloController,
                    label: 'Modelo',
                    icon: Icons.directions_car_outlined,
                    hint: 'Ej: Corolla, Civic, F-150',
                  ),
                  const SizedBox(height: 16),

                  _buildCommercialTextField(
                    controller: _colorController,
                    label: 'Color',
                    icon: Icons.palette_outlined,
                    hint: 'Ej: Rojo, Azul, Negro',
                  ),
                  const SizedBox(height: 30),

                  // Botones de acción mejorados
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Color(0xFF1A237E)),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              color: Color(0xFF1A237E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Obx(
                          () => ElevatedButton(
                            onPressed: controller.isSaving.value
                                ? null
                                : _saveCar,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFF1A237E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: controller.isSaving.value
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Registrar Vehículo',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommercialTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF1A237E), size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class EditCarModal extends StatefulWidget {
  final Map<String, dynamic> car;

  const EditCarModal({Key? key, required this.car}) : super(key: key);

  @override
  State<EditCarModal> createState() => _EditCarModalState();
}

class _EditCarModalState extends State<EditCarModal> {
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final CarController controller = Get.find<CarController>();

  dynamic _selectedImageFile;

  @override
  void initState() {
    super.initState();
    _marcaController.text = widget.car['marca'] ?? '';
    _modeloController.text = widget.car['modelo'] ?? '';
    _colorController.text = widget.car['color'] ?? '';
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedImageFile = result.files.first.bytes;
        });
      }
    } else {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
        });
      }
    }
  }

  Future<void> _updateCar() async {
    if (_marcaController.text.trim().isEmpty ||
        _modeloController.text.trim().isEmpty ||
        _colorController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Por favor completa todos los campos');
      return;
    }

    String? photoUrl = widget.car['foto'];

    if (_selectedImageFile != null) {
      photoUrl = await controller.uploadImageToStorage(
        _selectedImageFile,
        'car_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (photoUrl == null) {
        Get.snackbar('Error', 'Error al subir la imagen');
        return;
      }
    }

    final success = await controller.updateCar(
      idVehiculo: int.parse(widget.car['id_vehiculo'].toString()),
      marca: _marcaController.text.trim(),
      modelo: _modeloController.text.trim(),
      color: _colorController.text.trim(),
      imageFile: _selectedImageFile,
      existingImageUrl: photoUrl,
    );
    if (success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF1A237E),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Editar Vehículo',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Foto Section
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFF1A237E).withOpacity(0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _selectedImageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: kIsWeb
                                  ? Image.memory(
                                      _selectedImageFile as Uint8List,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                    )
                                  : Image.file(
                                      _selectedImageFile as File,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                    ),
                            )
                          : widget.car['foto'] != null &&
                                widget.car['foto'] != ''
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: Image.network(
                                widget.car['foto'],
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                              ),
                            )
                          : const Icon(
                              Icons.directions_car,
                              size: 50,
                              color: Colors.grey,
                            ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1A237E).withOpacity(0.8),
                            const Color(0xFF3949AB).withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: TextButton.icon(
                        onPressed: _pickImage,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('Cambiar Foto'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Form Fields
              _buildTextField(
                controller: _marcaController,
                label: 'Marca',
                icon: Icons.business,
                hint: 'Ej: Toyota, Honda, Ford',
              ),
              const SizedBox(height: 20),

              _buildTextField(
                controller: _modeloController,
                label: 'Modelo',
                icon: Icons.directions_car,
                hint: 'Ej: Corolla, Civic, F-150',
              ),
              const SizedBox(height: 20),

              _buildTextField(
                controller: _colorController,
                label: 'Color',
                icon: Icons.palette,
                hint: 'Ej: Rojo, Azul, Negro',
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1A237E)),
                        foregroundColor: const Color(0xFF1A237E),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFFF6F00)],
                        ),
                      ),
                      child: Obx(
                        () => ElevatedButton(
                          onPressed: controller.isSaving.value
                              ? null
                              : _updateCar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: controller.isSaving.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Actualizar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1A237E), size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
