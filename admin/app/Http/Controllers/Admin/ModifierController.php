<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Modifier;
use App\Models\ModifierGroup;
use Illuminate\Http\Request;

class ModifierController extends Controller
{
    public function index()
    {
        $modifiers = Modifier::with('group')->paginate(10);
        return view('admin.modifiers.index', compact('modifiers'));
    }

    public function create()
    {
        $groups = ModifierGroup::all();
        return view('admin.modifiers.create', compact('groups'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'modifier_group_id' => 'required|exists:modifier_groups,id',
            'price' => 'required|numeric|min:0',
            'weight' => 'nullable|integer',
            'is_active' => 'boolean'
        ]);

        Modifier::create($validated);

        return redirect()->route('admin.modifiers.index')->with('success', 'Модификатор создан');
    }

    public function edit(Modifier $modifier)
    {
        $groups = ModifierGroup::all();
        return view('admin.modifiers.edit', compact('modifier', 'groups'));
    }

    public function update(Request $request, Modifier $modifier)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'modifier_group_id' => 'required|exists:modifier_groups,id',
            'price' => 'required|numeric|min:0',
            'weight' => 'nullable|integer',
            'is_active' => 'boolean'
        ]);

        $modifier->update($validated);

        return redirect()->route('admin.modifiers.index')->with('success', 'Модификатор обновлен');
    }

    public function destroy(Modifier $modifier)
    {
        $modifier->delete();
        return redirect()->route('admin.modifiers.index')->with('success', 'Модификатор удален');
    }
}
