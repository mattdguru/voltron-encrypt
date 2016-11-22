cars = [
  "Camry",
  "Rogue",
  "Murano",
  "Tacoma",
  "Tundra",
  "Outback",
  "Forester",
  "Pathfinder",
  "4Runner",
  "Edge",
  "Blazer"
]

cars.each { |car| Car.create!(name: car) }