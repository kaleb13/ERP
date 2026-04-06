<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Legal Entity Types (PLC, NGO, etc.)
        Schema::create('legal_entity_types', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('abbreviation')->nullable();
            $table->enum('type', ['Private', 'Government'])->default('Private');
            $table->string('state')->default('active');
            $table->timestamps();
        });

        // 2. Entity Types (Business Group, Organization, etc.)
        Schema::create('entity_types', function (Blueprint $table) {
            $table->id();
            $table->string('name'); // e.g. "Business Group", "Organization", "Branch"
            $table->string('description')->nullable();
            $table->integer('level'); // hierarchy level
            $table->timestamps();
        });

        // 3. Main Entities Table (Hierarchical Nested Set Model)
        Schema::create('entities', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->string('name');
            $table->string('code')->unique();
            $table->foreignId('entity_type_id')->nullable()->constrained();
            $table->foreignId('parent_id')->nullable()->references('id')->on('entities')->onDelete('cascade');
            $table->string('path')->nullable();
            $table->integer('lft')->nullable();
            $table->integer('rgt')->nullable();
            $table->boolean('is_group')->default(false);
            $table->unsignedBigInteger('party_id')->nullable(); 
            $table->unsignedBigInteger('admin_unit_id')->nullable();
            $table->enum('pos_type', ['retail', 'hospitality', 'mixed'])->nullable();
            $table->string('abbreviation')->nullable();
            $table->boolean('has_detail')->default(false);
            $table->string('latitude')->nullable();
            $table->string('longitude')->nullable();
            $table->string('state')->default('active');
            $table->timestamps();
        });

        // 4. Entity Details
        Schema::create('entity_details', function (Blueprint $table) {
            $table->id();
            $table->foreignId('entity_id')->constrained()->onDelete('cascade');
            $table->foreignId('legal_entity_type_id')->nullable()->constrained();
            $table->string('logo')->nullable();
            $table->string('tin')->nullable();
            $table->string('vat_reg_number')->nullable();
            $table->date('vat_reg_date')->nullable();
            $table->string('email')->nullable();
            $table->string('phone')->nullable();
            $table->string('house_number')->nullable();
            $table->string('trade_name')->nullable();
            $table->string('legal_name')->nullable();
            $table->unsignedBigInteger('tax_center_id')->nullable();
            $table->integer('number_of_branches')->default(0);
            $table->integer('number_of_employees')->default(0);
            $table->date('date_established')->nullable();
            $table->boolean('is_primary')->nullable();
            $table->timestamps();
        });

        // 5. Outlets (Operational units)
        Schema::create('outlets', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->string('name');
            $table->foreignId('entity_id')->constrained()->onDelete('cascade');
            $table->string('state')->default('active');
            $table->timestamps();
        });

        // 6. Warehouse Types
        Schema::create('warehouse_types', function (Blueprint $table) {
            $table->id();
            $table->string('name'); // e.g. central, store_backroom...
            $table->string('code')->nullable();
            $table->string('status')->default('pending'); // pending, approved...
            $table->string('state')->default('active');
            $table->timestamps();
        });

        // 7. Warehouses
        Schema::create('warehouses', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->string('name');
            $table->unsignedBigInteger('admin_unit_id')->nullable();
            $table->string('longitude')->nullable();
            $table->string('latitude')->nullable();
            $table->foreignId('entity_id')->constrained()->onDelete('cascade');
            $table->foreignId('parent_warehouse_id')->nullable()->references('id')->on('warehouses')->onDelete('set null');
            $table->boolean('is_group')->default(false);
            $table->integer('level')->default(0);
            $table->boolean('has_shelf')->default(false);
            $table->boolean('has_bin')->default(false);
            $table->foreignId('warehouse_type_id')->constrained();
            $table->string('state')->default('active');
            $table->timestamps();
        });

        // 8. Shelves and Bins
        Schema::create('warehouse_shelves', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('tag')->nullable();
            $table->foreignId('warehouse_id')->constrained()->onDelete('cascade');
            $table->string('state')->default('active');
            $table->timestamps();
        });

        Schema::create('warehouse_bins', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('code')->nullable();
            $table->foreignId('warehouse_id')->constrained()->onDelete('cascade');
            $table->foreignId('warehouse_shelf_id')->nullable()->constrained()->onDelete('set null');
            $table->string('state')->default('active');
            $table->timestamps();
        });

        // 9. Employee and Customers
        Schema::create('employees', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('entity_id')->constrained()->onDelete('cascade');
            $table->unsignedBigInteger('party_id')->nullable();
            $table->timestamps();
        });

        Schema::create('customer_groups', function (Blueprint $table) {
            $table->id();
            $table->string('name'); // Wholesale, Retail...
            $table->string('status')->default('pending');
            $table->string('state')->default('active');
            $table->timestamps();
        });

        Schema::create('customers', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('entity_id')->constrained()->onDelete('cascade');
            $table->unsignedBigInteger('party_id')->nullable();
            $table->foreignId('customer_group_id')->constrained();
            $table->decimal('credit_limit', 15, 2)->default(0);
            $table->boolean('loyalty_enabled')->default(false);
            $table->string('state')->default('active');
            $table->timestamps();
        });

        // 10. Supporting tables (Pivot, Address, Sector, etc.)
        Schema::create('entity_sectors', function (Blueprint $table) {
            $table->id();
            $table->foreignId('entity_id')->constrained()->onDelete('cascade');
            $table->unsignedBigInteger('sector_id');
            $table->boolean('is_primary')->default(false);
            $table->string('state')->default('active');
            $table->timestamps();
        });

        Schema::create('entity_base_currencies', function (Blueprint $table) {
            $table->id();
            $table->foreignId('entity_id')->constrained()->onDelete('cascade');
            $table->unsignedBigInteger('base_currency_id');
            $table->string('state')->default('active');
            $table->timestamps();
        });
        
        // Costing rules
        Schema::create('entity_costing_rules', function (Blueprint $table) {
            $table->id();
            $table->foreignId('entity_id')->constrained()->onDelete('cascade');
            $table->string('costing_rule'); // FIFO, WAC
            $table->string('state')->default('active');
            $table->timestamps();
        });

    }

    public function down(): void
    {
        Schema::dropIfExists('entity_costing_rules');
        Schema::dropIfExists('entity_base_currencies');
        Schema::dropIfExists('entity_sectors');
        Schema::dropIfExists('customers');
        Schema::dropIfExists('customer_groups');
        Schema::dropIfExists('employees');
        Schema::dropIfExists('warehouse_bins');
        Schema::dropIfExists('warehouse_shelves');
        Schema::dropIfExists('warehouses');
        Schema::dropIfExists('warehouse_types');
        Schema::dropIfExists('outlets');
        Schema::dropIfExists('entity_details');
        Schema::dropIfExists('entities');
        Schema::dropIfExists('entity_types');
        Schema::dropIfExists('legal_entity_types');
    }
};
