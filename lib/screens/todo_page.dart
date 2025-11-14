// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'login_page.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  late Future<List<Task>> tasks;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();
  bool isAddingTask = false;
  int? selectedStatus; // Filtre pour le statut des tâches

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // Charger les tâches avec un filtre par statut si sélectionné
  Future<void> _loadTasks() async {
    setState(() {
      tasks = selectedStatus == null
          ? DatabaseHelper.instance
                .getAllTasks() // Récupérer toutes les tâches
          : DatabaseHelper.instance.getTasksByStatus(
              selectedStatus!,
            ); // Filtrer par statut
    });
  }

  // Ajouter une tâche
  void addTask() async {
    if (titleController.text.isNotEmpty) {
      Task newTask = Task(
        title: titleController.text,
        details: detailsController.text,
        status: 0,
        createdAt: DateTime.now().toIso8601String(),
      );
      await DatabaseHelper.instance.insertTask(newTask);
      _loadTasks();
      setState(() => isAddingTask = false);
      titleController.clear();
      detailsController.clear();
    }
  }

  // Supprimer une tâche
  void deleteTask(int taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la note ?'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette note ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteTask(taskId);
      if (!mounted) return;
      _loadTasks();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('La note a été supprimée.')));
    }
  }

  // Modifier une tâche existante
  void editTask(Task task) {
    _showTaskSheet(initial: task);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mes notes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ), // Flèche retour
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginPage(),
              ), // Retour à la page Login
            );
          },
        ),
        backgroundColor: Colors.pink,
        toolbarHeight: 90,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filtre par statut
            DropdownButton<int>(
              value: selectedStatus,
              hint: const Text('Filtrer par statut'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Note En cours')),
                DropdownMenuItem(value: 1, child: Text('Note prise en compte')),
                DropdownMenuItem(
                  value: 2,
                  child: Text('Note non prise en compte'),
                ),
              ],
              onChanged: (int? newValue) {
                setState(() {
                  selectedStatus = newValue;
                  _loadTasks();
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Task>>(
                future: tasks,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Aucune note à afficher'));
                  }

                  List<Task> taskList = snapshot.data!;
                  return ListView.builder(
                    itemCount: taskList.length,
                    itemBuilder: (context, index) {
                      Task task = taskList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        color: _getColorByStatus(task.status),
                        child: ListTile(
                          title: Text(
                            task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          subtitle: Text(
                            task.details ?? 'Pas de détails',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.black,
                                ),
                                onPressed: () => editTask(task),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => deleteTask(task.id!),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Ajouter une tâche
            if (isAddingTask)
              Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre de la note *',
                    ),
                    style: TextStyle(fontSize: 22),
                  ),
                  TextField(
                    controller: detailsController,
                    decoration: const InputDecoration(
                      labelText: 'Détails de la note',
                    ),
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: addTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          'Enregistrer',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => isAddingTask = false);
                          titleController.clear();
                          detailsController.clear();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            if (!isAddingTask)
              ElevatedButton(
                onPressed: () => setState(() => isAddingTask = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 10,
                  ),
                ),
                child: const Text(
                  'Ajouter une note',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTaskSheet({Task? initial}) async {
    final titleCtrl = TextEditingController(text: initial?.title ?? '');
    final detailCtrl = TextEditingController(text: initial?.details ?? '');
    int status = initial?.status ?? 0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + viewInsets),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    initial == null ? 'Nouvelle note' : 'Modifier la note',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Titre *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailCtrl,
                decoration: const InputDecoration(labelText: 'Détails'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Statut'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('En cours')),
                  DropdownMenuItem(value: 1, child: Text('Terminé')),
                  DropdownMenuItem(value: 2, child: Text('Non effectué')),
                ],
                onChanged: (k) => status = k ?? 0,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () async {
                        final title = titleCtrl.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Le titre est obligatoire.'),
                            ),
                          );
                          return;
                        }

                        try {
                          if (initial == null) {
                            await DatabaseHelper.instance.insertTask(
                              Task(
                                title: title,
                                details: detailCtrl.text.trim().isEmpty
                                    ? null
                                    : detailCtrl.text.trim(),
                                status: status,
                                createdAt: DateTime.now().toIso8601String(),
                              ),
                            );
                          } else {
                            await DatabaseHelper.instance.updateTask(
                              Task(
                                id: initial.id,
                                title: title,
                                details: detailCtrl.text.trim().isEmpty
                                    ? null
                                    : detailCtrl.text.trim(),
                                status: status,
                                createdAt: initial.createdAt,
                              ),
                            );
                          }

                          if (mounted) {
                            setState(() {
                              _loadTasks();
                            });
                          }

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                initial == null
                                    ? 'Note enregistrée.'
                                    : 'Note mise à jour.',
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Erreur : $e')),
                          );
                        }
                      },
                      child: const Text(
                        'Enregistrer',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

Color _getColorByStatus(int status) {
  switch (status) {
    case 1:
      return Colors.green; // Note prise en compte
    case 0:
      return Colors.grey; // Note en cours
    case 2:
      return const Color.fromARGB(
        255,
        105,
        68,
        100,
      ); // Note non prise en compte
    default:
      return Colors.grey;
  }
}
