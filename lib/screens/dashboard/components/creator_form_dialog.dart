import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin/controllers/creator_controller.dart';
import 'package:admin/models/Creator.dart';

class CreatorFormDialog extends StatefulWidget {
  final Creator? creator; // null for add mode, non-null for edit mode

  const CreatorFormDialog({Key? key, this.creator}) : super(key: key);

  @override
  _CreatorFormDialogState createState() => _CreatorFormDialogState();
}

class _CreatorFormDialogState extends State<CreatorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final CreatorController _controller = Get.find<CreatorController>();

  TextEditingController nameController = TextEditingController();
  TextEditingController companyNameController = TextEditingController();
  TextEditingController phoneNoController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordContriller = TextEditingController();
  String? _selectedStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.creator != null) {
      // Edit mode - fill with existing data
      nameController.text = widget.creator!.name ?? '';
      companyNameController.text = widget.creator!.companyName ?? '';
      phoneNoController.text = widget.creator!.phoneNo ?? '';
      emailController.text = widget.creator!.email ?? '';
      passwordContriller.text = widget.creator!.password ?? '';
      _selectedStatus =
          (widget.creator!.active ?? true) ? 'Active' : 'Inactive';
    } else {
      // Add mode - set defaults
      _selectedStatus = 'Active';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    companyNameController.dispose();
    phoneNoController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.creator != null) {
        // Edit mode
        Map<String, dynamic> updatedFields = {};
        if (nameController.text.isNotEmpty) {
          updatedFields['name'] = nameController.text;
        }
        if (companyNameController.text.isNotEmpty) {
          updatedFields['companyName'] = companyNameController.text;
        } else {
          updatedFields['companyName'] = '';
        }
        if (phoneNoController.text.isNotEmpty) {
          updatedFields['phoneNo'] = phoneNoController.text;
        }
        if (emailController.text.isNotEmpty) {
          updatedFields['email'] = emailController.text;
        }
        if (passwordContriller.text.isNotEmpty) {
          updatedFields['password'] = passwordContriller.text;
        }
        if (_selectedStatus != null) {
          updatedFields['active'] = _selectedStatus == 'Active';
        }

        await _controller.updateCreator(
          creatorId: widget.creator!.id,
          updatedFields: updatedFields,
        );

        Get.snackbar(
          'Success',
          'Creator updated successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        // Add mode
        await _controller.createCreator(
          name: nameController.text,
          companyName: companyNameController.text.isNotEmpty
              ? companyNameController.text
              : null,
          phoneNo: phoneNoController.text,
          email: emailController.text,
          password: passwordContriller.text,
          active: _selectedStatus == 'Active',
        );

        Get.snackbar(
          'Success',
          'Creator created successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to ${widget.creator != null ? 'update' : 'create'} creator: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: const Color.fromARGB(255, 30, 30, 30),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.creator != null ? 'Edit Creator' : 'Add New Creator',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 24),
                _buildFormField(
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
                _buildFormField(
                  "Company Name (Optional)",
                  companyNameController,
                  "Enter company name",
                  isOptional: true,
                ),
                const SizedBox(height: 16),
                _buildFormField(
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
                _buildFormField(
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
                const SizedBox(
                  height: 16,
                ),
                _buildFormField(
                  "Password",
                  passwordContriller,
                  "Enter Password",
                  keyboardType: TextInputType.visiblePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildStatusDropdown(),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text("OK"),
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

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
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
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
            fontSize: 16,
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
              contentPadding:
                  EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
