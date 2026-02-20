<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Categories
        if (!Schema::hasTable('categories')) {
            Schema::create('categories', function (Blueprint $table) {
                $table->id();
                $table->string('name')->index();
                $table->text('description')->nullable();
                $table->string('iiko_id')->nullable()->unique()->index();
                $table->integer('sort_order')->default(0);
                $table->boolean('is_active')->default(true);
                $table->timestamps();
            });
        }

        // Products
        if (!Schema::hasTable('products')) {
            Schema::create('products', function (Blueprint $table) {
                $table->id();
                $table->string('name')->index();
                $table->text('description')->nullable();
                $table->decimal('price', 10, 2);
                $table->string('image_url', 500)->nullable();
                $table->foreignId('category_id')->nullable()->constrained('categories')->nullOnDelete();
                $table->string('iiko_id')->nullable()->unique()->index();
                $table->boolean('is_available')->default(true);
                $table->integer('sort_order')->default(0);
                $table->timestamps();
            });
        }

        // Orders
        if (!Schema::hasTable('orders')) {
            Schema::create('orders', function (Blueprint $table) {
                $table->id();
                $table->bigInteger('telegram_user_id')->index();
                $table->string('telegram_username')->nullable();
                $table->string('customer_name');
                $table->string('customer_phone');
                $table->string('delivery_address', 500);
                $table->decimal('total_amount', 10, 2);
                $table->string('status')->default('new');
                $table->string('iiko_order_id')->nullable()->unique()->index();
                $table->text('comment')->nullable();
                $table->timestamps();
            });
        }

        // Order Items
        if (!Schema::hasTable('order_items')) {
            Schema::create('order_items', function (Blueprint $table) {
                $table->id();
                $table->foreignId('order_id')->constrained('orders')->cascadeOnDelete();
                $table->foreignId('product_id')->constrained('products');
                $table->string('product_name');
                $table->integer('quantity')->default(1);
                $table->decimal('price', 10, 2);
                $table->decimal('total', 10, 2);
                $table->timestamps();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('order_items');
        Schema::dropIfExists('orders');
        Schema::dropIfExists('products');
        Schema::dropIfExists('categories');
    }
};
