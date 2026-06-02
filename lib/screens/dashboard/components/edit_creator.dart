import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin/controllers/creator_controller.dart';

class EditCreatorPage extends StatefulWidget {
  final String creatorId;

  const EditCreatorPage({Key? key, required this.creatorId}) : super(key: key);

  @override
  _EditCreatorPageState createState() => _EditCreatorPageState();
}

class _EditCreatorPageState extends State<EditCreatorPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController companyNameController = TextEditingController();
  TextEditingController phoneNoController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  String? _selectedStatus; // 'Active' or 'Inactive'

  final CreatorController _controller = Get.find<CreatorController>();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCreatorData();
  }

  Future<void> _fetchCreatorData() async {
    var creator = _controller.creators.firstWhere((element) => element.id == widget.creatorId);
    nameController.text = creator.name ?? '';
    companyNameController.text = creator.companyName ?? '';
    phoneNoController.text = creator.phoneNo ?? '';
    emailController.text = creator.email ?? '';
    _selectedStatus = (creator.active ?? true) ? 'Active' : 'Inactive';
    setState(() {});
  }

  Future<void> _saveEditedCreator() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> updatedFields = {};

      if (nameController.text.isNotEmpty) {
        updatedFields['name'] = nameController.text;
      }
      if (companyNameController.text.isNotEmpty) {
        updatedFields['companyName'] = companyNameController.text;
      }
      if (phoneNoController.text.isNotEmpty) {
        updatedFields['phoneNo'] = phoneNoController.text;
      }
      if (emailController.text.isNotEmpty) {
        updatedFields['email'] = emailController.text;
      }
      if (_selectedStatus != null) {
        updatedFields['active'] = _selectedStatus == 'Active';
      }

      await _controller.updateCreator(
        creatorId: widget.creatorId,
        updatedFields: updatedFields,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Creator updated successfully!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      Get.back();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update creator: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Creator"),
        backgroundColor: const Color.fromARGB(255, 19, 24, 27),
        elevation: 4.0,
        shadowColor: Colors.black54,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          margin: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 30, 30, 30),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Edit Creator",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildFormSection(
                    "Creator Name",
                    nameController,
                    "Enter creator name",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter creator name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildFormSection(
                    "Company Name",
                    companyNameController,
                    "Enter company name",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter company name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildFormSection(
                    "Phone No",
                    phoneNoController,
                    "Enter phone number",
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildFormSection(
                    "Email",
                    emailController,
                    "Enter email address",
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email';
                      }
                      if (!GetUtils.isEmail(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildStatusDropdown(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => Get.back(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[700],
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: _saveEditedCreator,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 37, 35, 35),
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text("Save Changes"),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color.fromARGB(255, 40, 40, 40),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Status",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 40, 40, 40),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            ),
            dropdownColor: const Color.fromARGB(255, 40, 40, 40),
            style: const TextStyle(color: Colors.white),
            items: ['Active', 'Inactive'].map((String status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedStatus = newValue;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select status';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}

