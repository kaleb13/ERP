<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Business Groups
        $bgId = DB::table('business_groups')->insertGetId([
            'name' => 'Qelem Meda Investment Group',
            'abbreviation' => 'QMIG',
            'state' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $bgId2 = DB::table('business_groups')->insertGetId([
            'name' => 'Medirock Investment Group',
            'abbreviation' => 'MIG',
            'state' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 2. Organizations
        $orgId = DB::table('organizations')->insertGetId([
            'name' => 'Qelem Meda Solutions',
            'abbreviation' => 'QMS',
            'business_group_id' => $bgId,
            'pos_type' => 'mixed',
            'tin' => '0012345678',
            'email' => 'contact@qelemmeda.com',
            'state' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $orgId2 = DB::table('organizations')->insertGetId([
            'name' => 'Medirock Construction',
            'abbreviation' => 'MRC',
            'business_group_id' => $bgId2,
            'pos_type' => 'retail',
            'state' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 3. Branches
        $branch1Id = DB::table('branches')->insertGetId([
            'name' => 'Bole Main Branch',
            'organization_id' => $orgId,
            'is_primary' => true,
            'pos_type' => 'mixed',
            'state' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $branch2Id = DB::table('branches')->insertGetId([
            'name' => 'Kazanchis Branch',
            'organization_id' => $orgId,
            'is_primary' => false,
            'pos_type' => 'retail',
            'state' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 4. Branch Shops
        $shop1Id = DB::table('branch_shops')->insertGetId([
            'name' => 'Bole Electronics Shop',
            'branch_id' => $branch1Id,
            'pos_type' => 'retail',
            'state' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $shop2Id = DB::table('branch_shops')->insertGetId([
            'name' => 'Bole Service Center',
            'branch_id' => $branch1Id,
            'pos_type' => 'hospitality',
            'state' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 5. Outlets
        DB::table('outlets')->insert([
            ['name' => 'POS Terminal 01', 'branch_shop_id' => $shop1Id, 'state' => 'active', 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'POS Terminal 02', 'branch_shop_id' => $shop1Id, 'state' => 'active', 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Service Counter A', 'branch_shop_id' => $shop2Id, 'state' => 'active', 'created_at' => now(), 'updated_at' => now()],
        ]);

        // 6. Warehouses
        $wh1Id = DB::table('warehouses')->insertGetId([
            'name' => 'Central Storage A',
            'warehouse_type_id' => 'central',
            'is_group' => true,
            'has_shelf' => true,
            'has_bin' => true,
            'state' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $wh2Id = DB::table('warehouses')->insertGetId([
            'name' => 'Cold Storage 01',
            'parent_warehouse_id' => $wh1Id,
            'warehouse_type_id' => 'cold_storage',
            'state' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 7. Shelves & Bins
        $shelfId = DB::table('warehouse_shelves')->insertGetId([
            'name' => 'Section A - Electronics',
            'tag' => 'SEC-A',
            'warehouse_id' => $wh1Id,
            'state' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('warehouse_bins')->insert([
            ['name' => 'Bin 01 - Mobile Units', 'code' => 'A1-01', 'warehouse_id' => $wh1Id, 'warehouse_shelf_id' => $shelfId, 'state' => 'active', 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Bin 02 - Tablets', 'code' => 'A1-02', 'warehouse_id' => $wh1Id, 'warehouse_shelf_id' => $shelfId, 'state' => 'active', 'created_at' => now(), 'updated_at' => now()],
        ]);
    }
}
