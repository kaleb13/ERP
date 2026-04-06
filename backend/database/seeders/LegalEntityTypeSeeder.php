<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class LegalEntityTypeSeeder extends Seeder
{
    public function run(): void
    {
        DB::table('legal_entity_types')->insert([
            ['name' => 'PLC', 'abbreviation' => 'PLC', 'type' => 'Private', 'state' => 'active', 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Share Company', 'abbreviation' => 'S.C.', 'type' => 'Private', 'state' => 'active', 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Sole Proprietorship', 'abbreviation' => 'S.P.', 'type' => 'Private', 'state' => 'active', 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'NGO', 'abbreviation' => 'NGO', 'type' => 'Private', 'state' => 'active', 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Personal', 'abbreviation' => 'PERS', 'type' => 'Private', 'state' => 'active', 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Government', 'abbreviation' => 'GOV', 'type' => 'Government', 'state' => 'active', 'created_at' => now(), 'updated_at' => now()],
        ]);
    }
}
