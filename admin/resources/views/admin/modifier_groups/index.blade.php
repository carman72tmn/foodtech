@extends('adminlte::page')

@section('title', 'Группы модификаторов')

@section('content_header')
    <h1>Группы модификаторов</h1>
@stop

@section('content')
    <div class="card">
        <div class="card-header">
            <h3 class="card-title">Список групп</h3>
            <div class="card-tools">
                <a href="{{ route('admin.modifier-groups.create') }}" class="btn btn-primary btn-sm">
                    <i class="fas fa-plus"></i> Добавить группу
                </a>
            </div>
        </div>
        <div class="card-body p-0">
            <table class="table table-striped">
                <thead>
                    <tr>
                        <th style="width: 10px">#</th>
                        <th>Название</th>
                        <th>Мин. выбор</th>
                        <th>Макс. выбор</th>
                        <th>Обязательно</th>
                        <th>Действия</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach ($groups as $group)
                        <tr>
                            <td>{{ $group->id }}</td>
                            <td>{{ $group->name }}</td>
                            <td>{{ $group->min_select }}</td>
                            <td>{{ $group->max_select }}</td>
                            <td>
                                @if ($group->required)
                                    <span class="badge badge-warning">Да</span>
                                @else
                                    <span class="badge badge-secondary">Нет</span>
                                @endif
                            </td>
                            <td>
                                <a href="{{ route('admin.modifier-groups.edit', $group->id) }}" class="btn btn-sm btn-info">
                                    <i class="fas fa-pencil-alt"></i>
                                </a>
                                <form action="{{ route('admin.modifier-groups.destroy', $group->id) }}" method="POST"
                                    style="display:inline;">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="btn btn-sm btn-danger"
                                        onclick="return confirm('Удалить группу?')">
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
            {{ $groups->links() }}
        </div>
    </div>
@stop
