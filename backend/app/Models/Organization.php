<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Organization extends Model
{
    protected $guarded = [];

    public function businessGroup()
    {
        return $this->belongsTo(BusinessGroup::class);
    }

    public function branches()
    {
        return $this->hasMany(Branch::class);
    }
}
