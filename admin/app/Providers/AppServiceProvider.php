<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        if ($this->app->environment('production')) {
            \Illuminate\Support\Facades\URL::forceScheme('https');
            \Illuminate\Support\Facades\URL::forceRootUrl('https://vezuroll.ru');

            // Debug logging
            \Illuminate\Support\Facades\Log::info('Booting AppServiceProvider', [
                'scheme' => request()->getScheme(),
                'secure' => request()->secure(),
                'url' => config('app.url'),
            ]);
        }
    }
}
