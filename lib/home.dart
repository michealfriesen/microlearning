// annie loves making stuff with u guys 
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'theme.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _controller;
  
  List<GraphNode> nodes = [
    GraphNode(id: '1', label: 'hello', position: Offset(400, 400)),
    GraphNode(id: '2', label: '', position: Offset(400, 300)),
  ];

  List<GraphEdge> edges = [
    GraphEdge(from: '1', to: '2'),
  ];

  GraphNode? draggedNode;
  bool isPanning = false;
  Offset? lastPanPosition;
  
  // For creating connections
  GraphNode? connectionStartNode;
  Offset? connectionEndPosition;
  bool isCreatingConnection = false;
  GraphNode? hoveredNode; 

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 16),
    )..addListener(() {
        setState(() {
          _updatePhysics();
        });
      })..repeat();
  }

  bool areNodesConnected(String id1, String id2) {
    return edges.any((edge) => 
      (edge.from == id1 && edge.to == id2) || 
      (edge.from == id2 && edge.to == id1)
    );
  }

  void _updatePhysics() {
    final Size screenSize = MediaQuery.of(context).size;
    final Offset center = Offset(screenSize.width / 2, screenSize.height / 2);

    for (int i = 0; i < nodes.length; i++) {
      if (nodes[i] == draggedNode) continue;
      if (isPanning) continue;
      
      Offset force = Offset.zero;
      
      for (int j = 0; j < nodes.length; j++) {
        if (i == j) continue;
        
        Offset diff = nodes[j].position - nodes[i].position;
        double distance = diff.distance;
        
        if (distance < 1) continue;

        double repulsion = 50000 / (distance * distance);
        force -= Offset(diff.dx / distance * repulsion, diff.dy / distance * repulsion);
        
        if (areNodesConnected(nodes[i].id, nodes[j].id)) {
          double targetDistance = 200;
          double attraction = (distance - targetDistance) * 0.09;
          force += Offset(diff.dx / distance * attraction, diff.dy / distance * attraction);
        }
      }

      Offset toCenter = center - nodes[i].position;
      double centerDistance = toCenter.distance;
      if (centerDistance > 1) {
        double centerForce = centerDistance * 0.001;
        force += Offset(toCenter.dx / centerDistance * centerForce, 
                       toCenter.dy / centerDistance * centerForce);
      }
      
      nodes[i].velocity += force * 0.02;
      nodes[i].velocity *= 0.9;
      nodes[i].position += nodes[i].velocity;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showColorSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Color Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('Background Color'),
                  trailing: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onTap: () {
                    _pickColor(
                      context: context,
                      currentColor: AppTheme.background,
                      title: 'Pick Background Color',
                      onColorChanged: (color) {
                        setState(() {
                          AppTheme.updateColors(newBackground: color);
                        });
                      },
                    );
                  },
                ),
                SizedBox(height: 10),
                ListTile(
                  title: Text('Node Color'),
                  trailing: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onTap: () {
                    _pickColor(
                      context: context,
                      currentColor: AppTheme.primary,
                      title: 'Pick Node Color',
                      onColorChanged: (color) {
                        setState(() {
                          AppTheme.updateColors(newPrimary: color);
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  AppTheme.updateColors(
                    newBackground: Colors.black,
                    newPrimary: Colors.blue,
                  );
                });
              },
              child: Text('Reset'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _pickColor({
    required BuildContext context,
    required Color currentColor,
    required String title,
    required Function(Color) onColorChanged,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: onColorChanged,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('microlearning'),
        actions: [
          IconButton(
            icon: Icon(Icons.palette),
            onPressed: _showColorSettings,
            tooltip: 'Color Settings',
          ),
        ],
      ),
      body: Listener(
        onPointerMove: (event) {
          if (isCreatingConnection) {
            setState(() {
              connectionEndPosition = event.localPosition;
              
              // 👇 Check if hovering over a node
              hoveredNode = null;
              for (var node in nodes) {
                if (node != connectionStartNode &&
                    (node.position - event.localPosition).distance < 40) {
                  hoveredNode = node;
                  
                  // 👇 Auto-connect when line touches node!
                  if (!areNodesConnected(connectionStartNode!.id, node.id)) {
                    edges.add(GraphEdge(
                      from: connectionStartNode!.id,
                      to: node.id,
                    ));
                    // Reset connection state
                    connectionStartNode = null;
                    connectionEndPosition = null;
                    isCreatingConnection = false;
                    hoveredNode = null;
                  } else {
                    // Already connected, just cancel
                    connectionStartNode = null;
                    connectionEndPosition = null;
                    isCreatingConnection = false;
                    hoveredNode = null;
                  }
                  break;
                }
              }
            });
          }
        },
        child: MouseRegion(
          cursor: isPanning 
              ? SystemMouseCursors.grabbing
              : (isCreatingConnection 
                  ? SystemMouseCursors.click 
                  : SystemMouseCursors.basic),
          child: GestureDetector(
            onPanStart: (details) {
              bool foundNode = false;
              for (var node in nodes) {
                if ((node.position - details.localPosition).distance < 20) {
                  setState(() {
                    draggedNode = node;
                    isPanning = false;
                  });
                  foundNode = true;
                  break;
                }
              }
              
              if (!foundNode) {
                setState(() {
                  isPanning = true;
                  lastPanPosition = details.localPosition;
                });
              }
            },
            onPanUpdate: (details) {
              setState(() {
                if (draggedNode != null && !isCreatingConnection) {
                  Offset newPosition = details.localPosition;
                  draggedNode!.velocity = newPosition - draggedNode!.position;
                  draggedNode!.position = newPosition;
                } else if (isPanning && lastPanPosition != null) {
                  Offset delta = details.localPosition - lastPanPosition!;
                  
                  for (var node in nodes) {
                    node.position += delta;
                    node.velocity = Offset.zero;
                  }
                  
                  lastPanPosition = details.localPosition;
                }
              });
            },
            onPanEnd: (details) {
              setState(() {
                draggedNode = null;
                isPanning = false;
                lastPanPosition = null;
              });
            },
            child: CustomPaint(
              painter: GraphPainter(nodes, edges, connectionStartNode, connectionEndPosition, hoveredNode),
              size: Size.infinite,
              child: Stack(
                children: nodes.map((node) {
                  return Positioned(
                    left: node.position.dx - 20,
                    top: node.position.dy - 20,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        // 👇 Double-click to EDIT node
                        onDoubleTap: () {
                          _editNode(node);
                        },
                        // 👇 Right-click to START connection (only if other nodes exist)
                        onSecondaryTapDown: (details) {
                          // 👇 Check if there are other nodes to connect to
                          if (nodes.length > 1) {
                            setState(() {
                              connectionStartNode = node;
                              connectionEndPosition = node.position;
                              isCreatingConnection = true;
                            });
                          } else {
                            // Show message that you need more nodes
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Add more nodes to create connections'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            // 👇 Visual feedback for connection mode
                            color: (node == hoveredNode)
                                ? AppTheme.primary.withOpacity(0.9) // Bright when hovering
                                : (node == connectionStartNode
                                    ? AppTheme.primary.withOpacity(0.7) // Medium when starting connection
                                    : (node == draggedNode
                                        ? AppTheme.primary.withOpacity(0.6) // Medium when dragging
                                        : AppTheme.primary.withOpacity(0.3))), // Normal
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (node == hoveredNode || node == connectionStartNode)
                                  ? AppTheme.primary
                                  : AppTheme.primary.withOpacity(0.6),
                              width: (node == hoveredNode || node == connectionStartNode) ? 3 : 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              node.label,
                              style: AppTheme.nodeTextStyle,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
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
            decoration: InputDecoration(hintText: 'Enter subject'),
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
                    edges.removeWhere((edge) => 
                      edge.from == node.id || edge.to == node.id);
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

class GraphEdge {
  String from;
  String to;

  GraphEdge({required this.from, required this.to});
}

class GraphPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final GraphNode? connectionStartNode;
  final Offset? connectionEndPosition;
  final GraphNode? hoveredNode;

  GraphPainter(this.nodes, this.edges, this.connectionStartNode, this.connectionEndPosition, this.hoveredNode);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary.withOpacity(0.3)
      ..strokeWidth = 2;

    for (var edge in edges) {
      final fromNode = nodes.firstWhere((n) => n.id == edge.from);
      final toNode = nodes.firstWhere((n) => n.id == edge.to);
      canvas.drawLine(fromNode.position, toNode.position, paint);
    }

    if (connectionStartNode != null && connectionEndPosition != null) {
      final previewPaint = Paint()
        ..color = AppTheme.primary.withOpacity(0.6)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      final endPos = hoveredNode?.position ?? connectionEndPosition!;
      canvas.drawLine(connectionStartNode!.position, endPos, previewPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}