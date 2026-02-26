<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\OrderController;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::apiResource('products', ProductController::class);
Route::apiResource('categories', CategoryController::class);
Route::apiResource('orders', OrderController::class);

    // Proxy requests to the FastAPI backend
    Route::any('v1/{path}', function (Request $request, $path) {
        $backendUrl = env('BACKEND_URL', 'http://backend:8000/api/v1/');
        $url = rtrim($backendUrl, '/') . '/' . trim($path, '/') . '/';
    // Get query parameters string
    $queryString = $request->getQueryString();
    if ($queryString) {
        $url .= '?' . $queryString;
    }

    $headers = collect($request->header())->mapWithKeys(function ($values, $key) {
        return [$key => $values[0]];
    })->except(['host', 'content-length', 'content-type'])->toArray();

    // Adding Content-Type manually if present
    if ($request->header('Content-Type')) {
        $headers['Content-Type'] = $request->header('Content-Type');
    }

    // Proxy the request using Laravel HTTP client
    try {
        $response = \Illuminate\Support\Facades\Http::withOptions([
            'allow_redirects' => true,
        ])
        ->withHeaders($headers)
        ->send($request->method(), $url, [
            'body' => $request->getContent()
        ]);

        return response($response->body(), $response->status())
            ->withHeaders($response->headers());
            
    } catch (\Exception $e) {
        return response()->json([
            'error' => 'Backend connection failed',
            'message' => $e->getMessage()
        ], 502);
    }
})->where('path', '.*');
