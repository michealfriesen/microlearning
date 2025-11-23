// annie loves making stuff with u guys 
import 'dart:math';
import 'package:flutter/material.dart'; // imports 


// stateful widgets - a stateful widget is a widget that can change overtime 
class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState(); // createState() mutable state for this widget 
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _controller;
  
  List<GraphNode> nodes = [
    GraphNode(id: '1', label: 'hello', position: Offset(400, 400)),
    GraphNode(id: '2', label: '', position: Offset(400, 300)),
  ];

  GraphNode? draggedNode;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 16), // ~60fps
    )..addListener(() {
        setState(() {
          _updatePhysics();
        });
      })..repeat();
  }

  void _updatePhysics() {
    // Get screen center for centering force
    final Size screenSize = MediaQuery.of(context).size;
    final Offset center = Offset(screenSize.width / 2, screenSize.height / 2);
    
    // Physics simulation runs for all nodes, even during dragging!
    // The dragged node will be repositioned by touch, but other nodes respond to forces

    for (int i = 0; i < nodes.length; i++) {
      // Skip applying physics to the node being dragged (it follows the finger)
      if (nodes[i] == draggedNode) continue;
      
      Offset force = Offset.zero;
      
      for (int j = 0; j < nodes.length; j++) {
        if (i == j) continue;
        
        Offset diff = nodes[j].position - nodes[i].position;
        double distance = diff.distance;
        
        if (distance < 1) continue;
        
        // ┌─────────────────────────────────────────────┐
        // │ REPULSION: Always active!                   │
        // │ Gets exponentially stronger as nodes        │
        // │ approach each other (1/distance²)           │
        // └─────────────────────────────────────────────┘
        double repulsion = 50000 / (distance * distance);
        force -= Offset(diff.dx / distance * repulsion, diff.dy / distance * repulsion);
        
        // Attraction (Spring Force)
        double targetDistance = 200;
        double attraction = (distance - targetDistance) * 0.09;
        force += Offset(diff.dx / distance * attraction, diff.dy / distance * attraction);
      }

      // Center Force - pulls nodes toward screen center
      Offset toCenter = center - nodes[i].position;
      double centerDistance = toCenter.distance;
      if (centerDistance > 1) {
        double centerForce = centerDistance * 0.001;  // Weak centering force
        force += Offset(toCenter.dx / centerDistance * centerForce, 
                       toCenter.dy / centerDistance * centerForce);
      }
      
      // Apply force with damping
      nodes[i].velocity += force * 0.02;
      nodes[i].velocity *= 0.9; // Damping
      nodes[i].position += nodes[i].velocity;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stretchy Nodes')),
      body: GestureDetector(
        onPanStart: (details) {
          // Find node under touch
          for (var node in nodes) {
            if ((node.position - details.localPosition).distance < 40) {
              setState(() {
                draggedNode = node;
                // Keep the velocity when starting drag for smoother motion
              });
              break;
            }
          }
        },
        onPanUpdate: (details) {
          if (draggedNode != null) {
            setState(() {
              // Update dragged node position
              Offset newPosition = details.localPosition;
              
              // Calculate velocity based on movement (for momentum when released)
              draggedNode!.velocity = newPosition - draggedNode!.position;
              draggedNode!.position = newPosition;
            });
          }
        },
        onPanEnd: (details) {
          setState(() {
            // Release the node - it will continue with its current velocity
            draggedNode = null;
          });
        },
        child: CustomPaint(
          painter: GraphPainter(nodes),
          size: Size.infinite,
          child: Stack(
            children: nodes.map((node) {
              return Positioned(
                left: node.position.dx - 20,
                top: node.position.dy - 20,
                child: GestureDetector(
                  onTap: () => _editNode(node),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: node == draggedNode 
                          ? Colors.blue.shade300  // Highlight when dragging
                          : Colors.blue.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: node == draggedNode ? Colors.blue.shade700 : Colors.blue, 
                        width: node == draggedNode ? 3 : 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        node.label,
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNode,
        child: Icon(Icons.add),
        tooltip: 'Add Node',
      ),
    );
  }

  void _addNode() {
    setState(() {
      final random = Random();
      nodes.add(GraphNode(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: '',
        position: Offset(
          random.nextDouble() * 400 + 200,
          random.nextDouble() * 300 + 200,
        ),
      ));
    });
  }

  void _editNode(GraphNode node) {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController controller = TextEditingController(text: node.label);
        return AlertDialog(
          title: Text('Edit Node'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Enter text'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  node.label = controller.text;
                });
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
            if (nodes.length > 1)
              TextButton(
                onPressed: () {
                  setState(() {
                    nodes.remove(node);
                  });
                  Navigator.pop(context);
                },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
          ],
        );
      },
    );
  }
}

class GraphNode {
  String id;
  String label;
  Offset position;
  Offset velocity;

  GraphNode({
    required this.id,
    required this.label,
    required this.position,
    this.velocity = Offset.zero,
  });
}

class GraphPainter extends CustomPainter {
  final List<GraphNode> nodes;

  GraphPainter(this.nodes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..strokeWidth = 2;

    // Draw connections between nodes
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        canvas.drawLine(nodes[i].position, nodes[j].position, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}