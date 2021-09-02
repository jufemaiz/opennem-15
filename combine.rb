require 'csv'
require 'date'
require 'time'
require 'fileutils'

NEM_TIMEZONE = '+10:00'
SWIS_TIMEZONE = '+08:00'
OUTPUT_DIR = 'output'

FileUtils.mkdir_p(OUTPUT_DIR)

def read(filepath, timezone)
  CSV.read(
    filepath,
    header_converters: :symbol,
    headers: true,
    converters: :numeric
  ).map do |row|
    row = row.to_h

    date = row[:date].split
    row[:date] = Time.parse("#{date[0]}T#{date[1]}:00#{timezone}")

    row
  end
end

nem_data = read('20210902-nem.csv', NEM_TIMEZONE)
swis_data = read('20210901-swis.csv', SWIS_TIMEZONE)
all_data = read('20210902-all.csv', NEM_TIMEZONE)

combined = {
  types: [],
  data: {}
}

nem_data.each do |row|
  d = row[:date]
  combined[:data][d.utc] ||= { date: d, total: nil, swis: {}, nem: {}, all: {} }

  combined[:data][d.utc][:nem] = row
  combined[:data][d.utc][:nem].delete(:date)
end

swis_data.each do |row|
  d = row[:date]
  combined[:data][d.utc] ||= { date: d, total: nil, swis: {}, nem: {}, all: {} }

  combined[:data][d.utc][:swis] = row
  combined[:data][d.utc][:swis].delete(:date)
end

all_data.each do |row|
  d = row[:date]
  combined[:data][d.utc] ||= { date: d, total: nil, swis: {}, nem: {}, all: {} }

  combined[:data][d.utc][:all] = row
  combined[:data][d.utc][:all].delete(:date)

  combined[:types] |= row.keys
end

combined[:types].each do |type|
  headers = %w[data nem swis sum all_regions]
  output = []
  combined[:data].each_pair do |k, vals|
    nem = vals[:nem][type]
    swis = vals[:swis][type]
    all = vals[:all][type]
    sum = [nem, swis].compact.reduce(:+)

    output << [k.strftime('%FT%T%:z'), nem, swis, sum, all]
  end

  output.sort! { |x, y| x.first <=> y.first }

  CSV.open(File.join(OUTPUT_DIR, "#{type}.csv"), 'w+') do |csv|
    csv << headers

    output.each { |r| csv << r }
  end
end
