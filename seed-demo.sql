-- Demo products were removed from the seed script.
-- Use this cleanup when a demo batch was already inserted in the database.
delete from products where is_demo = true;
