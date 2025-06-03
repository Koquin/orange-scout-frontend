import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // Importe Crashlytics

// Importe seus DTOs
import 'package:OrangeScoutFE/dto/team_dto.dart';
// Importe o resultado da operação do controlador
import 'package:OrangeScoutFE/controller/team_controller.dart'; // Contém TeamOperationResult

// Importe seu utilitário de Snackbar
import 'package:OrangeScoutFE/util/persistent_snackbar.dart';


class CreateTeamScreen extends StatefulWidget {
  final int? teamId; // teamId é nulo para criação, preenchido para edição

  const CreateTeamScreen({
    super.key,
    required this.teamId,
  });

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _abbreviationController = TextEditingController();
  String? _logoPath; // PADRONIZAÇÃO: Renomeado para _logoPath (privado)
  File? _selectedImage; // PADRONIZAÇÃO: Renomeado para _selectedImage (privado)
  final String fallbackImage = 'assets/images/TeamShieldIcon-cutout.png';
  bool _isLoading = false;
  bool _isFetchingDetails = false; // NOVO: Para controlar loading ao buscar detalhes do time

  final TeamController _teamController = TeamController();

  @override
  void initState() {
    super.initState();
    _setPortraitOrientation(); // Garante orientação de retrato
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAnalytics.instance.logScreenView(
        screenName: widget.teamId == null ? 'CreateTeamScreen' : 'EditTeamScreenDetails',
        screenClass: 'CreateTeamScreenState',
        parameters: {'team_id': widget.teamId},
      );
    });
    // Se teamId não é nulo, estamos editando, então buscamos os detalhes do time
    if (widget.teamId != null) {
      _fetchTeamDetails();
    }
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _abbreviationController.dispose();
    super.dispose();
  }

  // Garante orientação de retrato para esta tela
  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// Abre o seletor de imagens para o usuário escolher um logo.
  Future<void> _pickImage() async {
    FirebaseAnalytics.instance.logEvent(name: 'pick_image_button_tapped');
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _logoPath = pickedFile.path; // Atualiza o caminho para salvar
      });
      FirebaseAnalytics.instance.logEvent(name: 'image_picked_successfully');
    } else {
      FirebaseAnalytics.instance.logEvent(name: 'image_pick_canceled');
    }
  }

  /// Busca os detalhes do time existente para preencher o formulário (apenas no modo de edição).
  Future<void> _fetchTeamDetails() async {
    setState(() {
      _isFetchingDetails = true; // Inicia o loading para buscar detalhes
      _isLoading = true; // Mantém o botão de salvar desabilitado
    });
    FirebaseAnalytics.instance.logEvent(name: 'fetch_team_details_attempt', parameters: {'team_id': widget.teamId});
    FirebaseCrashlytics.instance.log('Trying to fetch team details to edit: ${widget.teamId}');

    // CORREÇÃO: teamController.fetchTeamDetails retorna TeamDTO?
    final TeamDTO? fetchedTeamData = await _teamController.fetchTeamDetails(widget.teamId!);

    if (mounted) {
      if (fetchedTeamData != null) {
        _teamNameController.text = fetchedTeamData.teamName;
        _abbreviationController.text = fetchedTeamData.abbreviation;
        _logoPath = fetchedTeamData.logoPath; // Atribui o caminho do logo
        // Tenta carregar a imagem se for um caminho de arquivo local
        if (_logoPath != null && (_logoPath!.startsWith('/data/') || _logoPath!.startsWith('file://') || File(_logoPath!).existsSync())) {
          _selectedImage = File(_logoPath!);
        } else {
          _selectedImage = null; // Reseta se não for um arquivo local ou não existir
        }
        FirebaseAnalytics.instance.logEvent(name: 'team_details_fetched_success', parameters: {'team_id': widget.teamId});
      } else {
        // Exibe erro se o time não for encontrado ou houver falha
        PersistentSnackbar.show(
          context: context,
          message: 'Failed fetching team details or team not found.',
          backgroundColor: Colors.red.shade700,
          textColor: Colors.white,
          icon: Icons.error_outline,
        );
        FirebaseAnalytics.instance.logEvent(name: 'fetch_team_details_failed', parameters: {'team_id': widget.teamId, 'reason': 'not_found'});
        Navigator.pop(context); // Volta se não conseguir carregar os detalhes
      }
    }
    setState(() {
      _isFetchingDetails = false;
      _isLoading = false; // Habilita o botão de salvar
    });
  }

  /// Envia o formulário para criar ou atualizar um time.
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      FirebaseAnalytics.instance.logEvent(name: 'save_team_failed', parameters: {'reason': 'validation_failed'});
      PersistentSnackbar.show(
        context: context,
        message: 'Please, fill all fields correctly.',
        backgroundColor: Colors.red.shade700,
        textColor: Colors.white,
        icon: Icons.error_outline,
      );
      return;
    }

    setState(() {
      _isLoading = true; // Ativa o loading do botão
    });

    // Usa fallbackImage se nenhum logo foi selecionado
    final String finalLogoPath = _logoPath ?? fallbackImage;
    FirebaseAnalytics.instance.logEvent(name: 'team_logo_used', parameters: {'type': _logoPath == null ? 'fallback' : 'custom'});

    // CORREÇÃO: Cria TeamDTO e passa para o controlador
    final TeamDTO teamDTO = TeamDTO(
      id: widget.teamId, // Será nulo para criação, ou o ID para edição
      teamName: _teamNameController.text.trim(),
      abbreviation: _abbreviationController.text.trim(),
      logoPath: finalLogoPath,
      // userId NÃO é passado do frontend. O backend infere isso do JWT.
    );

    // CORREÇÃO: teamController.saveOrUpdateTeam retorna TeamOperationResult
    final TeamOperationResult result = await _teamController.saveOrUpdateTeam(teamDTO);

    if (mounted) {
      if (result.success) {
        PersistentSnackbar.show(
          context: context,
          message: result.userMessage ?? "Team successfully saved!",
          backgroundColor: Colors.green.shade700,
          textColor: Colors.white,
          icon: Icons.check_circle_outline,
        );
        FirebaseAnalytics.instance.logEvent(name: 'team_saved_successfully', parameters: {'team_id': result.success});
        Navigator.pop(context, true); // Sinaliza para a tela pai que a operação foi bem-sucedida e fecha
      } else {
        // Usa a userMessage do resultado para exibir a mensagem de erro
        PersistentSnackbar.show(
          context: context,
          message: result.userMessage ?? 'Unknown error saving team.',
          backgroundColor: Colors.red.shade700,
          textColor: Colors.white,
          icon: Icons.error_outline,
        );
        FirebaseAnalytics.instance.logEvent(name: 'team_save_failed', parameters: {'reason': result.errorMessage});
      }
    }
    setState(() {
      _isLoading = false; // Desativa o loading
    });
  }

  // --- Widgets de Entrada Personalizados (Reusados do Login/Register Screen) ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFFFFCC80)),
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFFF57C00).withOpacity(0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
        counterStyle: const TextStyle(color: Colors.white70), // Estilo para o contador de caracteres
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _setPortraitOrientation(); // Garante orientação de retrato

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.teamId == null ? 'Create team' : 'Edit team'),
        backgroundColor: const Color(0xFFFF4500),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            FirebaseAnalytics.instance.logEvent(name: 'create_edit_team_back_button_tapped', parameters: {'team_id': widget.teamId});
            Navigator.pop(context); // Fecha a tela
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFF84442E),
              Color(0xFF3A2E2E),
            ],
            stops: [0.0, 0.7],
          ),
        ),
        child: _isFetchingDetails // Mostra CircularProgressIndicator enquanto busca detalhes do time
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _teamNameController,
                        labelText: "Team name",
                        hintText: "Team's complete name",
                        maxLength: 100, // Limite de caracteres conforme o DTO
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Team name is required.";
                          }
                          if (value.trim().length < 2) {
                            return "Team name must be at least 2 characters long.";
                          }
                          if (value.trim().length > 30) {
                            return "Team name have a limit of 30 characters.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _abbreviationController,
                        labelText: "Abbreviation",
                        hintText: "E.G: FLA, GSW, ORS",
                        maxLength: 10, // Limite de caracteres conforme o DTO
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Abbreviation is required.";
                          }
                          if (value.trim().length < 2 || value.trim().length > 3) {
                            return "Abbreviation must have 3 characters.";
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _selectedImage != null
                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                          : Image.asset(fallbackImage, fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm, // Desabilita durante o loading
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading // Exibe CircularProgressIndicator no botão
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          : Text(
                        widget.teamId == null ? "Create" : "Save", // Texto do botão dinâmico
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white54),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: IconButton(
                        onPressed: _pickImage,
                        icon: Image.asset('assets/images/UploadImageIcon.png', width: 40, height: 40),
                        tooltip: "Pick team shield",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}