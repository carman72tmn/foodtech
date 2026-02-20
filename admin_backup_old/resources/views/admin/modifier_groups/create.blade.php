@extends('adminlte::page')

@section('title', 'Новая группа модификаторов')

@section('content_header')
    <h1>Новая группа модификаторов</h1>
@stop

@section('content')
    <div class="card card-primary">
        <form action="{{ route('admin.modifier-groups.store') }}" method="POST">
            @csrf
            <div class="card-body">
                <div class="form-group">
                    <label>Название</label>
                    <input type="text" name="name" class="form-control" required placeholder="Например: Соусы">
                </div>
                <div class="row">
                    <div class="col-md-6">
                        <div class="form-group">
                            <label>Минимум (0 = не обязательно)</label>
                            <input type="number" name="min_select" class="form-control" value="0" min="0">
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="form-group">
                            <label>Максимум</label>
                            <input type="number" name="max_select" class="form-control" value="1" min="1">
                        </div>
                    </div>
                </div>
                <div class="form-check">
                    <input type="hidden" name="required" value="0">
                    <input type="checkbox" name="required" class="form-check-input" value="1" id="isRequired">
                    <label class="form-check-label" for="isRequired">Обязательный выбор</label>
                </div>
            </div>
            <div class="card-footer">
                <button type="submit" class="btn btn-primary">Сохранить</button>
            </div>
        </form>
    </div>
@stop
