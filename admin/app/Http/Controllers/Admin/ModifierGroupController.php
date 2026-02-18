<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ModifierGroup;
use Illuminate\Http\Request;

class ModifierGroupController extends Controller
{
    public function index()
    {
        $groups = ModifierGroup::paginate(10);
        return view('admin.modifier_groups.index', compact('groups'));
    }

    public function create()
    {
        return view('admin.modifier_groups.create');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'min_select' => 'required|integer|min:0',
            'max_select' => 'required|integer|min:1|gte:min_select',
            'required' => 'boolean'
        ]);

        ModifierGroup::create($validated);

        return redirect()->route('admin.modifier-groups.index')->with('success', 'Группа создана');
    }

    public function edit(ModifierGroup $modifierGroup)
    {
        return view('admin.modifier_groups.edit', compact('modifierGroup'));
    }

    public function update(Request $request, ModifierGroup $modifierGroup)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'min_select' => 'required|integer|min:0',
            'max_select' => 'required|integer|min:1|gte:min_select',
            'required' => 'boolean'
        ]);

        $modifierGroup->update($validated);

        return redirect()->route('admin.modifier-groups.index')->with('success', 'Группа обновлена');
    }

    public function destroy(ModifierGroup $modifierGroup)
    {
        $modifierGroup->delete();
        return redirect()->route('admin.modifier-groups.index')->with('success', 'Группа удалена');
    }
}
