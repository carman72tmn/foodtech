@extends('adminlte::page')

@section('title', 'Редактирование модификатора')

@section('content_header')
    <h1>Редактирование модификатора</h1>
@stop

@section('content')
    <div class="card card-warning">
        <form action="{{ route('admin.modifiers.update', $modifier->id) }}" method="POST">
            @csrf
            @method('PUT')
            <div class="card-body">
                <div class="row">
                    <div class="col-md-6">
                        <div class="form-group">
                            <label>Название</label>
                            <input type="text" name="name" class="form-control" value="{{ $modifier->name }}" required>
                        </div>
                        <div class="form-group">
                            <label>Группа</label>
                            <select name="modifier_group_id" class="form-control">
                                @foreach ($groups as $group)
                                    <option value="{{ $group->id }}"
                                        {{ $modifier->modifier_group_id == $group->id ? 'selected' : '' }}>
                                        {{ $group->name }}
                                    </option>
                                @endforeach
                            </select>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="form-group">
                            <label>Цена (₽)</label>
                            <input type="number" name="price" class="form-control" value="{{ $modifier->price }}"
                                required min="0">
                        </div>
                        <div class="form-group">
                            <label>Вес (г)</label>
                            <input type="number" name="weight" class="form-control" value="{{ $modifier->weight }}"
                                min="0">
                        </div>
                        <div class="form-check mt-4">
                            <input type="checkbox" name="is_active" class="form-check-input" value="1" id="isActive"
                                {{ $modifier->is_active ? 'checked' : '' }}>
                            <label class="form-check-label" for="isActive">Активен</label>
                        </div>
                    </div>
                </div>
            </div>
            <div class="card-footer">
                <button type="submit" class="btn btn-primary">Обновить</button>
            </div>
        </form>
    </div>
@stop
