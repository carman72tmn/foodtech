@extends('adminlte::page')

@section('title', 'Редактирование группы')

@section('content_header')
    <h1>Редактирование группы</h1>
@stop

@section('content')
    <div class="card card-warning">
        <form action="{{ route('admin.modifier-groups.update', $modifierGroup->id) }}" method="POST">
            @csrf
            @method('PUT')
            <div class="card-body">
                <div class="form-group">
                    <label>Название</label>
                    <input type="text" name="name" class="form-control" value="{{ $modifierGroup->name }}" required>
                </div>
                <div class="row">
                    <div class="col-md-6">
                        <div class="form-group">
                            <label>Минимум</label>
                            <input type="number" name="min_select" class="form-control"
                                value="{{ $modifierGroup->min_select }}" min="0">
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="form-group">
                            <label>Максимум</label>
                            <input type="number" name="max_select" class="form-control"
                                value="{{ $modifierGroup->max_select }}" min="1">
                        </div>
                    </div>
                </div>
                <div class="form-check">
                    <input type="hidden" name="required" value="0">
                    <input type="checkbox" name="required" class="form-check-input" value="1" id="isRequired"
                        {{ $modifierGroup->required ? 'checked' : '' }}>
                    <label class="form-check-label" for="isRequired">Обязательный выбор</label>
                </div>
            </div>
            <div class="card-footer">
                <button type="submit" class="btn btn-primary">Обновить</button>
            </div>
        </form>
    </div>
@stop
