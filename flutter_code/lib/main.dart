import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minha Aplicação',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyForm(),
    );
  }
}

class MyForm extends StatefulWidget {
  @override
  _MyFormState createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  File? _pdfFile = null;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    runApp(MyApp());
  }

  Future<void> _uploadPDF() async {
    if (_pdfFile == null) {
      return;
    }
    final firebaseStorageRef = FirebaseStorage.instance
        .ref()
        .child('contracts/${_pdfFile!.path.split('/').last}');
    final uploadTask = firebaseStorageRef.putFile(_pdfFile!);
    await uploadTask
        .whenComplete(() => print('File uploaded to Firebase Storage'));
    final pdfUrl = await firebaseStorageRef.getDownloadURL();
    _submitForm(pdfUrl);
  }

  Future<void> _submitForm(String pdfUrl) async {
    final formData = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text.trim(),
      'pdfUrl': pdfUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'gender': _gender,
    };
    await FirebaseFirestore.instance.collection('contracts').add(formData);
    _formKey.currentState!.reset();
    setState(() => _pdfFile = null);
  }
  String? _gender;
  bool _obscureText = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Formulário')),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Nome completo'),
                  validator: (value) => value!.trim().isEmpty
                      ? 'Por favor, insira seu nome'
                      : null,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'E-mail'),
                  validator: (value) {
                    if (value!.trim().isEmpty) {
                      return 'Por favor introduza o seu e-mail';
                    } else if (!value.trim().contains('@')) {
                      return 'Por favor digite um email válido';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    suffixIcon: GestureDetector(
                      onTap: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                      child: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                  validator: (value) => value!.trim().isEmpty
                      ? 'Por favor, insira sua senha'
                      : null,
                ),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Gênero'),
                  value: _gender,
                  onChanged: (value) {
                    setState(() {
                      _gender = value;
                    });
                  },
                  items: ['Masculino', 'Feminino']
                      .map((e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(e),
                          ))
                      .toList(),
                ),
                SizedBox(height: 16.0),
                _pdfFile != null
                    ? Text(_pdfFile!.path.split('/').last)
                    : ElevatedButton(
                        child: Text('Anexar contrato'),
                        onPressed: () async {
                          final file = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf']);
                          if (file == null || file.files.isEmpty) {
                            return;
                          }
                          setState(
                              () => _pdfFile = File(file.files.single.path!));
                        },
                      ),
                SizedBox(height: 32.0),
                ElevatedButton(
                  child: Text('Enviar'),
                  onPressed: () {
                    if (_formKey.currentState!.validate() && _pdfFile != null) {
                      _uploadPDF();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
