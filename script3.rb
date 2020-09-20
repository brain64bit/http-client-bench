require 'excon'
require 'parallel'
require 'memory_profiler'
require 'json'


class Client
  attr_accessor :connection, :manager

  CHUNK_SIZE = 10
  COUNT = 500

  def initialize
    self.connection = Excon.new(-"https://jsonplaceholder.typicode.com", debug_request: true)
  end

  def run
    requests = 1.upto(COUNT).to_a.map{|id| request(id) }.each_slice(10).to_a

    responses = [] 
    puts ">>>>> start populate responses"
    responses = Parallel.map(requests, in_processes: 8) do |slice_requests|
      connection.batch_requests(slice_requests)
    end
    responses.flatten!
    puts ">>>>> finish populate responses: #{responses.size}"
    puts ">>>>> last response: #{responses.last.body}"
  end

  def request(id)
    {
      method: :get,
      path: -"/photos/#{id}",
      headers: {
        "Content-Type" => "application/json"
      }
    }
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
