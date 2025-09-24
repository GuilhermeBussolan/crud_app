import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AddressApp());
}

class AddressApp extends StatelessWidget {
  const AddressApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Address App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Centralização da URL da API
class ApiConfig {
  static const String baseUrl =
      "https://easy-address-app-15d989ca7c47.herokuapp.com";
  static String addresses() => "$baseUrl/addresses";
  static String addressById(int id) => "$baseUrl/addresses/$id";
  static String cep(String cep) => "$baseUrl/cep/$cep";
}

class Address {
  final int id;
  final String nomeUsuario;
  final String cep;
  final String logradouro;
  final String bairro;
  final String cidade;
  final String uf;
  final String tipo;
  Address({
    required this.id,
    required this.nomeUsuario,
    required this.cep,
    required this.logradouro,
    required this.bairro,
    required this.cidade,
    required this.uf,
    required this.tipo,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      nomeUsuario: json['nomeUsuario'],
      cep: json['cep'],
      logradouro: json['logradouro'],
      bairro: json['bairro'],
      cidade: json['cidade'],
      uf: json['uf'],
      tipo: json['tipo'],
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Address> addresses = [];

  @override
  void initState() {
    super.initState();
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    final response = await http.get(Uri.parse(ApiConfig.addresses()));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        addresses = data.map((e) => Address.fromJson(e)).toList();
      });
    }
  }

  void goToForm({Address? address}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddressFormPage(address: address)),
    );
    fetchAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Endereços")),
      body: ListView.builder(
        itemCount: addresses.length,
        itemBuilder: (context, index) {
          final addr = addresses[index];
          return ListTile(
            title: Text(addr.nomeUsuario),
            subtitle: Text(
              "${addr.logradouro}, ${addr.bairro} - ${addr.cidade}/${addr.uf}",
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => goToForm(address: addr),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => goToForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddressFormPage extends StatefulWidget {
  final Address? address;
  const AddressFormPage({super.key, this.address});
  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController cepController = TextEditingController();
  final TextEditingController logradouroController = TextEditingController();
  final TextEditingController bairroController = TextEditingController();
  final TextEditingController cidadeController = TextEditingController();
  final TextEditingController ufController = TextEditingController();
  final TextEditingController tipoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      nomeController.text = widget.address!.nomeUsuario;
      cepController.text = widget.address!.cep;
      logradouroController.text = widget.address!.logradouro;
      bairroController.text = widget.address!.bairro;
      cidadeController.text = widget.address!.cidade;
      ufController.text = widget.address!.uf;
      tipoController.text = widget.address!.tipo;
    }
  }

  Future<void> saveAddress() async {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> data = {
        "nomeUsuario": nomeController.text,
        "cep": cepController.text,
        "logradouro": logradouroController.text,
        "bairro": bairroController.text,
        "cidade": cidadeController.text,
        "uf": ufController.text,
        "tipo": tipoController.text,
      };
      if (widget.address == null) {
        await http.post(
          Uri.parse(ApiConfig.addresses()),
          headers: {"Content-Type": "application/json"},
          body: json.encode(data),
        );
      } else {
        await http.put(
          Uri.parse(ApiConfig.addressById(widget.address!.id)),
          headers: {"Content-Type": "application/json"},
          body: json.encode(data),
        );
      }
      if (mounted) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Falha ao salvar')));
    }
  }

  Future<void> deleteAddress() async {
    if (widget.address == null) return;
    final response = await http.delete(
      Uri.parse(ApiConfig.addressById(widget.address!.id)),
    );
    if (response.statusCode == 200) {
      if (mounted) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Erro ao excluir endereço")));
    }
  }

  Future<bool> showConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Confirmação"),
            content: const Text("Deseja realmente excluir este endereço?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Excluir"),
              ),
            ],
          ),
        ) ??
        false; // se o usuário fechar o diálogo sem escolher
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.address != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Editar Endereço" : "Novo Endereço"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: "Nome do Usuário"),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Preencha o nome' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: cepController,
                      decoration: const InputDecoration(labelText: "CEP"),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    // TODO: implementar função fetchCep()
                    onPressed: () {
                      // exemplo:
                      // fetchCep();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Função de buscar CEP não implementada"),
                        ),
                      );
                    },
                  ),
                ],
              ),
              TextFormField(
                controller: logradouroController,
                decoration: const InputDecoration(labelText: "Logradouro"),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Preencha o logradouro' : null,
              ),
              TextFormField(
                controller: bairroController,
                decoration: const InputDecoration(labelText: "Bairro"),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Preencha o bairro' : null,
              ),
              TextFormField(
                controller: cidadeController,
                decoration: const InputDecoration(labelText: "Cidade"),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Preencha a cidade' : null,
              ),
              TextFormField(
                controller: ufController,
                decoration: const InputDecoration(labelText: "UF"),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Preencha o UF' : null,
              ),
              TextFormField(
                controller: tipoController,
                decoration: const InputDecoration(labelText: "Tipo"),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Preencha o tipo' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveAddress,
                child: const Text("Salvar"),
              ),
              if (isEditing) ...[
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    final confirm = await showConfirmDialog(context);
                    if (confirm == true) {
                      deleteAddress();
                    }
                  },
                  child: const Text("Excluir"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nomeController.dispose();
    cepController.dispose();
    logradouroController.dispose();
    bairroController.dispose();
    cidadeController.dispose();
    ufController.dispose();
    tipoController.dispose();
    super.dispose();
  }
}
