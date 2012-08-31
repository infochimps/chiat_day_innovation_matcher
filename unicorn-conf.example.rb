#!/usr/bin/env ruby
worker_processes  1
preload_app       true
stderr_path       'log/unicorn.stderr.log'
stdout_path       'log/unicorn.stdout.log'

# # REE
GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)

timeout             80
working_directory   ''
listen              'tmp/unicorn.sock', :backlog => 64
pid                 'tmp/unicorn.pid'

after_fork do |server, worker|
  # per-process listener ports for debugging/admin/migrations
  addr = "0.0.0.0:#{3000 + worker.nr}"
  # keep trying to connect to port, wait 5s in between (an older daemon might
  # still be quitting and won the port).
  server.listen(addr, :tries => -1, :delay => 5, :backlog => 64)  # , :tcp_nopush => true
end
