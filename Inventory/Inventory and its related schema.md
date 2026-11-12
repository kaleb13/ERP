## 1. Custom Field Engine

	### ModelLists -- central registry of “who supports custom fields”
		- id
		- model            -- product, party, order, locationType
		- code             -- location, product, order
		- target_model_id  -- if it is null the custom field values is the model it slef , if it is not null the fields is for this target model
		- entity_id        --  null if it is tenant spesfic..
		- status_lookup_value_id  -- pending ... if it has entity_id
		- state

	### CustomField --- Defines metadata for dynamic fields.
		- id 
		- uuid — Unique identifier
		- model_list_id — Target model (location Type, product, party, order)
		- record_id       -- nullable for spesfic records instead of model
		- name_key — System key (temperature, loyalty_level)
		- label — Display name ---jsonb
		- language_supported --- boolean default false 
		- data_type — string, number, boolean, date, array, select, multiselect, json
		- is_required — Field is mandatory
		- default_value — Default value (nullable)
		- option_source_type
		- option_source_config
		- validation_rule — Validation logic { min: 1, between: [1,2] } [Rule::min(1), Rule::between([1,2])]
		- format -- jsonb
		- ui_component — input, select, toggle, date, radio, che..., textarea
		- entity_id —  null if it is tenant spesfic..
		- status_lookup_value_id — pending ... if it has entity_id
		- state — system state

	### CustomFieldOption --- Defines selectable values for fields of type "select" and "multiselect".
		- id 
		- custom_field_id — FK to CustomField
		- key — Stored value (gold, silver)
		- label — Display label -- jsonb
		- sort_order — Ordering
		- is_active — Active flag


	### CustomFieldValue --- Stores actual values for entities.
		- id 
		- custom_field_id — FK to CustomField
		- model_id    — the model that triger the fields, index
		- target_model_id - the actual model that holds the values for the fields, index
		- recored_id — Record ID, index
		- value JSONB - GIN INDEX

## 2. Lookup Tables 

	--- A lookup table is a small, static (or rarely changing) table that stores predefined values used by other tables.

	### LookupType --- Defines the category (like PosType, OrderStatus, etc.)
			- id                                                     
			- code                              -- Unique system code (OrderStatusType, ItemType)              
			- name                              -- Human readable name                                         
			- desctiption                       -- Human readable descritption                                 
			- applies_to_model                  -- JSON array of allowed entities (order, product, stock, etc.)                      
			- is_system                         -- TRUE = core system lookup (cannot delete)                   
			- entity_id                         -- Optional: tenant/entity-specific                            
			- status_lookup_value_id            -- pending                                                     
			- state                            -- active/inactive  
				
		### LookupValue --- Stores actual values
			- id                           
			- lookup_type_id                  -- FK → LookupType                      
			- code                            -- System value (e.g. draft, confirmed) 
			- name                            -- Default label json                   
			- color                           -- UI color (optional)                  
			- icon                            -- UI icon (optional)                   
			- order                           -- Display order                        
			- is_default                      -- Active flag, only ONE default per LookupType (enforce constraint) 
			- entity_id                       -- for entity spesfic       
			- status_lookup_value_id          -- pending for entity spesfic                 
			- state                           -- activ/inactive    

		### LookupTransition  -- Prevents invalid operations
			- id             
			- lookup_type_id --  FK → LookupType  
			- from_value_id  --  FK → LookupValue 
			- to_value_id    --  FK → LookupValue   
			- state          -- active/inactive 

## 2  Workflow and Approval --- work flow and approval for every ERP modules 
		### Workflow -- Defines configurable approval and operational workflow structures.
			- id                           
			- uuid
			- code
			- name
			- lookup_type_id           -- FK LookupType (like OrderStatus, etc.)
			- entity_id                -- entity spesfic work flow
			- description nullable
			- state

		### WorkflowStep --- Defines sequential approval or review stages within a workflow.
			- id
			- uuid
			- workflow_id
			- lookup_value_id      --- steps in this workflow
			- order                --- order of approval          
			- role_id              --- assing this step to spesfic role 
			- user_id              --- assing this step to spesfic user 
			- is_required BOOLEAN
			- state 
