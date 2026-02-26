<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    use HasFactory;

    protected $fillable = [
        'telegram_user_id',
        'telegram_username',
        'branch_id',
        'customer_id',
        'customer_name',
        'customer_phone',
        'delivery_address',
        'total_amount',
        'bonus_spent',
        'total_discount',
        'promo_code_id',
        'status',
        'iiko_order_id',
        'comment',
    ];

    protected $casts = [
        'total_amount' => 'decimal:2',
        'bonus_spent' => 'decimal:2',
        'total_discount' => 'decimal:2',
        'created_at' => 'datetime',
    ];

    public function items()
    {
        return $this->hasMany(OrderItem::class);
    }
}
