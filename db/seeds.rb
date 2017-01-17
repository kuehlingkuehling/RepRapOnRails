# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)

Filament.create(
  :name => "Polymaker PC-Max white",
  :extrusion_temp => 280
)

PreheatingProfile.create(
  :name => "Preheating for PC",
  :chamber_temp => 40,
  :bed_temp => 100
)