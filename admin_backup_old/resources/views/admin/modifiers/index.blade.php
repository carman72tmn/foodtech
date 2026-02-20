@extends('adminlte::page')

@section('title', 'Модификаторы')

@section('content_header')
    <h1>Модификаторы</h1>
@stop

@section('content')
    <div class="card">
        <div class="card-header">
            <h3 class="card-title">Список модификаторов</h3>
            <div class="card-tools">
                <a href="{{ route('admin.modifiers.create') }}" class="btn btn-primary btn-sm">
                    <i class="fas fa-plus"></i> Добавить
                </a>
            </div>
        </div>
        <div class="card-body p-0">
            <table class="table table-striped">
                <thead>
                    <tr>
                        <th style="width: 10px">#</th>
                        <th>Название</th>
                        <th>Группа</th>
                        <th>Цена</th>
                        <th>Вес</th>
                        <th>Статус</th>
                        <th>Действия</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach ($modifiers as $modifier)
                        <tr>
                            <td>{{ $modifier->id }}</td>
                            <td>{{ $modifier->name }}</td>
                            <td>{{ $modifier->group->name ?? '-' }}</td>
                            <td>{{ number_format($modifier->price, 0, '.', ' ') }} ₽</td>
                            <td>{{ $modifier->weight }} г</td>
                            <td>
                                @if ($modifier->is_active)
                                    <span class="badge badge-success">Активен</span>
                                @else
                                    <span class="badge badge-danger">Скрыт</span>
                                @endif
                            </td>
                            <td>
                                <a href="{{ route('admin.modifiers.edit', $modifier->id) }}" class="btn btn-sm btn-info">
                                    <i class="fas fa-pencil-alt"></i>
                                </a>
                                <form action="{{ route('admin.modifiers.destroy', $modifier->id) }}" method="POST"
                                    style="display:inline;">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="btn btn-sm btn-danger"
                                        onclick="return confirm('Удалить модификатор?')">
                                        <i class="fas fa-trash"></i>
                                    </button>
                                </form>
                            </td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
        <div class="card-footer">
            {{ $modifiers->links() }}
        </div>
    </div>
@stop
