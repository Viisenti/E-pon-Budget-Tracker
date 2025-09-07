import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../providers/budget_provider.dart';

class AddBudgetBottomSheet extends StatefulWidget {
  final Budget? budget; // For editing existing budget

  const AddBudgetBottomSheet({super.key, this.budget});

  @override
  State<AddBudgetBottomSheet> createState() => _AddBudgetBottomSheetState();
}

class _AddBudgetBottomSheetState extends State<AddBudgetBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  
  Category? _selectedCategory;
  String _selectedPeriod = 'monthly';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isLoading = false;

  final List<String> _periods = ['daily', 'weekly', 'monthly', 'yearly'];

  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      _nameController.text = widget.budget!.budgetName;
      _amountController.text = widget.budget!.budgetAmount.toString();
      _selectedPeriod = widget.budget!.periodType ?? 'monthly';
      _startDate = widget.budget!.startDate;
      _endDate = widget.budget!.endDate;
      
      // Find the selected category
      final provider = Provider.of<BudgetProvider>(context, listen: false);
      _selectedCategory = provider.getCategoryById(widget.budget!.categoryId ?? '');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.budget == null ? 'Add Budget' : 'Edit Budget',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Budget Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Budget Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a budget name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Amount
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Budget Amount (₱)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Category Dropdown
                    Consumer<BudgetProvider>(
                      builder: (context, provider, child) {
                        final List<DropdownMenuItem<Category>> categoryItems = [];
                        for (final category in provider.categories) {
                          categoryItems.add(
                            DropdownMenuItem<Category>(
                              value: category,
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Color(int.parse(category.colorCode?.replaceFirst('#', '0xFF') ?? '0xFF4CAF50')),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(category.name),
                                ],
                              ),
                            ),
                          );
                        }
                        
                        return DropdownButtonFormField<Category>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: categoryItems,
                          onChanged: (Category? value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a category';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Period Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedPeriod,
                      decoration: InputDecoration(
                        labelText: 'Period',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _periods.map((period) {
                        return DropdownMenuItem<String>(
                          value: period,
                          child: Text(period.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _selectedPeriod = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveBudget,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0CAF60),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(widget.budget == null ? 'Add Budget' : 'Update Budget'),
                          ),
                        ),
                      ],
                    ),
                    
                    // Add bottom padding for safe area
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<BudgetProvider>(context, listen: false);
      final now = DateTime.now();
      
      final budget = Budget(
        budgetId: widget.budget?.budgetId ?? const Uuid().v4(),
        categoryId: _selectedCategory!.categoryId,
        budgetName: _nameController.text.trim(),
        budgetAmount: double.parse(_amountController.text),
        periodType: _selectedPeriod,
        startDate: _startDate,
        endDate: _endDate,
        spentAmount: widget.budget?.spentAmount ?? 0.0,
        isActive: true,
        createdAt: widget.budget?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.budget == null) {
        await provider.addBudget(budget);
      } else {
        await provider.updateBudget(budget);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.budget == null ? 'Budget added successfully!' : 'Budget updated successfully!'),
            backgroundColor: const Color(0xFF0CAF60),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
