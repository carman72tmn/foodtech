<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'price',
        'image_url',
        'category_id',
        'iiko_id',
        'is_available',
        'sort_order',
        'article',
        'weight_grams',
        'volume_ml',
        'calories',
        'proteins',
        'fats',
        'carbohydrates',
        'is_popular',
        'old_price',
        'max_discount_percent',
        'bonus_accrual_percent',
        'stop_list_branch_ids',
    ];

    protected $casts = [
        'is_available' => 'boolean',
        'price' => 'decimal:2',
        'old_price' => 'decimal:2',
        'is_popular' => 'boolean',
        'stop_list_branch_ids' => 'array',
        'weight_grams' => 'integer',
        'volume_ml' => 'integer',
        'calories' => 'integer',
        'proteins' => 'float',
        'fats' => 'float',
        'carbohydrates' => 'float',
        'max_discount_percent' => 'integer',
        'bonus_accrual_percent' => 'integer',
    ];

    public function category()
    {
        return $this->belongsTo(Category::class);
    }
}
