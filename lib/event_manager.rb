require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def count_frequency(arr)
  arr.max_by { |a| arr.count(a) }
end

def clean_phone_number(phone_number)

  phone_number.gsub!(/\D/, '')

  if phone_number.length == 10
    phone_number
  elsif phone_number.length == 1 && phone_number[1] == 1
    phone_number[1..10]
  else
    "Error"
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)
content_size = CSV.read('event_attendees.csv').length
template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
content_size-= 1
hour_of_day = Array.new(content_size)
day_of_week = Array.new(content_size)
j = 0
cal = { 0 => "sunday", 1 => "monday", 2 => "tuesday", 3 => "wednesday", 4 => "thursday", 5 => "friday", 6 => "saturday" }

contents.each do |row|

  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  hour_registration = row[:regdate]

  legislators = legislators_by_zipcode(zipcode)

  reg_date_to_print = DateTime.strptime(hour_registration, "%m/%d/%y %H:%M")
  hour_of_day[j] = reg_date_to_print.hour
  day_of_week[j] = reg_date_to_print.wday
  j += 1

  puts "Name: #{name}, phone_number: #{phone_number},
              zipCode: #{zipcode},
        Most Active hour is : #{count_frequency(hour_of_day)}
        Most Active hour is : #{cal[count_frequency(day_of_week)]}"

  form_letter = erb_template.result(binding)

  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end