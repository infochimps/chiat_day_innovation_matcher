working_directory   File.dirname(__FILE__)

worker_processes  1
preload_app       true
stderr_path       File.expand_path('../log/unicorn.stderr.log', __FILE__)
stdout_path       File.expand_path('../log/unicorn.stdout.log', __FILE__)
pid               File.expand_path('../tmp/unicorn.pid',        __FILE__)

# # REE
GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)

timeout           80
listen            File.expand_path('../tmp/unicorn.sock', __FILE__), :backlog => 64

after_fork do |server, worker|
  # per-process listener ports for debugging/admin/migrations
  addr = "0.0.0.0:#{3000 + worker.nr}"
  # keep trying to connect to port, wait 5s in between (an older daemon might
  # still be quitting and won the port).
  server.listen(addr, :tries => -1, :delay => 5, :backlog => 64)  # , :tcp_nopush => true
end

