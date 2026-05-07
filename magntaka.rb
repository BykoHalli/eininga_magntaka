require 'csv'

model = Sketchup.active_model
entities = model.entities

unit_data = {}

# Helper to extract dimensions from a transformation-applied bounding box
def get_dimensions(entity)
  # Determine whether it's a group or component
  entities = entity.respond_to?(:definition) ? entity.definition.entities : entity.entities

  # Get all vertex positions from faces
  points = []
  entities.grep(Sketchup::Face).each do |face|
    face.vertices.each do |v|
      points << v.position
    end
  end

  return [0, 0, 0] if points.empty?

  # In local coordinates, so just measure min/max directly
  x_vals = points.map(&:x)
  y_vals = points.map(&:y)
  z_vals = points.map(&:z)

  width  = (x_vals.max - x_vals.min).to_mm.round(0)
  depth  = (y_vals.max - y_vals.min).to_mm.round(0)
  height = (z_vals.max - z_vals.min).to_mm.round(0)

  [width, depth, height].sort
end

# Helper to check name prefix
def is_samlokueining?(name)
  name.downcase.start_with?("samlokueining")
end

# Gather data from groups
# entities.grep(Sketchup::Group).each do |group|
#   name = group.name
#   next unless is_samlokueining?(name)
#   unit_data[name] = get_dimensions(group)
# end

# Gather data from component instances
entities.grep(Sketchup::ComponentInstance).each do |instance|
  name = instance.definition.name
  next unless is_samlokueining?(name)
  dimensions = get_dimensions(instance)
  samloku_type = name.split(" - ")[1]
  pound_index = samloku_type.index('#')
  if pound_index != nil
    pound_index = pound_index-1
  end
  samloku_type = samloku_type[0..pound_index]
  dict_key = "samlokueining - " + samloku_type + " - " + dimensions[0].to_s + " - " + dimensions[1].to_s + " - " + dimensions[2].to_s
  if unit_data[dict_key] == nil
    unit_data[dict_key] = 1
  else
    unit_data[dict_key] += 1
  end
end

# Prepare output file path (Desktop/samlokueining_data.csv)
csv_path = "C:/Users/hallgrimur/Desktop/VinnuHalli/Documents-Vinna/Forritun/sketchup/eininga_magntaka/samlokueining_data.csv"

# Write to CSV
timestamp = Time.now.strftime("%H:%M:%S:%d:%m:%Y")
total_string = timestamp + ";;;;\n" + "Type;thickness;width;length;count\n"

begin
  unit_data.each do |name, count|
    name_list = name.split(" - ")
    
    total_string += name_list[1] + ";" + name_list[2] + ";" + name_list[3] + ";" + name_list[4] + ";" + count.to_s + "\n"
  end

  csv_path = UI.savepanel("Save data to...", "C:/Users/hallgrimur/Desktop/VinnuHalli/Documents-Vinna/Forritun/sketchup/eininga_magntaka", "*.csv")

  File.write(csv_path, total_string)
  


  UI.messagebox("CSV export complete!\nSaved to:\n#{csv_path}")
rescue StandardError => e
  UI.messagebox("Failed to write CSV:\n#{e.message}")
end

