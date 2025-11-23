// annie loves making stuff with u guys 
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class GraphState {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  
  GraphState(this.nodes, this.edges);
  
  GraphState copy() {
    return GraphState(
      nodes.map((n) => GraphNode(
        id: n.id,
        label: n.label,
        note: n.note,
        position: n.position,
        velocity: n.velocity,
      )).toList(),
      edges.map((e) => GraphEdge(from: e.from, to: e.to, note: e.note)).toList(),
    );
  }
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _controller;
  final FocusNode _focusNode = FocusNode();
  
  // Define custom magenta color
  static const Color magentaColor = Color(0xFFFF00FF);
  
  List<GraphNode> nodes = [];
  List<GraphEdge> edges = [];

  GraphNode? draggedNode;
  bool isPanning = false;
  Offset? lastPanPosition;
  
  // For creating connections
  GraphNode? connectionStartNode;
  Offset? connectionEndPosition;
  bool isCreatingConnection = false;
  GraphNode? hoveredNode;
  
  // For viewing connection notes
  GraphEdge? hoveredEdge;
  GraphNode? closestNodeToHover;
  Offset? currentMousePosition;

  // Zoom and pan
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  // Undo/Redo
  List<GraphState> _history = [];
  int _historyIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadGraph();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 16),
    )..addListener(() {
        setState(() {
          _updatePhysics();
        });
      })..repeat();
    
    // Request focus for keyboard shortcuts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _saveState() {
    // Remove any states after current index (if we're not at the end)
    if (_historyIndex < _history.length - 1) {
      _history = _history.sublist(0, _historyIndex + 1);
    }
    
    // Add new state
    _history.add(GraphState(nodes, edges).copy());
    _historyIndex++;
    
    // Limit history to 50 states
    if (_history.length > 50) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  void _undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      final state = _history[_historyIndex];
      setState(() {
        nodes = state.copy().nodes;
        edges = state.copy().edges;
      });
    }
  }

  void _redo() {
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      final state = _history[_historyIndex];
      setState(() {
        nodes = state.copy().nodes;
        edges = state.copy().edges;
      });
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isControlPressed = HardwareKeyboard.instance.isControlPressed || 
                               HardwareKeyboard.instance.isMetaPressed;
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      
      if (isControlPressed) {
        // Zoom shortcuts
        if (event.logicalKey == LogicalKeyboardKey.equal || 
            event.logicalKey == LogicalKeyboardKey.add ||
            event.logicalKey == LogicalKeyboardKey.numpadAdd) {
          setState(() {
            _scale = (_scale * 1.2).clamp(0.5, 3.0);
          });
        } else if (event.logicalKey == LogicalKeyboardKey.minus ||
                   event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
          setState(() {
            _scale = (_scale / 1.2).clamp(0.5, 3.0);
          });
        } else if (event.logicalKey == LogicalKeyboardKey.digit0 ||
                   event.logicalKey == LogicalKeyboardKey.numpad0) {
          setState(() {
            _scale = 1.0;
            _offset = Offset.zero;
          });
        }
        // Undo/Redo shortcuts
        else if (event.logicalKey == LogicalKeyboardKey.keyZ && !isShiftPressed) {
          _undo();
        } else if ((event.logicalKey == LogicalKeyboardKey.keyZ && isShiftPressed) ||
                   event.logicalKey == LogicalKeyboardKey.keyY) {
          _redo();
        }
      }
    }
  }

  // Load graph data from storage
  Future<void> _loadGraph() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nodesJson = prefs.getString('nodes');
      final edgesJson = prefs.getString('edges');
      
      if (nodesJson != null && edgesJson != null) {
        final List<dynamic> nodesList = json.decode(nodesJson);
        final List<dynamic> edgesList = json.decode(edgesJson);
        
        setState(() {
          nodes = nodesList.map((json) => GraphNode.fromJson(json)).toList();
          edges = edgesList.map((json) => GraphEdge.fromJson(json)).toList();
        });
        
        // Save initial state for undo/redo
        _saveState();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Graph loaded successfully')),
        );
      } else {
        // Load default graph if no saved data
        setState(() {
          nodes = [
            GraphNode(id: '1', label: 'hello', note: 'This is about greetings', position: Offset(400, 400)),
            GraphNode(id: '2', label: 'world', note: 'This is about the world', position: Offset(400, 300)),
          ];
          edges = [
            GraphEdge(from: '1', to: '2', note: 'hello relates to world because they form a common phrase'),
          ];
        });
        _saveState();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load graph: $e')),
      );
    }
  }

  // Save graph data to storage
  Future<void> _saveGraph() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final nodesJson = json.encode(nodes.map((node) => node.toJson()).toList());
      final edgesJson = json.encode(edges.map((edge) => edge.toJson()).toList());
      
      await prefs.setString('nodes', nodesJson);
      await prefs.setString('edges', edgesJson);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Graph saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save graph: $e')),
      );
    }
  }

  // Clear all data
  Future<void> _clearGraph() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Clear Graph?'),
          content: Text('This will delete all nodes and connections. This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('nodes');
                await prefs.remove('edges');
                
                setState(() {
                  nodes.clear();
                  edges.clear();
                  _history.clear();
                  _historyIndex = -1;
                });
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Graph cleared')),
                );
              },
              child: Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  bool areNodesConnected(String id1, String id2) {
    return edges.any((edge) => 
      (edge.from == id1 && edge.to == id2) || 
      (edge.from == id2 && edge.to == id1)
    );
  }

  // Calculate distance from point to line segment
  double distanceToLineSegment(Offset point, Offset lineStart, Offset lineEnd) {
    final double lengthSquared = pow(lineEnd.dx - lineStart.dx, 2) + pow(lineEnd.dy - lineStart.dy, 2).toDouble();
    if (lengthSquared == 0) return (point - lineStart).distance;
    
    double t = ((point.dx - lineStart.dx) * (lineEnd.dx - lineStart.dx) + 
                (point.dy - lineStart.dy) * (lineEnd.dy - lineStart.dy)) / lengthSquared;
    t = max(0, min(1, t));
    
    final Offset projection = Offset(
      lineStart.dx + t * (lineEnd.dx - lineStart.dx),
      lineStart.dy + t * (lineEnd.dy - lineStart.dy),
    );
    
    return (point - projection).distance;
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
    _focusNode.dispose();
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

  void _defineRelationship(GraphNode fromNode, GraphNode toNode) {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController controller = TextEditingController();
        return AlertDialog(
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'How are these related? (e.g., music relates to coding because of pattern-based thinking)',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  edges.add(GraphEdge(
                    from: fromNode.id,
                    to: toNode.id,
                    note: '',
                  ));
                  _saveState();
                });
                Navigator.pop(context);
              },
              child: Text('Skip'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  edges.add(GraphEdge(
                    from: fromNode.id,
                    to: toNode.id,
                    note: controller.text,
                  ));
                  _saveState();
                });
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // View connection and node notes
  void _viewNotes(GraphEdge edge, GraphNode node) {
    final fromNode = nodes.firstWhere((n) => n.id == edge.from);
    final toNode = nodes.firstWhere((n) => n.id == edge.to);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${fromNode.label} ↔ ${toNode.label}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (edge.note.isNotEmpty) ...[
                  Text(
                    'Connection Note:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(edge.note),
                  SizedBox(height: 16),
                ],
                Text(
                  'Node: ${node.label}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(node.note ?? 'No note'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text('microlearning'),
          actions: [
            IconButton(
              icon: Icon(Icons.undo),
              onPressed: _historyIndex > 0 ? _undo : null,
              tooltip: 'Undo (Ctrl+Z)',
            ),
            IconButton(
              icon: Icon(Icons.redo),
              onPressed: _historyIndex < _history.length - 1 ? _redo : null,
              tooltip: 'Redo (Ctrl+Y)',
            ),
            IconButton(
              icon: Icon(Icons.zoom_in),
              onPressed: () {
                setState(() {
                  _scale = (_scale * 1.2).clamp(0.5, 3.0);
                });
              },
              tooltip: 'Zoom In (Ctrl +)',
            ),
            IconButton(
              icon: Icon(Icons.zoom_out),
              onPressed: () {
                setState(() {
                  _scale = (_scale / 1.2).clamp(0.5, 3.0);
                });
              },
              tooltip: 'Zoom Out (Ctrl -)',
            ),
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveGraph,
              tooltip: 'Save Graph',
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadGraph,
              tooltip: 'Reload Graph',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline),
              onPressed: _clearGraph,
              tooltip: 'Clear Graph',
            ),
            IconButton(
              icon: Icon(Icons.palette),
              onPressed: _showColorSettings,
              tooltip: 'Color Settings',
            ),
          ],
        ),
        body: Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              setState(() {
                if (pointerSignal.scrollDelta.dy < 0) {
                  _scale = (_scale * 1.1).clamp(0.5, 3.0);
                } else {
                  _scale = (_scale / 1.1).clamp(0.5, 3.0);
                }
              });
            }
          },
          onPointerMove: (event) {
            currentMousePosition = event.localPosition;
            
            if (isCreatingConnection) {
              setState(() {
                connectionEndPosition = (event.localPosition - _offset) / _scale;
                
                hoveredNode = null;
                for (var node in nodes) {
                  if (node != connectionStartNode &&
                      (node.position - ((event.localPosition - _offset) / _scale)).distance < 40) {
                    hoveredNode = node;
                    
                    if (!areNodesConnected(connectionStartNode!.id, node.id)) {
                      final startNode = connectionStartNode;
                      final endNode = node;
                      
                      connectionStartNode = null;
                      connectionEndPosition = null;
                      isCreatingConnection = false;
                      hoveredNode = null;
                      
                      _defineRelationship(startNode!, endNode);
                    } else {
                      connectionStartNode = null;
                      connectionEndPosition = null;
                      isCreatingConnection = false;
                      hoveredNode = null;
                    }
                    break;
                  }
                }
              });
            } else {
              // Check if hovering over a connection
              setState(() {
                hoveredEdge = null;
                closestNodeToHover = null;
                
                for (var edge in edges) {
                  final fromNode = nodes.firstWhere((n) => n.id == edge.from);
                  final toNode = nodes.firstWhere((n) => n.id == edge.to);
                  
                  double dist = distanceToLineSegment(
                    (event.localPosition - _offset) / _scale,
                    fromNode.position,
                    toNode.position,
                  );
                  
                  if (dist < 10) {
                    hoveredEdge = edge;
                    
                    // Find closest node
                    double distToFrom = ((event.localPosition - _offset) / _scale - fromNode.position).distance;
                    double distToTo = ((event.localPosition - _offset) / _scale - toNode.position).distance;
                    
                    closestNodeToHover = distToFrom < distToTo ? fromNode : toNode;
                    break;
                  }
                }
              });
            }
          },
          onPointerHover: (event) {
            currentMousePosition = event.localPosition;
          },
          child: MouseRegion(
            cursor: isPanning 
                ? SystemMouseCursors.grabbing
                : (isCreatingConnection 
                    ? SystemMouseCursors.click 
                    : (hoveredEdge != null ? SystemMouseCursors.click : SystemMouseCursors.basic)),
            child: GestureDetector(
              onPanStart: (details) {
                final localPos = (details.localPosition - _offset) / _scale;
                bool foundNode = false;
                for (var node in nodes) {
                  if ((node.position - localPos).distance < 20) {
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
                    Offset newPosition = (details.localPosition - _offset) / _scale;
                    draggedNode!.velocity = newPosition - draggedNode!.position;
                    draggedNode!.position = newPosition;
                  } else if (isPanning && lastPanPosition != null) {
                    Offset delta = details.localPosition - lastPanPosition!;
                    _offset += delta;
                    lastPanPosition = details.localPosition;
                  }
                });
              },
              onPanEnd: (details) {
                if (draggedNode != null) {
                  _saveState();
                }
                setState(() {
                  draggedNode = null;
                  isPanning = false;
                  lastPanPosition = null;
                });
              },
              child: Transform.translate(
                offset: _offset,
                child: Transform.scale(
                  scale: _scale,
                  child: CustomPaint(
                    painter: GraphPainter(
                      nodes, 
                      edges, 
                      connectionStartNode, 
                      connectionEndPosition, 
                      hoveredNode,
                      hoveredEdge,
                      closestNodeToHover,
                    ),
                    size: Size.infinite,
                    child: Stack(
                      children: nodes.map((node) {
                        return Positioned(
                          left: node.position.dx - 20,
                          top: node.position.dy - 20,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                // If hovering over edge and clicking closest node, show notes
                                if (hoveredEdge != null && node == closestNodeToHover) {
                                  _viewNotes(hoveredEdge!, node);
                                } else {
                                  _editNode(node);
                                }
                              },
                              onDoubleTap: () {
                                _editNode(node);
                              },
                              onSecondaryTapDown: (details) {
                                if (nodes.length > 1) {
                                  setState(() {
                                    connectionStartNode = node;
                                    connectionEndPosition = node.position;
                                    isCreatingConnection = true;
                                  });
                                } else {
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
                                  // Magenta when it's the closest node to hover
                                  color: (node == closestNodeToHover && hoveredEdge != null)
                                      ? magentaColor.withOpacity(0.8)
                                      : (node == hoveredNode)
                                          ? AppTheme.primary.withOpacity(0.9)
                                          : (node == connectionStartNode
                                              ? AppTheme.primary.withOpacity(0.7)
                                              : (node == draggedNode
                                                  ? AppTheme.primary.withOpacity(0.6)
                                                  : AppTheme.primary.withOpacity(0.3))),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: (node == closestNodeToHover && hoveredEdge != null)
                                        ? magentaColor
                                        : (node == hoveredNode || node == connectionStartNode)
                                            ? AppTheme.primary
                                            : AppTheme.primary.withOpacity(0.6),
                                    width: (node == closestNodeToHover || node == hoveredNode || node == connectionStartNode) ? 3 : 2,
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
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addNode,
          child: Icon(Icons.add),
          tooltip: 'Add Node',
        ),
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
      _saveState();
    });
  }

  void _editNode(GraphNode node) {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController nameController = TextEditingController(text: node.label);
        TextEditingController noteController = TextEditingController(text: node.note ?? '');
        
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Title/Name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  hintText: 'Note',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  node.label = nameController.text;
                  node.note = noteController.text;
                  _saveState();
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
                    _saveState();
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
  String? note;
  Offset position;
  Offset velocity;

  GraphNode({
    required this.id,
    required this.label,
    this.note,
    required this.position,
    this.velocity = Offset.zero,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'note': note,
      'position': {'dx': position.dx, 'dy': position.dy},
    };
  }

  // Create from JSON
  factory GraphNode.fromJson(Map<String, dynamic> json) {
    return GraphNode(
      id: json['id'],
      label: json['label'],
      note: json['note'],
      position: Offset(json['position']['dx'], json['position']['dy']),
    );
  }
}

class GraphEdge {
  String from;
  String to;
  String note;

  GraphEdge({
    required this.from,
    required this.to,
    this.note = '',
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'note': note,
    };
  }

  // Create from JSON
  factory GraphEdge.fromJson(Map<String, dynamic> json) {
    return GraphEdge(
      from: json['from'],
      to: json['to'],
      note: json['note'] ?? '',
    );
  }
}

class GraphPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final GraphNode? connectionStartNode;
  final Offset? connectionEndPosition;
  final GraphNode? hoveredNode;
  final GraphEdge? hoveredEdge;
  final GraphNode? closestNodeToHover;

  GraphPainter(
    this.nodes, 
    this.edges, 
    this.connectionStartNode, 
    this.connectionEndPosition, 
    this.hoveredNode,
    this.hoveredEdge,
    this.closestNodeToHover,
  );

  @override
  void paint(Canvas canvas, Size size) {
    const Color magentaColor = Color(0xFFFF00FF);
    
    for (var edge in edges) {
      final fromNode = nodes.firstWhere((n) => n.id == edge.from);
      final toNode = nodes.firstWhere((n) => n.id == edge.to);
      
      // Magenta if hovered, otherwise normal
      final paint = Paint()
        ..color = (edge == hoveredEdge) 
            ? magentaColor.withOpacity(0.7)
            : AppTheme.primary.withOpacity(0.3)
        ..strokeWidth = (edge == hoveredEdge) ? 3 : 2;
      
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