## 3 Icon Engine --  a centralized icon library where icons are grouped and reusable across multiple modules
	
		#### IconGroup
			- id
			- uuid
			- name -- group name for the icon
			- description
			- state         -- active, inactive
			
		### Icon
			- id            --  Primary key                        
			- uuid          --  Unique identifier                  
			- name          --  Icon name                          
			- group_id      --  FK → icon_groups   
			- lookup_type_id -- svg / image / url --- statically define function to return their value and display based on their type            
			- svg_content   --  Full SVG string (nullable)         
			- image         --  Stored image path or CDN link      
			- url           --  External icon URL                  
			- view_box      --  SVG viewBox (important for scaling)
			- width         --  Default width                      
			- height        --  Default height                     
			- tags          --  Search tags                        
			- state         --  active / inactive 

## 3. Brand, Measurement, Item & Product Management

	##3.1 Brand and Measurement

		### Brand
			- id
			- uuid
			- name
			- code
			- description (nullable)
			- logo_url (nullable)
			- entity_id (nullable)  -- if you allow custom brand per tenant
			- status_lookup_value_id -- pending, acceptForAll, acceptForThis
			- state BOOLEAN 
			
		### MeasurementCategory --- measurement category .
			- id 
			- name -- like mass, tempreture, current, liquid
			- state

		### Measurement --- list of possible measurement .
			- id
			- uuid
			- name            (Kilogram, Piece, Liter)
			- name_plural     (Kilograms, Piecies, Liters)
			- symbol          (kg, pcs, l)
			- measurement_category_id
			- is_enabled_for_sale --- in order to be compatable with the MoR set true ... !!!!!!!!!
			- has_decimal_support --- boolean to check the measurement accept decimal values or not
			- code --- unique 3 digit string to communicate with EIMS(Electronic invoicing management system)
			- entity_id --- measurement registered by enitity
			- status_lookup_value_id -- pending, acceptForAll, acceptForThis
			- state -- active / in active

		### MeasurementConversion --- Universal unit relationships across system, NOT packaging. Defines conversion rules between measurements. its physics
			- id
			- from_measurement_id (measurements.id)
			- to_measurement_id   (measurements.id)
			- conversion_rate (number of TO-units that make up one FROM-unit)			
			- entity_id --- measurement registered by enitity
			- status_lookup_value_id -- pending, acceptForAll, acceptForThis
			- user_id
			- state

	##3.2 Item

		### ItemCategory --- Hierarchical categorization of items.
			- id
			- uuid
			- name
			- code 
			- level
			- is_group -- if it is true  not avialiabe in item register category dropdown list
			- parent_id (item_categories.id, nullable)
			- state

		### ItemCategoryBrand 
			- id
			- brand_id
			- item_category_id
			- state

		### Item --- Generic definition of what is being sold or consumed.
			- id
			- uuid
			- name
			- item_category_id (item_categories.id)
			- type_lookup_value_id ('goods','service')
			- entity_id      --- entity spesfic item		
			- status_lookup_value_id -- pending, acceptForAll, acceptForThis
			- state --- active, deactive

		### ItemMeasurements --- Possible item measurements
			- id
			- item_id
			- measurement_id
			- entity_id      --- entity spesfic item measurement		
			- status_lookup_value_id -- pending, acceptForAll, acceptForThis
			- state

	##3.3 Product
		### Batch -- Batch/Serial/Expiry = Instances created during StockIn
			- id
			- uuid
			- batch 001
			- entity_id       -- entity spesfic batch		
			- status_lookup_value_id -- pending, acceptForAll, acceptForThis
			- state

		### ProductAttribute    --- Defines configurable attributes for both pos types .
			- id (PK)                 
			- name                         -- Size, Color, Flavor, Temperature, Gender 
			- input_type                   -- text | number | boolean | select 
			- applied_lookup_value_id      -- 'variant_only', 'product_only', 'both'
			- ui_component                 -— input, select, toggle, date, radio, che..., textarea, colorpicker  !!!!!!!!!
			- entity_id                    -- entity based attributes		
			- status_lookup_value_id       -- pending, acceptForAll, acceptForThis
			- state 

		### ProductAttributeValue --- Allowed values for an attribute if it's type is select and multiselect.
			- id (PK)
			- product_attribute_id (FK)
			- value                 -- Small, Medium, Large, XL / Red / Blue, Male, Female
			- order                 -- display order !!!!!!!!!
			- entity_id             -- entity based attribute values	
			- status_lookup_value_id       -- pending, acceptForAll, acceptForThis
			- state

		### ProductGroup  --- Sales filtering, POS quick buttons, Reports, Discounts, Category analytics
			- id
			- uuid
			- name
			- level
			- parent_id (productGroups.id, nullable)
			- is_group -- if it is true  not avialiabe in product register product group dropdown list
			- entity_id      --- entity spesfic product group		
			- status_lookup_value_id -- pending, acceptForAll, acceptForThis
			- state

		### EntityProductGroup
			- product_group_id
			- entity_id
			- state -- active / inactive

		### Product    --- Organization based product list .
			- id
			- uuid
			- code
			- name
			- sku                     -- internal sellable code TSRM
			- barcode                 -- scanned identity
			- color --- for easy access during sale
			- item_id (items.id)
			- entity_id
			- product_group_id (productGroups.id)
			- parent_id    -- NULL = main product, NOT NULL = variant
			- product_type --- Direct Sale, Bundle, Combo
			- bussiness_lookup_value_id -- Sale, Purchase, Both Sales and Purchase
			- attribute_values json ---  for easily access or cache
			- is_fixed_asset  BOOLEAN
			- has_serial_number  BOOLEAN
			- has_warranty  BOOLEAN
			- is_variant  BOOLEAN         --- if true the product itself is a variant
			- measurement_id ---  BASE INVENTORY UNIT, default_measurement_id, if is_variant is true. All stock is stored in base units; all sales are converted to base units before inventory changes.
			- brand_id (FK brands.id) 
			- has_alternative BOOLEAN --- if it is true register alternative produts
			- has_ingredient BOOLEAN --- if it is true register ingredients --- like piza has_ingredient == true is_localy_produced == false
			- is_localy_produced BOOLEAN --- for localy produced item  --- like paty has_ingredient == is_localy_produced == true
			- is_for_all_variants BOOLEAN --- the properties here applied to all variants under this product 
			- is_tax_included BOOLEAN --- set price with tax or without tax 
			- track_stock BOOLEAN --- Should this product affect inventory 
				--- null for product with is_variant true,  if is_for_all_variants true in parent products
			- track_batch BOOLEAN --- Do we track lot/batch for this product?
			- track_expiry BOOLEAN --- Does this product expire?
			- is_transferable BOOLEAN ---
			- costing_rule --- to give spesfic consting rule per product
			- state

		### ProductVariantOption --- Links variant to attribute values.
			- id (PK)
			- product_id (FK) TSRM
			- product_attribute_value_id (FK)  --- if the product variant value is from select option
			- product_attribute_id (FK)        -- if product_attribute_value_id is null this product_attribute_id should have values  !!!!!!!!!
			- value                            --- if the value is custom like color, temperature  when product_attribute_id is not null !!!!!!!!!
			- attachment				       -- If the attribute value has any image
			- state

		### ProductIngredient --- What inventory items are consumed to produce ONE menu item for pos hospitality only?
			- id (PK)
			- menu_product_id   -- the Pizza, Paty variant being produced
			- ingredient_product_id --  Flour, Cheese, Tomato, Paty
			- quantity_required
			- measurement_id (FK)
			- waste_percent (nullable)     -- Cooking loss %
			- use_alternative BOOLEAN      --  if it is true register on product_ingredient_alternative
			- is_optional BOOLEAN          -- Optional ingredient
			- state

		### ProductAlternative
			- id
			- from_product_id
			- to_product_id
			- state -- active / inactive

		### ProductIngredientAlternative
			- id (PK)
			- menu_product_ingredient_id   -- the Cheese, Tomato
			- product_alternative_id    --  CheeseAlt, TomatoAlt
			- quantity_required
			- measurement_id (FK)
			- waste_percent (nullable)     -- Cooking loss %
			- is_optional BOOLEAN          -- Optional ingredient
			- state

		### ProductModifier --- Optional add-ons selectable at POS for pos type hospitality. Which product allow which product.
			- id
			- uuid
			- name              -- Extra cheese, Extra sauce
			- entity_id         --- entity spesfic modifier		
			- status_lookup_value_id   -- pending, acceptForAll, acceptForThis
			- state

		### ProductModifierItem --- Optional add-ons selectable at POS for pos type hospitality. Which product allow which  product.
			- id (PK)
			- product_modifier_id	   -- Extra cheese
			- base_product_id        -- Pizza, Burger
			- added_product_id       -- Cheese
			- state

		### ComboBundleConfig
			- id
			- uuid
			- name                      --- Smartphone Package
			- product_id                -- main salable item (bundle/combo product) Smartphone Package, BreakFast Combo
			- type_lookup_value_id      -- bundle | combo
			- base_price null           -- base selling price for combo
			- state

		### ComboBundleGroup -- combo choice + product group name 
			- id
			- uuid
			- name --- hot, pastry
			- free_item_quantity -- same amount with  max_item_quantity if type bundel
			- max_item_quantity -- same amoutn with free_item_quantity if type bundle
			- state

		### ComboBundleConfigGroup -- possible choice for combo and 1 row for a single product bundle 
			- id
			- uuid
			- bundle_config_id
			- bundle_group_id
			- state

		### ComboBundleItem
			- id
			- uuid
			- bundle_group_id
			- product_id
			- extra_price null  -- for combo, null if it is bundle
			- quantity null  -- for bundle, null if it is combo
			- default -- main product to make it bundle or combo
			- state

		### ProductBrand
			- id 
			- brand_id
			- product_id
			- state

		### ProductMeasurement --- Possible product measurement
			- id
			- product_id (products.id)
			- measurement_id (measurements.id)
			- state

		### ProductMeasurementConversion --- get products possible conversion rate
			- id
			- product_id
			- measurement_conversion_id
			- state

		### EntityProduct --- to know products sold in a spesfic shope
			- id
			- entity_id
			- product_id
			- state

		### WarrantyType
			- id
			- name
			- description
			- entity_id  -- for which entity this belongs
			- status_lookup_value_id -- pending
			- state

		### WarrantyTypeHistory
			- id
			- name
			- warranty_type_id
			- entity_id  -- for which entity this belongs
			- status_lookup_value_id -- pending
			- description
			- state

		### ProductWarrantyPeriod
			- id
			- product_id
			- warranty_type_id
			- days

		### ProductWarranty   
			- id
			- product_id
			- warranty_type_history_id
			- customer_id
			- type_lookup_value_id -- invoice / order, manual, repair
			- source_id nullabe
			- source_line_id
			- start_date
			- end_date
			- state

		### ProductBatch -- State (current reality) → what exists now in stock with spesfic batch
			- id
			- uuid
			- product_id
			- location_id
			- batch_id -- actual batch (B001)
			- serial_no -- one serial per row (nullable)
			- expiry_date -- actual expiry
			- manufactured_date
			- quantity
			- updated_at
			- state

		### Product Media ????
			- id
			- product_id
			- type_lookup_value_id (image, video, url, document)
			- value -- nullable use it for url 
			******* if the type is image, document, video
				- file_name      -- original file name
				- file_path      -- storage path (e.g., /uploads/products/img1.jpg)
				- extension      -- jpg, png, webp
				- size           -- file size
			******* end *******
			- is_primary     -- for display in menue or on the web
			- state

		### ProductInventoryPolicy --- feature for procurement
			- id
			- product_id 
			- entity_id  -- for which entity this belongs nullable
			- location_id  nullable    --- location where the rule applies
			- reorder_level	          ---level that triggers reorder
			- reorder_quantity          -- recommended purchase quantity
			- min_order_quantity        -- not allowed to order quantity less than
			- minimum_stock_level	      --- lowest allowed inventory before the system blocks operations.
			- maximum_stock_level	      --- maximum storage capacity
			- safety_stock	          --- extra stock reserved to protect against uncertainty.emergency level 
			- lead_time_days	          --- number of days supplier takes to deliver / supplier lead time
			- state
	
