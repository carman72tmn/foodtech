<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Category;
use App\Models\Product;
use App\Models\Order;
use App\Models\OrderItem;

class FoodTechSeeder extends Seeder
{
    public function run()
    {
        $pizza = Category::create([
            'name' => 'Пицца',
            'description' => 'Вкусная пицца',
            'sort_order' => 1
        ]);

        $sushi = Category::create([
            'name' => 'Суши',
            'description' => 'Свежие суши',
            'sort_order' => 2
        ]);

        Product::create([
            'name' => 'Маргарита',
            'description' => 'Классика',
            'price' => 450.00,
            'category_id' => $pizza->id,
            'is_available' => true
        ]);

        Product::create([
            'name' => 'Пепперони',
            'description' => 'Острая',
            'price' => 550.00,
            'category_id' => $pizza->id,
            'is_available' => true
        ]);

        Product::create([
            'name' => 'Филадельфия',
            'description' => 'С лососем',
            'price' => 600.00,
            'category_id' => $sushi->id,
            'is_available' => true
        ]);

        $order = Order::create([
            'telegram_user_id' => 123456,
            'customer_name' => 'Test User',
            'customer_phone' => '+79990000000',
            'delivery_address' => 'Test Address',
            'total_amount' => 1000.00,
            'status' => 'new'
        ]);
        
        // Items logic would go here
    }
}
