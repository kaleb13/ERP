<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class EntityTypeSeeder extends Seeder
{
    public function run(): void
    {
        DB::table('entity_types')->insert([
            ['name' => 'Business Group', 'level' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Organization', 'level' => 2, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Branch', 'level' => 3, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Branch Shop', 'level' => 4, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Outlet', 'level' => 5, 'created_at' => now(), 'updated_at' => now()],
        ]);

        DB::table('warehouse_types')->insert([
            ['name' => 'Central', 'code' => 'CENT', 'state' => 'active', 'status' => 'approved', 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Store Backroom', 'code' => 'SBAK', 'state' => 'active', 'status' => 'approved', 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Kitchen Store', 'code' => 'KIST', 'state' => 'active', 'status' => 'approved', 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Cold Storage', 'code' => 'COST', 'state' => 'active', 'status' => 'approved', 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Wastage Storage', 'code' => 'WAST', 'state' => 'active', 'status' => 'approved', 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Transit Storage', 'code' => 'TRAN', 'state' => 'active', 'status' => 'approved', 'created_at' => now(), 'updated_at' => now()],
        ]);
    }
}