## 4. Stock Operation, Document / Voucher --- The systems organize location operations using standard business documents that control procurement, stock movement, sales, and inventory adjustments.
	
	##4.1 Document
		### DocumentType / VoucherType
			- id
			- uuid
			- code -- GRN, SIV, TRANSFER, ADJUSTMENT, WASTE, IWGP, OWGP, STS, GRN sufix-prifix based on location while using doc number
			- name -- Goods Receiving Note, Store Issue Voucher, Transfer Voucher, Stock Adjustment, Waste Voucher, INWARD Gate Pass / OUTWARD Gate Pass, Stock Taking Session, cash sales, credit sales, Credit Note, Debit Note, Sales Invoice...
			- description -- nullable Explanation of document purpose
			- affects_stock BOOLEAN -- like Quality & Compliance Documents like Inspection report, Quality approval, Compliance certificate may not affect 
			- affects_finance BOOLEAN -- like sales document may affect 
			- requires_approval BOOLEAN -- Whether approval workflow is needed
			- entity_id -- nullable but entity can define their document type
			- is_system --- predefined during dev..
			- allowed_digit --- doocument sequence digit 
			- posting_lookup_value_id --- AUTO, MANUAL, SCHEDULED
			- status_lookup_value_id --- pending, approved_for_entity, approved_for_all, reject
			- workflow_id            --- set default approval work flow
			- state

		### ModuleDocumentType -- entity may use documents based on their usage so that they can set first.
			- id
			- module_id
			- document_type_id			
			- entity_id -- nullable but entity can define their document type
			- status_lookup_value_id --- pending, approved_for_entity, approved_for_all, reject
			- state

		### OperationDocumentType -- entity may use documents based on their operations so that they can set first.
			- id
			- document_type_id
			- operation_lookup_value_id ---IN, OUT, TRANSFER_IN, TRANSFER_OUT, ADJUSTMENT, StockTaking...
			- entity_id -- nullable but entity can define their document type
			- status_lookup_value_id --- pending, approved_for_entity, approved_for_all, reject
			- state

		### DocumentSequence  -- Controls document numbering (prefix, suffix, running number).????
			- id      
			- uuid                          
			- document_type_id         -- document type                     
			- entity_id                -- Organization/tenant               
			- location_id              -- Optional location-based numbering 
			- prefix                   -- Beginning of document number      
			- suffix                   -- Ending part (optional)            
			- current_number           -- Last used number                  
			- reset_lookup_value_id    -- yearly / monthly / never , need static function to reset sequence
			- fiscal_year_id           -- nullable 
			- last_reset_at            -- nullable     
			- state                    -- active / inactive   

		### Document -- This is the central document table used by all operations. It represents every business document. ????
			- id                         
			- uuid                    --  Global unique ID          
			- document_number         --  Generated unique number / from document sequence  
			- document_type_id        --  Type of document          
			- entity_id               --  Tenant/company            
			- location_id             --  Where operation happens   
			- document_id             --  if there is a parent document to initiate this document        
			- reference_no            --  add external system reference / manual referench that you have
			- document_date           --  Business date             
			- posting_date            --  Accounting/posting date 
			- status_lookup_value_id  --  draft / comepleted / posted / cancelled
			- posting_lookup_value_id -- unposted, posted, reversed
			- created_by              --  User who created          
			- approved_by             --  User who approved   
			- can_referenced          -- act as a reference for other documents      
			- remarks                 --  Additional notes      

		# DocumentApproval -- Tracks approval actions performed against documents.
			- id
			- uuid
			- document_id
			- workflow_step_id
			- user_id               --- nullable
			- remarks nullable
			- approved_at nullable

		### DocumentAttachment -- one docuemt may have many attachments. ????
			- id
			- document_id
			- type_lookup_value_id (image, video, url, document)
			- value -- nullable use it for url 
			******* if the type is image, document, video
			- file_name      -- original file name null if it is url
			- file_path      -- storage path (e.g., /uploads/products/img1.jpg) null if it is url
			- extension      -- jpg, png, webp null if it is url
			- size           -- file size null if it is url
			******** end ******
			- state          --- hide the attachement 

	##4.2 Stock Operation

		### StockSummary --- unique for product in one location, Cached current stock (derived from ledger).Summary , calculated balance
			- id
			- uuid
			- product_id (products.id)
			- product_batch_id nullabe          -- inorder to know by wich batch 
			- measurement_id                    -- deafult inventory measurement  ????
			- entity_id                         --- for which entity this summary belongs to 
			- location_id (locations.id)        --- in which location
			- physical_qty	                    -- Total items of this batch currently on the shelf.
			- reserved_qty	                    -- Items of this specific batch allocated to pending orders.
			- available_qty	                    -- physical_qty - reserved_qty. This is what the POS or Web app sees
			- unit_cost                         -- current cost of the product based on entity costing rule
			- updated_at
			- state

		### InventoryValuationLayer -- It tells us how many units we have, what each cost, and how much is left . by using costing rule ????
			- id 
			- uuid             
			- product_id              -- Reference to the specific product variant
			- product_batch_id        -- Batch (nullable)
			- location_id             -- Warehouse where this stock is located
			- measurement_id          -- by which measurement the taking session conducted
			- quantity                -- Quantity added or removed in this layer
			- unit_cost               -- Cost per unit for this batch/operation
			- total_cost              -- Total cost = quantity * unit_cost
			- remaining_qty           -- Quantity remaining in stock from this layer
			- document_id             -- by which document this valuation updated, by sales , by other stock operations ....  as a reference   
			- state                   -- active and inactive , if it is active it shows the current valuatin layer for that spesfic product

		### StockOperation
			-- for IN  .. physically receiving goods into a location(Supplier delivers goods, Internal transfer arrives, Opening stock is entered). Stock receiving header. “Receiving Note / GRN (Goods Receipt Note)” -> When?, Where?, Overall status?
			-- for OUT ..Issuing / Consumption 
			-- for Transfer .. Warehouse-to-location movement.
			-- For Adjustment ..What is physically in the location does NOT match what the system stays
			-- reason_lookup_value_id, status_lookup_value_id may be depend on operation_lookup_value_id, 
			- id                       
			- uuid  
			- barcode	
			- name                      -- nullable but we can give name for our operation
			- document_id               -- Reference to Document
			- operation_lookup_value_id --- STOCK_IN, STOCK_OUT, TRANSFER_IN, TRANSFER_OUT, ADJUSTMENT_PLUS, ADJUSTMENT_MINUS
			- entity_id                 -- Tenant
			- source_location_id        -- From location (nullable)
			- destination_location_id   -- To location (nullable) for transfer 
			- operation_date            -- Business date, stock in date, transfer date, adjustment date....
			- posting_date              -- Accounting date, if it is posted to accounting module else nulll
			- reason_lookup_value_id    -- in, sale, damage, expired, internal_use / used for stock out, adjustment operation
			- status_lookup_value_id    -- draft, initiated, completed, pending, completed, posted, cancelled, rejected
			- remarks                   -- Notes
			- created_by                -- User
			- approved_by               -- User


		### StockOperationLine
			- id             
			- stock_operation_id   -- Parent operation
			- product_id           -- Product
			- product_batch_id     -- Batch (nullable)
			- quantity             -- Quantity
			- unit_cost            -- nullable Cost per unit
			- total_cost           -- nullable Total cost
			- measurement_id       -- Unit of measure
			- system_qty           --- nullable it's important for adustment 
			- physical_qty         --- nullable it's important for adustment 
			- difference           --- nullable it's important for adustment 
			- supplier_id               --- nullable , supplier may be the orginazation it self or any other suppliers example paty produced by them selves or other org
			- state                -- active

		### StockOperationBatch -- when we insert data to this table we have to update the quantity or register as new in product batch table.
			- id                        
			- stock_operation_line_id   -- Parent line 
			- batch_id                  -- Batch 
			- serial_no                 -- Serial (nullable) 
			- expiry_date               -- Expiry 
			- manufactured_date         -- MFG date 
			- quantity                  -- Quantity 
			- system_qty                --- nullable it's important for adustment 
			- physical_qty              --- nullable it's important for adustment 
			- difference                --- nullable it's important for adustment 
			- state

		### StockOperationPrice 
			-- product price in different measurement during stock in if they use sales module 
			-- when we set price during stock in the system fetch price from price list items with that product id with corresponding measurement so we can update or set other price and save at the same time on this table and on price list item with base price category.
			- id
			- uuid                   
			- stock_operation_line_id   -- Parent line
			- unit_price 				-- Conditional
			- measurement_id 			-- Conditional
			- state

		### StockLedger
			- id                       
			- product_id                            --  Product
			- product_batch_id nullabe
			- measurement_id                        -- deafult inventory measurement  ????
			- entity_id                             --- the one who ledger this row
			- location_id                           --  Location
			- operation_lookup_value_id             ---IN, OUT, TRANSFER_IN, TRANSFER_OUT, ADJUSTMENT ....
			- quantity                              --  + or -
			- unit_cost                             --  Cost
			- total_cost                            --  Total
			- unit_price nullable                   -- stock out by sales 
			- total_price nullable                  -- stock out by sales 
			- stock_operation_id                    --  Link to operation
			- inventory_valuation_layer_id          -- the cost associated with this movement.

		### StockReservation --- reserved or draft item order should be register here 
			- id
			- entity_id                             --- for which entity this belongs to                       
			- location_id
			- product_id                            --  Product
			- product_batch_id                      -- nullabe
			- measurement_id                        -- deafult inventory measurement
			- quantity
			- document_id                          -- document that trigger this reservation
			- state                                -- if it is inactive the product is not reserved by this quantity

		### GatePass --- Government, Manufacturing ...The purpose is physical control of inventory movement.
			- id
			- uuid
			- barcode
			- document_id	
			- entity_id		
			- gatepass_type_lookup_value_id  -- inward, outward	
			- source_location_id                 -- From location (nullable)
			- destination_location_id            -- To location (nullable) for transfer 
			- driver_name nullable
			- plate nullable                     -- bemekina techino emiweta kehone
			- issued_to                          --- receiver from users table 
			- issued_by                          --- staff initiate document, from users table
			- issued_at
			- state

		### GatePassLine  --- product list with measurement and quantity for a single gate pass ????
			- id
			- quantity
			- gatepass_id
			- measurement_id
			- product_id nullabe (products.id)
			- product_batch_id nullabe
			- state

		### StockTakingSession --- Physically counting the real quantity of products in the location and comparing it with the quantity recorded in the ERP system.
			- id
			- uuid
			- barcode	
			- name -- January Warehouse Stock Count
			- document_id
			- location_id
			- started_at
			- completed_at
			- conducted_by --- a person who taking the session from users table 
			- approved_by  --- a person who approved taking session from users table 
			- remarks
			- state

		### StockTakingLine --- each product counted during stock taking
			- id
			- uuid
			- stock_taking_session_id
			- product_id                       -- nullable
			- product_batch_id nullabe
			- measurement_id                   -- by which measurement the taking session conducted, use default measurement for inventory operation ????
			- system_quantity
			- counted_quantity
			- difference_quantity             -- contain negative value, and needs adjustment 
			- adjustment_required BOOLEAN
			- reason
		
