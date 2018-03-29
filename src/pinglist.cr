require "./pinglist/*"
require "commander"

# TODO: Write documentation for `Pinglist`

def getIpList(filename : String)
  list = [] of String

  # version 1 , just add 1
  File.read_lines(filename).each { |a|
    list = list + [a.gsub(/0\/[0-9]+$/, "1")]
  # ?\.[0-9]*\.[0-9]*\.(0)\/[0-9]*
  }

  list
end

def ping(iplist : Array(String))
  ch = Channel(Array(String)).new

  iplist.each { |x|
    puts "ping #{x}..."
    spawn do
      # puts 1
      output = IO::Memory.new
      Process.run("ping", ["-c 3", x], output: output)
      # puts output.to_s

      if res = /[0-9.]*\/([0-9.]*)\/[0-9.]*\/[0-9.]*/.match(output.to_s)
        # puts res[1]
        # ch.send({x => res[1]})
        ch.send([x, res[1]])
      else
        ch.send([x, "-1"])
      end
    end
  }

  our_file = File.open "result.txt", "w"

  iplist.size.times do
    res = ch.receive

    our_file.puts "#{res[0]} #{res[1]}"
  end

  our_file.close
end

module Pinglist
  cli = Commander::Command.new do |cmd|
    cmd.use = "pinglist"
    cmd.long = "ping a list of server"

    cmd.flags.add do |flag|
      flag.name = "infile"
      flag.short = "-i"
      flag.long = "--infile"
      flag.default = "~/iplist.txt"
      flag.description = "input ip list"
    end

    cmd.flags.add do |flag|
      flag.name = "outfile"
      flag.short = "-o"
      flag.long = "--outfile"
      flag.default = "~/result.txt"
      flag.description = "ping test result"
    end

    cmd.run do |options, arguments|
      infile = options.string["infile"]
      outfile = options.string["outfile"]

      iplist = getIpList(infile)

      ping(iplist)
      # puts iplist
    end
  end

  Commander.run(cli, ARGV)

  # iplist = getIpList("a.txt")

  # ping(iplist)
  # # puts iplist

  # puts "test over"
end
