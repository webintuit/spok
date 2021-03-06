require 'spok/version'
require 'spok/workday'
require 'spok/calendars'

Spok::Calendars.preload
# Public: Class responsible for dealing with periods of Dates, considering
# workdays and restdays.
class Spok
  # Internal: String specifying format for dates in the period.
  DATE_FORMAT = '%Y%m%d'.freeze

  attr_reader :start_date, :end_date

  mattr_reader :default_calendar

  @@default_calendar = :brazil

  # Public: Add a new calendar of holidays to Spok. Calendars are defined with
  # YAML files containing a single key with its name and an array of dates.
  #
  # For reference of builtin calendars, please see the `lib/spok/config` directory.
  #
  # name - A String or Symbol with the name of the calendar.
  # path - A String with the full path for the calendar YAML file.
  #
  # Returns nothing.
  def self.add_calendar(name, path)
    Spok::Calendars.add(name, path)
  end

  # Public: Parses a string into a Spok.
  #
  # dates_string - String containing the start and end dates for a period of
  #                 days separated by a dash.
  #
  # Examples
  #
  #   Spok.parse('20120101-20120103')
  #   # => #<Spok:0x00007f951e8a2ea0 ...>
  #
  #   Spok.parse('invalid string')
  #   # => nil
  #
  # Returns a Spok or nil when the string does not contain two valid dates.
  def self.parse(dates_string)
    return nil unless dates_string

    start_date, end_date = dates_string.split('-')

    if start_date && end_date
      return Spok.new(::Date.parse(start_date), ::Date.parse(end_date))
    end

    nil
  end

  # Public: Initialize a Spok.
  #
  # start_date - Initial Date for the Spok.
  # end_date - Final Date for Spok.
  def initialize(start_date, end_date)
    @start_date = start_date
    @end_date = end_date
    validate!
  end

  # Public: Returns the Spok start date as an Integer.
  #
  # Examples
  #
  #   spok.start_date_as_integer
  #   # => 20120101
  def start_date_as_integer
    as_integer @start_date
  end

  # Public: Returns the Spok end date as an Integer.
  #
  # Examples
  #
  #   spok.end_date_as_integer
  #   # => 20120103
  def end_date_as_integer
    as_integer @end_date
  end

  # Public: Returns the Spok start date as a String.
  #
  # Examples
  #
  #   spok.start_date_as_string
  #   # => "20120101"
  def start_date_as_string
    as_string @start_date
  end

  # Public: Returns the Spok end date as a String.
  #
  # Examples
  #
  #   spok.end_date_as_string
  #   # => "20120103"
  def end_date_as_string
    as_string @end_date
  end

  # Public: Returns an array containing all workdays on Spok.
  #
  # calendar - Symbol informing in which calendar to check for workdays
  #            (default: :brazil).
  #
  # Examples
  #
  #   spok.workdays
  #   # => [Mon, 02 Jan 2012, Tue, 03 Jan 2012]
  def workdays(calendar = Spok.default_calendar)
    (@start_date..@end_date).to_a.delete_if{ |date| Workday.restday?(date, calendar: calendar) }
  end

  # Public: Checks if a given day is a restday.
  #
  # date     - The Date to be checked.
  # calendar - Symbol informing in which calendar the date will be checked
  #            (default: :brazil).
  #
  # Examples
  #
  #   Spok.restday?(Date.new(2012, 8, 6))
  #   # => false
  #
  # Returns a boolean.
  def self.restday?(date, calendar: Spok.default_calendar)
    Workday.restday?(date, calendar: calendar)
  end

  # Public: Checks if a given day is a workday.
  #
  # date     - The Date to be checked.
  # calendar - Symbol informing in which calendar the date will be checked
  #            (default: :brazil).
  #
  # Examples
  #
  #   Spok.workday?(Date.new(2012, 8, 6))
  #   # => true
  #
  # Returns a boolean.
  def self.workday?(date, calendar: Spok.default_calendar)
    Workday.workday?(date, calendar: calendar)
  end

  # Public: Checks if a given Date is on a weekend.
  #
  # date - The Date to be checked.
  #
  # Examples
  #
  #   Spok.weekend?(Date.new(2012, 8, 6))
  #   # => false
  #
  # Returns a boolean.
  def self.weekend?(date)
    Workday.weekend?(date)
  end

  # Public: Checks if a given Date is on a holiday.
  #
  # date     - The Date to be checked.
  # calendar - Symbol informing in which calendar the date will be checked
  #            (default: :brazil).
  #
  # Examples
  #
  #   Spok.holiday?(Date.new(2012, 5, 1))
  #   # => true
  #
  # Returns a boolean.
  def self.holiday?(date, calendar: Spok.default_calendar)
    Workday.holiday?(date, calendar: calendar)
  end

  # Public: Returns the last workday until the informed date.
  # It returns the informed date in case it is a workday.
  #
  # date     - End Date to check for workdays.
  # calendar - Symbol informing in which calendar the date will be checked
  #            (default: :brazil).
  #
  # Examples
  #   Spok.last_workday(Date.new(2012, 10, 21))
  #   # => #<Date: 2012-10-19 ((2456220j,0s,0n),+0s,2299161j)>
  def self.last_workday(date, calendar: Spok.default_calendar)
    Workday.last_workday(date, calendar: calendar)
  end

  # Public: Returns the next workday starting from the informed date.
  # It returns the informed date in case it is a workday.
  #
  # date     - Start Date to check for workdays.
  # calendar - Symbol informing in which calendar the date will be checked
  #            (default: :brazil).
  #
  # Examples
  #   Spok.next_workday(Date.new(2012, 10, 21))
  #   # => #<Date: 2012-10-19 ((2456220j,0s,0n),+0s,2299161j)>
  def self.next_workday(date, calendar: Spok.default_calendar)
    Workday.next_workday(date, calendar: calendar)
  end

  # Public: Returns a Spok containing the same dates in a different calendar.
  #
  # calendar - Symbol informing calendar for new Spok (default: :brazil).
  #
  # Examples
  #
  #   spok.to_calendar(:brazil)
  #   # => #<Spok:0x00007fbf122dba08 ...>
  def to_calendar(calendar = Spok.default_calendar)
    Spok.new(
      Workday.last_workday(@start_date, calendar: calendar),
      Workday.last_workday(@end_date, calendar: calendar)
    )
  end

  # Public: Returns an array containing all Dates on Spok.
  #
  # Examples
  #
  #   spok.to_a
  #   # => [Sun, 01 Jan 2012, Mon, 02 Jan 2012, Tue, 03 Jan 2012]
  def to_a
    (@start_date..@end_date).to_a
  end

  # Public: Returns a String containing the Spok start and end date separated
  # by a dash.
  #
  # Examples
  #
  #   spok.to_s
  #   # => "20120101-20120103"
  def to_s
    "#{start_date_as_string}-#{end_date_as_string}"
  end

  # Public: Informs whether the Spok has just one day or not.
  #
  # Examples
  #
  #   spok.one_day?
  #   # => false
  #
  # Returns a boolean.
  def one_day?
    @start_date == @end_date
  end

  # Public: Returns an Integer with the number of days in the Spok.
  #
  # Examples
  #
  #   spok.days_count
  #   # => 2
  def days_count
    (@end_date - @start_date).to_i
  end

  # Public: Returns a Float with the number of years in the Spok.
  #
  # Examples
  #
  #   spok.years_count
  #   # => 1.6
  def years_count
    ((@end_date - @start_date).to_f / 365).to_f.round(1)
  end

  # Public: Compares the Spok with other Spok. Two spoks are considered
  # equal when they are both instances of Spok, and have the same start and
  # end dates.
  #
  # other - Spok to be checked against.
  #
  # Examples
  #
  #   spok == other
  #   # => false
  #
  # Returns a boolean.
  def ==(other)
    other.class == self.class &&
      other.start_date == @start_date &&
      other.end_date == @end_date
  end

  # Public: Returns a range containing the Dates in the Spok.
  #
  # Examples
  #
  #   spok.to_range
  #   # => Sun, 01 Jan 2012..Tue, 03 Jan 2012
  def to_range
    (@start_date..@end_date)
  end

  class << self
    def default_calendar=(calendar)
      class_variable_set(:@@default_calendar, calendar)
    end
  end

  private

  def as_string(date)
    date.strftime(DATE_FORMAT)
  end

  def as_integer(date)
    date.strftime(DATE_FORMAT).to_i
  end

  def validate!
    raise ArgumentError, 'Start date must be present.' unless @start_date
    raise ArgumentError, 'End date must be present.' unless @end_date

    if @start_date > @end_date
      raise ArgumentError, "End date (#{@end_date}) must be greater or equal to start date (#{@start_date})"
    end
  end
end
