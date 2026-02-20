<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\URL;
use Symfony\Component\HttpFoundation\Response;

class ForceHttps
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        if (!$request->secure() && app()->environment('production')) {
             URL::forceScheme('https');
        }

        // Также попробуем добавить CSP, чтобы блокировать mixed content
        $response = $next($request);

        // Добавляем HTTPS в пагинацию и другие сгенерированные ссылки
        // Но это уже делает forceScheme.

        return $response;
    }
}
