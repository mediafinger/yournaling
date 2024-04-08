# RUN with: `ruby script/benchmarks/benchmark_yids.rb`
#
# Having the benchmark only create objects led to only minimal differences
# in which UUIDs and YIDs have been only a few % slower than incremental integer IDs.
#
# Once we compare finding records via ID / UUID / YID the differences
# become slightly more significant, as you can see below:
#
# ruby 3.2.2 (2023-03-30 revision e51014f9c0) [arm64-darwin21]
#
# Calculating -------------------------------------
#                  IDs      0.050 (± 0.0%) i/s -      1.000 in  20.064142s
#                UUIDs      0.049 (± 0.0%) i/s -      1.000 in  20.482737s
#                 YIDs      0.039 (± 0.0%) i/s -      1.000 in  25.832514s
#
# Comparison:
#                  IDs:        0.0 i/s
#                UUIDs:        0.0 i/s - 1.02x  slower
#                 YIDs:        0.0 i/s - 1.29x  slower
#
# Given the rather simple YID implementation, is only ~25% slower than UUIDs,
# and the performance costs will come mostly from string comparison in the SQL queries,
# I have no worries about paying this extra performance cost in a production environment.
# As this cost may rise in really large tables, or when joining many objects in a query,
# it would be good to keep an eye on it nevertheless.

require_relative "../../config/environment"

# Remove records created during a failed or canceled previous run

BenchmarkId.where(name: "BenchmarkId").delete_all
BenchmarkUuid.where(name: "BenchmarkUuid").delete_all
BenchmarkYid.where(name: "BenchmarkYid").delete_all

Team.find_by(name: "Team Id")&.destroy
Team.find_by(name: "Team Uuid")&.destroy
Team.find_by(name: "Team Yid")&.destroy

# Benchmark Setup

n = 1000
x = 50
t = 1000
m = x * t

puts "Starting Benchmark SETUP at: #{Time.current}"
puts "Will create 3x #{m} records and do 3x #{n} runs during the Benchmark."

team_id = Team.create!(name: "Team Id")
team_uuid = Team.create!(name: "Team Uuid")
team_yid = Team.create!(name: "Team Yid")

start_creating_ids = Time.current
puts "Starting creation of ID-records at: #{start_creating_ids.iso8601(4)}"
m.times do
  BenchmarkId.create!(name: " BenchmarkId ", team: team_id)
end
finish_creating_ids = Time.current
puts "Finished creation of ID-records, took: #{((finish_creating_ids - start_creating_ids) / x.to_f).round(4)}s / #{t}"

start_creating_uuids = Time.current
puts "Starting creation of UUID-records at: #{start_creating_uuids.iso8601(4)}"
m.times do
  BenchmarkUuid.create!(name: " BenchmarkUuid ", team: team_uuid)
end
finish_creating_uuids = Time.current
puts "Finished creation of UUID-records, took: #{((finish_creating_uuids - start_creating_uuids) / x.to_f).round(4)}s / #{t}"

start_creating_yids = Time.current
puts "Starting creation of YID-records at: #{start_creating_yids.iso8601(4)}"
m.times do
  BenchmarkYid.create!(name: " BenchmarkYid ", team: team_yid)
end
finish_creating_yids = Time.current
puts "Finished creation of YID-records, took: #{((finish_creating_yids - start_creating_yids) / x.to_f).round(4)}s / #{t}"

# Benchmark

puts "TIME_BEFORE: #{Time.current}"

Benchmark.ips do |x|
  x.report("IDs") do
    n.times do
      some_ids = BenchmarkId.order("RANDOM()").limit(400).pluck(:id).sample(50)
      some_ids.each do |id|
        BenchmarkId.find_by!(id:).created_at
      end
    end
  end

  x.report("UUIDs") do
    n.times do
      some_uuids = BenchmarkUuid.order("RANDOM()").limit(400).pluck(:id).sample(50)
      some_uuids.each do |uuid|
        BenchmarkUuid.find_by!(id: uuid).created_at
      end
    end
  end

  x.report("YIDs") do
    n.times do
      some_yids = BenchmarkYid.order("RANDOM()").limit(400).pluck(:yid).sample(50)
      some_yids.each do |yid|
        BenchmarkYid.find_by!(yid:).created_at
      end
    end
  end

  x.compare!
end

puts "TIME_AFTER: #{Time.current}"

# Remove created records

BenchmarkId.where(name: "BenchmarkId").delete_all
BenchmarkUuid.where(name: "BenchmarkUuid").delete_all
BenchmarkYid.where(name: "BenchmarkYid").delete_all

Team.find_by(name: "Team Id").destroy
Team.find_by(name: "Team Uuid").destroy
Team.find_by(name: "Team Yid").destroy