## 5. Loyalty, Promotion & Pricing Management

	##5.1 Loyalty

		### Tier 
			- id 
			- name             -- Tier name (Silver, Gold, Platinum)
			- icon
			- color 
			- entity_id -- nullable but entity can define their Tier
			- status_lookup_value_id --- pending, approved_for_entity, approved_for_all, reject

		### LoyaltyTier --- Defines loyalty levels configured per entity.
			- id (PK)     
			- tier_id          ---tier 
			- entity_id        -- Specific owner ID
			- min_points       -- Minimum points required to enter this tier
			- max_points       -- Maximum points allowed in this tier (NULL = unlimited)
			- state            -- active / inactive

		### CustomerLoyaltyAccount --- Stores each customer’s current loyalty status.
			- id
			- uuid
			- code                 -- loyality-access or apply madregiya pin                       
			- customer_id          -- Customer owning this loyalty account
			- entity_id            -- if loyality is for entity
			- loyalty_tier_id      -- Current tier of the customer
			- total_points         -- Total earned points (lifetime)
			- available_points     -- Points currently usable (after expiration & redemption)
			- expired_points       -- Total expired points
			- state                -- active / inactive
			- updated_at           -- Last points update timestamp

		### LoyaltyPointLedger ????
			- id
			- uuid
			- customer_loyalty_account_id  -- Reference to customer loyalty account
			- type_lookup_value_id         -- EARN | REDEEM | EXPIRE | ADJUST
			- points                       -- Positive (earn) or negative (redeem/expire)
			- document_id                  -- reference document to earn or redeem .. ???
			- expiry_date                  -- When these points expire (NULL = never expires)
			- description                  -- Explanation of transaction

		### LoyaltyRule --- Defines how customers earn loyalty points.
			- id (PK)    
			- name                 -- rule name
			- entity_id            -- entity
			- currency_id          -- Currency used for calculation (ETB, USD)
			- type_lookup_value_id -- PER_AMOUNT | PER_PRODUCT | PER_CATEGORY | PER_GROUP
			- amount_base          -- Base spending amount (e.g., 100 ETB)
			- points_per_amount    -- Points earned per amount_base 
			- product_id           -- Optional: specific product rule
			- item_category_id     -- Optional: category rule
			- product_group_id     -- Optional: group rule
			- start_date           -- Rule activation date
			- end_date             -- Rule expiration date
			- state                -- active / inactive

		### LoyaltyConversionRule
			- id
			- entity_id           -- entity
			- currency_id         -- Currency for redemption
			- type_lookup_value_id -- MONEY | PRODUCT
			- point_value         -- Value of 1 point in currency (e.g., 1 point = 0.1 ETB)
			- product_id          -- If PRODUCT redemption (gift item)
			- points_required     -- Points required to redeem product
			- start_date          -- Rule activation date
			- end_date            -- Rule expiration date
			- state               -- active / inactive

		### LoyaltyRedemption ????
			- id
			- customer_loyalty_account_id  -- Customer performing redemption
			- conversion_rule_id           -- Applied conversion rule
			- points_used                  -- Points consumed
			- redeemed_value               -- Monetary value or product equivalent
			- document_id                  -- reference document to earn or redeem .. ???
			- status                       -- pending | completed | cancelled  

	##5.2 Price

		### price_lists --- Defines pricing strategies and who they apply to.
			- id
			- uuid  
			- code                            ---  short code for pricing
			- name                            -- Price list name (Retail, VIP, Promotion) Abebe's price 
			- description                     -- Optional explanation
			- owner_entity_id                 -- price owner       
			- currency_id (FK) 	              -- Currency used for pricing
			- loyalty_tier_id (nullable FK)   -- Applied automatically for loyalty tier
			- customer_id (nullable FK)       -- Specific customer contract pricing
			- customer_group _id              -- retail, wholesale
			- buyer_entity_id (nullable FK)   -- Corporate/company contract pricing, Branch-specific pricing
			- start_date ()                   -- Promotion start date
			- end_date (nullable)             -- Promotion expiry date
			- priority INTEGER DEFAULT 1      -- Higher value overrides lower priority, it is not from form so that calculated from other price lists.
			- is_base BOOLEAN DEFAULT FALSE   -- (only one allowed active price list per entity) - Default system price list
			- state BOOLEAN                   -- Enables/disables price list

		### PriceListItem --- Defines product pricing rules inside a price list. it may come from inventory operation price during stock in by defualt price list ..
			- id (PK) 
			- uuid
			- price_list_id (FK)          -- Parent price list
			- product_id (FK)             -- Product being priced slk
			- measurement_id (FK)         -- Unit of sale (Piece, KG, Carton, der)
			- min_quantity DECIMAL        -- Minimum quantity for rule activation .. by default 1 for salling items 
			- max_quantity (nullable)     -- Maximum quantity (NULL = unlimited) 
			- lookup_value_id             -- FIXED | DISCOUNT | MARGIN
			- value DECIMAL               -- Price or percentage depending on type
			- standard_cost nullable      --  Cost used for margin calculation / pricing_type MARGIN ... it comes from inventory valuations table by calculating valuation based on costing rule
			- state 

	##5.3 Promotion Management -- Dynamic campaign logic

		### Promotion --- promotion header / Defines the campaign.
			- id
			- uuid
			- name  
			- code nullable --- used for prom code one 
			- entity_id
			- lookup_value_id -- BUY_X_GET_Y, SPEND_THRESHOLD_GIFT, CATEGORY_DISCOUNT, PRODUCT_DISCOUNT, INVOICE_DISCOUNT, PROMO_CODE
			- code            -- null if lookup_value_id is not PROMO_CODE
			- start_date
			- end_date
			- priority -- if multiple match for one customer we give for the higher priority
			- state
			- customer_count null -- if it is null for all customers either for customer 

		### PromotionCondition -- Defines WHEN rule applies.
			- id
			- uuid
			- promotion_id
			- lookup_value_id  --- MIN_QUANTITY, MIN_AMOUNT, PRODUCT,GROUP, CATEGORY, BRAND
			- brand_id -- specific brand
			- product_id -- specific product
			- product_group_id --- product group
			- item_category_id -- product category
			- min_value  -- required quantity or total amount to get reward
			- is_required
			- state

		### PromotionReward -- Defines WHAT customer gets.
			- id
			- uuid
			- promotion_id -- promotin_condition_id
			- reward_type -- FREE_PRODUCT, DISCOUNT_PERCENT, DISCOUNT_AMOUNT
			- product_id -- gift item or product 
			- typelookup_value_id         -- FIXED | DISCOUNT
			- value DECIMAL               -- Price or percentage depending on type
			- reward_quantity -- gift quantity
			- state

