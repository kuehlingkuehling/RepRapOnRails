# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)

Filament.create(
  :name => "K\u00fchling\u0026K\u00fchling ABS snow-white",
  :extrusion_temp => 260
)

PreheatingProfile.create(
  :name => "Preheating for ABS",
  :chamber_temp => 70,
  :bed_temp => 100
)