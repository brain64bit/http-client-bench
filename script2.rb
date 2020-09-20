require 'faraday'
require 'parallel'
require 'memory_profiler'
require 'json'


class Client
  attr_accessor :connection

  CHUNK_SIZE = 10
  COUNT = 500

  def initialize
    options = {
      url: -"https://jsonplaceholder.typicode.com",
      headers: {
        content_type: -"application/json"
      }
    }

    self.connection = Faraday.new(options)

  end

  def run
    ids = 1.upto(COUNT).to_a

    puts ">>>>> start populate responses"
    responses = Parallel.map(ids, in_processes: 8) do |id|
      request(id)
    end
    connection.close
    puts ">>>>> finish populate responses: #{responses.size}"
    puts ">>>>> last response: #{responses.last.body}"
  end

  def request(id)
    connection.get(-"/photos/#{id}")
  end
end
start_time = Time.now
duration = 0
MemoryProfiler.report do
  Client.new.run
  duration = Time.now - start_time
end.pretty_print(
  to_file: "log-#{Time.now.to_i}.txt",
  color_output: true,
  scale_bytes: true
)
puts "duration #{duration}s"
puts "enter to close ..."
gets
5.times { GC.start; puts "gc started"; sleep 1 }
sleep 5