## 6. Tax & Product Tax Management

	###6.1 Tax

		### TaxPolicy
			- id
			- uuid
			- name                -- VAT Proclamation No 285/2002
			- effective_from
			- effective_to null
			- state

		### TaxType
			- id
			- uuid
			- code        --TOT, VAT, EXCISE, SURTAX, WHT,
			- name
			- holdable    --- to show taxhold rate form
			- state

		###  TaxRate
			- id
			- uuid 
			- harmonization_code nullable for Excise
			- tax_type_id (tax_types.id)
			- rate_percent      --0 15, 20, 10, Ex => null, WHT-3..
			- holdable --- to show hold rate input during sales 
			- state

		###  TaxHoldRate
			- id 
			- uuid
			- tax_type_id (tax_types.id)
			- rate_percent      -- 7.5% for government 
			- state

		### TaxRatePolicy
			- id
			- uuid
			- tax_rate_id (tax_rates.id)
			- tax_policy_id (tax_policies.id)
			- start_date
			- end_date
			- state

		###  WithholdRule
			- id 
			- uuid
			- lookup_value_id --- ('goods','service') 
			- minimum_holdable
			- state

		### WithholdPolicy
			- id
			- uuid
			- tax_policy_id
			- withhold_rule_id  
			- start_date
			- end_date
			- state

	###6.2 ProductTax

		### ProductTaxRate --- Links product to applicable tax rates, Multiple taxes per product
			- id
			- uuid
			- product_id 
			- tax_rate_id
			- state
